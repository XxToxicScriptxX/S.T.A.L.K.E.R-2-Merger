# STALKER 2 Mod Merger

**Smart PowerShell GUI tool** for detecting and merging conflicting mods in *S.T.A.L.K.E.R. 2: Heart of Chornobyl*.

Supports **classic `.pak`** and **IOStore** (`.pak` + `.ucas` + `.utoc`) mods. Built to reduce config conflicts so more mods can run together.

---

## Features

- Detects `.pak`, `.ucas`, and `.utoc` (including in subfolders)
- Auto-detects game install and `~mods` folder from the game executable
- Uses **repak** for classic packs and **retoc** for IOStore when available
- Smart tool routing with fallbacks (one failed mod does not stop the run)
- Timestamped backup of all mod files before any changes
- Dry-run mode (scan only, no merge)
- Conflict report export (`conflicts.txt`)
- Optional list of mods to disable after merging
- Primary output: reliable `MergedMod.pak` (best for config conflicts)
- Optional experimental IOStore output

---

## Requirements

Place these **next to the script**:

| Tool | Required | Download |
|------|----------|----------|
| **repak.exe** | Yes (for classic `.pak`) | [trumank/repak releases](https://github.com/trumank/repak/releases) |
| **retoc.exe** | Optional (for IOStore) | [trumank/retoc releases](https://github.com/trumank/retoc/releases) |

- Windows 10/11  
- PowerShell 5.1+ (included with Windows)

---

## Installation

1. Download or clone this repository.
2. Put `repak.exe` (and optionally `retoc.exe`) in the same folder as `STALKER2_Merger.ps1`.
3. Right-click the `.ps1` → **Properties** → enable **Unblock** if shown → Apply.
4. Run:
   - Right-click → **Run with PowerShell**, or  
   - Open PowerShell in the folder and run:  
     `powershell -ExecutionPolicy Bypass -File .\STALKER2_Merger.ps1`

---

## Usage

1. **Select** any STALKER 2 executable  
   (`Stalker2.exe` or `Stalker2-Win64-Shipping.exe`).
2. Click **Auto-Detect** (or browse to your `~mods` folder).
3. Leave **Recursive search** enabled if you organize mods in subfolders.
4. (Recommended) Enable **Dry-run** first to preview conflicts.
5. Click **Run Merge**.
6. Find the output in your mods folder:
   - `MergedMod.pak` (main result)
7. In Vortex / your mod manager, **disable** the original mods that were merged.
8. Launch the game and test.

### Typical mods path

```text
S.T.A.L.K.E.R. 2 Heart of Chornobyl\Stalker2\Content\Paks\~mods
```
How it works

Scans ~mods for .pak / .ucas / .utoc sets
Unpacks or converts them (repak and/or retoc)
Builds a map of files → which mods provide them
Merges overlapping .cfg files
For other (binary) conflicts, applies last-wins
Packs a single MergedMod.pak
Leaves a full backup under _backup_YYYYMMDD_HHMMSS


Important limitations


Content typeMerge qualityConfig / .cfg filesGood (combined)Other text-like dataPartialBinary assets (.uasset, meshes, Blueprints, etc.)Not a real merge — one version wins

Best suited for config / balance mod conflicts (the most common STALKER 2 case).
Complex asset mods may still need manual load order or a hand-made compatibility patch.
Always keep the automatic backup. Test in-game after merging.


Options in the GUI



OptionDescriptionRecursive searchFind mod files in subfolders under ~modsDry-runList conflicts only; no unpack/merge/packShow conflict detailsPrint every conflicting path in the logExport conflicts.txtWrite a report next to the scriptShow mods to disableList originals that were merged (for Vortex/MO2)Also try IOStore outputExperimental; may produce .pak+.ucas+.utoc (classic .pak remains the main result)

Troubleshooting
“AES key not found”

Select the real shipping EXE (Stalker2-Win64-Shipping.exe under Binaries\Win64).
“No mods could be unpacked”

Confirm repak.exe / retoc.exe are next to the script
Confirm the AES key was extracted
Try Dry-run to see which tool is planned for each mod

Merged mod has no effect

Ensure MergedMod.pak is inside ~mods
Disable the original conflicting mods
Prefer a name that loads late if you rename it (e.g. zzz_MergedMod_P.pak)

Script blocked by PowerShell
PowerShellSet-ExecutionPolicy -Scope CurrentUser RemoteSigned
Or run once with:
PowerShellpowershell -ExecutionPolicy Bypass -File .\STALKER2_Merger.ps1

Credits

Community STALKER 2 merger scripts and guides
repak by trumank
retoc by trumank


License
Free to use and share.

Please credit this project (and the tool authors above) if you redistribute or build on it.

Disclaimer
This tool modifies mod files in your game directory.

Always keep backups. Use at your own risk. The authors are not responsible for broken saves, crashes, or corrupted installs.
