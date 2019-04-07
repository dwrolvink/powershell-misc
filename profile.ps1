# Put this in C:\users\<user>\Documents\WindowsPowershell\"
# It rewrites the prompt, and puts the current location in the titlebar

Function prompt {
    
    # Get information about bit version, elevated priviledge, and pwd
    # ---------------
    $size = '32 bit'
    If ([System.IntPtr]::Size -eq 8) {$size = '64 bit'}

    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $secprin = New-Object Security.Principal.WindowsPrincipal $currentUser

    $admin = 'Non-Administrator'
    If ($secprin.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)){
        $admin = 'Administrator'
    }

    # Rewrite title and prompt
    # ---------------
    $host.ui.RawUI.WindowTitle = "$admin | $size | $(Get-Location)"
    "PS> "
}
