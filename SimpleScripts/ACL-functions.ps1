

<# Add-ACLFromSourceFolder

   This function takes the ACL from a source folder, and adds the ACE's to a target folder, such that the original ACE's of the 
   target folder are preserved.
#>

function Add-ACLFromSourceFolder
{
    param($TargetFolder, $SourceFolder)

    # Get ACL from source folder, which we want to merge with the ACL of the target folder
    $ACL_source = get-acl $SourceFolder 

    # Get target folder's ACL
    $Acl_target = Get-Acl $TargetFolder

    # Add each ACE in the source folder's ACL to the target folder's ACL
    foreach ($ACE in $ACL_source.Access)
    {
        $Acl_target.SetAccessRule($ACE)
    }

    # Set explicit rule
    #$rule = New-Object System.Security.AccessControl.FileSystemAccessRule(`
    #                $ADobject, "FullControl", "ContainerInherit, ObjectInherit", "None", "Allow")
    #$Acl_target.SetAccessRule($rule)

    Set-Acl $TargetFolder $Acl_target
}




<# 
   Enable-Inheritance
   
   This function sets inheritance to enable. This is a quick way to restore inheritance after a /mir with robocopy 
   (where the source acl is preserved, but the groups of the target parent folder are not automatically applied to the copied 
   files/folders.)
   The same could be achieved through the GUI, disabling and then reenabling inheritance, but such would take twice as long, 
   as first disabling will take its time to apply with big folders. (And first disabling is only necessary in the GUI, 
   enabling it like this updates the ACL just fine.) 
 #>
 
Function Enable-Inheritance
{
    param($Folder)

    $SourceACL = Get-ACL -Path $Folder
 
    #Enable inheritance
    $SourceACL.SetAccessRuleProtection($False,$True)
    Set-Acl -Path $Folder -AclObject $SourceACL
 
}

# MAIN CODE

$Folder = '\\usa-of-whatever\parent\update-this-folders-acl-inheritance'
Enable-Inheritance -Folder $Folder

$TargetFolder = 'C:\folder-to-be-updated'
$SourceFolder = 'C:\acl-template-folder'
Add-ACLFromSourceFolder -TargetFolder $TargetFolder  -SourceFolder $SourceFolder
