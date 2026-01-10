If (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show("请以管理员身份运行此脚本！", "权限不足", "OK", "Warning")
    Break
}

$hostsPath = "C:\Windows\System32\drivers\etc\hosts"

If ((Get-Item $hostsPath).IsReadOnly) {
    Set-ItemProperty -Path $hostsPath -Name IsReadOnly -Value $false
}

$hostsContent = Get-Content -Path $hostsPath

Add-Type -AssemblyName System.Windows.Forms
$form = New-Object System.Windows.Forms.Form
$form.Text = "添加 hosts 条目"
$form.Width = 500
$form.Height = 400
$form.StartPosition = "CenterScreen"

$textbox = New-Object System.Windows.Forms.TextBox
$textbox.Multiline = $true
$textbox.ScrollBars = "Vertical"
$textbox.WordWrap = $false
$textbox.Width = 460
$textbox.Height = 300
$textbox.Top = 10
$textbox.Left = 10
$form.Controls.Add($textbox)

$okButton = New-Object System.Windows.Forms.Button
$okButton.Text = "确定"
$okButton.Top = 320
$okButton.Left = 200
$okButton.Width = 80
$okButton.Add_Click({$form.DialogResult = [System.Windows.Forms.DialogResult]::OK})
$form.Controls.Add($okButton)

if ($form.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
    Write-Output "用户取消输入，退出脚本。"
    Break
}

$linesToAdd = $textbox.Text -split "`r?`n"

$addedLines = @()
foreach ($line in $linesToAdd) {
    $trimmedLine = $line.Trim()
    if (-not [string]::IsNullOrWhiteSpace($trimmedLine) -and $hostsContent -notcontains $trimmedLine) {
        Add-Content -Path $hostsPath -Value ($trimmedLine + "`n")  # 这里强制换行
        $addedLines += $trimmedLine
    }
}

try {
    ipconfig /flushdns | Out-Null
    $dnsMessage = "DNS 缓存已刷新。"
} catch {
    $dnsMessage = "刷新 DNS 缓存失败，请手动执行 'ipconfig /flushdns'。"
}

Add-Type -AssemblyName System.Windows.Forms
if ($addedLines.Count -gt 0) {
    [System.Windows.Forms.MessageBox]::Show(
        "成功添加以下条目:`n" + ($addedLines -join "`n") + "`n`n$dnsMessage",
        "操作成功",
        "OK",
        "Information"
    )
} else {
    [System.Windows.Forms.MessageBox]::Show(
        "输入的条目已全部存在，无需添加。`n$dnsMessage",
        "提示",
        "OK",
        "Information"
    )
}
