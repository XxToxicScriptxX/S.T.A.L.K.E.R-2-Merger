#Requires -Version 5.1
##############################################
# STALKER 2 MOD MERGER
# Compatible with Windows PowerShell 5.1 and PowerShell 7+
# Features:
#  - STA enforcement
#  - PowerShell version log at startup
#  - Full crash logging (UI + unhandled)
#  - Interactive per-key CFG conflict resolver
#  - Manual "Resolve CFG Conflicts" button
#  - Priority-based merge + smart .cfg handling
##############################################

# Force STA apartment state (required for WinForms)
if ($Host.Runspace.ApartmentState -ne 'STA') {
    Write-Host "Re-launching in STA mode (required for the GUI)..." -ForegroundColor Yellow

    $scriptPath = $MyInvocation.MyCommand.Path
    if (-not $scriptPath) {
        Write-Error "Could not determine script path for re-launch."
        return
    }

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    if (Get-Command pwsh -ErrorAction SilentlyContinue) {
        $psi.FileName = "pwsh"
    } else {
        $psi.FileName = "powershell"
    }
    $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -STA -File `"$scriptPath`""
    $psi.UseShellExecute = $true
    [System.Diagnostics.Process]::Start($psi) | Out-Null
    return
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"

# script root
if (-not $PSScriptRoot) {
    $PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
}

# ============================================================
# PowerShell version log (for troubleshooting crashes)
# ============================================================
$versionLogFile = Join-Path $PSScriptRoot ("ps_version_{0:yyyyMMdd_HHmmss}.txt" -f (Get-Date))

$versionInfo = @"
STALKER 2 Mod Merger - PowerShell Environment Log
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
========================================

PSVersionTable:
$($PSVersionTable | Format-List | Out-String)

Additional Host Information:
- ApartmentState     : $($Host.Runspace.ApartmentState)
- Host Name          : $($Host.Name)
- Host Version       : $($Host.Version)
- UI Culture         : $($Host.CurrentUICulture)
- Culture            : $($Host.CurrentCulture)
- OS                 : $([System.Environment]::OSVersion.VersionString)
- Is 64-bit OS       : $([System.Environment]::Is64BitOperatingSystem)
- Is 64-bit Process  : $([System.Environment]::Is64BitProcess)
- PowerShell Edition : $($PSVersionTable.PSEdition)
- CLR Version        : $($PSVersionTable.CLRVersion)

Script Path          : $PSCommandPath
PSScriptRoot         : $PSScriptRoot
"@

$versionInfo | Out-File -FilePath $versionLogFile -Encoding UTF8
Write-Host "PowerShell version log written to: $versionLogFile" -ForegroundColor Cyan

# ============================================================
# Crash / Error logging
# ============================================================
$script:crashLogFile = Join-Path $PSScriptRoot ("crash_log_{0:yyyyMMdd_HHmmss}.txt" -f (Get-Date))

function Write-CrashLog {
    param(
        [Parameter(Mandatory = $true)]
        $ErrorRecordOrException,
        [string]$Source = "Unknown"
    )

    try {
        $sb = New-Object System.Text.StringBuilder
        [void]$sb.AppendLine("============================================================")
        [void]$sb.AppendLine("STALKER 2 Mod Merger - CRASH / ERROR LOG")
        [void]$sb.AppendLine("Time        : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
        [void]$sb.AppendLine("Source      : $Source")
        [void]$sb.AppendLine("PowerShell  : $($PSVersionTable.PSVersion) ($($PSVersionTable.PSEdition))")
        [void]$sb.AppendLine("OS          : $([System.Environment]::OSVersion.VersionString)")
        [void]$sb.AppendLine("============================================================")
        [void]$sb.AppendLine("")

        if ($ErrorRecordOrException -is [System.Management.Automation.ErrorRecord]) {
            $ex = $ErrorRecordOrException.Exception
            [void]$sb.AppendLine("ErrorRecord Message : $($ErrorRecordOrException.Exception.Message)")
            [void]$sb.AppendLine("CategoryInfo        : $($ErrorRecordOrException.CategoryInfo)")
            [void]$sb.AppendLine("FullyQualifiedErrorId: $($ErrorRecordOrException.FullyQualifiedErrorId)")
            [void]$sb.AppendLine("ScriptStackTrace    :")
            [void]$sb.AppendLine($ErrorRecordOrException.ScriptStackTrace)
            [void]$sb.AppendLine("")
            [void]$sb.AppendLine("InvocationInfo:")
            [void]$sb.AppendLine(($ErrorRecordOrException.InvocationInfo | Format-List | Out-String))
        }
        else {
            $ex = $ErrorRecordOrException
        }

        $depth = 0
        while ($null -ne $ex) {
            [void]$sb.AppendLine("----- Exception (depth $depth) -----")
            [void]$sb.AppendLine("Type    : $($ex.GetType().FullName)")
            [void]$sb.AppendLine("Message : $($ex.Message)")
            [void]$sb.AppendLine("Source  : $($ex.Source)")
            [void]$sb.AppendLine("StackTrace:")
            [void]$sb.AppendLine($ex.StackTrace)
            [void]$sb.AppendLine("")
            $ex = $ex.InnerException
            $depth++
        }

        [void]$sb.AppendLine("============================================================")
        [void]$sb.AppendLine("")

        $text = $sb.ToString()
        Add-Content -Path $script:crashLogFile -Value $text -Encoding UTF8 -ErrorAction SilentlyContinue

        if ($conflictBox -and -not $conflictBox.IsDisposed) {
            try {
                Log "CRASH logged to: $script:crashLogFile"
            } catch {}
        }

        try {
            [System.Windows.Forms.MessageBox]::Show(
                "A crash occurred.`n`nDetails written to:`n$script:crashLogFile`n`n$($ErrorRecordOrException.ToString())",
                "Crash Detected",
                "OK",
                "Error"
            )
        } catch {}
    }
    catch {
        try {
            "Failed to write crash log: $($_.Exception.Message)" |
                Out-File (Join-Path $PSScriptRoot "crash_log_fallback.txt") -Append -Encoding UTF8
        } catch {}
    }
}

[System.Windows.Forms.Application]::SetUnhandledExceptionMode(
    [System.Windows.Forms.UnhandledExceptionMode]::CatchException
)

[System.Windows.Forms.Application]::add_ThreadException({
    param($sender, $e)
    Write-CrashLog -ErrorRecordOrException $e.Exception -Source "Application.ThreadException"
})

[System.AppDomain]::CurrentDomain.add_UnhandledException({
    param($sender, $e)
    Write-CrashLog -ErrorRecordOrException $e.ExceptionObject -Source "AppDomain.UnhandledException"
})

# -------------------------------
# GUI
# -------------------------------

$form = New-Object System.Windows.Forms.Form
$form.Text = "STALKER 2 Mod Merger (PS 5.1 / 7+ compatible)"
$form.Size = New-Object System.Drawing.Size(980, 820)
$form.StartPosition = "CenterScreen"
$form.MinimumSize = New-Object System.Drawing.Size(900, 720)
$form.FormBorderStyle = "Sizable"
$form.Font = New-Object System.Drawing.Font("Segoe UI", 9)

# 1. EXE
$grpExe = New-Object System.Windows.Forms.GroupBox
$grpExe.Text = "1. Game Executable"
$grpExe.Location = New-Object System.Drawing.Point(12, 10)
$grpExe.Size = New-Object System.Drawing.Size(940, 78)
$grpExe.Anchor = "Top,Left,Right"

$labelGame = New-Object System.Windows.Forms.Label
$labelGame.Text = "Select Stalker2.exe or Stalker2-Win64-Shipping.exe:"
$labelGame.Location = New-Object System.Drawing.Point(12, 20)
$labelGame.AutoSize = $true

$textGame = New-Object System.Windows.Forms.TextBox
$textGame.Location = New-Object System.Drawing.Point(12, 42)
$textGame.Size = New-Object System.Drawing.Size(800, 23)
$textGame.Anchor = "Top,Left,Right"

$btnBrowse = New-Object System.Windows.Forms.Button
$btnBrowse.Text = "Browse..."
$btnBrowse.Location = New-Object System.Drawing.Point(820, 40)
$btnBrowse.Size = New-Object System.Drawing.Size(100, 27)
$btnBrowse.Anchor = "Top,Right"

$grpExe.Controls.AddRange(@($labelGame, $textGame, $btnBrowse))
$form.Controls.Add($grpExe)

# 2. Mods folder
$grpMods = New-Object System.Windows.Forms.GroupBox
$grpMods.Text = "2. Mods Folder (~mods)"
$grpMods.Location = New-Object System.Drawing.Point(12, 95)
$grpMods.Size = New-Object System.Drawing.Size(940, 78)
$grpMods.Anchor = "Top,Left,Right"

$labelMods = New-Object System.Windows.Forms.Label
$labelMods.Text = "Auto-detect or override. Finds .pak / .ucas / .utoc (including subfolders)."
$labelMods.Location = New-Object System.Drawing.Point(12, 20)
$labelMods.AutoSize = $true

$textMods = New-Object System.Windows.Forms.TextBox
$textMods.Location = New-Object System.Drawing.Point(12, 42)
$textMods.Size = New-Object System.Drawing.Size(700, 23)
$textMods.Anchor = "Top,Left,Right"

$btnBrowseMods = New-Object System.Windows.Forms.Button
$btnBrowseMods.Text = "Browse..."
$btnBrowseMods.Location = New-Object System.Drawing.Point(720, 40)
$btnBrowseMods.Size = New-Object System.Drawing.Size(100, 27)
$btnBrowseMods.Anchor = "Top,Right"

$btnAutoDetect = New-Object System.Windows.Forms.Button
$btnAutoDetect.Text = "Auto-Detect"
$btnAutoDetect.Location = New-Object System.Drawing.Point(830, 40)
$btnAutoDetect.Size = New-Object System.Drawing.Size(90, 27)
$btnAutoDetect.Anchor = "Top,Right"

$grpMods.Controls.AddRange(@($labelMods, $textMods, $btnBrowseMods, $btnAutoDetect))
$form.Controls.Add($grpMods)

# 3. Options
$grpOptions = New-Object System.Windows.Forms.GroupBox
$grpOptions.Text = "3. Options"
$grpOptions.Location = New-Object System.Drawing.Point(12, 180)
$grpOptions.Size = New-Object System.Drawing.Size(940, 70)
$grpOptions.Anchor = "Top,Left,Right"

$chkAutoDisable = New-Object System.Windows.Forms.CheckBox
$chkAutoDisable.Text = "Show mods to disable"
$chkAutoDisable.Location = New-Object System.Drawing.Point(15, 28)
$chkAutoDisable.AutoSize = $true
$chkAutoDisable.Checked = $true

$chkShowConflicts = New-Object System.Windows.Forms.CheckBox
$chkShowConflicts.Text = "Show conflict details"
$chkShowConflicts.Location = New-Object System.Drawing.Point(170, 28)
$chkShowConflicts.AutoSize = $true
$chkShowConflicts.Checked = $true

$chkDryRun = New-Object System.Windows.Forms.CheckBox
$chkDryRun.Text = "Dry-run only"
$chkDryRun.Location = New-Object System.Drawing.Point(340, 28)
$chkDryRun.AutoSize = $true

$chkExportConflicts = New-Object System.Windows.Forms.CheckBox
$chkExportConflicts.Text = "Export conflicts.txt"
$chkExportConflicts.Location = New-Object System.Drawing.Point(460, 28)
$chkExportConflicts.AutoSize = $true

$chkRecursive = New-Object System.Windows.Forms.CheckBox
$chkRecursive.Text = "Recursive search"
$chkRecursive.Location = New-Object System.Drawing.Point(620, 28)
$chkRecursive.AutoSize = $true
$chkRecursive.Checked = $true

$chkTryIoStoreOut = New-Object System.Windows.Forms.CheckBox
$chkTryIoStoreOut.Text = "Also try IOStore output"
$chkTryIoStoreOut.Location = New-Object System.Drawing.Point(760, 28)
$chkTryIoStoreOut.AutoSize = $true
$chkTryIoStoreOut.Checked = $false

$grpOptions.Controls.AddRange(@($chkAutoDisable, $chkShowConflicts, $chkDryRun, $chkExportConflicts, $chkRecursive, $chkTryIoStoreOut))
$form.Controls.Add($grpOptions)

# 4. Mod list
$grpModList = New-Object System.Windows.Forms.GroupBox
$grpModList.Text = "4. Mods to include (checked = include • higher in list = higher priority)"
$grpModList.Location = New-Object System.Drawing.Point(12, 260)
$grpModList.Size = New-Object System.Drawing.Size(940, 180)
$grpModList.Anchor = "Top,Left,Right"

$listMods = New-Object System.Windows.Forms.ListView
$listMods.Location = New-Object System.Drawing.Point(12, 22)
$listMods.Size = New-Object System.Drawing.Size(820, 145)
$listMods.View = "Details"
$listMods.FullRowSelect = $true
$listMods.CheckBoxes = $true
$listMods.GridLines = $true
$listMods.Anchor = "Top,Left,Right,Bottom"
[void]$listMods.Columns.Add("Mod", 380)
[void]$listMods.Columns.Add("Type", 90)
[void]$listMods.Columns.Add("Files", 80)
[void]$listMods.Columns.Add("Path", 250)

$btnUp = New-Object System.Windows.Forms.Button
$btnUp.Text = "▲ Up"
$btnUp.Location = New-Object System.Drawing.Point(845, 40)
$btnUp.Size = New-Object System.Drawing.Size(80, 28)
$btnUp.Anchor = "Top,Right"

$btnDown = New-Object System.Windows.Forms.Button
$btnDown.Text = "▼ Down"
$btnDown.Location = New-Object System.Drawing.Point(845, 75)
$btnDown.Size = New-Object System.Drawing.Size(80, 28)
$btnDown.Anchor = "Top,Right"

$btnSelectAll = New-Object System.Windows.Forms.Button
$btnSelectAll.Text = "Select All"
$btnSelectAll.Location = New-Object System.Drawing.Point(845, 120)
$btnSelectAll.Size = New-Object System.Drawing.Size(80, 28)
$btnSelectAll.Anchor = "Top,Right"

$grpModList.Controls.AddRange(@($listMods, $btnUp, $btnDown, $btnSelectAll))
$form.Controls.Add($grpModList)

# Buttons
$btnRun = New-Object System.Windows.Forms.Button
$btnRun.Text = "Run Merge"
$btnRun.Location = New-Object System.Drawing.Point(12, 450)
$btnRun.Size = New-Object System.Drawing.Size(120, 34)
$btnRun.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$btnRun.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
$btnRun.ForeColor = [System.Drawing.Color]::White
$btnRun.FlatStyle = "Flat"

$btnScan = New-Object System.Windows.Forms.Button
$btnScan.Text = "Scan Mods"
$btnScan.Location = New-Object System.Drawing.Point(140, 450)
$btnScan.Size = New-Object System.Drawing.Size(100, 34)

$btnResolve = New-Object System.Windows.Forms.Button
$btnResolve.Text = "Resolve CFG Conflicts"
$btnResolve.Location = New-Object System.Drawing.Point(250, 450)
$btnResolve.Size = New-Object System.Drawing.Size(160, 34)
$btnResolve.BackColor = [System.Drawing.Color]::FromArgb(40, 167, 69)
$btnResolve.ForeColor = [System.Drawing.Color]::White
$btnResolve.FlatStyle = "Flat"

$progressLabel = New-Object System.Windows.Forms.Label
$progressLabel.Text = "Status: Waiting...  (Scan → optionally Resolve CFG → Run Merge)"
$progressLabel.Location = New-Object System.Drawing.Point(420, 458)
$progressLabel.AutoSize = $true

$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(12, 495)
$progressBar.Size = New-Object System.Drawing.Size(940, 22)
$progressBar.Anchor = "Top,Left,Right"

$form.Controls.AddRange(@($btnRun, $btnScan, $btnResolve, $progressLabel, $progressBar))

$conflictBox = New-Object System.Windows.Forms.TextBox
$conflictBox.Location = New-Object System.Drawing.Point(12, 530)
$conflictBox.Size = New-Object System.Drawing.Size(940, 230)
$conflictBox.Multiline = $true
$conflictBox.ScrollBars = "Both"
$conflictBox.ReadOnly = $true
$conflictBox.Font = New-Object System.Drawing.Font("Consolas", 9)
$conflictBox.Anchor = "Top,Bottom,Left,Right"
$conflictBox.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$conflictBox.ForeColor = [System.Drawing.Color]::FromArgb(220, 220, 220)
$form.Controls.Add($conflictBox)

# -------------------------------
# Shared state
# -------------------------------
$script:allModSets = @()
$script:logFile = $null
$script:savedCfgChoices = $null

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
    $line = "$(Get-Date -Format 'HH:mm:ss')  $msg"
    $conflictBox.AppendText("$line`r`n")
    $conflictBox.SelectionStart = $conflictBox.Text.Length
    $conflictBox.ScrollToCaret()
    $form.Refresh()
    [System.Windows.Forms.Application]::DoEvents()
    if ($script:logFile) {
        Add-Content -Path $script:logFile -Value $line -ErrorAction SilentlyContinue
    }
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
    foreach ($c in $candidates) {
        if (Test-Path $c) { return (Resolve-Path $c).Path }
    }
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

function Invoke-RetocToLegacy {
    param([string]$retocPath, [string]$aesKey, [string]$utocPath, [string]$outDir)
    if (-not (Test-Path $utocPath)) { return $null }
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
    try {
        $null = & $retocPath --aes-key $aesKey to-legacy $utocPath $outDir 2>&1
        if (Test-HasContent $outDir) { return $outDir }
    } catch {}
    $parent = Split-Path $utocPath -Parent
    try {
        $null = & $retocPath --aes-key $aesKey to-legacy $parent $outDir 2>&1
        if (Test-HasContent $outDir) { return $outDir }
    } catch {}
    try {
        $null = & $retocPath --aes-key $aesKey unpack $utocPath -o $outDir 2>&1
        if (Test-HasContent $outDir) { return $outDir }
    } catch {}
    return $null
}

function Invoke-RepakUnpack {
    param([string]$repakPath, [string]$pakPath, [string]$workDir)
    if (-not (Test-Path $pakPath)) { return $null }
    New-Item -ItemType Directory -Path $workDir -Force | Out-Null
    $localPak = Join-Path $workDir (Split-Path $pakPath -Leaf)
    Copy-Item $pakPath $localPak -Force
    Push-Location $workDir
    try { $null = & $repakPath unpack "`"$localPak`"" 2>&1 } catch {}
    finally { Pop-Location }
    $dirs = Get-ChildItem $workDir -Directory -ErrorAction SilentlyContinue
    foreach ($d in $dirs) {
        if (Test-HasContent $d.FullName) { return $d.FullName }
    }
    if (Test-HasContent $workDir) { return $workDir }
    return $null
}

function Parse-CfgFile {
    param([string]$path)
    $result = @{}
    if (-not (Test-Path $path)) { return $result }
    $currentSection = ""
    $result[""] = @{}
    foreach ($raw in (Get-Content $path -ErrorAction SilentlyContinue)) {
        $line = $raw
        if ($line -match '^\s*\[([^\]]+)\]\s*(?:;.*)?$') {
            $currentSection = $Matches[1].Trim()
            if (-not $result.ContainsKey($currentSection)) { $result[$currentSection] = @{} }
            continue
        }
        if ($line -match '^\s*([^=;]+?)\s*=\s*(.*?)\s*(?:;.*)?$') {
            $key = $Matches[1].Trim()
            if ([string]::IsNullOrWhiteSpace($key)) { continue }
            if (-not $result.ContainsKey($currentSection)) { $result[$currentSection] = @{} }
            $result[$currentSection][$key] = $line.TrimEnd()
        }
    }
    return $result
}

function Move-ListItem {
    param([bool]$up)
    if ($listMods.SelectedItems.Count -ne 1) { return }
    $idx = $listMods.SelectedIndices[0]
    $newIdx = if ($up) { $idx - 1 } else { $idx + 1 }
    if ($newIdx -lt 0 -or $newIdx -ge $listMods.Items.Count) { return }
    $item = $listMods.Items[$idx]
    $listMods.Items.RemoveAt($idx)
    [void]$listMods.Items.Insert($newIdx, $item)
    $listMods.Items[$newIdx].Selected = $true
    $listMods.EnsureVisible($newIdx)
}

# -------------------------------------------------------
# INTERACTIVE CFG CONFLICT RESOLVER (popup)
# -------------------------------------------------------
function Show-CfgConflictResolver {
    param(
        [array]$CfgConflicts,
        [hashtable]$UnpackedMods
    )

    $finalChoices = @{}

    $resolver = New-Object System.Windows.Forms.Form
    $resolver.Text = "CFG Conflict Resolver – choose which value to keep per key"
    $resolver.Size = New-Object System.Drawing.Size(1100, 700)
    $resolver.StartPosition = "CenterParent"
    $resolver.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $resolver.TopMost = $true

    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = "Select a conflicting .cfg on the left. Then choose which mod's value to keep for each key. Click Done when finished."
    $lbl.Location = New-Object System.Drawing.Point(12, 10)
    $lbl.AutoSize = $true
    $resolver.Controls.Add($lbl)

    $listFiles = New-Object System.Windows.Forms.ListBox
    $listFiles.Location = New-Object System.Drawing.Point(12, 40)
    $listFiles.Size = New-Object System.Drawing.Size(280, 550)
    $listFiles.Anchor = "Top,Bottom,Left"
    $resolver.Controls.Add($listFiles)

    $grid = New-Object System.Windows.Forms.DataGridView
    $grid.Location = New-Object System.Drawing.Point(310, 40)
    $grid.Size = New-Object System.Drawing.Size(760, 550)
    $grid.Anchor = "Top,Bottom,Left,Right"
    $grid.AllowUserToAddRows = $false
    $grid.AllowUserToDeleteRows = $false
    $grid.RowHeadersVisible = $false
    $grid.SelectionMode = "FullRowSelect"
    $grid.AutoSizeColumnsMode = "Fill"
    $resolver.Controls.Add($grid)

    $btnDone = New-Object System.Windows.Forms.Button
    $btnDone.Text = "Done – Save Choices"
    $btnDone.Location = New-Object System.Drawing.Point(310, 610)
    $btnDone.Size = New-Object System.Drawing.Size(180, 35)
    $btnDone.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
    $btnDone.ForeColor = [System.Drawing.Color]::White
    $btnDone.FlatStyle = "Flat"
    $resolver.Controls.Add($btnDone)

    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Text = "Cancel"
    $btnCancel.Location = New-Object System.Drawing.Point(510, 610)
    $btnCancel.Size = New-Object System.Drawing.Size(120, 35)
    $resolver.Controls.Add($btnCancel)

    $script:resolverData = @{}
    $script:currentRel = $null
    $script:userChoices = @{}

    foreach ($c in $CfgConflicts) {
        $rel = $c.Key
        $mods = $c.Value
        $parsed = @{}
        foreach ($m in $mods) {
            $path = Join-Path $UnpackedMods[$m] $rel
            $parsed[$m] = Parse-CfgFile $path
        }
        $script:resolverData[$rel] = @{ Mods = $mods; Parsed = $parsed }
        [void]$listFiles.Items.Add($rel)
        $script:userChoices[$rel] = @{}
    }

    $listFiles.Add_SelectedIndexChanged({
        if ($listFiles.SelectedIndex -lt 0) { return }
        $rel = $listFiles.SelectedItem.ToString()
        $script:currentRel = $rel
        $info = $script:resolverData[$rel]
        $mods = $info.Mods
        $parsed = $info.Parsed

        $grid.Columns.Clear()
        $grid.Rows.Clear()

        $colKey = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
        $colKey.HeaderText = "Section.Key"
        $colKey.ReadOnly = $true
        $colKey.MinimumWidth = 200
        [void]$grid.Columns.Add($colKey)

        foreach ($m in $mods) {
            $col = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
            $col.HeaderText = $m
            $col.ReadOnly = $true
            [void]$grid.Columns.Add($col)
        }

        $colChoice = New-Object System.Windows.Forms.DataGridViewComboBoxColumn
        $colChoice.HeaderText = "Keep From"
        $colChoice.FlatStyle = "Flat"
        [void]$grid.Columns.Add($colChoice)

        $allKeys = New-Object System.Collections.Generic.List[string]
        foreach ($m in $mods) {
            foreach ($sec in $parsed[$m].Keys) {
                foreach ($key in $parsed[$m][$sec].Keys) {
                    $full = if ($sec) { "$sec|$key" } else { "|$key" }
                    if (-not $allKeys.Contains($full)) { $allKeys.Add($full) }
                }
            }
        }
        $allKeys = $allKeys | Sort-Object

        foreach ($full in $allKeys) {
            $parts = $full -split '\|', 2
            $sec = $parts[0]
            $key = $parts[1]
            $display = if ($sec) { "[$sec].$key" } else { $key }

            $row = New-Object System.Windows.Forms.DataGridViewRow
            $row.CreateCells($grid)
            $row.Cells[0].Value = $display

            $availableMods = New-Object System.Collections.Generic.List[string]
            for ($i = 0; $i -lt $mods.Count; $i++) {
                $m = $mods[$i]
                $val = ""
                if ($parsed[$m].ContainsKey($sec) -and $parsed[$m][$sec].ContainsKey($key)) {
                    $line = $parsed[$m][$sec][$key]
                    if ($line -match '=\s*(.*)$') { $val = $Matches[1].Trim() }
                    else { $val = $line }
                    $availableMods.Add($m)
                }
                $row.Cells[$i + 1].Value = $val
            }

            $combo = $row.Cells[$mods.Count + 1]
            $combo.Items.AddRange($availableMods.ToArray())
            if ($availableMods.Count -gt 0) {
                $combo.Value = $availableMods[$availableMods.Count - 1]
            }

            [void]$grid.Rows.Add($row)
        }
    })

    $btnDone.Add_Click({
        if ($script:currentRel) {
            $info = $script:resolverData[$script:currentRel]
            $mods = $info.Mods
            for ($r = 0; $r -lt $grid.Rows.Count; $r++) {
                $display = $grid.Rows[$r].Cells[0].Value
                $chosen = $grid.Rows[$r].Cells[$mods.Count + 1].Value
                if ($chosen) {
                    if ($display -match '^\[([^\]]+)\]\.(.+)$') {
                        $full = "$($Matches[1])|$($Matches[2])"
                    } else {
                        $full = "|$display"
                    }
                    $script:userChoices[$script:currentRel][$full] = $chosen
                }
            }
        }

        foreach ($rel in $script:resolverData.Keys) {
            $info = $script:resolverData[$rel]
            $mods = $info.Mods
            $parsed = $info.Parsed
            $choices = $script:userChoices[$rel]

            $baseMod = $mods[$mods.Count - 1]
            $basePath = Join-Path $UnpackedMods[$baseMod] $rel
            $baseLines = Get-Content $basePath -ErrorAction SilentlyContinue

            $output = New-Object System.Collections.Generic.List[string]
            $used = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
            $currentSec = ""

            foreach ($raw in $baseLines) {
                $line = $raw
                if ($line -match '^\s*\[([^\]]+)\]\s*(?:;.*)?$') {
                    $currentSec = $Matches[1].Trim()
                    $output.Add($line)
                    continue
                }
                if ($line -match '^\s*([^=;]+?)\s*=\s*(.*?)\s*(?:;.*)?$') {
                    $key = $Matches[1].Trim()
                    $full = if ($currentSec) { "$currentSec|$key" } else { "|$key" }
                    $chosenMod = if ($choices.ContainsKey($full)) { $choices[$full] } else { $baseMod }
                    if ($parsed[$chosenMod].ContainsKey($currentSec) -and $parsed[$chosenMod][$currentSec].ContainsKey($key)) {
                        $output.Add($parsed[$chosenMod][$currentSec][$key])
                        [void]$used.Add($full)
                    }
                    continue
                }
                $output.Add($line)
            }

            foreach ($full in $choices.Keys) {
                if ($used.Contains($full)) { continue }
                $chosenMod = $choices[$full]
                $parts = $full -split '\|', 2
                $sec = $parts[0]
                $key = $parts[1]
                if ($parsed[$chosenMod].ContainsKey($sec) -and $parsed[$chosenMod][$sec].ContainsKey($key)) {
                    if ($sec -and -not ($output | Where-Object { $_ -match "^\s*\[$([regex]::Escape($sec))\]" })) {
                        $output.Add("")
                        $output.Add("[$sec]")
                    }
                    $output.Add($parsed[$chosenMod][$sec][$key])
                }
            }

            $finalChoices[$rel] = $output
        }

        $resolver.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $resolver.Close()
    })

    $btnCancel.Add_Click({
        $resolver.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
        $resolver.Close()
    })

    if ($listFiles.Items.Count -gt 0) { $listFiles.SelectedIndex = 0 }

    $result = $resolver.ShowDialog($form)
    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        return $finalChoices
    }
    return $null
}

# -------------------------------
# BUTTON EVENTS
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

$btnUp.Add_Click({ Move-ListItem $true })
$btnDown.Add_Click({ Move-ListItem $false })
$btnSelectAll.Add_Click({ foreach ($item in $listMods.Items) { $item.Checked = $true } })

# SCAN
$btnScan.Add_Click({
    try {
        $conflictBox.Clear()
        $listMods.Items.Clear()
        $script:allModSets = @()
        $script:savedCfgChoices = $null

        $selectedExe = $textGame.Text.Trim()
        if (-not (Test-Path $selectedExe)) {
            [System.Windows.Forms.MessageBox]::Show("Select a valid game executable.", "Error", "OK", "Error")
            return
        }

        Set-Status "Locating EXE...", 5
        $realExe = Find-RealExe $selectedExe
        if (-not $realExe) {
            [System.Windows.Forms.MessageBox]::Show("Could not find Stalker2-Win64-Shipping.exe.", "Error", "OK", "Error")
            return
        }
        Log "Real EXE: $realExe"

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

        Set-Status "Scanning mods...", 20
        $script:allModSets = @(Get-AllModSets -modsDir $ModsDir -recursive $chkRecursive.Checked)

        if ($script:allModSets.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show("No .pak/.ucas/.utoc found.", "No mods", "OK", "Information")
            Set-Status "No mods found.", 0
            return
        }

        foreach ($s in $script:allModSets) {
            $tag = if ($s.HasIoStore) { "IOStore" } else { "classic" }
            $bits = @()
            if ($s.Pak)  { $bits += "pak" }
            if ($s.Ucas) { $bits += "ucas" }
            if ($s.Utoc) { $bits += "utoc" }
            $item = New-Object System.Windows.Forms.ListViewItem($s.Name)
            [void]$item.SubItems.Add($tag)
            [void]$item.SubItems.Add(($bits -join "+"))
            [void]$item.SubItems.Add($s.Directory)
            $item.Checked = $true
            $item.Tag = $s
            [void]$listMods.Items.Add($item)
        }

        Log "Found $($script:allModSets.Count) mod set(s). Check the ones you want and order them (top = highest priority)."
        Set-Status "Scan complete. You can now click 'Resolve CFG Conflicts' or 'Run Merge'.", 100
    }
    catch {
        Write-CrashLog -ErrorRecordOrException $_ -Source "btnScan.Click"
        Log "SCAN ERROR: $($_.Exception.Message)"
        Set-Status "Scan error.", 0
        [System.Windows.Forms.MessageBox]::Show("Scan error:`n$($_.Exception.Message)", "Error", "OK", "Error")
    }
})

# Resolve CFG Conflicts button
$btnResolve.Add_Click({
    if ($listMods.CheckedItems.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Scan mods first and check at least one.", "Nothing selected", "OK", "Warning")
        return
    }

    $btnResolve.Enabled = $false
    $btnRun.Enabled = $false
    $btnScan.Enabled = $false
    $conflictBox.Clear()
    $script:logFile = Join-Path $PSScriptRoot ("resolve_log_{0:yyyyMMdd_HHmmss}.txt" -f (Get-Date))

    try {
        $selectedOrdered = @()
        for ($i = 0; $i -lt $listMods.Items.Count; $i++) {
            $item = $listMods.Items[$i]
            if ($item.Checked) { $selectedOrdered += $item.Tag }
        }

        Set-Status "Preparing to resolve CFG conflicts...", 5
        Log "=== Manual CFG Conflict Resolver ==="

        $selectedExe = $textGame.Text.Trim()
        $realExe = Find-RealExe $selectedExe
        if (-not $realExe) { throw "Could not find shipping EXE." }

        $repak = Join-Path $PSScriptRoot "repak.exe"
        $retoc = Join-Path $PSScriptRoot "retoc.exe"
        $hasRepak = Test-Path $repak
        $hasRetoc = Test-Path $retoc
        if (-not $hasRepak -and -not $hasRetoc) { throw "Need repak.exe or retoc.exe." }

        Set-Status "Extracting AES key...", 10
        $bytes = [IO.File]::ReadAllBytes($realExe)
        $hex = [BitConverter]::ToString($bytes).Replace("-", "")
        $AESKey = $null
        $m = [regex]::Match($hex, "0x[0-9A-F]{64}")
        if ($m.Success) { $AESKey = $m.Value }
        else {
            $m2 = [regex]::Match($hex, "[0-9A-F]{64}")
            if ($m2.Success) { $AESKey = "0x" + $m2.Value }
        }
        if (-not $AESKey) { throw "AES key not found." }

        $tempRoot = Join-Path $env:TEMP ("S2Resolve_{0}" -f [Guid]::NewGuid().ToString("N").Substring(0, 8))
        New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
        $unpackedMods = @{}

        try {
            Set-Status "Unpacking selected mods...", 20
            $i = 0
            foreach ($s in $selectedOrdered) {
                $i++
                $pct = 20 + [int](($i / [Math]::Max(1, $selectedOrdered.Count)) * 40)
                Set-Status "Unpacking $($s.Name) ($i/$($selectedOrdered.Count))..." $pct

                $work = Join-Path $tempRoot $s.BaseName
                New-Item -ItemType Directory -Path $work -Force | Out-Null
                $got = $null

                if ($s.HasIoStore -and $s.Utoc -and $hasRetoc) {
                    $ioDir = Join-Path $work "_io"
                    New-Item -ItemType Directory -Path $ioDir -Force | Out-Null
                    if ($s.Pak)  { Copy-Item $s.Pak.FullName  $ioDir -Force }
                    if ($s.Ucas) { Copy-Item $s.Ucas.FullName $ioDir -Force }
                    if ($s.Utoc) { Copy-Item $s.Utoc.FullName $ioDir -Force }
                    $legacyOut = Join-Path $work "legacy"
                    $utocLocal = Join-Path $ioDir $s.Utoc.Name
                    $got = Invoke-RetocToLegacy -retocPath $retoc -aesKey $AESKey -utocPath $utocLocal -outDir $legacyOut
                }
                if (-not $got -and $s.Pak -and $hasRepak) {
                    $got = Invoke-RepakUnpack -repakPath $repak -pakPath $s.Pak.FullName -workDir (Join-Path $work "pak_out")
                }
                if ($got) { $unpackedMods[$s.Name] = $got }
            }

            if ($unpackedMods.Count -eq 0) { throw "Could not unpack any mods." }

            Set-Status "Scanning for CFG conflicts...", 70
            $fileMap = @{}
            foreach ($name in $unpackedMods.Keys) {
                $folder = $unpackedMods[$name]
                Get-ChildItem $folder -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
                    $rel = $_.FullName.Substring($folder.Length).TrimStart('\')
                    if (-not $fileMap.ContainsKey($rel)) {
                        $fileMap[$rel] = New-Object System.Collections.Generic.List[string]
                    }
                    $fileMap[$rel].Add($name)
                }
            }
            $cfgConflicts = @($fileMap.GetEnumerator() | Where-Object {
                $_.Value.Count -gt 1 -and [IO.Path]::GetExtension($_.Key) -eq ".cfg"
            })

            if ($cfgConflicts.Count -eq 0) {
                Log "No conflicting .cfg files found among the selected mods."
                [System.Windows.Forms.MessageBox]::Show("No conflicting .cfg files found.", "No CFG Conflicts", "OK", "Information")
                Set-Status "No CFG conflicts.", 100
                return
            }

            Log "Found $($cfgConflicts.Count) conflicting .cfg file(s). Opening resolver..."
            Set-Status "Opening CFG Conflict Resolver...", 90

            $choices = Show-CfgConflictResolver -CfgConflicts $cfgConflicts -UnpackedMods $unpackedMods

            if ($null -eq $choices) {
                Log "Resolver cancelled."
                Set-Status "Cancelled.", 0
                return
            }

            $script:savedCfgChoices = $choices
            Log "CFG choices saved. You can now click Run Merge – it will use these choices."
            Set-Status "CFG choices saved. Ready to Run Merge.", 100
            [System.Windows.Forms.MessageBox]::Show(
                "Choices saved successfully.`n`nYou can now click Run Merge and it will use the values you selected.",
                "CFG Resolver", "OK", "Information")
        }
        finally {
            if (Test-Path $tempRoot) {
                Remove-Item $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
    catch {
        Write-CrashLog -ErrorRecordOrException $_ -Source "btnResolve.Click"
        Log "ERROR: $($_.Exception.Message)"
        Set-Status "Error.", 0
        [System.Windows.Forms.MessageBox]::Show("Error:`n$($_.Exception.Message)", "Error", "OK", "Error")
    }
    finally {
        $btnResolve.Enabled = $true
        $btnRun.Enabled = $true
        $btnScan.Enabled = $true
    }
})

# RUN MERGE
$btnRun.Add_Click({
    if ($listMods.CheckedItems.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Scan mods first and check at least one.", "Nothing selected", "OK", "Warning")
        return
    }

    $btnRun.Enabled = $false
    $btnScan.Enabled = $false
    $btnResolve.Enabled = $false
    $conflictBox.Clear()
    $script:logFile = Join-Path $PSScriptRoot ("merge_log_{0:yyyyMMdd_HHmmss}.txt" -f (Get-Date))

    try {
        $selectedOrdered = @()
        for ($i = 0; $i -lt $listMods.Items.Count; $i++) {
            $item = $listMods.Items[$i]
            if ($item.Checked) { $selectedOrdered += $item.Tag }
        }

        Set-Status "Starting...", 0
        Log "=== Merge started ==="
        Log "PowerShell version: $($PSVersionTable.PSVersion)"

        $selectedExe = $textGame.Text.Trim()
        if (-not (Test-Path $selectedExe)) { throw "Select a valid game executable." }

        $repak = Join-Path $PSScriptRoot "repak.exe"
        $retoc = Join-Path $PSScriptRoot "retoc.exe"
        $hasRepak = Test-Path $repak
        $hasRetoc = Test-Path $retoc
        if (-not $hasRepak -and -not $hasRetoc) {
            throw "Need at least one of repak.exe or retoc.exe next to the script."
        }
        Log "Tools: repak=$(if($hasRepak){'YES'}else{'NO'})  retoc=$(if($hasRetoc){'YES'}else{'NO'})"

        Set-Status "Locating EXE...", 5
        $realExe = Find-RealExe $selectedExe
        if (-not $realExe) { throw "Could not find Stalker2-Win64-Shipping.exe." }
        Log "Real EXE: $realExe"

        $ModsDir = (Resolve-Path $textMods.Text).Path
        Log "Mods folder: $ModsDir"
        Log "Processing $($selectedOrdered.Count) selected mod(s) (top = highest priority):"
        foreach ($s in $selectedOrdered) { Log "  - $($s.Name)" }

        # AES
        Set-Status "Extracting AES key...", 15
        $bytes = [IO.File]::ReadAllBytes($realExe)
        $hex = [BitConverter]::ToString($bytes).Replace("-", "")
        $AESKey = $null
        $m = [regex]::Match($hex, "0x[0-9A-F]{64}")
        if ($m.Success) { $AESKey = $m.Value }
        else {
            $m2 = [regex]::Match($hex, "[0-9A-F]{64}")
            if ($m2.Success) { $AESKey = "0x" + $m2.Value }
        }
        if (-not $AESKey) { throw "AES key not found in EXE." }
        Set-Content (Join-Path $PSScriptRoot "aes_key.txt") $AESKey -Force
        Log "AES key saved."

        # Backup
        Set-Status "Backing up...", 22
        $BackupDir = Join-Path $ModsDir ("_backup_{0:yyyyMMdd_HHmmss}" -f (Get-Date))
        New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
        foreach ($s in $selectedOrdered) {
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
            foreach ($s in $selectedOrdered) {
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

        try {
            Set-Status "Unpacking mods...", 30
            $i = 0
            foreach ($s in $selectedOrdered) {
                $i++
                $pct = 30 + [int](($i / [Math]::Max(1, $selectedOrdered.Count)) * 25)
                Set-Status "Processing $($s.Name) ($i/$($selectedOrdered.Count))..." $pct

                $work = Join-Path $tempRoot $s.BaseName
                New-Item -ItemType Directory -Path $work -Force | Out-Null
                $got = $null

                if ($s.HasIoStore -and $s.Utoc -and $hasRetoc) {
                    Log "Trying retoc: $($s.Name)"
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

                if (-not $got -and $s.Pak -and $hasRepak) {
                    Log "Trying repak: $($s.Name)"
                    $got = Invoke-RepakUnpack -repakPath $repak -pakPath $s.Pak.FullName -workDir (Join-Path $work "pak_out")
                    if ($got) { Log "  OK via repak" }
                }

                if ($got) { $unpackedMods[$s.Name] = $got }
                else {
                    Log "  SKIPPED (could not extract)"
                    $failedMods += $s.Name
                }
            }

            if ($unpackedMods.Count -eq 0) {
                throw "No mods could be unpacked.`nFailed: $($failedMods -join ', ')"
            }
            if ($failedMods.Count -gt 0) {
                Log "WARNING: skipped mods: $($failedMods -join ', ')"
            }

            Set-Status "Scanning conflicts...", 60
            $fileMap = @{}
            foreach ($name in $unpackedMods.Keys) {
                $folder = $unpackedMods[$name]
                Get-ChildItem $folder -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
                    $rel = $_.FullName.Substring($folder.Length).TrimStart('\')
                    if (-not $fileMap.ContainsKey($rel)) {
                        $fileMap[$rel] = New-Object System.Collections.Generic.List[string]
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
                    Log "  MODS (low→high priority): $($c.Value -join ' → ')"
                }
            }
            if ($chkExportConflicts.Checked) {
                $report = @("Conflict Report $(Get-Date)", "====================", "")
                foreach ($c in $conflicts) {
                    $report += "FILE: $($c.Key)"
                    $report += "  MODS: $($c.Value -join ' → ')"
                    $report += ""
                }
                $report | Set-Content (Join-Path $PSScriptRoot "conflicts.txt") -Encoding UTF8
                Log "Exported conflicts.txt"
            }

            if ($conflicts.Count -eq 0) {
                Log "No overlapping files. No merge needed."
                Set-Status "No conflicts.", 100
                [System.Windows.Forms.MessageBox]::Show("No conflicts found.", "Done", "OK", "Information")
                return
            }

            $cfgConflicts = @($conflicts | Where-Object { [IO.Path]::GetExtension($_.Key) -eq ".cfg" })
            $otherConflicts = @($conflicts | Where-Object { [IO.Path]::GetExtension($_.Key) -ne ".cfg" })

            $cfgChoices = $script:savedCfgChoices
            if ($cfgConflicts.Count -gt 0 -and $null -eq $cfgChoices) {
                Log "Opening interactive CFG Conflict Resolver..."
                $cfgChoices = Show-CfgConflictResolver -CfgConflicts $cfgConflicts -UnpackedMods $unpackedMods
                if ($null -eq $cfgChoices) {
                    Log "User cancelled the conflict resolver."
                    Set-Status "Cancelled.", 0
                    return
                }
            } elseif ($cfgChoices) {
                Log "Using previously saved CFG choices from the Resolve button."
            }

            Set-Status "Building merged content...", 70
            $mergedFolder = Join-Path $tempRoot "MergedMod"
            New-Item -ItemType Directory -Path $mergedFolder -Force | Out-Null

            $conflictSet = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
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

            Set-Status "Applying CFG choices...", 80
            if ($cfgChoices) {
                foreach ($rel in $cfgChoices.Keys) {
                    $target = Join-Path $mergedFolder $rel
                    $td = Split-Path $target -Parent
                    if (-not (Test-Path $td)) { New-Item -ItemType Directory -Path $td -Force | Out-Null }
                    $cfgChoices[$rel] | Set-Content $target -Encoding UTF8
                    Log "Wrote user-resolved .cfg: $rel"
                }
            }

            foreach ($c in $otherConflicts) {
                $rel = $c.Key
                $mods = $c.Value
                $winner = $mods[$mods.Count - 1]
                $src = Join-Path $unpackedMods[$winner] $rel
                $target = Join-Path $mergedFolder $rel
                $td = Split-Path $target -Parent
                if (-not (Test-Path $td)) { New-Item -ItemType Directory -Path $td -Force | Out-Null }
                if (Test-Path $src) { Copy-Item $src $target -Force }
                Log "Non-cfg (highest priority = $winner): $rel"
            }

            Set-Status "Packing MergedMod.pak...", 90
            $produced = @()

            if ($hasRepak) {
                Push-Location $tempRoot
                try { $null = & $repak pack "MergedMod" 2>&1 }
                catch { Log "repak pack warning: $($_.Exception.Message)" }
                finally { Pop-Location }

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
                    } catch { Log "  version $ver failed" }
                }
                if (-not $ioOk) { Log "IOStore output skipped." }
            }

            $disable = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
            foreach ($c in $conflicts) { foreach ($m in $c.Value) { [void]$disable.Add($m) } }

            Set-Status "Done!", 100
            Log ""
            Log "Finished. Log file: $script:logFile"

            if ($produced.Count -eq 0) {
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
                $msg += "`n`nSkipped:`n  - $($failedMods -join "`n  - ")"
            }

            [System.Windows.Forms.MessageBox]::Show($msg, "Success", "OK", "Information")
        }
        finally {
            if (Test-Path $tempRoot) {
                Remove-Item $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
    catch {
        Write-CrashLog -ErrorRecordOrException $_ -Source "btnRun.Click"
        Log "ERROR: $($_.Exception.Message)"
        Set-Status "Error.", 0
        [System.Windows.Forms.MessageBox]::Show("Error:`n$($_.Exception.Message)", "Error", "OK", "Error")
    }
    finally {
        $btnRun.Enabled = $true
        $btnScan.Enabled = $true
        $btnResolve.Enabled = $true
    }
})

# -------------------------------
# Start the form Main for all you Devs =)
# -------------------------------
try {
    [void]$form.ShowDialog()
}
catch {
    Write-CrashLog -ErrorRecordOrException $_ -Source "Main ShowDialog"
    throw
}
