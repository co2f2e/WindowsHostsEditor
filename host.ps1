If (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    [System.Windows.Forms.MessageBox]::Show("请以管理员身份运行此脚本！", "权限不足", "OK", "Warning")
    Break
}

$hostsPath = "C:\Windows\System32\drivers\etc\hosts"

If ((Get-Item $hostsPath).IsReadOnly) {
    Set-ItemProperty -Path $hostsPath -Name IsReadOnly -Value $false
}

Add-Type -AssemblyName Microsoft.VisualBasic

$inputText = [Microsoft.VisualBasic.Interaction]::InputBox(
    "请输入要添加到 hosts 文件的内容：`n每行一个条目，例如：127.0.0.1 example.com", 
    "添加 hosts 条目"
)

If ([string]::IsNullOrWhiteSpace($inputText)) {
    Write-Output "未输入内容，退出脚本。"
    Break
}

$hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"

$hostsContent = Get-Content -Path $hostsPath

$linesToAdd = $inputText -split "`r?`n"

$addedLines = @()
foreach ($line in $linesToAdd) {
    $trimmedLine = $line.Trim()
    if (-not [string]::IsNullOrWhiteSpace($trimmedLine) -and $hostsContent -notcontains $trimmedLine) {
        Add-Content -Path $hostsPath -Value $trimmedLine
        $addedLines += $trimmedLine
    }
}

try {
    ipconfig /flushdns | Out-Null
    $dnsMessage = "DNS 缓存已刷新。"
} catch {
    $dnsMessage = "刷新 DNS 缓存失败，请手动执行 'ipconfig /flushdns'。"
}

If ($addedLines.Count -gt 0) {
    [System.Windows.Forms.MessageBox]::Show(
        "成功添加以下条目:`n" + ($addedLines -join "`n") + "`n`n$dnsMessage", 
        "操作成功", 
        "OK", 
        "Information"
    )
} Else {
    [System.Windows.Forms.MessageBox]::Show("输入的条目已全部存在，无需添加。`n$dnsMessage", "提示", "OK", "Information")
}
