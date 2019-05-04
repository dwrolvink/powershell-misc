# Powershell-Misc
This is where I put all my general purpose powershell scripts

### GUI & Jobs Demo
When creating a powershell GUI, it's quite tricky to have the GUI not freeze up while a called function is running.
To combat this, I've created a handler function that will run a powershell job and processes GUI events while the job is running.

[gui_and_jobs_demo.ps1](gui/gui_and_jobs_demo.ps1)

### Rewrite prompt and titlebar
When browsing long filepaths, the ISE prompt can get pretty longwinded and fill up the entire row.
This profile will rewrite the titlebar to show the user, whether you're elevated as that user, and the filepath.

[profile.ps1](profile.ps1)

### r_GetFolderSize($current_folder)
This function can be used to crawl a folder down to all the subfolders and get a total size of the folder
Especially useful for network shares that don't show the folder size in the properties.

### Restart Service On Multiple Computers
Takes ServiceName, Computer list, login credential
Script tries to log in to every computer in the computer list using the given Credential
It then tries to restart the service using Invoke-Command
