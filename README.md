# Powershell-Misc
This is where I put all my general purpose powershell scripts/tutorials

## Tutorials
### Introduction to Powershell modules
How to best organize powershell code? In this tutorial I describe the problems with organizing code, how to solve it without modules, and finally how to do it better with modules.

[Introduction to Powershell Modules](Tutorials/IntroductionToModules.md)

## Scripts

### GUI & Jobs Demo
When creating a powershell GUI, it's quite tricky to have the GUI not freeze up while a called function is running.
To combat this, I've created a handler function that will run a powershell job and processes GUI events while the job is running.

[gui_and_jobs_demo.ps1](gui/gui_and_jobs_demo.ps1)

### Rewrite prompt and titlebar
When browsing long filepaths, the ISE prompt can get pretty longwinded and fill up the entire row.
This profile will rewrite the titlebar to show the user, whether you're elevated as that user, and the filepath.

[SimpleScripts/profile.ps1](profile.ps1)

### Apply ACL From Source folder To Destination folder
With this script, you can define the proper access control list on a template folder, and apply it to any destination folder, while preserving whatever extra ACE's there might be on that destination folder. 

(ACL-functions.ps1)[SimpleScripts/ACL-functions.ps1)

### r_GetFolderSize($current_folder)
This function can be used to crawl a folder down to all the subfolders and get a total size of the folder
Especially useful for network shares that don't show the folder size in the properties.

### Restart Service On Multiple Computers
Takes ServiceName, Computer list, login credential
Script tries to log in to every computer in the computer list using the given Credential
It then tries to restart the service using Invoke-Command
