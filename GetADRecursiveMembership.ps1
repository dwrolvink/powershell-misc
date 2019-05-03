# This script creates a GUI with which you can recursively search either membership (all groups a user belongs to via nesting),
# or members (all users that are a member of a group, either directly or indirectly).

# Super bulky, if anyone has a more... elegant solution, let me know.

#################################################################################################
# 
#                                           CONFIG
#
#################################################################################################

# Defaults
$DefaultUser     = 'myusername'
$DefaultGroup    = 'testgroup'

$DefaultMaxDepth = 2

# Don't load members of large groups, like:
$Blacklist = @()

# Colors
# -----------------------------------------------------------------
$OutPut_BackgroundColor       = 'Navy'
$Heading_ForeGroundColor      = 'Yellow'
$SubHeading_ForeGroundColor   = 'Dodgerblue'
$Text_ForegroundColor         = 'White' 
$null_ForegroundColor         = 'dimgray'
$Form_BackgroundColor         = 'White' 
$Notification_ForegroundColor = $null_ForegroundColor 

# Fonts
# -----------------------------------------------------------------
$Output_Font = "Microsoft Sans Serif,9"



#################################################################################################
# 
#                                           FUNCTIONS
#
#################################################################################################
# Init 
# -----------------------------------------------------------------
$script:terminate = $false

Add-Type -assembly System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

# Install RSAT-AD feature so we can use the AD cmdlets
# -----------------------------------------------------------------
Import-Module ServerManager
If (! (Get-WindowsFeature RSAT-AD-Powershell)){
    Write-host "Installing RSAT-AD-Powershell... (one time only)" -ForegroundColor cyan
    Add-WindowsFeature RSAT-AD-Powershell | Out-Null
    Write-Host "Done." -ForegroundColor cyan
}


# Write output to form
# -----------------------------------------------------------------
Function say(){
    param($Line, $Color=$Text_ForegroundColor)

    $Output.SelectionColor = $Color
    $Output.AppendText("   "*$Tab + $Line + "`r`n")
    #write-host $Line
}

Function ExitStatement(){
    [System.Windows.Forms.Application]::DoEvents() 
    return $script:terminate
}

# Get group members when searching on groupname
# -----------------------------------------------------------------
Function r_GetGroupMembers(){
    param($Tab, $GroupName)

    $form.Focus()

    # Exit statement
    if(ExitStatement){return "exit"}

    # Write Name of group
    If ($Tab -eq 0){
        say $GroupName -Color $Heading_ForeGroundColor 
    } Else {
        say $GroupName -Color $SubHeading_ForeGroundColor
    }
    $Tab++

    # Get children
    $Children = Get-ADGroupMember -Identity $GroupName
    $Groups   = $Children | ?{$_.objectClass -eq 'group'}
    $Users    = $Children | ?{$_.objectClass -eq 'user'}

    # Print users
    If ($Users.Count -eq 0){
        say "<empty>" -Color $null_ForegroundColor
    }
    Else {
        Foreach($user in $Users){
            say $user.name
        }
    }

    # Recurse child groups
    Foreach($group in $Groups)
    {
        r_GetGroupMembers -Tab $Tab -GroupName $group.name
    }
}

# Get all groups a user is member of (directly, and indirectly)
# -----------------------------------------------------------------
Function r_GetGroups(){
    param($Tab, $UserName, $GroupName, [int]$Depth=0, [int]$MaxDepth=1)

    # Exit statement
    if(ExitStatement){return "exit"}

    # Get direct group membership of user
    # -----------------------------------------------------------------
    If ($UserName)
    {
        # Write Name of User
        say $UserName -Color $Heading_ForeGroundColor 
        $Tab++

        # Get children
        $Groups = Get-ADPrincipalGroupMembership -Identity $UserName

        # Recurse child groups
        Foreach($group in $Groups)
        {
            $result = r_GetGroups -Tab $Tab -GroupName $group.name -Depth ($Depth+1) -MaxDepth $MaxDepth 
            If ($result -eq "exit"){
                return "exit"
            }
        }  
    }
    # Recurse through groups
    # -----------------------------------------------------------------
    Else
    {
        # Write name of group
        If ($Tab -eq 1){
            say ($GroupName)
        }
        Else {
            say ($GroupName) -Color $SubHeading_ForeGroundColor
        }
        $Tab++

        # Don't load members of certain huge groups
        If ($GroupName -in $Blacklist)
        {
            say "<skipped reading members>" -Color $null_ForegroundColor
            return;
        }

        # Get group members
        #write-host $GroupName
        try{
            $Groups = Get-ADPrincipalGroupMembership -Identity $GroupName
        }
        catch {
            $Groups = @()
        }

        If(($Depth+1) -gt $MaxDepth){
            say "<max depth reached>" -Color $Notification_ForegroundColor
            return 2
        }

        # Recurse through group members that are groups themselves
        Foreach($group in $Groups)
        {
            $result = r_GetGroups -Tab $Tab -GroupName $group.name -Depth ($Depth+1) -MaxDepth $MaxDepth
            If ($result -eq "exit"){
                return "exit"
            }
        }
    }

    # Exit normally
    # -----------------------------------------------------------------
    return "normal";
}



#################################################################################################
# 
#                                          FORM FUNCTIONS
#
#################################################################################################

# submit groupmember search
# -----------------------------------------------------------------
$handler_groupboxSubmit_OnClick = {

    # UI react to click
    # -------------------
    $groupbox_submit.Text = "Loading..."
    $Output.Text = ""
    $Output.AppendText("`r`n")

    # Check if group exists
    # -------------------
    Try {
        $group = Get-ADGroup -Identity $text_Groupname.Text
    } Catch{
        $Output.Text = ""; say "Groep `"$($text_Groupname.Text)`" niet gevonden" -Color $Notification_ForegroundColor  
        $groupbox_submit.Text = "Zoek"
        say "<done>" -Color $Notification_ForegroundColor  
        return;
    }
    $result = r_GetGroupMembers -GroupName $text_Groupname.Text -Tab $Tab
    
    # Exit handling
    # -------------------
    If ($result -eq "exit")
    {
        say "<operation aborted prematurely>" -Color $Notification_ForegroundColor
    }
    Elseif ($result -eq "normal")
    {
        say "<done>"                          -Color $Notification_ForegroundColor
    }
    $this.Text = "Zoek"
    $script:terminate = $False
}

# submit groupmembership search
# -----------------------------------------------------------------
$handler_userboxSubmit_OnClick = {

    # UI react to click
    # -------------------
    $this.Text = "Loading..." 
    $Output.Text = ""
    $Output.AppendText("`r`n")

    # Check if user exists
    # -------------------
    try {
        $user = Get-ADUser -Identity $text_Username.Text
    } Catch{
        $Output.Text = ""; say "Gebruiker `"$($text_Username.Text)`" niet gevonden" -Color $Notification_ForegroundColor 
        $submit_Username.Text = "Zoek"
        say "<done>" -Color $Notification_ForegroundColor
        return;
    }
    # Find groups
    # -------------------
    $result = r_GetGroups -UserName $text_Username.Text -Tab $Tab -MaxDepth $text_Depth.Text

    # Exit handling
    # -------------------
    If ($result -eq "exit")
    {
        say "<operation aborted prematurely>" -Color $Notification_ForegroundColor
    }
    Elseif ($result -eq "normal")
    {
        say "<done>" -Color $Notification_ForegroundColor
    }
    $this.Text = "Zoek"
    $script:terminate = $False
    
}

# Cancel operation
# -----------------------------------------------------------------
$handler_cancel = {
     $script:terminate = $true; # $this.Parent.Parent.Close(); 
}

#################################################################################################
# 
#                                              FORM
#
#################################################################################################
# Init
# -----------------------------------------------------------------
$Tab = 0                        # used for indentation

# Create form
# -----------------------------------------------------------------
$Form               = New-Object  System.Windows.Forms.Form
$Form.Size          = New-Object  System.Drawing.Size(570,540)
$Form.Text          = "Find all AD members/membership"
$Form.StartPosition = "CenterScreen"
$Form.BackColor     = $Form_BackgroundColor

# Find AD users in group
# -----------------------------------------------------------------
# Groupbox
$GroupBox          = New-Object System.Windows.Forms.GroupBox #create the group box
$GroupBox.Location = New-Object System.Drawing.Size(32,10) #location of the group box (px) in relation to the primary window's edges (length, height)
$GroupBox.size     = New-Object System.Drawing.Size(245,100) #the size in px of the group box (length, height)
$GroupBox.text      = "Vind groupmembers:" #labeling the box

# Input
# -----------------------------
# Groupname
$label_Groupname           = New-Object  System.Windows.Forms.Label
$label_Groupname.Text      = "Groep"
$label_Groupname.Top       = 15
$label_Groupname.Left      = 10
$label_Groupname.Width     = 240
$label_Groupname.Height    = 20
$label_Groupname.TextAlign = "BottomLeft"

$text_Groupname           = New-Object  System.Windows.Forms.TextBox
$text_Groupname.Top       = 40
$text_Groupname.Left      = 10
$text_Groupname.Width     = 230
$text_Groupname.Height    = 20
$text_Groupname.Padding   = 10
$text_Groupname.Text      = $DefaultGroup 

$GroupBox.Controls.Add($label_Groupname)
$GroupBox.Controls.Add($text_Groupname)
$text_Groupname.add_doubleclick({   $this.SelectAll() })

# Submit
$groupbox_submit           = New-Object  System.Windows.Forms.Button
$groupbox_submit.Text      = "Zoek"
$groupbox_submit.Top       = 65
$groupbox_submit.Left      = 10
$groupbox_submit.Width     = 60
$groupbox_submit.Height    = 20
$groupbox_submit.Padding   = 1
$groupbox_submit.TextAlign = "MiddleCenter"

$GroupBox.Controls.Add($groupbox_submit)
$groupbox_submit.Add_Click($handler_groupboxSubmit_OnClick)

# Cancel
$groupbox_cancel           = New-Object  System.Windows.Forms.Button
$groupbox_cancel.Text      = "Cancel"
$groupbox_cancel.Top       = 65
$groupbox_cancel.Left      = 70
$groupbox_cancel.Width     = 60
$groupbox_cancel.Height    = 20
$groupbox_cancel.Padding   = 1
$groupbox_cancel.TextAlign = "MiddleCenter"

$GroupBox.Controls.Add($groupbox_cancel)
$groupbox_cancel.add_click($handler_cancel)

$Form.Controls.Add($GroupBox)


# Find AD groups based on user
# -----------------------------------------------------------------
# Userbox
$UserBox          = New-Object System.Windows.Forms.GroupBox #create the group box
$UserBox.Location = New-Object System.Drawing.Size(285,10) #location of the group box (px) in relation to the primary window's edges (length, height)
$UserBox.size     = New-Object System.Drawing.Size(245,100) #the size in px of the group box (length, height)
$UserBox.text      = "Vind groep membership:" #labeling the box

# Input
# -----------------------------
# Username
$label_Username = New-Object  System.Windows.Forms.Label
$label_Username.Text      = "Gebruiker"
$label_Username.Top       = 15
$label_Username.Left      = 10
$label_Username.Width     = 200
$label_Username.Height    = 20
$label_Username.TextAlign = "BottomLeft"

$text_Username = New-Object  System.Windows.Forms.TextBox
$text_Username.Top       = 40
$text_Username.Left      = 12
$text_Username.Width     = 200
$text_Username.Height    = 20
$text_Username.Padding   = 10
$text_Username.Text      = $DefaultUser 

# Submit
$submit_Username = New-Object  System.Windows.Forms.Button
$submit_Username.Text      = "Zoek"
$submit_Username.Top       = 65
$submit_Username.Left      = 10
$submit_Username.Width     = 60
$submit_Username.Height    = 20
$submit_Username.Padding   = 1
$submit_Username.TextAlign = "MiddleCenter"

# Cancel
$Userbox_cancel = New-Object  System.Windows.Forms.Button
$Userbox_cancel.Text      = "Cancel"
$Userbox_cancel.Top       = 65
$Userbox_cancel.Left      = 70
$Userbox_cancel.Width     = 60
$Userbox_cancel.Height    = 20
$Userbox_cancel.Padding   = 1
$Userbox_cancel.TextAlign = "MiddleCenter"


# Programmability
# -----------------------------
$text_Username.add_doubleclick({ $this.SelectAll()             })
$submit_Username.Add_Click(      $handler_userboxSubmit_OnClick)
$Userbox_cancel.add_click(       $handler_cancel               )

# Add to group
# -----------------------------
$UserBox.Controls.Add($label_Username)
$UserBox.Controls.Add($text_Username)
$UserBox.Controls.Add($submit_Username)
$UserBox.Controls.Add($Userbox_cancel)
$Form.Controls.Add($UserBox)

# Output screen
# -----------------------------------------------------------------
$Output                 = New-Object System.Windows.Forms.RichTextBox 
$Output.Width           = 500
$Output.Height          = 300
$Output.Left            = 15
$Output.SelectionIndent = 5
$Output.BackColor       = $OutPut_BackgroundColor
$Output.Multiline       = $true
$Output.location        = new-object system.drawing.point(32,125)
$Output.Font            = $Output_Font

$Form.controls.Add($Output)

# Controls
# -----------------------------------------------------------------
# Controlbox
$ControlBox          = New-Object System.Windows.Forms.GroupBox
$ControlBox.Location = New-Object System.Drawing.Size(32,435)
$ControlBox.size     = New-Object System.Drawing.Size(508,60) 
$ControlBox.text      = "Controls" 

# MAxdepth
$label_Depth = New-Object  System.Windows.Forms.Label
$label_Depth.Text      = "MaxDepth"
$label_Depth.Top       = 15
$label_Depth.Left      = 10
$label_Depth.Width     = 60
$label_Depth.Height    = 14
$label_Depth.TextAlign = "BottomLeft"

$text_Depth = New-Object  System.Windows.Forms.TextBox
$text_Depth.Top       = 30
$text_Depth.Left      = 12
$text_Depth.Width     = 20
$text_Depth.Height    = 20
$text_Depth.Padding   = 10
$text_Depth.Text      = $DefaultMaxDepth 

# Add & Programmabilty
$text_Depth.add_doubleclick({   $this.SelectAll() })

$ControlBox.Controls.Add($label_Depth)
$ControlBox.Controls.Add($text_Depth)
$Form.Controls.Add($ControlBox)

# Show form
# -----------------------------------------------------------------
$Form.Add_Shown({$Form.Activate()})
$Form.ShowDialog()
