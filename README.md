README
STALKER 2 Auto‑Detect Mod Merger

This tool is a PowerShell‑based mod conflict detector and auto‑merger for S.T.A.L.K.E.R. 2: Heart of Chornobyl.
It automatically detects the real game executable, extracts the AES key, unpacks the base game and all mods, scans for conflicts, merges compatible files, and builds a single merged mod.

Everything is automated and designed to avoid crashes. Missing mod folders, unpack failures, and Move‑Item errors are safely skipped.

What This Tool Does

  Auto‑detects the real Stalker2-Win64-Shipping.exe even if you select the wrong EXE.
  
  Extracts the AES key from the executable.
  
  Creates a full backup of all .pak mods before merging.
  
  Unpacks the base game pakchunk0.
  
  Unpacks every mod in the ~mods folder.
  
  Safely skips mods that fail to unpack or have missing folders.
  
  Detects file conflicts between mods.
  
  Categorizes conflicts (NPC HP, Loot, Economy, Weapons, HUD, Misc).
  
  Automatically merges .cfg conflicts.
  
  Builds a new MergedMod.pak.
  
  Deletes all unpacked folders to keep your ~mods folder clean.
  
  Shows progress and logs everything in a GUI window.

Requirements

  PowerShell (included with Windows 10/11)
  
  repak.exe (required for unpacking and packing STALKER 2 .pak files)
  
  Download repak here:
  https://github.com/trumank/repak/releases
  
  Recommended file:
  repak_cli-x86_64-pc-windows-msvc.zip
  
  Extract repak.exe into the same folder as this script.

Installation

  Download the script folder.
  
  Place repak.exe next to merge.ps1.
  
  Make sure your mods are installed in:
  Stalker2\Content\Paks\~mods\
  
  Right‑click merge.ps1 → Run with PowerShell.

How to Use

  Launch merge.ps1.
  
  Click “Browse…” and select ANY Stalker2.exe or Stalker2-Win64-Shipping.exe.
  
  Click “Run Merge”.
  
  The script will:
  
  Detect the real EXE
  
  Extract AES key
  
  Backup all mods
  
  Unpack base game
  
  Unpack mods
  
  Detect conflicts
  
  Merge .cfg files
  
  Build MergedMod.pak
  
  Clean up unpacked folders
  
  When finished, move MergedMod.pak into:
  Stalker2\Content\Paks\~mods\
  
  Disable the merged mods in Vortex.
