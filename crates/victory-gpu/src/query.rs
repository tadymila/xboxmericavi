//! Query heaps. Nothing runs on a GPU yet, so no query ever produces a
//! result; the heap only remembers its description.
#![allow(clippy::not_unsafe_ptr_arg_deref)]

use crate::object::{self, E_INVALIDARG, HRESULT, Iid, Object, QUERY_HEAP, Table, This, guid};
use crate::resource::PAGEABLE_IIDS;

const HEAP_IIDS: [Iid; 4] = [
    guid(
        0x0d9658ae,
        0xed45,
        0x469e,
        [0xa6, 0x1d, 0x97, 0x0e, 0xc5, 0x83, 0xca, 0xb4],
    ),
    PAGEABLE_IIDS[0],
    PAGEABLE_IIDS[1],
    PAGEABLE_IIDS[2],
];

#[repr(C)]
#[derive(Debug, Clone, Copy)]
pub(crate) struct Desc {
    kind: u32,
    count: u32,
    nodes: u32,
}

#[repr(C)]
struct Heap {
    object: Object,
    desc: Desc,
    /// With `VICTORY_OCCLUSION`: the host heap occlusion queries run in, made on first use (none for other kinds).
    #[cfg(windows)]
    host: std::sync::OnceLock<Option<windows::Win32::Graphics::Direct3D12::ID3D12QueryHeap>>,
    /// Per query: 0 not on the host (answered "visible" as before), `list << 2 | 1` begun on the host in that host
    /// list, 2 ended on the host. Made with the host heap.
    #[cfg(windows)]
    states: std::sync::OnceLock<Vec<std::sync::atomic::AtomicUsize>>,
}

/// Device method.
pub(crate) extern "system" fn create(
    _: This,
    desc: *const Desc,
    iid: *const Iid,
    out: *mut This,
) -> HRESULT {
    // SAFETY: the title passes a description (null is tolerated).
    let Some(&desc) = (unsafe { desc.as_ref() }) else {
        return E_INVALIDARG;
    };
    tracing::debug!(?desc, "query heap");
    let heap = Box::new(Heap {
        object: Object::new(&FUNCTIONS),
        desc,
        #[cfg(windows)]
        host: std::sync::OnceLock::new(),
        #[cfg(windows)]
        states: std::sync::OnceLock::new(),
    });
    object::hand_out(QUERY_HEAP, heap, iid, &HEAP_IIDS, out)
}

/// Whether occlusion queries (console kinds 0 and 1) run on the host GPU and their results are resolved from it
/// (`VICTORY_OCCLUSION=1`; off by default: every one answers "visible", as before; `alt`: twenty seconds with,
/// twenty without, in turn, each change said in the log; decided at each `BeginQuery`). After Marvisak/VIctory
/// #3138 (FoxxoOwO), occlusion only.
#[cfg(windows)]
pub(crate) fn occlusion() -> bool {
    /// 0 off, 1 on, 2 in turn.
    static MODE: std::sync::OnceLock<u8> = std::sync::OnceLock::new();
    match *MODE.get_or_init(|| match std::env::var("VICTORY_OCCLUSION").as_deref() {
        Ok("1") => 1,
        Ok("alt") => 2,
        _ => 0,
    }) {
        0 => false,
        1 => true,
        _ => {
            static EPOCH: std::sync::OnceLock<std::time::Instant> = std::sync::OnceLock::new();
            let on = (EPOCH.get_or_init(std::time::Instant::now).elapsed().as_secs() / 20) % 2 == 1;
            static LAST: std::sync::atomic::AtomicU8 = std::sync::atomic::AtomicU8::new(2);
            if LAST.swap(u8::from(on), std::sync::atomic::Ordering::Relaxed) != u8::from(on) {
                tracing::info!(
                    "occlusion queries run on the host GPU from now (VICTORY_OCCLUSION=alt): {}",
                    if on { "ON" } else { "off, every one answers visible as usual" }
                );
            }
            on
        }
    }
}

/// Always counted: `BeginQuery` calls by console kind (0 occlusion, 1 binary, 2 timestamp, 3 statistics, 4
/// other), queries ended on the host, queries resolved from the host, queries resolved as "visible".
pub(crate) static COUNTS: [std::sync::atomic::AtomicU64; 8] = [const { std::sync::atomic::AtomicU64::new(0) }; 8];

/// Counts a `BeginQuery` of `kind`; says the counts at every power of two of all of them (whether the title uses
/// queries at all decides whether this lever can matter).
pub(crate) fn counted(kind: u32) {
    use std::sync::atomic::Ordering::Relaxed;
    COUNTS[kind.min(4) as usize].fetch_add(1, Relaxed);
    let all: u64 = (0..5).map(|k| COUNTS[k].load(Relaxed)).sum();
    if all.is_power_of_two() {
        let c = COUNTS.each_ref().map(|a| a.load(Relaxed));
        tracing::info!(
            "queries begun so far: {} occlusion, {} binary occlusion, {} timestamp, {} statistics, {} other; on the host (VICTORY_OCCLUSION): {} ended, {} resolved from it, {} resolved as visible",
            c[0], c[1], c[2], c[3], c[4], c[5], c[6], c[7]
        );
    }
}

/// The host heap and per-query states of the console heap `this` (occlusion kinds only), made on first use.
#[cfg(windows)]
fn host_heap(this: This) -> Option<(&'static Heap, windows::Win32::Graphics::Direct3D12::ID3D12QueryHeap)> {
    use windows::Win32::Graphics::Direct3D12::*;
    if this.is_null() {
        return None;
    }
    // SAFETY: the title passes one of our query heaps, alive while it uses it.
    let heap: &'static Heap = unsafe { &*this.cast::<Heap>() };
    if heap.desc.kind > 1 || heap.desc.count == 0 {
        return None;
    }
    let host = heap
        .host
        .get_or_init(|| {
            let device = crate::host::host()?.device().clone();
            let mut made: Option<ID3D12QueryHeap> = None;
            // SAFETY: plain object creation.
            unsafe {
                device
                    .CreateQueryHeap(
                        &D3D12_QUERY_HEAP_DESC { Type: D3D12_QUERY_HEAP_TYPE_OCCLUSION, Count: heap.desc.count, NodeMask: 0 },
                        &mut made,
                    )
                    .ok()?;
            }
            made
        })
        .clone()?;
    heap.states.get_or_init(|| (0..heap.desc.count).map(|_| std::sync::atomic::AtomicUsize::new(0)).collect());
    Some((heap, host))
}

#[cfg(windows)]
fn host_type(kind: u32) -> windows::Win32::Graphics::Direct3D12::D3D12_QUERY_TYPE {
    use windows::Win32::Graphics::Direct3D12::*;
    if kind == 1 { D3D12_QUERY_TYPE_BINARY_OCCLUSION } else { D3D12_QUERY_TYPE_OCCLUSION }
}

/// `BeginQuery` of an occlusion query on `list`: begun on the host too, with the switch on.
#[cfg(windows)]
pub(crate) fn begin(list: &crate::host::HostList, this: This, kind: u32, index: u32) {
    if kind > 1 || !occlusion() {
        return;
    }
    let Some((heap, host)) = host_heap(this) else { return };
    let Some(state) = heap.states.get().and_then(|s| s.get(index as usize)) else { return };
    // SAFETY: an open list and our query heap; the index is inside it.
    unsafe { list.list.BeginQuery(&host, host_type(kind), index) };
    state.store((list as *const _ as usize) << 2 | 1, std::sync::atomic::Ordering::Relaxed);
    list.query_opened(host, kind, index, this as usize);
}

/// `EndQuery` of an occlusion query on `list`: ended on the host if it was begun there in this same list (D3D12
/// wants both in one list); one begun in another list is left to that list's close and answers "visible".
#[cfg(windows)]
pub(crate) fn end(list: &crate::host::HostList, this: This, kind: u32, index: u32) {
    use std::sync::atomic::Ordering::Relaxed;
    if kind > 1 {
        return;
    }
    let Some((heap, host)) = host_heap(this) else { return };
    let Some(state) = heap.states.get().and_then(|s| s.get(index as usize)) else { return };
    let mine = (list as *const _ as usize) << 2 | 1;
    let now = state.load(Relaxed);
    if now == mine {
        // SAFETY: an open list and our query heap; the query was begun in this list.
        unsafe { list.list.EndQuery(&host, host_type(kind), index) };
        state.store(2, Relaxed);
        list.query_closed(this as usize, index);
        COUNTS[5].fetch_add(1, Relaxed);
    } else if now & 3 == 1 {
        state.store(0, Relaxed);
    }
}

/// At the close of `list`: queries begun on the host in it and not ended there are ended now (D3D12 wants it) and
/// answer "visible" (their state goes back to 0).
#[cfg(windows)]
pub(crate) fn close_open(open: Vec<(windows::Win32::Graphics::Direct3D12::ID3D12QueryHeap, u32, u32, usize)>, list: &crate::host::HostList) {
    for (host, kind, index, console) in open {
        // SAFETY: an open list and our query heap; the query was begun in this list.
        unsafe { list.list.EndQuery(&host, host_type(kind), index) };
        if let Some((heap, _)) = host_heap(console as This)
            && let Some(state) = heap.states.get().and_then(|s| s.get(index as usize))
        {
            state.store(0, std::sync::atomic::Ordering::Relaxed);
        }
    }
}

/// Read-back buffers of resolved queries, by slot, with the byte offset of the slot's result and the value written
/// if the read fails ([`result`]).
#[cfg(windows)]
static RESULTS: std::sync::Mutex<Option<std::collections::HashMap<u32, Back>>> = std::sync::Mutex::new(None);

/// A slot of [`RESULTS`]: the read-back buffer, the result's byte offset in it, the value if it cannot be read.
#[cfg(windows)]
struct Back(windows::Win32::Graphics::Direct3D12::ID3D12Resource, u64, u64);
// SAFETY: D3D12 resources are free-threaded; the buffer is only mapped and read, behind the lock's hand-over.
#[cfg(windows)]
unsafe impl Send for Back {}
static NEXT_SLOT: std::sync::atomic::AtomicU32 = std::sync::atomic::AtomicU32::new(0);

/// `ResolveQueryData` of `count` occlusion queries from `first` into title memory at `title` (8 bytes each): from
/// the host GPU if every one of them was begun and ended on the host, as `Written::Query` writes landing with the
/// list (as the "visible" answers did); false (the caller answers "visible") otherwise.
#[cfg(windows)]
pub(crate) fn resolve(list: &crate::host::HostList, this: This, kind: u32, first: u32, count: u32, title: u64) -> bool {
    use std::sync::atomic::Ordering::Relaxed;
    use windows::Win32::Graphics::Direct3D12::*;
    use windows::Win32::Graphics::Dxgi::Common::DXGI_SAMPLE_DESC;
    if kind > 1 || count == 0 {
        return false;
    }
    let Some((heap, host)) = host_heap(this) else { return false };
    let Some(states) = heap.states.get() else { return false };
    let all_ended = (first..first.saturating_add(count)).all(|i| states.get(i as usize).is_some_and(|s| s.load(Relaxed) == 2));
    if !all_ended {
        COUNTS[7].fetch_add(u64::from(count), Relaxed);
        return false;
    }
    let Some(device) = crate::host::host().map(|h| h.device().clone()) else { return false };
    let readback = D3D12_HEAP_PROPERTIES { Type: D3D12_HEAP_TYPE_READBACK, ..Default::default() };
    let desc = D3D12_RESOURCE_DESC {
        Dimension: D3D12_RESOURCE_DIMENSION_BUFFER,
        Width: u64::from(count) * 8,
        Height: 1,
        DepthOrArraySize: 1,
        MipLevels: 1,
        SampleDesc: DXGI_SAMPLE_DESC { Count: 1, Quality: 0 },
        Layout: D3D12_TEXTURE_LAYOUT_ROW_MAJOR,
        ..Default::default()
    };
    let mut back: Option<ID3D12Resource> = None;
    // SAFETY: plain object creation.
    if unsafe { device.CreateCommittedResource(&readback, D3D12_HEAP_FLAG_NONE, &desc, D3D12_RESOURCE_STATE_COPY_DEST, None, &mut back) }.is_err() {
        return false;
    }
    let Some(back) = back else { return false };
    // SAFETY: an open list, our query heap (every query of the range ended), a read-back buffer of their size.
    unsafe { list.list.ResolveQueryData(&host, host_type(kind), first, count, &back, 0) };
    let visible = if kind == 1 { 1 } else { 1 << 20 };
    let mut results = RESULTS.lock().unwrap_or_else(|e| e.into_inner());
    let results = results.get_or_insert_with(Default::default);
    for i in 0..count {
        let slot = NEXT_SLOT.fetch_add(1, Relaxed);
        results.insert(slot, Back(back.clone(), u64::from(i) * 8, visible));
        list.defer_write(title.wrapping_add(u64::from(i) * 8) as *mut u8, crate::queue::Written::Query(slot), 8);
    }
    COUNTS[6].fetch_add(u64::from(count), Relaxed);
    true
}

/// The value of the resolved query in `slot` ([`resolve`]), once the list has run: read from its read-back buffer,
/// or "visible" if that fails. The slot is let go.
pub(crate) fn result(slot: u32) -> u64 {
    #[cfg(windows)]
    {
        use windows::Win32::Graphics::Direct3D12::D3D12_RANGE;
        let entry = RESULTS.lock().unwrap_or_else(|e| e.into_inner()).as_mut().and_then(|m| m.remove(&slot));
        let Some(Back(back, at, visible)) = entry else { return 1 << 20 };
        let mut data = std::ptr::null_mut();
        let range = D3D12_RANGE { Begin: at as usize, End: at as usize + 8 };
        // SAFETY: a read-back buffer the list resolved into; it has run.
        if unsafe { back.Map(0, Some(&range), Some(&mut data)) }.is_err() || data.is_null() {
            return visible;
        }
        // SAFETY: the mapped buffer holds the slot's 8 bytes at `at`.
        let value = unsafe { data.cast::<u8>().add(at as usize).cast::<u64>().read_unaligned() };
        // SAFETY: the same buffer, mapped above.
        unsafe { back.Unmap(0, Some(&D3D12_RANGE { Begin: 0, End: 0 })) };
        value
    }
    #[cfg(not(windows))]
    {
        let _ = slot;
        1 << 20
    }
}

extern "system" fn query(this: This, iid: *const Iid, out: *mut This) -> HRESULT {
    object::answer(
        QUERY_HEAP,
        iid,
        object::is(iid, &HEAP_IIDS).then_some(this),
        out,
    )
}
extern "system" fn release(this: This) -> u32 {
    object::release_boxed::<Heap>(this)
}

/// IUnknown 3, object 4, device child 1.
static FUNCTIONS: Table<24> = {
    let mut f = object::d3d12_object(object::missing_table::<QUERY_HEAP, 24>());
    f[0] = query as *const ();
    f[2] = release as *const ();
    f[7] = object::parent_device as *const (); // 0x38
    Table(f)
};
