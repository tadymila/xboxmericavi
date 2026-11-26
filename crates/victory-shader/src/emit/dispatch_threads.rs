//! Threads past a `DispatchX` thread count (after fork pull request #646,
//! mynzjerko).
//!
//! The console's `DispatchX(x, y, z, flags)` with bit 5 of its flags
//! (`COMPUTE_DISPATCH_INITIATOR.USE_THREAD_DIMENSIONS`, 0x20) counts
//! threads, not groups: the card runs the groups that hold them, and in the
//! last group of an axis the threads at or past the count are not in EXEC.
//! The ray-tracing structure builder's two box stages dispatch this way
//! (`28918b7150a7aad5`, `caa78b8ca62bc3d6`; 0x8020 on `4ddd6f9702fab2a7`,
//! `5062bc7a48e842f8`). Taken as groups they ran up to 64 times the threads
//! asked for and wrote nodes megabytes past the structure, over the title's
//! own objects: the title died seconds after the builder started (fork
//! testers on 32-lane cards, and our run 336).
//!
//! The host dispatches whole groups ([`super::super::shader::USER_DISPATCH_THREADS`]
//! gives the count per axis, 0 for whole groups); here the threads past it
//! leave at once where nothing makes them wait, else stay for the group's
//! barriers and the halves' exchange and do nothing that shows.

use super::super::shader::USER_DISPATCH_THREADS;
use super::{Bin, Lower, Term, V, Val, Why, pred};
use crate::native::RootType;

impl<'a> Lower<'a> {
    /// The guard of an instruction with an effect (a memory or LDS access,
    /// a sample): [`Self::guard`], and within the `DispatchX` thread count
    /// when the threads past it stay ([`Self::partial_active`]).
    pub(super) fn effect_guard(&mut self, b: usize, i: usize) -> Result<Option<V>, Why> {
        let g = self.guard(b, i)?;
        Ok(match (g, self.partial_active) {
            (Some(g), Some(a)) => Some(self.s.m.bin(self.cur, Bin::And, g, a)),
            (g, a) => g.or(a),
        })
    }

    /// For a compute program with a spilled user-data table: whether this
    /// thread lies within the `DispatchX` thread count of each axis whose
    /// group is wider than one thread (`USER_DISPATCH_THREADS`, 0: no
    /// count). Without a group barrier, a halves' exchange or a loop back to
    /// the first block, the threads past it return from the entry block, so
    /// EXEC, ballots and wave reductions see the console's lanes with no
    /// guard on each instruction; else they stay and [`Self::partial_active`]
    /// leaves them out of memory accesses, ballots and reductions.
    pub(super) fn dispatch_threads_prologue(&mut self, order: &[usize]) {
        let Some(threads) = self.s.threads else {
            return;
        };
        let e = self.s.entry;
        let zero = self.s.m.i32(0);
        let mut active: Option<V> = None;
        for (c, &dim) in threads.iter().enumerate() {
            if dim <= 1 {
                continue;
            }
            let limit = self.host_word(RootType::Other(USER_DISPATCH_THREADS), 0, c as u32);
            let Val::I32(tid) = self.thread_id(c as u8) else {
                unreachable!()
            };
            let Val::I32(gid) = self.compute_id("groupId.i32", 94, c as u8) else {
                unreachable!()
            };
            let g = self.s.m.i32(dim);
            let base = self.s.m.bin(e, Bin::Mul, gid, g);
            let global = self.s.m.bin(e, Bin::Add, base, tid);
            let no_limit = self.s.m.cmp(e, pred::EQ, limit, zero);
            let within = self.s.m.cmp(e, pred::IULT, global, limit);
            let ok = self.s.m.bin(e, Bin::Or, no_limit, within);
            active = Some(match active {
                None => ok,
                Some(prev) => self.s.m.bin(e, Bin::And, prev, ok),
            });
        }
        let Some(active) = active else {
            return;
        };
        let barrier = self.x.p.blocks.iter().enumerate().any(|(b, blk)| {
            !self.no_barrier.contains(&b) && blk.insts.iter().any(|i| i.name() == "s_barrier")
        });
        // (Not where the translation adds group barriers of its own: two host
        // waves per console wave, `halves` or `split_lds`. Fork #646 checks the
        // exchange and `s_barrier` only.)
        let leave = self.exchange.is_none()
            && self.halves.is_none()
            && !self.split_lds
            && !barrier
            && self.x.p.blocks[order[0]].preds.is_empty();
        if leave {
            let body = self.s.m.new_block();
            let exit = self.s.m.new_block();
            self.s.m.terminate(e, Term::CondBr(active, body, exit));
            self.s.m.terminate(exit, Term::Ret);
            self.body_entry = body;
            self.block[order[0]] = Some(body);
            self.cur = body;
        } else {
            self.partial_active = Some(active);
        }
    }
}
