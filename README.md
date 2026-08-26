# STALKER 2 Auto‑Detect Mod Merger
A PowerShell‑based mod conflict scanner and auto‑merger for  
**S.T.A.L.K.E.R. 2: Heart of Chornobyl**.

This tool automatically:
- Detects the real game executable (Steam, GOG, Epic supported)
- Extracts the AES key directly from the game EXE
- Unpacks the base game and all mod `.pak` files
- Scans for file conflicts between mods
- Merges compatible files into a single `MergedMod.pak`
- Provides optional toggles for conflict display, auto‑disable, dry‑run, and exporting reports
- Cleans up unpacked folders automatically
- Creates a timestamped backup of all mods before merging

---

## Features

### Auto‑Detection
- Automatically locates the correct game executable.
- Supports non‑standard installs and launchers.
- Install source dropdown: **Steam / GOG / Epic**.

### Conflict Handling
- Detects overlapping files across mods.
- Categorizes conflicts (NPC, loot, economy, weapons, HUD, misc).
- Optional conflict display toggle.
- Optional conflict export (`conflicts.txt`).

### Merge Engine
- Safely merges `.cfg` conflicts using base game + mod overrides.
- Copies non‑conflicting files automatically.
- Produces a single `MergedMod.pak`.

### Safety & Cleanup
- Timestamped backup of all `.pak` mods before merging.
- Auto‑delete unpacked folders after merge.
- Skip‑missing‑mods logic prevents crashes.

### Toggles
- **Auto‑Disable Mods** — prints a list of mods to disable in Vortex.
- **Show Conflicts** — prints detailed conflict breakdown.
- **Dry‑Run Mode** — scans conflicts only; no unpack, no merge.
- **Export Conflict Report** — writes `conflicts.txt`.

---

## Installation

1. Download the latest release ZIP.
2. Extract it anywhere (Desktop recommended).
3. Place `repak.exe` next to the script.  
   Official repak download:  
   https://github.com/trumank/repak/releases
4. Run the script by double‑clicking:

If PowerShell blocks it, right‑click → **Properties → Unblock**.

---

## Usage

1. Launch the tool.
2. Select **ANY** STALKER 2 executable:
   - `Stalker2.exe`
   - `Stalker2-Win64-Shipping.exe`
3. Choose your **Install Source** (Steam / GOG / Epic).
4. Enable any toggles you want:
   - Auto‑Disable Mods  
   - Show Conflict Details  
   - Dry‑Run  
   - Export Conflict Report  
5. Click **Run Merge**.

If Dry‑Run is enabled → no merge occurs.  
If Dry‑Run is disabled → `MergedMod.pak` is created.

Place `MergedMod.pak` in your `~mods` folder.

---

## File Output

The tool may generate:
MergedMod.pak
aes_key.txt
conflicts.txt
_backup_YYYYMMDD_HHMMSS/


---

## Troubleshooting

- **AES key not found**  
  Ensure you selected the correct executable inside `Stalker2/Binaries/Win64`.

- **~mods folder not found**  
  Verify your install source selection (Steam/GOG/Epic).

- **repak.exe not found**  
  Place `repak.exe` in the same folder as the script.

---

## Changelog

### v1.0.0
- Added Steam/GOG/Epic install source dropdown
- Added Dry‑Run mode
- Added conflict export system
- Added conflict display toggle
- Added auto‑disable toggle
- Added Steam auto‑locator fallback
- Added full backup system
- Added auto‑delete unpacked folders
- Improved conflict categorization
- Improved GUI layout

---

## Credits

- Script by **Patrick (XxToxicScriptxX)**
- repak.exe by **trumank**  
  https://github.com/trumank/repak
