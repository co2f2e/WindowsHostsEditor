# host

```powershell
$Script = irm https://raw.githubusercontent.com/co2f2e/WindowsHostsEditor/main/HostsEditor.ps1
$ScriptBlock = [ScriptBlock]::Create($Script)
& $ScriptBlock
```
