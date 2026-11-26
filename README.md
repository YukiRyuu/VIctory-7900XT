# VIctory on an RX 7900 XT

A fork of [avatarmanz/VIctory-7900XTX](https://github.com/avatarmanz/VIctory-7900XTX),
itself a fork of [VIctory](https://github.com/Marvisak/VIctory): a compatibility
layer that runs an Xbox Series title natively on Windows from files the user
supplies. This one is tuned and measured on an **RX 7900 XT with 32 GB of RAM**,
half the memory the forks it comes from were tested with, by **ryuki**.

**This repository contains no game files, code or assets.** You need your own
copy of the game. It is not affiliated with or endorsed by the game's developer
or publisher.

## The PC it was tested on

| | |
|---|---|
| GPU | AMD Radeon RX 7900 XT, 20 GB (driver 32.0.32015.7029), Resizable BAR on |
| CPU | AMD Ryzen 7 7800X3D (8 cores, 16 threads) |
| RAM | 32 GB DDR5 (about 31 GB usable), running at 4800 MT/s |
| Board | Gigabyte B650 AORUS ELITE AX |
| OS | Windows 11 Pro, build 26300 |
| Display | 2560x1440, the title's Series X profile |
| Page file | on D:, 32 GB initial, 88 GB most |

## Where it stands (2026-11-26)

| | |
|---|---|
| Menus, videos, loading screens | 30 fps (the title's cap) |
| In the world (prologue, first mission) | about 18-19 fps median, peaks in the mid 20s |
| Longest session | over 30 minutes; stable since the page file was raised |
| Memory | 35-40 GB committed during play, more in bursts |

Where it started on this PC: 12-13 fps, and out-of-memory crashes at cutscene
skips.

Still wrong:

- Trees and plants flicker outdoors.
- Textures of what just came into view appear late while the title streams.
- The first run with a new driver or build stutters while pipelines are made
  (`victory warm` makes them ahead).

## How to run it

You need Windows 10/11 x64, a CPU with AVX2, a Direct3D 12 GPU with shader
model 6.6 and mesh shaders, Rust (the toolchain is pinned), the MSVC build
tools, and your own dump of the title.

**With 32 GB of RAM, raise the page file first** (System > About > Advanced
system settings > Performance > Advanced > Virtual memory): the process commits
more than the RAM, and below RAM + page file the title stops with "no host list
for a state prelude" (0x8007000E). Windows caps one page file at three times the
RAM.

```powershell
git clone https://github.com/YukiRyuu/VIctory-7900XT
cd VIctory-7900XT
copy victory.example.toml victory.toml      # then set your paths, outside this folder
cargo build --locked --profile diag -p victory --features diagnostics
$env:VICTORY_HOST_WAVE = '64'; $env:VICTORY_VIEW_LIMIT = '2097151'
target\diag\victory.exe shaders <the shader archives>   # every shader translated ahead, minutes
scripts\play.ps1 -RX7900XT -Exe <path of your copy's executable>
```

`-RX7900XT` adds the settings measured on this PC to the fork's own (they are
listed in the script). If PowerShell refuses to run scripts, start it as
`powershell -ExecutionPolicy Bypass -File scripts\play.ps1 -RX7900XT -Exe ...`
(for that one window only). After a first run, `target\diag\victory.exe warm --used`
makes the pipelines it drew with ahead of the next one. In a diagnostics build,
`-More @{VICTORY_CAPTURE='<a folder>'}` lets F11 save the next 8 frames there.

## What was found

All runs, figures and reasons: [docs/rx7900xt.md](docs/rx7900xt.md). In short:

- **Commit, not RAM, is the limit.** The process commits 35-40 GB in play and
  jumped 7 GB in 40 s at a cutscene skip. A bigger page file ended the crashes.
- **Less committed memory** in windows of title memory outside buffers:
  `VICTORY_WINDOW_KB=1024` with `VICTORY_ROOT_WINDOW_MB=12`, 6.9 GB down to
  1.3 GB at the same point, and faster (15.9 to 18.2 fps).
- **A device removal in the intro fixed**: a root view has no size and was
  given 4 MiB of title memory; a shader read past it into freed memory (DRED).
  Its window now reaches the title memory committed around it.
- **Shader-write compares on the card for buffers of 1 MiB and more**
  (`VICTORY_CARD_BUFFERS_MIN_MB=1`, `VICTORY_CARD_BUFFERS_MB=1536`), smaller
  texture steps at scene cuts (`VICTORY_TEXTURE_STAGE_MS=80`), and windows in
  private memory used in place (`VICTORY_INPLACE=1`): preparing a frame 45 to
  37 ms.
- **Most of a frame is the cost of two memories.** In a 53 ms frame: the write
  watch 10.8 ms, refreshes 11.5, copy-back 16.1, waits on the trackers' locks
  26 ms across threads, the card about 67 % busy. The direction that could
  close it: the title's page-pool sections committed, each page placed in the
  order of its addresses, buffers over them used in place (the driver opens
  committed memory as a heap; it refuses reserved memory, and tile mappings
  into such a heap remove the device).
- **Tried and not kept:**
  - The title's GPU memory on the card through Resizable BAR (ForwardVI's
    `VICTORY_CARD_MEMORY`): 19.4 down to 12.7-15.5 fps, and characters' faces
    black. The processor reads that memory at about 30 MB/s.
  - Replacing command allocators every 128 resets: 2 MB given back in 12,288
    swaps. The ~21 GB of write-combined memory in the process is not theirs.
  - Turning the indirect paths off for the tree flicker: still flickers, half
    the frame rate. The suspect left: copies without a per-submission snapshot
    while two frames are prepared ahead (`VICTORY_RELAY`); not tested yet.
  - Mip levels on demand: over the card's memory budget.

## Credits

This is a tree of other people's work with a little on top. The history is
kept, and commits taken from elsewhere keep their authors.

- **[avatarmanz/VIctory-7900XTX](https://github.com/avatarmanz/VIctory-7900XTX)**:
  the fork this one is built on, its speed work and its findings
  ([docs/README-avatarmanz.md](docs/README-avatarmanz.md),
  [docs/findings.md](docs/findings.md)), with ZETTROX, whom its README names.
- **[VIctory](https://github.com/Marvisak/VIctory)** by Marvisak and its
  contributors: the loader, the runtime services, the Direct3D 12 back end and
  the shader recompiler.
- Carried by avatarmanz's fork: **[fxceless/victory-fork](https://github.com/fxceless/victory-fork)**,
  **[DexNom/VIctory](https://github.com/DexNom/VIctory)**,
  **[Belobug/VIctory-Belobug-AMD](https://github.com/Belobug/VIctory-Belobug-AMD)**
  (and romainhedouin), **[FQY55kai/ZJOU-VICTORY](https://github.com/FQY55kai/ZJOU-VICTORY)**,
  **[myokex/victory-amd](https://github.com/myokex/victory-amd)** (with Spexivus,
  joroyt, tightfall and Joshua Odom), **Geckomacabre** and **cxy0072019-sketch**.
- **codec_d's cool_fox** (published as
  [JordanFromIT/cool_fox](https://github.com/JordanFromIT/cool_fox)): memory
  budgets for 32 GB PCs, descriptor slots released on completion, and more,
  merged as they are (CHANGELOG.md).
- Built on, tested or studied on the way here, for code, settings, ideas and
  measurements:
  **[soldsawn/victory-nvidia-8gb](https://github.com/soldsawn/victory-nvidia-8gb)**
  (where the root-view fix was first made),
  **[PastiiJay/klbf-lab](https://github.com/PastiiJay/klbf-lab)**,
  **[CDR-0000/ForwardVI](https://github.com/CDR-0000/ForwardVI)** (card memory and
  the driver shader-cache trim, tried here),
  **[shadowdog00/vi-pc-combo](https://github.com/shadowdog00/vi-pc-combo)**,
  **[kzkvf88zhs-boop/ANYDEV](https://github.com/kzkvf88zhs-boop/ANYDEV)**,
  **[clankenjoyer/victory-fps](https://github.com/clankenjoyer/victory-fps)**,
  **[SnickeredMG/specific-assets-vctry](https://github.com/SnickeredMG/specific-assets-vctry)**,
  and the dumps shared in
  **[skornuta/victory-fork](https://github.com/skornuta/victory-fork)**.
- **[XCL](https://github.com/ivall/xcl)** (GPL-2.0-only) was read by
  avatarmanz's fork for how the same title behaves under another layer; no code
  of it is here.
- This fork's changes were made by ryuki with
  [Claude Code](https://claude.com/claude-code).

## License

GPL-3.0-or-later, as VIctory. See [LICENSE](LICENSE); the one file that is not
covered is named in [docs/asset-policy.md](docs/asset-policy.md).
