# Threat model

## What this project does and where untrusted input enters
- far2l is a text-mode file manager (a Linux port of Far Manager): two file panels, an editor, a viewer, and loadable plugins. It is an interactive TUI application, not a daemon.
- Untrusted input arrives whenever the user opens, views, or extracts a file or connects to a remote host. The main entry points:
  - Archive contents: `plugins/arclite` (libarchive + custom parsers, e.g. deb/rpm), `plugins/multiarc` (invokes external packers), `plugins/inside` (in-process RAR/ARK unpacking under `plugins/inside/src/`).
  - Network panels: `plugins/NetRocks` and `plugins/farftp` (FTP/SSH/SFTP via libcurl/libssh — server responses, listings, and file contents are attacker-controlled), `plugins/adb` and `plugins/mtp` (device metadata).
  - Terminal data: escape sequences and console input read through `WinPort` (our own TUI/console abstraction, including the ANSI/xterm escape parser) from a hostile terminal server or from output piped into panels.
  - File contents: the editor and viewer in `far2l/src` (selection, encoding via libuchardet), `plugins/colorer` (XML syntax files via libxml2), `plugins/compare`, image viewer.
  - Configuration/state: INI-style config and registry emulation in `far2l/src` and `WinPort`, panel shortcuts, `.far2l` bookmarks — less attacker-controlled, but parsing bugs still count.
- We assume any file the user browses, any archive, and any remote-server response is fully hostile.

## Components that matter most / least
- Highest priority: `WinPort/` (especially the escape-sequence/input handling and console buffers), `far2l/src/` (editor, viewer, panels, message handling), `plugins/arclite`, `plugins/inside`, `plugins/NetRocks`, `plugins/farftp`, `plugins/multiarc` argument handling.
- Medium: remaining `plugins/*`, `far2l/DE` (dialogs), `utils/`.
- Low / out of scope: `far2l/far2sdk` (upstream Far SDK headers), `packaging/`, `_ci/`, `Brewfile`, `.travis.yml`, `bash-completion`, third-party data under `themes/` and `plugins/python/plugins`.

## How to exercise it
- The scanner image builds to `/src/build/install`: binary at `install/far2l`, built plugins under `install/Plugins/`. Sources remain at `/src`.
- far2l needs a terminal; run it under a pty (e.g. `script -qec "/src/build/install/far2l" /dev/null`) or via the smoke harness in `testing/far2l-smoke` (that harness requires rebuilding with `-DTESTING=yes` and Go, so a plain pty run is preferred).
- The most productive fuzzing targets are the parsers reachable through file/archive viewing; you can also drive the `arclite`/`inside` parsing code directly from their sources in `plugins/arclite` and `plugins/inside/src`.

## How you rate severity
- Memory corruption (overflow, UAF, double free) reachable from a hostile file, archive, terminal sequence, or server response: high minimum; critical when the primitive looks controllable and leads to code execution while merely browsing.
- Information disclosure or arbitrary file write outside the panel (e.g. zip-slip through an extraction path) without code execution: medium-high.
- Crashes/DoS: medium — far2l is an interactive user-facing tool, so a crash is not catastrophic.
- Anything requiring the user to already run a hostile external packer binary (multiarc shells out to `rar`, `lha`, etc.) is out of scope; only far2l's own argument construction and output parsing matter.

## Anything to leave alone
- Do not report issues that only manifest under exotic console drivers when a mainstream terminal works fine.
- `plugins/python` is disabled in the scanner build; skip it.
- Deliberate Win32-compatibility quirks (registry emulation, `WIN_PORT_*` shims) are expected design, not vulnerabilities, unless they cause memory unsafety.
