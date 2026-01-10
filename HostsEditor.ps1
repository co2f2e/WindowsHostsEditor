If (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show("Please run this script as Administrator!", "Insufficient Privileges", "OK", "Warning")
    Break
}

$hostsPath = "C:\Windows\System32\drivers\etc\hosts"

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = "Hosts Editor"
$form.Width = 800
$form.Height = 600
$form.StartPosition = "CenterScreen"

$rtb = New-Object System.Windows.Forms.RichTextBox
$rtb.Multiline = $true
$rtb.ScrollBars = "Vertical"
$rtb.WordWrap = $false
$rtb.Font = New-Object System.Drawing.Font("Consolas",10)
$rtb.Dock = "Fill"
$form.Controls.Add($rtb)

$saveButton = New-Object System.Windows.Forms.Button
$saveButton.Text = "Save"
$saveButton.Width = 100
$saveButton.Height = 30
$saveButton.Top = 10
$saveButton.Left = 680
$form.Controls.Add($saveButton)

function Load-Hosts {
    $rtb.Clear()
    $lines = Get-Content $hostsPath
    while ($lines.Count -gt 0 -and [string]::IsNullOrWhiteSpace($lines[-1])) {
        $lines = $lines[0..($lines.Count-2)]
    }
    foreach ($line in $lines) {
        $rtb.AppendText($line + "`r`n")
    }
    $rtb.SelectionStart = $rtb.TextLength
    $rtb.SelectionLength = 0
    $rtb.ScrollToCaret()
    $rtb.Modified = $false
}

Load-Hosts

function Save-Hosts {
    try {
        if ((Get-Item $hostsPath).IsReadOnly) {
            Set-ItemProperty -Path $hostsPath -Name IsReadOnly -Value $false
        }
        $rtb.Lines | Out-File -FilePath $hostsPath -Encoding ASCII
        ipconfig /flushdns | Out-Null
        Set-ItemProperty -Path $hostsPath -Name IsReadOnly -Value $true
        $rtb.Modified = $false
        [System.Windows.Forms.MessageBox]::Show("Saved successfully. DNS cache flushed and hosts file set to read-only.", "Success", "OK", "Information")
        Load-Hosts
        return $true
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Save failed! Please check permissions or if the file is in use.", "Error", "OK", "Error")
        return $false
    }
}

$saveButton.Add_Click({ Save-Hosts })

$form.Add_FormClosing({
    param($sender, $e)

    $allLinesEmptyOrWhitespace = $true
    foreach ($line in $rtb.Lines) {
        if (-not [string]::IsNullOrWhiteSpace($line)) {
            $allLinesEmptyOrWhitespace = $false
            break
        }
    }

    $modifiedToCheck = if ($allLinesEmptyOrWhitespace) { $false } else { $rtb.Modified }

    if ($modifiedToCheck) {
        $result = [System.Windows.Forms.MessageBox]::Show("Content has been modified. Do you want to save?", "Prompt", "YesNoCancel", "Question")
        if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
            $success = Save-Hosts
            if (-not $success) { $e.Cancel = $true }
        } elseif ($result -eq [System.Windows.Forms.DialogResult]::Cancel) {
            $e.Cancel = $true
        }
    } else {
        if (-not (Get-Item $hostsPath).IsReadOnly) {
            Set-ItemProperty -Path $hostsPath -Name IsReadOnly -Value $true
        }
    }
})

$null = $form.ShowDialog()
Exit
