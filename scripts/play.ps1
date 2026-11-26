# Starts the title with the settings this fork is played with (README.md, "How to run it").
#   scripts\play.ps1 -Exe <path of your own copy's executable>
# -Safe         without the newer, faster ways (the first thing to try when something is wrong)
# -RayTracing   the title's own ray-traced indirect light: lit interiors, about a third slower
# -Build        target\diag (the default, the build all measurements are of) or target\release
# -RX7900XT     also the settings measured best on an RX 7900 XT with 32 GB of RAM (docs/rx7900xt.md)
# -More         other settings: -More @{VICTORY_PANEL='1'}
# Run it from a normal window, not as administrator: the driver then keeps its shader cache elsewhere.
param(
    [Parameter(Mandatory)][string]$Exe,
    [switch]$Safe,
    [switch]$RayTracing,
    [switch]$RX7900XT,
    [ValidateSet('diag', 'release')][string]$Build = 'diag',
    [hashtable]$More = @{}
)
$settings = @{
    VICTORY_TEXTURE_NO_WAIT = '1'; VICTORY_RELAY = '2'; VICTORY_WIDE_BACK = '1'; VICTORY_CARD_REHASH_RUNS = '1'
    VICTORY_JOIN_COPIES = '1'; VICTORY_INDIRECT_WINDOW = '1'; VICTORY_RELAY_COPY = '1'; VICTORY_CARD_STEPS = '2'
    VICTORY_INDIRECT_BATCH = '2'; VICTORY_MAP_THREADS = '1'; VICTORY_TITLE_PRIORITIES = '0'; VICTORY_CARD_AWAKE = '1'
    VICTORY_SHOW_AFTER = '1'; VICTORY_AMBIENT = '0.8'; VICTORY_D3D12_DRED = 'light'; VICTORY_SKIP_PIPELINES = 'none'
}
if ($Safe) {
    $settings.VICTORY_UNDER_WIDE = '0'; $settings.VICTORY_LAND_ECHO = '0'
} else {
    $settings.VICTORY_THIN = '1'; $settings.VICTORY_JOIN_PARTS = '8'; $settings.VICTORY_UPLOAD_AHEAD = '1'
}
if ($RayTracing) { $settings.VICTORY_BVH_BUILDER = '1' }
if ($RX7900XT) {
    # Shader-write compares on the card for buffers of 1 MiB and more; less committed
    # memory in windows of title memory (about 5 GB less); smaller texture steps at scene
    # cuts; windows in private memory used in place; pipelines written down for "victory warm".
    $settings.VICTORY_CARD_BUFFERS_MIN_MB = '1'; $settings.VICTORY_CARD_BUFFERS_MB = '1536'
    $settings.VICTORY_ROOT_WINDOW_MB = '12'; $settings.VICTORY_WINDOW_KB = '1024'
    $settings.VICTORY_TEXTURE_STAGE_MS = '80'
    $settings.VICTORY_INPLACE = '1'; $settings.VICTORY_INPLACE_MB = '3072'
    $settings.VICTORY_PIPELINE_BOOK = '1'
    # Measured for 20 fps on the 7800X3D (CHANGELOG.md): the write watch asked
    # early, the heaps' records every 1 ms, longer joined submissions, and the
    # title's idle threads at below normal (16 threads are not enough for them
    # to wait their turn).
    $settings.VICTORY_ASK_EARLY = '2'; $settings.VICTORY_HEAP_SYNC_EARLY = '1'
    $settings.VICTORY_JOIN_PARTS = '16'; $settings.VICTORY_JOIN_LISTS = '96'
    $settings.VICTORY_TITLE_PRIORITIES = '1'
    # Fewer of our threads translating list calls and comparing title bytes
    # (8 and 6 were for a 24-thread CPU): on 16 the title's own threads ran
    # short (free roam: 6-13 ms less preparing a frame, CHANGELOG.md).
    $settings.VICTORY_THIN_THREADS = '4'; $settings.VICTORY_UNDER_THREADS = '3'
    $settings.VICTORY_LAND_THREADS = '3'
    # From the Scarlett fork: pool pages given back when free RAM is low, the
    # title's fills not waiting behind flights, and only the changed levels of
    # a texture sent again (free roam: walking's slowest tenth 7.7 -> 14.1 fps).
    $settings.VICTORY_POOL_DISCARD = '1'; $settings.VICTORY_FILL_TITLE = '1'
    $settings.VICTORY_PARTIAL_DELTA = '1'
}
foreach ($k in $More.Keys) { $settings[$k] = $More[$k] }

$victory = Join-Path $PSScriptRoot "..\target\$Build\victory.exe"
if (-not (Test-Path $victory)) { Write-Host "No $victory. Build it first (README.md)."; return }
if (-not (Test-Path $Exe)) { Write-Host "No $Exe."; return }
# (Other settings left over in this window go; where your files are stays.)
$paths = 'VICTORY_CONFIG', 'VICTORY_GAME_DIR', 'VICTORY_CACHE_DIR', 'VICTORY_DATA_DIR'
Get-ChildItem Env:VICTORY_* | Where-Object { $_.Name -notin $paths } | ForEach-Object { Remove-Item "Env:$($_.Name)" }
foreach ($k in $settings.Keys) { Set-Item "Env:$k" $settings[$k] }
$Exe = (Resolve-Path $Exe).Path
Push-Location (Join-Path $PSScriptRoot '..')   # victory.toml is looked for here
try { & $victory run $Exe --execute } finally { Pop-Location }
