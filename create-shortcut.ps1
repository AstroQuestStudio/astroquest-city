$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut('C:\Users\trufa\Desktop\AstroQuest City.lnk')
$Shortcut.TargetPath = 'C:\Users\trufa\Documents\AstroQuest City\start-prod.bat'
$Shortcut.WorkingDirectory = 'C:\Users\trufa\Documents\AstroQuest City'
$Shortcut.IconLocation = 'C:\Users\trufa\Documents\AstroQuest City\apps\city\src-tauri\icons\icon.ico'
$Shortcut.Description = 'Lance AstroQuest City (release avec opencode local)'
$Shortcut.Save()
Write-Host "Raccourci Bureau cree : C:\Users\trufa\Desktop\AstroQuest City.lnk"