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
