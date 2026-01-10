# host

```powershell
$Script = irm https://raw.githubusercontent.com/co2f2e/host/main/HostsEditor.ps1
$ScriptBlock = [ScriptBlock]::Create($Script)
& $ScriptBlock
```
