# This function sets the log, and then calls r_CompareFolderTreesL2R recursively.
# L2R means that it takes the left folder, and checks if all the file and folders exist on the right side.
# In a future version, I'd like to make it check also if files exist on the right but not on the left,
# but for now that's too slow to do well in a recursive manner.
# 'FolderTree' is used to denote that we take the folder and all it's contents recursively

function CompareFolderTreesL2R()
{
    [CmdletBinding()]
    param (
            [string] $Left,
            [string] $Right
        )

    $logfile = 'C:\Users\adm-ad-rolvinkd01\Documents\output.txt'
    ("Started at: " + (Get-Date)) | Out-File -FilePath $logfile

    r_CompareFolderTreesL2R -Left $Left -Right $Right -LogFile $logfile

    ("Completed at: " + (Get-Date)) | Out-File -FilePath $logfile -Append

}

# This function takes the full list of items in a folder,
# Then, if the item is a subfolder, and it exists on the right,
# it will call itself on that subfolder
# It only logs folders that exist on both ends, and files/folders that don't exist on the right
function r_CompareFolderTreesL2R()
{
    [CmdletBinding()]
    param (
            [string] $Left,
            [string] $Right,
            [string] $LogFile
        )


    # Get list of all items in the given folder (files/folders)
    $l_Subitems = Get-ChildItem $Left
    
    # For each item (left)
    for ($i = 0; $i -lt $l_Subitems.count; $i++)
    {
        # Set subitem name
        $subitemName = $l_Subitems[$i].Name
            
        # Check if the item exists on the right end
        $success = Test-Path -Path (Join-Path $Right $subitemName)

        # if left side item does not exist on right side
        if(!$success)
        {
            # stdout / log
            Write-Host (Join-Path $Left $subitemName) " does not exist on right side" -ForegroundColor Red
            ("[!R] " + (Join-Path $Left $subitemName)) | Out-File -Append -FilePath $LogFile

        }
        # if left side item does exist on the right side
        else
        {
            # If item is a folder, log that it has been checked (to track script progression), and recurse
            if ($l_Subitems[$i].Attributes -eq 'Directory')
            {
                # log
                (Join-Path $Left $subitemName) | Out-File -Append -FilePath $LogFile

                # Recurse
                r_CompareFolderTreesL2R -Left (Join-Path $Left $subitemName) -Right (Join-Path $Right $subitemName) -LogFile $LogFile
            }
        }
    }


}

# Set folders
$Left  =   'C:\Users\adm-ad-rolvinkd01\Documents\test1'
$Right =   'C:\Users\adm-ad-rolvinkd01\Documents\test2'

# execute
CompareFolderTreesL2R -Left $left -Right $Right
