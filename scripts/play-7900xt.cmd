@echo off
rem Starts the title with the settings measured best on an RX 7900 XT, 31 GB RAM,
rem Ryzen 7 7800X3D (docs/rx7900xt.md): play.ps1's set plus the memory and
rem texture-pacing switches, and windows of title memory in place.
rem   scripts\play-7900xt.cmd <path of your own copy's executable> [diag|release]
rem A .cmd, not a .ps1: it runs where PowerShell scripts are blocked.
setlocal
if "%~1"=="" (
  echo Usage: scripts\play-7900xt.cmd ^<path of your copy's executable^> [diag^|release]
  exit /b 1
)
set "BUILD=%~2"
if "%BUILD%"=="" set "BUILD=diag"
set "ROOT=%~dp0.."
set "VICTORY=%ROOT%\target\%BUILD%\victory.exe"
if defined CARGO_TARGET_DIR set "VICTORY=%CARGO_TARGET_DIR%\%BUILD%\victory.exe"
if not exist "%VICTORY%" (
  echo No %VICTORY%. Build it first: cargo build --locked --profile diag -p victory --features diagnostics
  exit /b 1
)

rem play.ps1's normal set
set VICTORY_TEXTURE_NO_WAIT=1
set VICTORY_RELAY=2
set VICTORY_WIDE_BACK=1
set VICTORY_CARD_REHASH_RUNS=1
set VICTORY_JOIN_COPIES=1
set VICTORY_INDIRECT_WINDOW=1
set VICTORY_RELAY_COPY=1
set VICTORY_CARD_STEPS=2
set VICTORY_INDIRECT_BATCH=2
set VICTORY_MAP_THREADS=1
set VICTORY_TITLE_PRIORITIES=0
set VICTORY_CARD_AWAKE=1
set VICTORY_SHOW_AFTER=1
set VICTORY_AMBIENT=0.8
set VICTORY_D3D12_DRED=light
set VICTORY_SKIP_PIPELINES=none
set VICTORY_THIN=1
set VICTORY_JOIN_PARTS=8
set VICTORY_UPLOAD_AHEAD=1

rem Measured on the RX 7900 XT (docs/rx7900xt.md)
rem   shader-write compares on the card for buffers of 1 MiB and more
set VICTORY_CARD_BUFFERS_MIN_MB=1
set VICTORY_CARD_BUFFERS_MB=1536
rem   less committed memory in windows of title memory (about 5 GB less)
set VICTORY_ROOT_WINDOW_MB=12
set VICTORY_WINDOW_KB=1024
rem   smaller texture steps at scene cuts
set VICTORY_TEXTURE_STAGE_MS=80
rem   windows in private memory used by the card in place (no copy, refresh or copy-back)
set VICTORY_INPLACE=1
set VICTORY_INPLACE_MB=3072
rem   pipelines this run creates are written down for "victory warm"
set VICTORY_PIPELINE_BOOK=1

rem Diagnostics builds only: F11 saves the next 8 frames here
if /i "%BUILD%"=="diag" if not defined VICTORY_CAPTURE set "VICTORY_CAPTURE=%LOCALAPPDATA%\victory\captures"

pushd "%ROOT%"
"%VICTORY%" run "%~1" --execute
set RC=%ERRORLEVEL%
popd
exit /b %RC%
