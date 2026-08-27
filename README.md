# STALKER 2 Mod Merger

A PowerShell tool that merges conflicting STALKER 2 mods with an interactive per-key CFG conflict resolver.

## Features
- Automatic detection of `.pak` / `.ucas` / `.utoc` mods
- Priority-based merging
- Interactive CFG conflict resolver (choose which mod’s value to keep for each key)
- Manual “Resolve CFG Conflicts” button
- Backup of original mods
- Dry-run mode
- Compatible with Windows PowerShell 5.1 and PowerShell 7+
- Crash logging + PowerShell version logging

## Requirements
- Windows 10/11
- PowerShell 5.1 or newer
- repak.exe → https://github.com/trumank/repak/releases
- retoc.exe (optional but recommended for IOStore mods) → https://github.com/trumank/retoc/releases

## How to Use

1. Put the script, `repak.exe` and/or `retoc.exe` in the same folder.
2. Right-click the script → **Run with PowerShell**.
3. Select your `Stalker2.exe` (or use Auto-Detect).
4. Click **Scan Mods**.
5. Check the mods you want and order them (higher in the list = higher priority).
6. (Recommended) Click **Resolve CFG Conflicts**, choose the values you want, then click **Done**.
7. Click **Run Merge**.
8. Disable the original conflicting mods and keep the new `MergedMod.pak`.

## Options
- **Show mods to disable** – Lists which original mods should be turned off
- **Show conflict details** – Logs every conflicting file
- **Dry-run only** – Simulates the merge without changing files
- **Export conflicts.txt** – Writes a detailed conflict report
- **Recursive search** – Scans subfolders inside `~mods`
- **Also try IOStore output** – Attempts to create `.utoc` / `.ucas` files

## Logs
The tool creates several log files next to the script:
- `ps_version_....txt` – PowerShell environment info
- `merge_log_....txt` – Full merge log
- `resolve_log_....txt` – CFG resolver log
- `crash_log_....txt` – Crash details (only if something fails)
- `conflicts.txt` – Optional conflict export
- `aes_key.txt` – Extracted AES key

## Notes
- Always keep a backup of your `~mods` folder.
- After merging, test in-game. You can restore from the `_backup_...` folder if needed.
