##############################################
# STALKER 2 MOD MERGER - Smarter retoc + repak
# More resilient error handling and tool routing
##############################################

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"

# -------------------------------
# GUI (compact, same layout)
# -------------------------------

$form = New-Object System.Windows.Forms.Form
$form.Text = "STALKER 2 Mod Merger (Smart retoc/repak)"
$form.Size = New-Object System.Drawing.Size(940, 760)
$form.StartPosition = "CenterScreen"
$form.MinimumSize = New-Object System.Drawing.Size(840, 680)
$form.FormBorderStyle = "Sizable"
$form.Font = New-Object System.Drawing.Font("Segoe UI", 9)

$toolTip = New-Object System.Windows.Forms.ToolTip

# 1. EXE
$grpExe = New-Object System.Windows.Forms.GroupBox
$grpExe.Text = "1. Game Executable"
$grpExe.Location = New-Object System.Drawing.Point(12, 10)
$grpExe.Size = New-Object System.Drawing.Size(900, 78)
$grpExe.Anchor = "Top,Left,Right"

$labelGame = New-Object System.Windows.Forms.Label
$labelGame.Text = "Select Stalker2.exe or Stalker2-Win64-Shipping.exe:"
$labelGame.Location = New-Object System.Drawing.Point(12, 20)
$labelGame.AutoSize = $true

$textGame = New-Object System.Windows.Forms.TextBox
$textGame.Location = New-Object System.Drawing.Point(12, 42)
$textGame.Size = New-Object System.Drawing.Size(760, 23)
$textGame.Anchor = "Top,Left,Right"

$btnBrowse = New-Object System.Windows.Forms.Button
$btnBrowse.Text = "Browse..."
$btnBrowse.Location = New-Object System.Drawing.Point(780, 40)
$btnBrowse.Size = New-Object System.Drawing.Size(100, 27)
$btnBrowse.Anchor = "Top,Right"

$grpExe.Controls.AddRange(@($labelGame, $textGame, $btnBrowse))
$form.Controls.Add($grpExe)

# 2. Mods
$grpMods = New-Object System.Windows.Forms.GroupBox
$grpMods.Text = "2. Mods Folder (~mods)"
$grpMods.Location = New-Object System.Drawing.Point(12, 95)
$grpMods.Size = New-Object System.Drawing.Size(900, 78)
$grpMods.Anchor = "Top,Left,Right"

$labelMods = New-Object System.Windows.Forms.Label
$labelMods.Text = "Auto-detect or override. Finds .pak / .ucas / .utoc (including subfolders)."
$labelMods.Location = New-Object System.Drawing.Point(12, 20)
$labelMods.AutoSize = $true

$textMods = New-Object System.Windows.Forms.TextBox
$textMods.Location = New-Object System.Drawing.Point(12, 42)
$textMods.Size = New-Object System.Drawing.Size(660, 23)
$textMods.Anchor = "Top,Left,Right"

$btnBrowseMods = New-Object System.Windows.Forms.Button
$btnBrowseMods.Text = "Browse..."
$btnBrowseMods.Location = New-Object System.Drawing.Point(680, 40)
$btnBrowseMods.Size = New-Object System.Drawing.Size(100, 27)
$btnBrowseMods.Anchor = "Top,Right"

$btnAutoDetect = New-Object System.Windows.Forms.Button
$btnAutoDetect.Text = "Auto-Detect"
$btnAutoDetect.Location = New-Object System.Drawing.Point(790, 40)
$btnAutoDetect.Size = New-Object System.Drawing.Size(90, 27)
$btnAutoDetect.Anchor = "Top,Right"

$grpMods.Controls.AddRange(@($labelMods, $textMods, $btnBrowseMods, $btnAutoDetect))
$form.Controls.Add($grpMods)

# 3. Options
$grpOptions = New-Object System.Windows.Forms.GroupBox
$grpOptions.Text = "3. Options"
$grpOptions.Location = New-Object System.Drawing.Point(12, 180)
$grpOptions.Size = New-Object System.Drawing.Size(900, 95)
$grpOptions.Anchor = "Top,Left,Right"

$chkAutoDisable = New-Object System.Windows.Forms.CheckBox
$chkAutoDisable.Text = "Show mods to disable"
$chkAutoDisable.Location = New-Object System.Drawing.Point(15, 22)
$chkAutoDisable.AutoSize = $true
$chkAutoDisable.Checked = $true

$chkShowConflicts = New-Object System.Windows.Forms.CheckBox
$chkShowConflicts.Text = "Show conflict details"
$chkShowConflicts.Location = New-Object System.Drawing.Point(15, 48)
$chkShowConflicts.AutoSize = $true
$chkShowConflicts.Checked = $true

$chkDryRun = New-Object System.Windows.Forms.CheckBox
$chkDryRun.Text = "Dry-run only"
$chkDryRun.Location = New-Object System.Drawing.Point(220, 22)
$chkDryRun.AutoSize = $true

$chkExportConflicts = New-Object System.Windows.Forms.CheckBox
$chkExportConflicts.Text = "Export conflicts.txt"
$chkExportConflicts.Location = New-Object System.Drawing.Point(220, 48)
$chkExportConflicts.AutoSize = $true

$chkRecursive = New-Object System.Windows.Forms.CheckBox
$chkRecursive.Text = "Recursive search"
$chkRecursive.Location = New-Object System.Drawing.Point(420, 22)
$chkRecursive.AutoSize = $true
$chkRecursive.Checked = $true

$chkTryIoStoreOut = New-Object System.Windows.Forms.CheckBox
$chkTryIoStoreOut.Text = "Also try IOStore output (optional, may fail)"
$chkTryIoStoreOut.Location = New-Object System.Drawing.Point(420, 48)
$chkTryIoStoreOut.AutoSize = $true
$chkTryIoStoreOut.Checked = $false

$grpOptions.Controls.AddRange(@($chkAutoDisable, $chkShowConflicts, $chkDryRun, $chkExportConflicts, $chkRecursive, $chkTryIoStoreOut))
$form.Controls.Add($grpOptions)

# Run + status
$btnRun = New-Object System.Windows.Forms.Button
$btnRun.Text = "Run Merge"
$btnRun.Location = New-Object System.Drawing.Point(12, 285)
$btnRun.Size = New-Object System.Drawing.Size(140, 34)
$btnRun.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$btnRun.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
$btnRun.ForeColor = [System.Drawing.Color]::White
$btnRun.FlatStyle = "Flat"

$progressLabel = New-Object System.Windows.Forms.Label
$progressLabel.Text = "Status: Waiting..."
$progressLabel.Location = New-Object System.Drawing.Point(165, 293)
$progressLabel.AutoSize = $true

$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(12, 330)
$progressBar.Size = New-Object System.Drawing.Size(900, 22)
$progressBar.Anchor = "Top,Left,Right"

$form.Controls.AddRange(@($btnRun, $progressLabel, $progressBar))

$conflictBox = New-Object System.Windows.Forms.TextBox
$conflictBox.Location = New-Object System.Drawing.Point(12, 365)
$conflictBox.Size = New-Object System.Drawing.Size(900, 330)
$conflictBox.Multiline = $true
$conflictBox.ScrollBars = "Both"
$conflictBox.ReadOnly = $true
$conflictBox.Font = New-Object System.Drawing.Font("Consolas", 9)
$conflictBox.Anchor = "Top,Bottom,Left,Right"
$conflictBox.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$conflictBox.ForeColor = [System.Drawing.Color]::FromArgb(220, 220, 220)
$form.Controls.Add($conflictBox)

# -------------------------------
# HELPERS
# -------------------------------

function Set-Status {
    param([string]$msg, [int]$progress = -1)
    $progressLabel.Text = "Status: $msg"
    if ($progress -ge 0 -and $progress -le 100) { $progressBar.Value = $progress }
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
    $candidates = @(
        (Join-Path $folder "Stalker2\Binaries\Win64\Stalker2-Win64-Shipping.exe"),
        (Join-Path $folder "Binaries\Win64\Stalker2-Win64-Shipping.exe"),
        (Join-Path (Split-Path $folder -Parent) "Binaries\Win64\Stalker2-Win64-Shipping.exe"),
        $selectedExe
    )
    foreach ($c in $candidates) { if (Test-Path $c) { return (Resolve-Path $c).Path } }
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
    $Win64 = Split-Path $realExe -Parent
    $Binaries = Split-Path $Win64 -Parent
    $Stalker2 = Split-Path $Binaries -Parent
    $PakDir = Join-Path $Stalker2 "Content\Paks"
    $ModsDir = Join-Path $PakDir "~mods"
    if (Test-Path $ModsDir) { return (Resolve-Path $ModsDir).Path }
    if (Test-Path $PakDir) {
        New-Item -ItemType Directory -Path $ModsDir -Force | Out-Null
        return (Resolve-Path $ModsDir).Path
    }
    return $null
}

function Get-AllModSets {
    param([string]$modsDir, [bool]$recursive)
    $allFiles = @()
    foreach ($ext in @("*.pak", "*.ucas", "*.utoc")) {
        if ($recursive) {
            $allFiles += Get-ChildItem -Path $modsDir -Filter $ext -File -Recurse -ErrorAction SilentlyContinue |
                Where-Object { $_.FullName -notmatch '\\_backup_' -and $_.Name -notmatch '(?i)^MergedMod' }
        } else {
            $allFiles += Get-ChildItem -Path $modsDir -Filter $ext -File -ErrorAction SilentlyContinue |
                Where-Object { $_.FullName -notmatch '\\_backup_' -and $_.Name -notmatch '(?i)^MergedMod' }
        }
    }

    $groups = $allFiles | Group-Object {
        "$($_.Directory.FullName)|$([IO.Path]::GetFileNameWithoutExtension($_.Name))"
    }

    $sets = @()
    foreach ($g in $groups) {
        $parts = $g.Name -split '\|', 2
        $pak  = $g.Group | Where-Object { $_.Extension -eq '.pak'  } | Select-Object -First 1
        $ucas = $g.Group | Where-Object { $_.Extension -eq '.ucas' } | Select-Object -First 1
        $utoc = $g.Group | Where-Object { $_.Extension -eq '.utoc' } | Select-Object -First 1
        $display = if ($pak) { $pak.Name } elseif ($utoc) { $utoc.Name } else { $ucas.Name }
        $sets += [PSCustomObject]@{
            Name       = $display
            BaseName   = $parts[1]
            Directory  = $parts[0]
            Pak        = $pak
            Ucas       = $ucas
            Utoc       = $utoc
            HasIoStore = ($null -ne $ucas -or $null -ne $utoc)
            AllFiles   = @($g.Group)
        }
    }
    return $sets | Sort-Object Name
}

function Test-HasContent {
    param([string]$dir)
    if (-not (Test-Path $dir)) { return $false }
    return (Get-ChildItem $dir -Recurse -File -ErrorAction SilentlyContinue | Measure-Object).Count -gt 0
}

# Try retoc to-legacy with several strategies; return unpacked folder or $null
function Invoke-RetocToLegacy {
    param(
        [string]$retocPath,
        [string]$aesKey,
        [string]$utocPath,
        [string]$outDir
    )
    if (-not (Test-Path $utocPath)) { return $null }
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null

    # Strategy 1: direct to-legacy on utoc
    try {
        $null = & $retocPath --aes-key $aesKey to-legacy $utocPath $outDir 2>&1
        if (Test-HasContent $outDir) { return $outDir }
    } catch {}

    # Strategy 2: to-legacy on the folder containing the trio
    $parent = Split-Path $utocPath -Parent
    try {
        $null = & $retocPath --aes-key $aesKey to-legacy $parent $outDir 2>&1
        if (Test-HasContent $outDir) { return $outDir }
    } catch {}

    # Strategy 3: plain unpack
    try {
        $null = & $retocPath --aes-key $aesKey unpack $utocPath -o $outDir 2>&1
        if (Test-HasContent $outDir) { return $outDir }
    } catch {}

    return $null
}

# Try repak unpack; return folder or $null
function Invoke-RepakUnpack {
    param(
        [string]$repakPath,
        [string]$pakPath,
        [string]$workDir
    )
    if (-not (Test-Path $pakPath)) { return $null }
    New-Item -ItemType Directory -Path $workDir -Force | Out-Null
    $localPak = Join-Path $workDir (Split-Path $pakPath -Leaf)
    Copy-Item $pakPath $localPak -Force

    Push-Location $workDir
    try {
        $null = & $repakPath unpack "`"$localPak`"" 2>&1
    } catch {}
    finally { Pop-Location }

    $dirs = Get-ChildItem $workDir -Directory -ErrorAction SilentlyContinue
    foreach ($d in $dirs) {
        if (Test-HasContent $d.FullName) { return $d.FullName }
    }
    # Sometimes files land directly in workDir
    if (Test-HasContent $workDir) { return $workDir }
    return $null
}

# -------------------------------
# BUTTONS
# -------------------------------

$btnBrowse.Add_Click({
    $d = New-Object System.Windows.Forms.OpenFileDialog
    $d.Filter = "STALKER 2 Executable|Stalker2.exe;Stalker2-Win64-Shipping.exe|All EXE|*.exe"
    if ($d.ShowDialog() -eq "OK") { $textGame.Text = $d.FileName }
})

$btnBrowseMods.Add_Click({
    $d = New-Object System.Windows.Forms.FolderBrowserDialog
    $d.Description = "Select ~mods folder"
    if ($d.ShowDialog() -eq "OK") { $textMods.Text = $d.SelectedPath }
})

$btnAutoDetect.Add_Click({
    if (-not (Test-Path $textGame.Text)) {
        [System.Windows.Forms.MessageBox]::Show("Select a valid EXE first.", "Error", "OK", "Warning")
        return
    }
    $real = Find-RealExe $textGame.Text
    if (-not $real) {
        [System.Windows.Forms.MessageBox]::Show("Could not find shipping EXE.", "Error", "OK", "Error")
        return
    }
    $mods = Find-ModsFolder $real
    if ($mods) { $textMods.Text = $mods; Log "Auto-detected: $mods" }
    else { [System.Windows.Forms.MessageBox]::Show("Could not find ~mods.", "Error", "OK", "Warning") }
})

# -------------------------------
# MAIN
# -------------------------------

$btnRun.Add_Click({
    try {
        $conflictBox.Clear()
        Set-Status "Starting...", 0

        $selectedExe = $textGame.Text.Trim()
        if (-not (Test-Path $selectedExe)) {
            [System.Windows.Forms.MessageBox]::Show("Select a valid game executable.", "Error", "OK", "Error")
            return
        }

        $repak = Join-Path $PSScriptRoot "repak.exe"
        $retoc = Join-Path $PSScriptRoot "retoc.exe"
        $hasRepak = Test-Path $repak
        $hasRetoc = Test-Path $retoc

        if (-not $hasRepak -and -not $hasRetoc) {
            [System.Windows.Forms.MessageBox]::Show(
                "Need at least one of:`n  repak.exe  (https://github.com/trumank/repak/releases)`n  retoc.exe  (https://github.com/trumank/retoc/releases)",
                "Missing tools", "OK", "Error")
            return
        }
        Log "Tools: repak=$(if($hasRepak){'YES'}else{'NO'})  retoc=$(if($hasRetoc){'YES'}else{'NO'})"

        Set-Status "Locating EXE...", 5
        $realExe = Find-RealExe $selectedExe
        if (-not $realExe) {
            [System.Windows.Forms.MessageBox]::Show("Could not find Stalker2-Win64-Shipping.exe.", "Error", "OK", "Error")
            return
        }
        Log "Real EXE: $realExe"

        $Stalker2 = Split-Path (Split-Path (Split-Path $realExe -Parent) -Parent) -Parent
        $PakDir   = Join-Path $Stalker2 "Content\Paks"

        if ($textMods.Text -and (Test-Path $textMods.Text)) {
            $ModsDir = (Resolve-Path $textMods.Text).Path
        } else {
            $ModsDir = Find-ModsFolder $realExe
            if (-not $ModsDir) {
                [System.Windows.Forms.MessageBox]::Show("~mods not found.", "Error", "OK", "Error")
                return
            }
            $textMods.Text = $ModsDir
        }
        Log "Mods folder: $ModsDir"

        Set-Status "Scanning mods...", 12
        $modSets = @(Get-AllModSets -modsDir $ModsDir -recursive $chkRecursive.Checked)
        if ($modSets.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show("No .pak/.ucas/.utoc found.", "No mods", "OK", "Information")
            return
        }

        Log "Found $($modSets.Count) mod set(s):"
        foreach ($s in $modSets) {
            $bits = @()
            if ($s.Pak)  { $bits += "pak" }
            if ($s.Ucas) { $bits += "ucas" }
            if ($s.Utoc) { $bits += "utoc" }
            $tag = if ($s.HasIoStore) { "IOStore" } else { "classic" }
            Log ("  - {0}  [{1}]  ({2})" -f $s.BaseName, $tag, ($bits -join "+"))
        }

        # AES
        Set-Status "Extracting AES key...", 18
        $bytes = [IO.File]::ReadAllBytes($realExe)
        $hex = [BitConverter]::ToString($bytes).Replace("-", "")
        $AESKey = $null
        $m = [regex]::Match($hex, "0x[0-9A-F]{64}")
        if ($m.Success) { $AESKey = $m.Value }
        else {
            $m2 = [regex]::Match($hex, "[0-9A-F]{64}")
            if ($m2.Success) { $AESKey = "0x" + $m2.Value }
        }
        if (-not $AESKey) {
            [System.Windows.Forms.MessageBox]::Show("AES key not found in EXE.", "Error", "OK", "Error")
            return
        }
        Set-Content (Join-Path $PSScriptRoot "aes_key.txt") $AESKey -Force
        Log "AES key saved."

        # Backup
        Set-Status "Backing up...", 22
        $BackupDir = Join-Path $ModsDir ("_backup_{0:yyyyMMdd_HHmmss}" -f (Get-Date))
        New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
        foreach ($s in $modSets) {
            foreach ($f in $s.AllFiles) {
                $dest = Join-Path $BackupDir $f.Name
                if (Test-Path $dest) { $dest = Join-Path $BackupDir ("{0}__{1}" -f $f.Directory.Name, $f.Name) }
                Copy-Item $f.FullName $dest -Force
            }
        }
        Log "Backup: $BackupDir"

        if ($chkDryRun.Checked) {
            Log ""
            Log "DRY-RUN — planned actions:"
            foreach ($s in $modSets) {
                $plan = "SKIP"
                if ($s.HasIoStore -and $s.Utoc -and $hasRetoc) { $plan = "retoc to-legacy" }
                elseif ($s.Pak -and $hasRepak) { $plan = "repak unpack" }
                Log ("  {0}  →  {1}" -f $s.Name, $plan)
            }
            Set-Status "Dry-run done.", 100
            [System.Windows.Forms.MessageBox]::Show("Dry-run complete. See log.", "Dry-Run", "OK", "Information")
            return
        }

        $tempRoot = Join-Path $env:TEMP ("S2Merger_{0}" -f [Guid]::NewGuid().ToString("N").Substring(0, 8))
        New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
        $unpackedMods = @{}
        $failedMods = @()

        # Unpack each mod with best available tool
        Set-Status "Unpacking mods...", 30
        $i = 0
        foreach ($s in $modSets) {
            $i++
            $pct = 30 + [int](($i / [Math]::Max(1, $modSets.Count)) * 25)
            Set-Status "Processing $($s.Name) ($i/$($modSets.Count))...", $pct

            $work = Join-Path $tempRoot $s.BaseName
            New-Item -ItemType Directory -Path $work -Force | Out-Null
            $got = $null

            # Prefer retoc for IOStore
            if ($s.HasIoStore -and $s.Utoc -and $hasRetoc) {
                Log "Trying retoc: $($s.Name)"
                # Copy trio together so retoc can resolve companions
                $ioDir = Join-Path $work "_io"
                New-Item -ItemType Directory -Path $ioDir -Force | Out-Null
                if ($s.Pak)  { Copy-Item $s.Pak.FullName  $ioDir -Force }
                if ($s.Ucas) { Copy-Item $s.Ucas.FullName $ioDir -Force }
                if ($s.Utoc) { Copy-Item $s.Utoc.FullName $ioDir -Force }

                $legacyOut = Join-Path $work "legacy"
                $utocLocal = Join-Path $ioDir $s.Utoc.Name
                $got = Invoke-RetocToLegacy -retocPath $retoc -aesKey $AESKey -utocPath $utocLocal -outDir $legacyOut
                if ($got) { Log "  OK via retoc" }
                else { Log "  retoc failed, will try repak if .pak exists" }
            }

            # Fallback / classic path
            if (-not $got -and $s.Pak -and $hasRepak) {
                Log "Trying repak: $($s.Name)"
                $got = Invoke-RepakUnpack -repakPath $repak -pakPath $s.Pak.FullName -workDir (Join-Path $work "pak_out")
                if ($got) { Log "  OK via repak" }
            }

            if ($got) {
                $unpackedMods[$s.Name] = $got
            } else {
                Log "  SKIPPED (could not extract)"
                $failedMods += $s.Name
            }
        }

        if ($unpackedMods.Count -eq 0) {
            Remove-Item $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
            [System.Windows.Forms.MessageBox]::Show(
                "No mods could be unpacked.`nFailed: $($failedMods -join ', ')`n`nCheck tools and AES key.",
                "Nothing extracted", "OK", "Error")
            return
        }

        if ($failedMods.Count -gt 0) {
            Log "WARNING: skipped mods: $($failedMods -join ', ')"
        }

        # Conflict scan
        Set-Status "Scanning conflicts...", 60
        $fileMap = @{}
        foreach ($name in $unpackedMods.Keys) {
            $folder = $unpackedMods[$name]
            Get-ChildItem $folder -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
                $rel = $_.FullName.Substring($folder.Length).TrimStart('\')
                if (-not $fileMap.ContainsKey($rel)) {
                    $fileMap[$rel] = [System.Collections.Generic.List[string]]::new()
                }
                $fileMap[$rel].Add($name)
            }
        }
        $conflicts = @($fileMap.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 })

        if ($chkShowConflicts.Checked) {
            Log ""
            Log "========== CONFLICTS ($($conflicts.Count)) =========="
            foreach ($c in $conflicts) {
                Log "FILE: $($c.Key)"
                Log "  MODS: $($c.Value -join ', ')"
            }
        }
        if ($chkExportConflicts.Checked) {
            $report = @("Conflict Report $(Get-Date)", "====================", "")
            foreach ($c in $conflicts) {
                $report += "FILE: $($c.Key)"
                $report += "  MODS: $($c.Value -join ', ')"
                $report += ""
            }
            $report | Set-Content (Join-Path $PSScriptRoot "conflicts.txt") -Encoding UTF8
            Log "Exported conflicts.txt"
        }

        if ($conflicts.Count -eq 0) {
            Log "No overlapping files. No merge needed."
            Remove-Item $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
            Set-Status "No conflicts.", 100
            [System.Windows.Forms.MessageBox]::Show("No conflicts found.", "Done", "OK", "Information")
            return
        }

        # Build merged folder
        Set-Status "Building merged content...", 70
        $mergedFolder = Join-Path $tempRoot "MergedMod"
        New-Item -ItemType Directory -Path $mergedFolder -Force | Out-Null

        $conflictSet = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
        foreach ($c in $conflicts) { [void]$conflictSet.Add($c.Key) }

        foreach ($name in $unpackedMods.Keys) {
            $folder = $unpackedMods[$name]
            Get-ChildItem $folder -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
                $rel = $_.FullName.Substring($folder.Length).TrimStart('\')
                if (-not $conflictSet.Contains($rel)) {
                    $target = Join-Path $mergedFolder $rel
                    $td = Split-Path $target -Parent
                    if (-not (Test-Path $td)) { New-Item -ItemType Directory -Path $td -Force | Out-Null }
                    if (-not (Test-Path $target)) { Copy-Item $_.FullName $target -Force }
                }
            }
        }

        Set-Status "Merging conflicts...", 80
        foreach ($c in $conflicts) {
            $rel = $c.Key
            $mods = $c.Value
            $target = Join-Path $mergedFolder $rel
            $td = Split-Path $target -Parent
            if (-not (Test-Path $td)) { New-Item -ItemType Directory -Path $td -Force | Out-Null }

            if ([IO.Path]::GetExtension($rel) -eq ".cfg") {
                $lines = [System.Collections.Generic.List[string]]::new()
                foreach ($m in $mods) {
                    $src = Join-Path $unpackedMods[$m] $rel
                    if (Test-Path $src) {
                        $lines.AddRange([string[]](Get-Content $src -ErrorAction SilentlyContinue))
                    }
                }
                $lines | Set-Content $target -Encoding UTF8
                Log "Merged .cfg: $rel"
            } else {
                $last = $mods[-1]
                $src = Join-Path $unpackedMods[$last] $rel
                if (Test-Path $src) { Copy-Item $src $target -Force }
                Log "Non-cfg (last wins): $rel"
            }
        }

        # Pack — always try classic pak first (most reliable for config merges)
        Set-Status "Packing MergedMod.pak...", 90
        $produced = @()

        if ($hasRepak) {
            Push-Location $tempRoot
            try {
                $null = & $repak pack "MergedMod" 2>&1
            } catch {
                Log "repak pack warning: $($_.Exception.Message)"
            } finally { Pop-Location }

            $outPak = Join-Path $tempRoot "MergedMod.pak"
            if (-not (Test-Path $outPak)) { $outPak = Join-Path $tempRoot "MergedMod\MergedMod.pak" }
            if (Test-Path $outPak) {
                $dest = Join-Path $ModsDir "MergedMod.pak"
                Copy-Item $outPak $dest -Force
                $produced += $dest
                Log "Created: $dest"
            } else {
                Log "WARNING: repak did not produce MergedMod.pak"
            }
        }

        # Optional IOStore (best-effort, never fails the run)
        if ($chkTryIoStoreOut.Checked -and $hasRetoc) {
            Log "Trying optional IOStore output..."
            $versions = @("UE5_4", "UE5_3", "UE5_2", "UE5_1")
            $ioOk = $false
            foreach ($ver in $versions) {
                try {
                    $ioUtoc = Join-Path $tempRoot "MergedMod_P.utoc"
                    $null = & $retoc to-zen $mergedFolder $ioUtoc --version $ver 2>&1
                    $base = [IO.Path]::ChangeExtension($ioUtoc, $null)
                    foreach ($ext in @(".pak", ".ucas", ".utoc")) {
                        $f = $base + $ext
                        if (Test-Path $f) {
                            $dest = Join-Path $ModsDir ("MergedMod_P" + $ext)
                            Copy-Item $f $dest -Force
                            $produced += $dest
                            $ioOk = $true
                        }
                    }
                    if ($ioOk) {
                        Log "IOStore output OK with --version $ver"
                        break
                    }
                } catch {
                    Log "  version $ver failed"
                }
            }
            if (-not $ioOk) { Log "IOStore output skipped (classic .pak is still available if created)." }
        }

        Remove-Item $tempRoot -Recurse -Force -ErrorAction SilentlyContinue

        $disable = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
        foreach ($c in $conflicts) { foreach ($m in $c.Value) { [void]$disable.Add($m) } }

        Set-Status "Done!", 100
        Log ""
        Log "Finished."
        if ($produced.Count -eq 0) {
            Log "ERROR: No output files were produced."
            [System.Windows.Forms.MessageBox]::Show("Merge ran but no output package was created. See log.", "Warning", "OK", "Warning")
            return
        }

        foreach ($p in $produced) { Log "  $p" }

        $msg = "Merge complete.`nConflicts: $($conflicts.Count)`n`nOutput:`n$($produced -join "`n")"
        if ($chkAutoDisable.Checked -and $disable.Count -gt 0) {
            $list = ($disable | Sort-Object) -join "`n  - "
            $msg += "`n`nDisable these originals:`n  - $list"
        }
        if ($failedMods.Count -gt 0) {
            $msg += "`n`nSkipped (could not unpack):`n  - $($failedMods -join "`n  - ")"
        }

        [System.Windows.Forms.MessageBox]::Show($msg, "Success", "OK", "Information")
    }
    catch {
        Log "ERROR: $($_.Exception.Message)"
        Set-Status "Error.", 0
        [System.Windows.Forms.MessageBox]::Show("Error:`n$($_.Exception.Message)", "Error", "OK", "Error")
    }
})

[void]$form.ShowDialog()
