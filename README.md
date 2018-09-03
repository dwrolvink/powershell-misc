# Powershell-Misc
This is where I put all my general purpose powershell scripts

### r_GetFolderSize($current_folder)
This function can be used to crawl a folder down to all the subfolders and get a total size of the folder
Especially useful for network shares that don't show the folder size in the properties.

### Restart Service On Multiple Computers
Takes ServiceName, Computer list, login credential
Script tries to log in to every computer in the computer list using the given Credential
It then tries to restart the service using Invoke-Command
