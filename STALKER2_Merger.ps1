##############################################
# STALKER 2 MOD MERGER - Improved GUI + Recursive
# Supports Steam / GOG / Epic / Game Pass + Manual Override
# Recursively finds ~mods and all .pak files (including subfolders)
##############################################

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"

# -------------------------------
# GUI SETUP
# -------------------------------

$form = New-Object System.Windows.Forms.Form
$form.Text = "STALKER 2 Mod Merger (Recursive)"
$form.Size = New-Object System.Drawing.Size(900, 720)
$form.StartPosition = "CenterScreen"
$form.MinimumSize = New-Object System.Drawing.Size(800, 650)
$form.FormBorderStyle = "Sizable"
$form.MaximizeBox = $true
$form.Font = New-Object System.Drawing.Font("Segoe UI", 9)

# ToolTip
$toolTip = New-Object System.Windows.Forms.ToolTip
$toolTip.AutoPopDelay = 8000

# -------------------------------
# GROUP: GAME EXECUTABLE
# -------------------------------

$grpExe = New-Object System.Windows.Forms.GroupBox
$grpExe.Text = "1. Game Executable"
$grpExe.Location = New-Object System.Drawing.Point(12, 12)
$grpExe.Size = New-Object System.Drawing.Size(860, 85)
$grpExe.Anchor = "Top,Left,Right"

$labelGame = New-Object System.Windows.Forms.Label
$labelGame.Text = "Select Stalker2.exe or Stalker2-Win64-Shipping.exe (any location is fine):"
$labelGame.Location = New-Object System.Drawing.Point(12, 22)
$labelGame.AutoSize = $true

$textGame = New-Object System.Windows.Forms.TextBox
$textGame.Location = New-Object System.Drawing.Point(12, 45)
$textGame.Size = New-Object System.Drawing.Size(720, 23)
$textGame.Anchor = "Top,Left,Right"

$btnBrowse = New-Object System.Windows.Forms.Button
$btnBrowse.Text = "Browse..."
$btnBrowse.Location = New-Object System.Drawing.Point(740, 43)
$btnBrowse.Size = New-Object System.Drawing.Size(100, 27)
$btnBrowse.Anchor = "Top,Right"

$grpExe.Controls.AddRange(@($labelGame, $textGame, $btnBrowse))
$form.Controls.Add($grpExe)

# -------------------------------
# GROUP: MODS FOLDER
# -------------------------------

$grpMods = New-Object System.Windows.Forms.GroupBox
$grpMods.Text = "2. Mods Folder (~mods)"
$grpMods.Location = New-Object System.Drawing.Point(12, 105)
$grpMods.Size = New-Object System.Drawing.Size(860, 95)
$grpMods.Anchor = "Top,Left,Right"

$labelMods = New-Object System.Windows.Forms.Label
$labelMods.Text = "Auto-detect from EXE (recommended) or override manually. Script searches recursively for .pak files."
$labelMods.Location = New-Object System.Drawing.Point(12, 22)
$labelMods.AutoSize = $true

$textMods = New-Object System.Windows.Forms.TextBox
$textMods.Location = New-Object System.Drawing.Point(12, 48)
$textMods.Size = New-Object System.Drawing.Size(620, 23)
$textMods.Anchor = "Top,Left,Right"
$textMods.ReadOnly = $false

$btnBrowseMods = New-Object System.Windows.Forms.Button
$btnBrowseMods.Text = "Browse..."
$btnBrowseMods.Location = New-Object System.Drawing.Point(640, 46)
$btnBrowseMods.Size = New-Object System.Drawing.Size(100, 27)
$btnBrowseMods.Anchor = "Top,Right"

$btnAutoDetect = New-Object System.Windows.Forms.Button
$btnAutoDetect.Text = "Auto-Detect"
$btnAutoDetect.Location = New-Object System.Drawing.Point(750, 46)
$btnAutoDetect.Size = New-Object System.Drawing.Size(90, 27)
$btnAutoDetect.Anchor = "Top,Right"

$grpMods.Controls.AddRange(@($labelMods, $textMods, $btnBrowseMods, $btnAutoDetect))
$form.Controls.Add($grpMods)

# -------------------------------
# GROUP: OPTIONS
# -------------------------------

$grpOptions = New-Object System.Windows.Forms.GroupBox
$grpOptions.Text = "3. Options"
$grpOptions.Location = New-Object System.Drawing.Point(12, 210)
$grpOptions.Size = New-Object System.Drawing.Size(860, 80)
$grpOptions.Anchor = "Top,Left,Right"

$chkAutoDisable = New-Object System.Windows.Forms.CheckBox
$chkAutoDisable.Text = "Show list of mods to disable (Vortex / MO2)"
$chkAutoDisable.Location = New-Object System.Drawing.Point(15, 25)
$chkAutoDisable.AutoSize = $true
$chkAutoDisable.Checked = $true

$chkShowConflicts = New-Object System.Windows.Forms.CheckBox
$chkShowConflicts.Text = "Show detailed conflicts in log"
$chkShowConflicts.Location = New-Object System.Drawing.Point(15, 48)
$chkShowConflicts.AutoSize = $true
$chkShowConflicts.Checked = $true

$chkDryRun = New-Object System.Windows.Forms.CheckBox
$chkDryRun.Text = "Dry-run (scan only, no merge)"
$chkDryRun.Location = New-Object System.Drawing.Point(320, 25)
$chkDryRun.AutoSize = $true

$chkExportConflicts = New-Object System.Windows.Forms.CheckBox
$chkExportConflicts.Text = "Export conflicts.txt"
$chkExportConflicts.Location = New-Object System.Drawing.Point(320, 48)
$chkExportConflicts.AutoSize = $true

$chkRecursive = New-Object System.Windows.Forms.CheckBox
$chkRecursive.Text = "Recursive search for .pak (subfolders)"
$chkRecursive.Location = New-Object System.Drawing.Point(560, 25)
$chkRecursive.AutoSize = $true
$chkRecursive.Checked = $true

$grpOptions.Controls.AddRange(@($chkAutoDisable, $chkShowConflicts, $chkDryRun, $chkExportConflicts, $chkRecursive))
$form.Controls.Add($grpOptions)

# -------------------------------
# RUN BUTTON + STATUS
# -------------------------------

$btnRun = New-Object System.Windows.Forms.Button
$btnRun.Text = "Run Merge"
$btnRun.Location = New-Object System.Drawing.Point(12, 300)
$btnRun.Size = New-Object System.Drawing.Size(140, 34)
$btnRun.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$btnRun.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
$btnRun.ForeColor = [System.Drawing.Color]::White
$btnRun.FlatStyle = "Flat"

$progressLabel = New-Object System.Windows.Forms.Label
$progressLabel.Text = "Status: Waiting for input..."
$progressLabel.Location = New-Object System.Drawing.Point(165, 308)
$progressLabel.AutoSize = $true
$progressLabel.Anchor = "Top,Left"

$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(12, 345)
$progressBar.Size = New-Object System.Drawing.Size(860, 22)
$progressBar.Anchor = "Top,Left,Right"

$form.Controls.AddRange(@($btnRun, $progressLabel, $progressBar))

# -------------------------------
# LOG
# -------------------------------

$conflictBox = New-Object System.Windows.Forms.TextBox
$conflictBox.Location = New-Object System.Drawing.Point(12, 380)
$conflictBox.Size = New-Object System.Drawing.Size(860, 280)
$conflictBox.Multiline = $true
$conflictBox.ScrollBars = "Both"
$conflictBox.ReadOnly = $true
$conflictBox.Font = New-Object System.Drawing.Font("Consolas", 9)
$conflictBox.Anchor = "Top,Bottom,Left,Right"
$conflictBox.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$conflictBox.ForeColor = [System.Drawing.Color]::FromArgb(220, 220, 220)

$form.Controls.Add($conflictBox)

# Tooltips
$toolTip.SetToolTip($textGame, "Select any STALKER 2 executable. The script will locate the real shipping EXE and the Content\Paks folder.")
$toolTip.SetToolTip($textMods, "Leave empty for auto-detect, or point to your ~mods folder. Recursive search finds .pak files in subfolders.")
$toolTip.SetToolTip($chkRecursive, "When checked, searches all subfolders under ~mods for .pak files (recommended).")

# -------------------------------
# HELPER FUNCTIONS
# -------------------------------

function Set-Status {
    param([string]$msg, [int]$progress = -1)
    $progressLabel.Text = "Status: $msg"
    if ($progress -ge 0 -and $progress -le 100) {
        $progressBar.Value = [Math]::Min(100, [Math]::Max(0, $progress))
    }
    $form.Refresh()
    [System.Windows.Forms.Application]::DoEvents()
}

function Log {
    param([string]$msg)
    $conflictBox.AppendText("$msg`r`n")
    $conflictBox.SelectionStart = $conflictBox.Text.Length
    $conflictBox.ScrollToCaret()
    $form.Refresh()
    [System.Windows.Forms.Application]::DoEvents()
}

function Find-RealExe {
    param([string]$selectedExe)
    $folder = Split-Path $selectedExe -Parent

    # Common locations
    $candidates = @(
        (Join-Path $folder "Stalker2\Binaries\Win64\Stalker2-Win64-Shipping.exe"),
        (Join-Path $folder "Binaries\Win64\Stalker2-Win64-Shipping.exe"),
        (Join-Path (Split-Path $folder -Parent) "Binaries\Win64\Stalker2-Win64-Shipping.exe"),
        $selectedExe
    )

    foreach ($c in $candidates) {
        if (Test-Path $c) { return (Resolve-Path $c).Path }
    }

    # Last resort: search upward a few levels
    $current = $folder
    for ($i = 0; $i -lt 5; $i++) {
        $try = Join-Path $current "Binaries\Win64\Stalker2-Win64-Shipping.exe"
        if (Test-Path $try) { return (Resolve-Path $try).Path }
        $try2 = Join-Path $current "Stalker2\Binaries\Win64\Stalker2-Win64-Shipping.exe"
        if (Test-Path $try2) { return (Resolve-Path $try2).Path }
        $parent = Split-Path $current -Parent
        if (-not $parent -or $parent -eq $current) { break }
        $current = $parent
    }

    return $null
}

function Find-ModsFolder {
    param([string]$realExe)

    $Win64    = Split-Path $realExe -Parent
    $Binaries = Split-Path $Win64 -Parent
    $Stalker2 = Split-Path $Binaries -Parent   # ...\Stalker2
    $PakDir   = Join-Path $Stalker2 "Content\Paks"
    $ModsDir  = Join-Path $PakDir "~mods"

    if (Test-Path $ModsDir) {
        return (Resolve-Path $ModsDir).Path
    }

    # Create if missing (common first-time case)
    if (Test-Path $PakDir) {
        New-Item -ItemType Directory -Path $ModsDir -Force | Out-Null
        return (Resolve-Path $ModsDir).Path
    }

    # Fallback: search upward for Content\Paks\~mods
    $current = $Stalker2
    for ($i = 0; $i -lt 4; $i++) {
        $try = Join-Path $current "Content\Paks\~mods"
        if (Test-Path $try) { return (Resolve-Path $try).Path }
        $parent = Split-Path $current -Parent
        if (-not $parent -or $parent -eq $current) { break }
        $current = $parent
    }

    return $null
}

function Get-AllPakFiles {
    param(
        [string]$modsDir,
        [bool]$recursive
    )

    if ($recursive) {
        return Get-ChildItem -Path $modsDir -Filter "*.pak" -Recurse -File -ErrorAction SilentlyContinue |
               Where-Object { $_.FullName -notmatch '\\_backup_' -and $_.Name -notmatch '^MergedMod' }
    }
    else {
        return Get-ChildItem -Path $modsDir -Filter "*.pak" -File -ErrorAction SilentlyContinue |
               Where-Object { $_.Name -notmatch '^MergedMod' }
    }
}

# -------------------------------
# BUTTON HANDLERS
# -------------------------------

$btnBrowse.Add_Click({
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Filter = "STALKER 2 Executable|Stalker2.exe;Stalker2-Win64-Shipping.exe|All EXE|*.exe"
    $dialog.Title = "Select ANY STALKER 2 executable"
    if ($dialog.ShowDialog() -eq "OK") {
        $textGame.Text = $dialog.FileName
    }
})

$btnBrowseMods.Add_Click({
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = "Select your ~mods folder (or any folder containing .pak files)"
    $dialog.ShowNewFolderButton = $true
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $textMods.Text = $dialog.SelectedPath
    }
})

$btnAutoDetect.Add_Click({
    if ([string]::IsNullOrWhiteSpace($textGame.Text) -or -not (Test-Path $textGame.Text)) {
        [System.Windows.Forms.MessageBox]::Show("Please select a valid game executable first.", "Missing EXE", "OK", "Warning")
        return
    }
    $real = Find-RealExe $textGame.Text
    if (-not $real) {
        [System.Windows.Forms.MessageBox]::Show("Could not locate the real shipping executable.", "Error", "OK", "Error")
        return
    }
    $mods = Find-ModsFolder $real
    if ($mods) {
        $textMods.Text = $mods
        Log "Auto-detected mods folder: $mods"
    }
    else {
        [System.Windows.Forms.MessageBox]::Show("Could not find or create ~mods folder.`nPlease browse manually.", "Not Found", "OK", "Warning")
    }
})

# -------------------------------
# MAIN RUN LOGIC
# -------------------------------

$btnRun.Add_Click({
    try {
        $conflictBox.Clear()
        Set-Status "Starting...", 0

        $selectedExe = $textGame.Text.Trim()
        if ([string]::IsNullOrWhiteSpace($selectedExe) -or -not (Test-Path $selectedExe)) {
            [System.Windows.Forms.MessageBox]::Show("Please select a valid game executable.", "Error", "OK", "Error")
            return
        }

        # Resolve real EXE
        Set-Status "Locating real game executable...", 5
        $realExe = Find-RealExe $selectedExe
        if (-not $realExe) {
            [System.Windows.Forms.MessageBox]::Show("Could not auto-detect the real Stalker2-Win64-Shipping.exe.", "Error", "OK", "Error")
            return
        }
        Log "Real EXE: $realExe"

        # Resolve paths from real EXE
        $Win64    = Split-Path $realExe -Parent
        $Binaries = Split-Path $Win64 -Parent
        $Stalker2 = Split-Path $Binaries -Parent
        $PakDir   = Join-Path $Stalker2 "Content\Paks"

        Log "Stalker2 folder: $Stalker2"
        Log "Paks folder:     $PakDir"

        # Mods folder
        if (-not [string]::IsNullOrWhiteSpace($textMods.Text) -and (Test-Path $textMods.Text)) {
            $ModsDir = (Resolve-Path $textMods.Text).Path
            Log "Using manual mods folder: $ModsDir"
        }
        else {
            Set-Status "Auto-detecting ~mods folder...", 8
            $ModsDir = Find-ModsFolder $realExe
            if (-not $ModsDir) {
                [System.Windows.Forms.MessageBox]::Show("~mods folder not found and could not be created.`nPlease browse to it manually.", "Error", "OK", "Error")
                return
            }
            $textMods.Text = $ModsDir
            Log "Auto-detected mods folder: $ModsDir"
        }

        # Collect .pak files (recursive option)
        Set-Status "Scanning for .pak files...", 12
        $pakFiles = @(Get-AllPakFiles -modsDir $ModsDir -recursive $chkRecursive.Checked)

        if ($pakFiles.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show("No .pak files found in:`n$ModsDir`n`n(Recursive: $($chkRecursive.Checked))", "No Mods", "OK", "Information")
            Log "No .pak files found."
            return
        }

        Log "Found $($pakFiles.Count) .pak file(s):"
        foreach ($p in $pakFiles) {
            $rel = $p.FullName.Substring($ModsDir.Length).TrimStart('\')
            Log "  - $rel"
        }

        # Backup
        Set-Status "Creating backup...", 15
        $BackupDir = Join-Path $ModsDir ("_backup_{0:yyyyMMdd_HHmmss}" -f (Get-Date))
        New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
        foreach ($pak in $pakFiles) {
            $dest = Join-Path $BackupDir $pak.Name
            # Avoid name collisions if same name in different subfolders
            if (Test-Path $dest) {
                $dest = Join-Path $BackupDir ("{0}_{1}" -f $pak.Directory.Name, $pak.Name)
            }
            Copy-Item $pak.FullName $dest -Force
        }
        Log "Backup created: $BackupDir"

        # AES key extraction
        Set-Status "Extracting AES key from EXE...", 20
        $bytes = [System.IO.File]::ReadAllBytes($realExe)
        $hex   = [BitConverter]::ToString($bytes).Replace("-", "")

        $AESKey = $null
        $m1 = [regex]::Match($hex, "0x[0-9A-F]{64}")
        if ($m1.Success) {
            $AESKey = $m1.Value
        }
        else {
            $m2 = [regex]::Match($hex, "[0-9A-F]{64}")
            if ($m2.Success) { $AESKey = "0x" + $m2.Value }
        }

        if (-not $AESKey) {
            [System.Windows.Forms.MessageBox]::Show("AES key not found in the executable.`nMake sure you selected the correct shipping EXE.", "Error", "OK", "Error")
            return
        }
        Set-Content -Path (Join-Path $PSScriptRoot "aes_key.txt") -Value $AESKey -Force
        Log "AES key extracted and saved to aes_key.txt"

        # Check for repak.exe
        $repak = Join-Path $PSScriptRoot "repak.exe"
        if (-not (Test-Path $repak)) {
            [System.Windows.Forms.MessageBox]::Show("repak.exe not found next to the script.`nDownload it from:`nhttps://github.com/trumank/repak/releases", "Missing Tool", "OK", "Error")
            return
        }

        # Unpack base game (only if needed for .cfg merge)
        $basePak = Join-Path $PakDir "pakchunk0-Windows.pak"
        $baseOut = Join-Path $PakDir "pakchunk0-Windows"
        if (-not $chkDryRun.Checked) {
            Set-Status "Unpacking base game (pakchunk0)...", 25
            if (-not (Test-Path $baseOut)) {
                if (Test-Path $basePak) {
                    & $repak --aes-key $AESKey unpack "`"$basePak`""
                    # Move if repak created it next to the pak
                    $created = Join-Path (Split-Path $basePak) "pakchunk0-Windows"
                    if ((Test-Path $created) -and ($created -ne $baseOut)) {
                        Move-Item $created $baseOut -Force
                    }
                    Log "Base game unpacked."
                }
                else {
                    Log "WARNING: pakchunk0-Windows.pak not found. .cfg merges will not have base content."
                }
            }
            else {
                Log "Base game already unpacked."
            }
        }

        # Unpack mods
        Set-Status "Unpacking mods...", 35
        $unpackedMods = @{}   # key = original pak full path, value = unpacked folder

        $tempRoot = Join-Path $env:TEMP ("S2Merger_{0}" -f [Guid]::NewGuid().ToString("N").Substring(0,8))
        New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null

        $i = 0
        foreach ($pak in $pakFiles) {
            $i++
            $pct = 35 + [int](($i / $pakFiles.Count) * 15)
            Set-Status "Unpacking $($pak.Name) ($i/$($pakFiles.Count))...", $pct
            Log "Unpacking: $($pak.Name)"

            $workDir = Join-Path $tempRoot $pak.BaseName
            New-Item -ItemType Directory -Path $workDir -Force | Out-Null
            Copy-Item $pak.FullName (Join-Path $workDir $pak.Name) -Force

            Push-Location $workDir
            try {
                & $repak unpack "`"$($pak.Name)`""
            }
            finally {
                Pop-Location
            }

            # Find the unpacked folder (usually same name without .pak)
            $unpacked = Get-ChildItem $workDir -Directory | Select-Object -First 1
            if ($unpacked) {
                $unpackedMods[$pak.FullName] = $unpacked.FullName
            }
            else {
                Log "  WARNING: No folder created after unpack for $($pak.Name)"
            }
        }

        # Build file map (relative path -> list of mod names)
        Set-Status "Scanning for conflicts...", 55
        $fileMap = @{}

        foreach ($pakPath in $unpackedMods.Keys) {
            $modFolder = $unpackedMods[$pakPath]
            $modName   = [System.IO.Path]::GetFileName($pakPath)

            $files = Get-ChildItem $modFolder -Recurse -File -ErrorAction SilentlyContinue
            foreach ($f in $files) {
                $rel = $f.FullName.Substring($modFolder.Length).TrimStart('\')
                if (-not $fileMap.ContainsKey($rel)) {
                    $fileMap[$rel] = [System.Collections.Generic.List[string]]::new()
                }
                $fileMap[$rel].Add($modName)
            }
        }

        $conflicts = $fileMap.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 }

        # Dry-run
        if ($chkDryRun.Checked) {
            Log ""
            Log "========== DRY-RUN MODE =========="
            Log "Conflicts found: $($conflicts.Count)"
            Log ""

            if ($chkShowConflicts.Checked -or $conflicts.Count -gt 0) {
                foreach ($c in $conflicts) {
                    Log "FILE: $($c.Key)"
                    Log "  MODS: $($c.Value -join ', ')"
                    Log ""
                }
            }

            if ($chkExportConflicts.Checked) {
                $report = @("Conflict Report - $(Get-Date)", "==============================", "")
                foreach ($c in $conflicts) {
                    $report += "FILE: $($c.Key)"
                    $report += "  MODS: $($c.Value -join ', ')"
                    $report += ""
                }
                $reportPath = Join-Path $PSScriptRoot "conflicts.txt"
                $report | Set-Content $reportPath -Encoding UTF8
                Log "Exported: $reportPath"
            }

            # Cleanup temp
            Remove-Item $tempRoot -Recurse -Force -ErrorAction SilentlyContinue

            Set-Status "Dry-run complete.", 100
            [System.Windows.Forms.MessageBox]::Show("Dry-run finished.`nConflicts: $($conflicts.Count)`nNo files were modified.", "Dry-Run", "OK", "Information")
            return
        }

        if ($conflicts.Count -eq 0) {
            Log "No overlapping files found between mods. No merge needed."
            Remove-Item $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
            Set-Status "No conflicts.", 100
            [System.Windows.Forms.MessageBox]::Show("No conflicts detected. Your mods do not overlap.", "Done", "OK", "Information")
            return
        }

        if ($chkShowConflicts.Checked) {
            Log ""
            Log "========== CONFLICTS ($($conflicts.Count)) =========="
            foreach ($c in $conflicts) {
                Log "FILE: $($c.Key)"
                Log "  MODS: $($c.Value -join ', ')"
                Log ""
            }
        }

        if ($chkExportConflicts.Checked) {
            $report = @("Conflict Report - $(Get-Date)", "==============================", "")
            foreach ($c in $conflicts) {
                $report += "FILE: $($c.Key)"
                $report += "  MODS: $($c.Value -join ', ')"
                $report += ""
            }
            $reportPath = Join-Path $PSScriptRoot "conflicts.txt"
            $report | Set-Content $reportPath -Encoding UTF8
            Log "Exported conflicts.txt"
        }

        # Create merged folder
        Set-Status "Building merged mod...", 65
        $mergedFolder = Join-Path $tempRoot "MergedMod"
        New-Item -ItemType Directory -Path $mergedFolder -Force | Out-Null

        # Copy non-conflicting files
        Set-Status "Copying non-conflicting files...", 70
        $conflictSet = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
        foreach ($c in $conflicts) { [void]$conflictSet.Add($c.Key) }

        foreach ($pakPath in $unpackedMods.Keys) {
            $modFolder = $unpackedMods[$pakPath]
            $files = Get-ChildItem $modFolder -Recurse -File -ErrorAction SilentlyContinue
            foreach ($f in $files) {
                $rel = $f.FullName.Substring($modFolder.Length).TrimStart('\')
                if (-not $conflictSet.Contains($rel)) {
                    $target = Join-Path $mergedFolder $rel
                    $targetDir = Split-Path $target -Parent
                    if (-not (Test-Path $targetDir)) {
                        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
                    }
                    if (-not (Test-Path $target)) {
                        Copy-Item $f.FullName $target -Force
                    }
                }
            }
        }

        # Merge .cfg conflicts (simple append strategy – last mod wins on duplicate lines is not perfect but matches original intent)
        Set-Status "Merging conflicting .cfg files...", 80
        foreach ($c in $conflicts) {
            $relPath = $c.Key
            $mods    = $c.Value

            if ([System.IO.Path]::GetExtension($relPath) -ne ".cfg") {
                Log "Skipping non-.cfg conflict (manual review recommended): $relPath"
                # Still copy the last one so something is present
                $lastMod = $mods[-1]
                $lastPak = $pakFiles | Where-Object { $_.Name -eq $lastMod } | Select-Object -First 1
                if ($lastPak -and $unpackedMods.ContainsKey($lastPak.FullName)) {
                    $src = Join-Path $unpackedMods[$lastPak.FullName] $relPath
                    if (Test-Path $src) {
                        $target = Join-Path $mergedFolder $relPath
                        $targetDir = Split-Path $target -Parent
                        if (-not (Test-Path $targetDir)) { New-Item -ItemType Directory -Path $targetDir -Force | Out-Null }
                        Copy-Item $src $target -Force
                    }
                }
                continue
            }

            $mergedTarget = Join-Path $mergedFolder $relPath
            $mergedDir    = Split-Path $mergedTarget -Parent
            if (-not (Test-Path $mergedDir)) {
                New-Item -ItemType Directory -Path $mergedDir -Force | Out-Null
            }

            $content = [System.Collections.Generic.List[string]]::new()

            # Base game content first
            $baseFile = Join-Path $baseOut $relPath
            if (Test-Path $baseFile) {
                $content.AddRange([string[]](Get-Content $baseFile -ErrorAction SilentlyContinue))
            }

            # Then each mod's version
            foreach ($modName in $mods) {
                $pak = $pakFiles | Where-Object { $_.Name -eq $modName } | Select-Object -First 1
                if ($pak -and $unpackedMods.ContainsKey($pak.FullName)) {
                    $modFile = Join-Path $unpackedMods[$pak.FullName] $relPath
                    if (Test-Path $modFile) {
                        $content.AddRange([string[]](Get-Content $modFile -ErrorAction SilentlyContinue))
                    }
                }
            }

            $content | Set-Content $mergedTarget -Encoding UTF8
            Log "Merged .cfg: $relPath"
        }

        # Pack
        Set-Status "Packing MergedMod.pak...", 90
        Push-Location $tempRoot
        try {
            & $repak pack "MergedMod"
        }
        finally {
            Pop-Location
        }

        $outputPak = Join-Path $tempRoot "MergedMod.pak"
        if (-not (Test-Path $outputPak)) {
            # Some versions of repak put it next to the folder
            $outputPak = Join-Path $tempRoot "MergedMod\MergedMod.pak"
        }

        if (Test-Path $outputPak) {
            $finalDest = Join-Path $ModsDir "MergedMod.pak"
            Copy-Item $outputPak $finalDest -Force
            Log ""
            Log "SUCCESS: MergedMod.pak created at:"
            Log "  $finalDest"
        }
        else {
            throw "repak did not produce MergedMod.pak"
        }

        # Cleanup
        Set-Status "Cleaning up temporary files...", 95
        Remove-Item $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
        if (Test-Path $baseOut) {
            # Optional: leave base unpacked or remove. Original removed it.
            # Remove-Item $baseOut -Recurse -Force -ErrorAction SilentlyContinue
        }

        # Auto-disable list
        $modDisableSet = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
        foreach ($c in $conflicts) {
            foreach ($m in $c.Value) { [void]$modDisableSet.Add($m) }
        }

        Set-Status "Done!", 100
        Log ""
        Log "Finished. Place MergedMod.pak in ~mods (already done) and disable the original conflicting mods."

        $msg = "MergedMod.pak created successfully in your ~mods folder.`n`nConflicts resolved: $($conflicts.Count)"
        if ($chkAutoDisable.Checked -and $modDisableSet.Count -gt 0) {
            $list = ($modDisableSet | Sort-Object) -join "`n  - "
            $msg += "`n`nDisable these original mods in Vortex / MO2:`n  - $list"
            Log ""
            Log "Mods that were merged (disable them):"
            foreach ($m in ($modDisableSet | Sort-Object)) { Log "  - $m" }
        }

        [System.Windows.Forms.MessageBox]::Show($msg, "Success", "OK", "Information")
    }
    catch {
        Log "ERROR: $($_.Exception.Message)"
        Set-Status "Error occurred.", 0
        [System.Windows.Forms.MessageBox]::Show("Error:`n$($_.Exception.Message)", "Error", "OK", "Error")
    }
})

# -------------------------------
# SHOW FORM
# -------------------------------

[void]$form.ShowDialog()
