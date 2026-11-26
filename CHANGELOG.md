# Changelog of this fork

Each entry names the commit and, where there is one, a tag to go back to:
`git checkout <tag>` to look, `git reset --hard <tag>` on a branch to return
(after saving anything newer elsewhere). Frame rates are medians of the log's
frame lines in the world, diagnostics build, on the PC in the README.

## Tried after step 3, not kept (2026-11-26)

- Windows' segment heap for the process (an application manifest): no
  better, noisier. mimalloc for our own allocations was not tried (a new
  dependency).
- Early rounds of the heaps' records in parts (a quarter of each heap a
  round): the submission waited longer (9.9 ms against 6.3).
- Kept for looking: `VICTORY_TIMELINE_SUBMIT=1` samples the submitting thread
  in a timeline. Its profile: about a quarter waiting (heaps' records, pools,
  locks), 6 % asking the write watch, 8 % copying bytes, about 9 % in the
  system heap's allocation and release.

## The measured settings in the launcher (2026-11-26)

`play.ps1 -RX7900XT` now also sets `VICTORY_ASK_EARLY=2`,
`VICTORY_HEAP_SYNC_EARLY=1`, `VICTORY_JOIN_PARTS=16`, `VICTORY_JOIN_LISTS=96`
and `VICTORY_TITLE_PRIORITIES=1` (the title's idle threads at below normal;
`play.ps1` alone keeps `0`). Tag `goal-20fps-step3`.

| | idle | driving (65 s) | camera spin |
|---|---|---|---|
| `goal-20fps-start` | 21.2 / 20.5 | 17.8 / 11.7 | - |
| `goal-20fps-step3` | 23.0 / 22.5 | 19.4 / 16.5 | 17.7 / 15.9 |

No better: 2 MiB windows (`VICTORY_WINDOW_KB=2048`), waiting awake in the
wide pool (`VICTORY_WIDE_SPIN=200`) or in the landing pools (tried in code,
not kept: the processors are busy enough that spinning took them from the
title), GPU timing (`VICTORY_GPU_TIMING=1`: 5 fps, for looking only).

## Settings measured after step 2 (2026-11-26)

Over the first 65 s of driving (median / p10) and 2 min idle:

| | idle | driving |
|---|---|---|
| step 2, `VICTORY_ASK_EARLY=2` | 22.5 / 22.0 | 19.4 / 17.3 |
| + `VICTORY_HEAP_SYNC_EARLY=1` | 22.8 / 22.6 | 19.4 / 16.4 |
| + `VICTORY_JOIN_PARTS=16`, `VICTORY_JOIN_LISTS=96` | 22.8 / 22.2 | 20.0 / 15.3 |

No better: `VICTORY_MAP_THREADS=4`, `VICTORY_VIEW_THREADS=8`, the slots'
locks by a hash of the index (the heaps' records waited longer: 9.3 ms
against 6.3). The driving path differs from run to run (4,000 to 5,500 draws),
so differences under about 1 fps there are noise.

## Root views' reach asked once a second (2026-11-26)

An ask without a length (a root view) is given the title memory committed
around it (the intro's device removal), found by asking Windows region by
region. It was asked at every such lookup, from the threads that translate
list calls, while the title maps and unmaps pages: 680 queries in 8 frames
of driving, 362 ms of those threads. The answer for a range is now used
again for 1 s (`VICTORY_ROOT_REACH_MS`, 0: every time). Tag
`goal-20fps-step2`.

| | idle | driving |
|---|---|---|
| step 1 | 20.3 / 19.7 | 18.9 / 17.8 |
| + this change | 22.5 / 22.0 | 19.6 / 16.0 |

Tried, no better: the Series S profile (`--console series-s`): as many draws,
slower.

## Window lookups share the lock (2026-11-26)

With windows finer than their 4 MiB cell (`VICTORY_WINDOW_KB=1024`, in
`play.ps1 -RX7900XT`), every lookup that may take any window holding a range
searched under the windows' write lock, so all threads asking stood in one
line: 1.4 s of waits in 4 frames of driving (timeline, all threads). The
search is now made under the read lock first; the write lock only makes a
window. The memory-line statistics read under the read lock too.

Self-test (boat mission, 120 s idle then 90 s driving; median / p10 fps):

| | idle | driving |
|---|---|---|
| before (`goal-20fps-start`) | 21.2 / 20.5 | 17.8 / 11.7 |
| + `VICTORY_ASK_EARLY=2` | 21.7 / 19.9 | 18.1 / 14.6 |
| + this change | 20.3 / 19.7 | 18.9 / 17.8 |

Tried, no better: `VICTORY_THIN_THREADS=12`; `VICTORY_LAND_THREADS=6` with
`VICTORY_VIEW_THREADS=6`.

## goal-20fps-start (2026-11-26)

The point the 20 fps work starts from: `scripts\play.ps1 -RX7900XT`, about
18-19 fps median in the world (run 7), peaks in the mid 20s. Tag
`goal-20fps-start`.

Before it, in order (see `git log`):

- A root view's window reaches the title memory committed around it (the
  device removal in the intro).
- Host lists' command allocators can be replaced every N resets
  (`VICTORY_ALLOCATOR_RESETS`, off: it gave back 2 MB).
- F11 saves the next 8 frames in diagnostics builds (`VICTORY_CAPTURE`).
- The RX 7900 XT settings (`play.ps1 -RX7900XT`), the notes in
  `docs/rx7900xt.md`, the README.
- Tried and not kept: ForwardVI's card memory (local branch `forwardvi-port`).
