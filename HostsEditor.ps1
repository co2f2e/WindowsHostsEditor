If (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show("请以管理员身份运行此脚本！", "权限不足", "OK", "Warning")
    Break
}

$hostsPath = "C:\Windows\System32\drivers\etc\hosts"

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = "Hosts 编辑器"
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
$saveButton.Text = "保存"
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
        [System.Windows.Forms.MessageBox]::Show("保存成功，DNS 已刷新，hosts 文件已设置为只读。","成功","OK","Information")
        Load-Hosts
        return $true
    } catch {
        [System.Windows.Forms.MessageBox]::Show("保存失败！请检查权限或文件是否被占用。","错误","OK","Error")
        return $false
    }
}

$saveButton.Add_Click({ Save-Hosts })

$form.Add_FormClosing({
    param($sender, $e)

    $allLinesEmpty = $true
    foreach ($line in $rtb.Lines) {
        if (-not [string]::IsNullOrWhiteSpace($line)) {
            $allLinesEmpty = $false
            break
        }
    }
    
    if ($rtb.Modified) {
        $result = [System.Windows.Forms.MessageBox]::Show("内容已修改，是否保存？","提示","YesNoCancel","Question")
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
