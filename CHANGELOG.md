# Changelog of this fork

Each entry names the commit and, where there is one, a tag to go back to:
`git checkout <tag>` to look, `git reset --hard <tag>` on a branch to return
(after saving anything newer elsewhere). Frame rates are medians of the log's
frame lines in the world, diagnostics build, on the PC in the README.

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
