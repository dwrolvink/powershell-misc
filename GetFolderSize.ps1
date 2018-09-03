
# r_GETFOLDERSIZE
#
# This function can be used to crawl a folder down to all the subfolders and get a total size of the folder
# Especially useful for network shares that don't show the folder size in the properties.
#
# Takes the current folder
# Finds subfolders, and calls itself on the subfolders to get the sum of the size of all it's subfolders
# then it calculates the sum of the file size in the current folder, and adds both sums together to reach the total size.
# Returns total size current folder

function r_GetFolderSize($folderURL)
{
    $total_size = 0
    $subfolder_size_sum = 0
    $file_size_sum = 0

    # Get list of all subfolders
    $subfolders = Get-ChildItem $folderURL -directory

    # If there are subfolders :: Foreach subfolder :: get subfolder size, and add it to the total_sum
    if ($folders.count)
    {
        foreach ($subfolder in $subfolders)
        {
            $subfolder_size= r_GetFolderSize($subfolder.FullName)
            $subfolder_size_sum += $subfolder_size
        }
    }

    # for the files in the current folder _if there are any_  get the sum
    $file_size = (Get-ChildItem $folderURL -file | Measure-Object -Sum Length).Sum

    if ($file_size -ne $null)
    {
        $file_size_sum = $file_size
    }
    
    Write-Host `n $folderURL -ForegroundColor Cyan
    Write-Host "Size of subfolders: " $subfolder_size_sum
    Write-Host "Size of files: " $file_size_sum

    # Add the file_size_sum and subfolder sizes to get the size of the current folder.
    $total_size = $file_size_sum + $subfolder_size_sum

    return $total_size
}

Write-Host "------------------------------" -ForegroundColor Gray
$total_size = r_GetFolderSize('\\civ-ipbw-wss1ms\PST\koningr09')
