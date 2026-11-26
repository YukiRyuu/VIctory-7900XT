# Changelog of this fork

Each entry names the commit and, where there is one, a tag to go back to:
`git checkout <tag>` to look, `git reset --hard <tag>` on a branch to return
(after saving anything newer elsewhere). Frame rates are medians of the log's
frame lines in the world, diagnostics build, on the PC in the README.

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
