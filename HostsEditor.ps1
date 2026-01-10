If (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show("请以管理员身份运行此脚本！", "权限不足", "OK", "Warning")
    Break
}

$hostsPath = "C:\Windows\System32\drivers\etc\hosts"

Add-Type -AssemblyName System.Windows.Forms

$form = New-Object System.Windows.Forms.Form
$form.Text = "Hosts 编辑器"
$form.Width = 700
$form.Height = 600
$form.StartPosition = "CenterScreen"

$textbox = New-Object System.Windows.Forms.TextBox
$textbox.Multiline = $true
$textbox.ScrollBars = "Vertical"
$textbox.WordWrap = $false
$textbox.Font = New-Object System.Drawing.Font("Consolas",10)
$textbox.Dock = "Fill"
$form.Controls.Add($textbox)

$textbox.Text = Get-Content $hostsPath | Out-String

$saveButton = New-Object System.Windows.Forms.Button
$saveButton.Text = "保存"
$saveButton.Width = 100
$saveButton.Height = 30
$saveButton.Top = 10
$saveButton.Left = 580
$form.Controls.Add($saveButton)

$saveButton.Add_Click({
    try {
        if ((Get-Item $hostsPath).IsReadOnly) {
            Set-ItemProperty -Path $hostsPath -Name IsReadOnly -Value $false
        }
        Set-Content -Path $hostsPath -Value $textbox.Text
        ipconfig /flushdns | Out-Null
        [System.Windows.Forms.MessageBox]::Show("保存成功，DNS 已刷新。","成功","OK","Information")
    } catch {
        [System.Windows.Forms.MessageBox]::Show("保存失败！请检查权限或文件是否被占用。","错误","OK","Error")
    }
})

$form.Add_FormClosing({
    if ($textbox.Modified) {
        $result = [System.Windows.Forms.MessageBox]::Show("内容已修改，是否保存？","提示","YesNoCancel","Question")
        if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
            try {
                if ((Get-Item $hostsPath).IsReadOnly) {
                    Set-ItemProperty -Path $hostsPath -Name IsReadOnly -Value $false
                }
                Set-Content -Path $hostsPath -Value $textbox.Text
                ipconfig /flushdns | Out-Null
            } catch {
                [System.Windows.Forms.MessageBox]::Show("保存失败！","错误","OK","Error")
            }
        } elseif ($result -eq [System.Windows.Forms.DialogResult]::Cancel) {
            $form.CloseReason = "None"
            $form.Cancel = $true
        }
    }
})

# 显示 GUI
$form.ShowDialog()
