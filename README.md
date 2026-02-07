# WindowsHostsEditor

* Run PowerShell as administrator
```powershell
$Script = irm https://raw.githubusercontent.com/Meokj/WindowsHostsEditor/main/HostsEditor.ps1
$ScriptBlock = [ScriptBlock]::Create($Script)
& $ScriptBlock
```

> [!TIP]
> If you are unable to execute the above command,  Temporarily bypass the execution policy (current window only)
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```
