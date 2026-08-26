##############################################
# STALKER 2 MOD MERGER - AUTO-DETECT EXE VERSION
# Supports Steam / GOG / Epic installs
##############################################

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"

# -------------------------------
# GUI SETUP
# -------------------------------

$form = New-Object System.Windows.Forms.Form
$form.Text = "STALKER 2 Auto-Detect Mod Merger"
$form.Size = New-Object System.Drawing.Size(720, 580)
$form.StartPosition = "CenterScreen"

$labelGame = New-Object System.Windows.Forms.Label
$labelGame.Text = "Select ANY Stalker2.exe or Stalker2-Win64-Shipping.exe"
$labelGame.AutoSize = $true
$labelGame.Location = New-Object System.Drawing.Point(10, 10)

$textGame = New-Object System.Windows.Forms.TextBox
$textGame.Location = New-Object System.Drawing.Point(10, 35)
$textGame.Size = New-Object System.Drawing.Size(550, 20)

$btnBrowse = New-Object System.Windows.Forms.Button
$btnBrowse.Text = "Browse..."
$btnBrowse.Location = New-Object System.Drawing.Point(570, 33)
$btnBrowse.Size = New-Object System.Drawing.Size(120, 24)

$btnRun = New-Object System.Windows.Forms.Button
$btnRun.Text = "Run Merge"
$btnRun.Location = New-Object System.Drawing.Point(10, 70)
$btnRun.Size = New-Object System.Drawing.Size(120, 30)

# -------------------------------
# TOGGLES
# -------------------------------

$chkAutoDisable = New-Object System.Windows.Forms.CheckBox
$chkAutoDisable.Text = "Auto-disable mods (Vortex list)"
$chkAutoDisable.Location = New-Object System.Drawing.Point(150, 75)
$chkAutoDisable.AutoSize = $true

$chkShowConflicts = New-Object System.Windows.Forms.CheckBox
$chkShowConflicts.Text = "Show conflict details"
$chkShowConflicts.Location = New-Object System.Drawing.Point(350, 75)
$chkShowConflicts.AutoSize = $true

$chkDryRun = New-Object System.Windows.Forms.CheckBox
$chkDryRun.Text = "Dry-Run (scan only, no merge)"
$chkDryRun.Location = New-Object System.Drawing.Point(150, 95)
$chkDryRun.AutoSize = $true

$chkExportConflicts = New-Object System.Windows.Forms.CheckBox
$chkExportConflicts.Text = "Export conflicts to conflicts.txt"
$chkExportConflicts.Location = New-Object System.Drawing.Point(350, 95)
$chkExportConflicts.AutoSize = $true

$form.Controls.Add($chkAutoDisable)
$form.Controls.Add($chkShowConflicts)
$form.Controls.Add($chkDryRun)
$form.Controls.Add($chkExportConflicts)

# -------------------------------
# STATUS + LOG WINDOW
# -------------------------------

$progressLabel = New-Object System.Windows.Forms.Label
$progressLabel.Text = "Status: Waiting..."
$progressLabel.AutoSize = $true
$progressLabel.Location = New-Object System.Drawing.Point(10, 130)

$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(10, 150)
$progressBar.Size = New-Object System.Drawing.Size(680, 20)
$progressBar.Minimum = 0
$progressBar.Maximum = 100
$progressBar.Value = 0

$conflictBox = New-Object System.Windows.Forms.TextBox
$conflictBox.Location = New-Object System.Drawing.Point(10, 180)
$conflictBox.Size = New-Object System.Drawing.Size(680, 350)
$conflictBox.Multiline = $true
$conflictBox.ScrollBars = "Vertical"
$conflictBox.ReadOnly = $true

$form.Controls.Add($labelGame)
$form.Controls.Add($textGame)
$form.Controls.Add($btnBrowse)
$form.Controls.Add($btnRun)
$form.Controls.Add($progressLabel)
$form.Controls.Add($progressBar)
$form.Controls.Add($conflictBox)

# -------------------------------
# INSTALL SOURCE DROPDOWN
# -------------------------------

$labelSource = New-Object System.Windows.Forms.Label
$labelSource.Text = "Install Source:"
$labelSource.Location = New-Object System.Drawing.Point(10, 540)
$labelSource.AutoSize = $true

$comboSource = New-Object System.Windows.Forms.ComboBox
$comboSource.Location = New-Object System.Drawing.Point(100, 535)
$comboSource.Size = New-Object System.Drawing.Size(200, 20)
$comboSource.DropDownStyle = "DropDownList"
$comboSource.Items.Add("Steam")
$comboSource.Items.Add("GOG")
$comboSource.Items.Add("Epic")
$comboSource.SelectedIndex = 0

$form.Controls.Add($labelSource)
$form.Controls.Add($comboSource)

# -------------------------------
# HELPER FUNCTIONS
# -------------------------------

function Set-Status {
    param([string]$msg, [int]$progress = -1)
    $progressLabel.Text = "Status: $msg"
    if ($progress -ge 0 -and $progress -le 100) {
        $progressBar.Value = $progress
    }
    $form.Refresh()
}

function Log {
    param([string]$msg)
    $conflictBox.AppendText($msg + [Environment]::NewLine)
    $form.Refresh()
}

function Categorize-Conflict {
    param([string]$relPath)
    $lower = $relPath.ToLower()

    if ($lower -match "npc|mutant|health|hp") { return "NPC / Mutant HP" }
    elseif ($lower -match "loot|drop|inventory") { return "Loot / Drops" }
    elseif ($lower -match "shop|vendor|price|economy") { return "Economy / Shop Prices" }
    elseif ($lower -match "weapon|gun|ammo|ballistic") { return "Weapons / Ballistics" }
    elseif ($lower -match "hud|ui|interface") { return "HUD / UI" }
    else { return "Other Gameplay / Misc" }
}

function AutoDetect-RealExe {
    param([string]$selectedExe)
    $folder = Split-Path $selectedExe

    $try1 = Join-Path $folder "Stalker2\Binaries\Win64\Stalker2-Win64-Shipping.exe"
    if (Test-Path $try1) { return $try1 }

    $try2 = Join-Path $folder "Binaries\Win64\Stalker2-Win64-Shipping.exe"
    if (Test-Path $try2) { return $try2 }

    if ($selectedExe.ToLower().Contains("win64")) { return $selectedExe }

    return $null
}

# -------------------------------
# BROWSE BUTTON
# -------------------------------

$btnBrowse.Add_Click({
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Filter = "STALKER 2 Executable|Stalker2.exe;Stalker2-Win64-Shipping.exe"
    $dialog.Title = "Select ANY STALKER 2 executable"

    if ($dialog.ShowDialog() -eq "OK") {
        $textGame.Text = $dialog.FileName
    }
})

# -------------------------------
# RUN BUTTON
# -------------------------------

$btnRun.Add_Click({
    try {
        $selectedExe = $textGame.Text

        if (!(Test-Path $selectedExe)) {
            [System.Windows.Forms.MessageBox]::Show("Invalid EXE selected.","Error","OK","Error")
            return
        }

        Set-Status "Auto-detecting real game executable...", 5

        $realExe = AutoDetect-RealExe $selectedExe

        if ($realExe -eq $null) {
            [System.Windows.Forms.MessageBox]::Show("Could not auto-detect REAL EXE.","Error","OK","Error")
            return
        }

        Log "Real EXE detected:"
        Log "  $realExe"

        $Win64    = Split-Path $realExe
        $Binaries = Split-Path $Win64
        $Stalker2 = Split-Path $Binaries
        $GameRoot = Split-Path $Stalker2

        $PakDir  = Join-Path $Stalker2 "Content\Paks"

        # INSTALL SOURCE AUTO-LOCATOR
        switch ($comboSource.SelectedItem) {
            "Steam" {
                $ModsDir = "C:\Program Files (x86)\Steam\steamapps\common\S.T.A.L.K.E.R. 2 Heart of Chornobyl\Stalker2\Content\Paks\~mods"
            }
            "GOG" {
                $ModsDir = "C:\GOG Games\STALKER 2 Heart of Chornobyl\Stalker2\Content\Paks\~mods"
            }
            "Epic" {
                $ModsDir = "C:\Program Files\Epic Games\STALKER2\Stalker2\Content\Paks\~mods"
            }
        }

        if (!(Test-Path $ModsDir)) {
            Log "Install source path not found. Falling back to auto-detected path."
            $ModsDir = Join-Path $PakDir "~mods"
        }

        Log "Mods folder: $ModsDir"

        if (!(Test-Path $ModsDir)) {
            [System.Windows.Forms.MessageBox]::Show("~mods folder not found.","Error","OK","Error")
            return
        }

        # AUTO-BACKUP SYSTEM
        $BackupDir = Join-Path $ModsDir "_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        New-Item -ItemType Directory -Path $BackupDir | Out-Null

        Log "Backup folder created: $BackupDir"

        Get-ChildItem $ModsDir -Filter "*.pak" | ForEach-Object {
            Copy-Item $_.FullName $BackupDir -Force
        }

        Log "All mods backed up before merge."

        # AES extraction
        Set-Status "Extracting AES key...", 10

        $bytes = [System.IO.File]::ReadAllBytes($realExe)
        $hex   = [BitConverter]::ToString($bytes).Replace("-", "")

        $regex1 = [regex]"0x[0-9A-F]{64}"
        $match1 = $regex1.Match($hex)

        $regex2 = [regex]"[0-9A-F]{64}"
        $match2 = $regex2.Match($hex)

        if ($match1.Success) {
            $AESKey = $match1.Value
        }
        elseif ($match2.Success) {
            $AESKey = "0x" + $match2.Value
        }
        else {
            [System.Windows.Forms.MessageBox]::Show("AES key not found.","Error","OK","Error")
            return
        }

        Set-Content -Path ".\aes_key.txt" -Value $AESKey
        Log "AES key extracted."

        # Unpack base game
        Set-Status "Unpacking base game...", 20
        $basePak = Join-Path $PakDir "pakchunk0-Windows.pak"
        $baseOut = Join-Path $PakDir "pakchunk0-Windows"

        if (!(Test-Path $baseOut)) {
            & ".\repak.exe" --aes-key $AESKey unpack "`"$basePak`""
            Log "Base game unpacked."
        } else {
            Log "Base game already unpacked."
        }

        # Unpack mods
        Set-Status "Unpacking mods...", 35
        $pakFiles     = Get-ChildItem $ModsDir -Filter "*.pak"
        $unpackedMods = @{}


        foreach ($pak in $pakFiles) {
            Log "Unpacking mod: $($pak.Name)"
            & ".\repak.exe" unpack "`"$pak.FullName`""

            $folder = $pak.FullName.Substring(0, $pak.FullName.Length - 4)

            if (Test-Path $folder) {
                try {
                    Move-Item $folder $ModsDir -Force
                    $unpackedMods[$pak.Name] = $folder
                }
                catch {
                    Log "Warning: Could not move unpacked folder for $($pak.Name). Skipping."
                }
            }
            else {
                Log "Warning: Mod folder missing after unpack: $($pak.Name). Skipping."
            }
        }

        # Detect conflicts
        Set-Status "Scanning for conflicts...", 50
        $fileMap = @{}


        foreach ($modName in $unpackedMods.Keys) {
            $modFolder = $unpackedMods[$modName]
            $files = Get-ChildItem $modFolder -Recurse -File

            foreach ($f in $files) {
                $rel = $f.FullName.Substring($modFolder.Length + 1)
                if (-not $fileMap.ContainsKey($rel)) {
                    $fileMap[$rel] = @()
                }
                $fileMap[$rel] += $modName
            }
        }

        $conflicts = $fileMap.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 }

        # DRY-RUN MODE
        if ($chkDryRun.Checked) {
            Log ""
            Log "DRY-RUN MODE ENABLED — NO MERGE WILL BE PERFORMED"
            Log ""

            foreach ($c in $conflicts) {
                $relPath = $c.Key
                $mods    = $c.Value
                Log ("FILE: " + $relPath)
                Log ("  MODS: " + ($mods -join ', '))
                Log ""
            }

            if ($chkExportConflicts.Checked) {
                $report = @()
                $report += "Conflict Report"
                $report += "==============="
                foreach ($c in $conflicts) {
                    $relPath = $c.Key
                    $mods    = $c.Value
                    $report += "FILE: $relPath"
                    $report += "  MODS: " + ($mods -join ', ')
                    $report += ""
                }
                $report | Set-Content "conflicts.txt"
                Log "Conflict report exported to conflicts.txt"
            }

            [System.Windows.Forms.MessageBox]::Show(
                "Dry-run complete. No merge performed.",
                "Dry-Run",
                "OK",
                "Information"
            )

            return
        }

        if ($conflicts.Count -eq 0) {
            Set-Status "No conflicts found.", 100
            Log "Your mods do not overlap. No merge needed."
            return
        }

        if ($chkShowConflicts.Checked) {
            Log ""
            Log "Conflicting files and the mods involved:"
            foreach ($c in $conflicts) {
                $relPath = $c.Key
                $mods    = $c.Value
                Log ("FILE: " + $relPath)
                Log ("  MODS: " + ($mods -join ', '))
                Log ""
            }
        }

        if ($chkExportConflicts.Checked) {
            $report = @()
            $report += "Conflict Report"
            $report += "==============="
            foreach ($c in $conflicts) {
                $relPath = $c.Key
                $mods    = $c.Value
                $report += "FILE: $relPath"
                $report += "  MODS: " + ($mods -join ', ')
                $report += ""
            }
            $report | Set-Content "conflicts.txt"
            Log "Conflict report exported to conflicts.txt"
        }

                # Create merged folder
        Set-Status "Creating merged mod folder...", 60
        $mergedFolder = Join-Path $ModsDir "MergedMod"
        if (Test-Path $mergedFolder) {
            Remove-Item $mergedFolder -Recurse -Force
        }
        New-Item -ItemType Directory -Path $mergedFolder | Out-Null

        # Copy safe files
        Set-Status "Copying safe files...", 70
        foreach ($modName in $unpackedMods.Keys) {
            $modFolder = $unpackedMods[$modName]
            $files = Get-ChildItem $modFolder -Recurse -File

            foreach ($f in $files) {
                $rel = $f.FullName.Substring($modFolder.Length + 1)

                if (-not $conflicts.Name -contains $rel) {
                    $target = Join-Path $mergedFolder $rel
                    $targetDir = Split-Path $target
                    if (-not (Test-Path $targetDir)) {
                        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
                    }
                    if (-not (Test-Path $target)) {
                        Copy-Item $f.FullName $target -Force
                    }
                }
            }
        }

        # Merge .cfg conflicts
        Set-Status "Merging .cfg conflicts...", 80
        foreach ($c in $conflicts) {
            $relPath = $c.Key
            $mods    = $c.Value

            if ([System.IO.Path]::GetExtension($relPath) -ne ".cfg") {
                Log "Skipping non-.cfg: $relPath"
                continue
            }

            $baseFile     = Join-Path $baseOut $relPath
            $mergedTarget = Join-Path $mergedFolder $relPath
            $mergedDir    = Split-Path $mergedTarget

            if (-not (Test-Path $mergedDir)) {
                New-Item -ItemType Directory -Path $mergedDir -Force | Out-Null
            }

            $content = @()

            if (Test-Path $baseFile) {
                $content += Get-Content $baseFile
            }

            foreach ($modName in $mods) {
                $modFolder = $unpackedMods[$modName]
                $modFile   = Join-Path $modFolder $relPath
                if (Test-Path $modFile) {
                    $content += Get-Content $modFile
                }
            }

            $content | Set-Content $mergedTarget
            Log "Merged: $relPath"
        }

        # AUTO-DELETE UNPACKED FOLDERS
        Set-Status "Cleaning up unpacked folders...", 85

        foreach ($modName in $unpackedMods.Keys) {
            $modFolder = $unpackedMods[$modName]
            if (Test-Path $modFolder) {
                try {
                    Remove-Item $modFolder -Recurse -Force
                    Log "Deleted unpacked folder: $modFolder"
                }
                catch {
                    Log "Warning: Could not delete unpacked folder: $modFolder"
                }
            }
        }

        if (Test-Path $baseOut) {
            try {
                Remove-Item $baseOut -Recurse -Force
                Log "Deleted base unpack folder: $baseOut"
            }
            catch {
                Log "Warning: Could not delete base unpack folder: $baseOut"
            }
        }

        # Pack merged mod
        Set-Status "Packing merged mod...", 90
        & ".\repak.exe" pack "`"$mergedFolder`""

        Set-Status "Done!", 100
        Log ""
        Log "MergedMod.pak created successfully."
        Log "Place MergedMod.pak in your ~mods folder."

        # Auto-disable mods list
        $modDisableSet = New-Object System.Collections.Generic.HashSet[string]
        foreach ($c in $conflicts) {
            foreach ($m in $c.Value) {
                [void]$modDisableSet.Add($m)
            }
        }

        if ($chkAutoDisable.Checked) {
            Log ""
            Log "Disable these mods in Vortex (they were merged):"
            foreach ($m in $modDisableSet) {
                Log ("  - " + $m)
            }

            $disableList = ($modDisableSet | Sort-Object) -join "`n  - "

            [System.Windows.Forms.MessageBox]::Show(
                "MergedMod.pak created successfully.`n`nPlace it in ~mods, then disable these mods in Vortex:`n`n  - $disableList",
                "Success",
                "OK",
                "Information"
            )
        }
        else {
            [System.Windows.Forms.MessageBox]::Show(
                "MergedMod.pak created successfully.`n`nCheck the log window for details.",
                "Success",
                "OK",
                "Information"
            )
        }
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Error: $($_.Exception.Message)","Error","OK","Error")
        Set-Status "Error.", 0
    }
})

# -------------------------------
# RUN FORM
# -------------------------------

[void]$form.ShowDialog()
