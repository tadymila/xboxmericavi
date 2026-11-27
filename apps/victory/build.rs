//! xboxmericavi: puts `branding/icon.ico` into `victory.exe` as its icon.
//!
//! The icon file is turned into a compiled resource file (`.res`) here, with
//! no tool and no crate: a `.res` is a list of entries, each a small header
//! and its bytes. The MSVC linker takes the `.res` as an input and puts the
//! resources in the executable. Other targets get no icon.

use std::path::PathBuf;

const RT_ICON: u16 = 3;
const RT_GROUP_ICON: u16 = 14;

fn main() {
    let manifest = PathBuf::from(std::env::var("CARGO_MANIFEST_DIR").unwrap());
    let icon = manifest.join("../../branding/icon.ico");
    println!("cargo:rerun-if-changed={}", icon.display());
    let target = std::env::var("TARGET").unwrap_or_default();
    if !target.contains("windows-msvc") {
        return;
    }
    let Ok(ico) = std::fs::read(&icon) else {
        println!("cargo:warning=no {}: victory.exe gets no icon", icon.display());
        return;
    };
    let Some(res) = resources(&ico) else {
        println!("cargo:warning={} is not an icon file: victory.exe gets no icon", icon.display());
        return;
    };
    let out = PathBuf::from(std::env::var("OUT_DIR").unwrap()).join("icon.res");
    std::fs::write(&out, res).unwrap();
    println!("cargo:rustc-link-arg-bins={}", out.display());
}

fn u16_at(b: &[u8], at: usize) -> Option<u16> {
    Some(u16::from_le_bytes(b.get(at..at + 2)?.try_into().ok()?))
}

fn u32_at(b: &[u8], at: usize) -> Option<u32> {
    Some(u32::from_le_bytes(b.get(at..at + 4)?.try_into().ok()?))
}

/// The `.res` bytes for the images of an `.ico` file: one icon resource per
/// image (ids 1..), and the group that lists them (id 1, the one Explorer shows).
fn resources(ico: &[u8]) -> Option<Vec<u8>> {
    if u16_at(ico, 0)? != 0 || u16_at(ico, 2)? != 1 {
        return None;
    }
    let count = usize::from(u16_at(ico, 4)?);
    let mut res = Vec::new();
    // A .res file starts with an empty entry.
    entry(&mut res, 0, 0, 0, &[]);
    let mut group = Vec::new();
    group.extend(0u16.to_le_bytes());
    group.extend(1u16.to_le_bytes());
    group.extend((count as u16).to_le_bytes());
    for i in 0..count {
        let dir = 6 + 16 * i;
        let len = u32_at(ico, dir + 8)? as usize;
        let at = u32_at(ico, dir + 12)? as usize;
        let image = ico.get(at..at + len)?;
        let id = (i + 1) as u16;
        entry(&mut res, RT_ICON, id, 0x1010, image);
        // The directory entry as in the file, with the resource id in place of the offset.
        group.extend(ico.get(dir..dir + 12)?);
        group.extend(id.to_le_bytes());
    }
    entry(&mut res, RT_GROUP_ICON, 1, 0x1030, &group);
    Some(res)
}

/// One `.res` entry: a header naming the type and the id by number, then the
/// bytes, each part padded to four bytes.
fn entry(res: &mut Vec<u8>, kind: u16, id: u16, flags: u16, data: &[u8]) {
    let mut header = Vec::new();
    header.extend((data.len() as u32).to_le_bytes());
    header.extend(32u32.to_le_bytes()); // this header's size
    header.extend([0xff, 0xff]);
    header.extend(kind.to_le_bytes());
    header.extend([0xff, 0xff]);
    header.extend(id.to_le_bytes());
    header.extend(0u32.to_le_bytes()); // data version
    header.extend(flags.to_le_bytes());
    // Language: none for the empty entry, US English (what rc.exe writes by default) otherwise.
    header.extend(if kind == 0 { 0u16 } else { 0x0409u16 }.to_le_bytes());
    header.extend(0u32.to_le_bytes()); // version
    header.extend(0u32.to_le_bytes()); // characteristics
    debug_assert_eq!(header.len(), 32);
    res.extend(header);
    res.extend(data);
    while res.len() % 4 != 0 {
        res.push(0);
    }
}
