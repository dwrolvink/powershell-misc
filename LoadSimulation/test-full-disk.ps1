# Create empty file of a certain size
function New-EmptyFile
{
   param( [string]$FilePath,[double]$Size )
 
   $file = [System.IO.File]::Create($FilePath)
   $file.SetLength($Size)
   $file.Close()
   Get-Item $file.Name
}

# Check how much size is available, and make a file that fills up that space minus 1gb
function Fill-Disk
{
    param( [string]$DiskToBeFilled)

    ## Config
    $BigFileName = 'BigFile.txt'
    $TestDir = 'test_temp\'
    $FreeSpaceToBeLeft = 1gb

    ## Init
    # Set save location
    $TestDir = Join-Path $DiskToBeFilled $TestDir
    $BigFileLocation = Join-Path $TestDir $BigFileName

    if ((Test-Path $TestDir) -eq $false)
    { 
        # Make dir if it does not exist
        New-Item -Path $TestDir -ItemType Directory
    } else {
        # Remove file if already exists
        if (Test-Path $BigFileLocation){ Remove-Item -Path $BigFileLocation }
    }

    ## Logic
    # Calculate freespace on disk
    $FreeSpace = (get-WmiObject win32_logicaldisk | Where-Object -Property DeviceID -eq $DiskToBeFilled).FreeSpace
    $BigFileSize = $FreeSpace - $FreeSpaceToBeLeft

    New-EmptyFile -FilePath $BigFileLocation -Size $BigFileSize
}

Fill-Disk -DiskToBeFilled "C:"
