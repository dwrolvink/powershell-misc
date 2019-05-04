# I copied the script below from the internet somewhere
# This script generates 100% CPU load in no time.
# ------------------------------------------

# Get number of processors    #Updated based on anonymous feedback.
#$NumberofProcs = (Get-WMIObject win32_processor | Measure-Object NumberofLogicalProcessors -sum).sum
$NumberofProcs= [int]$env:Number_of_Processors

# (Start a separate instance of powershell doing a large sum) * the number of processes
While ($NumberofProcs -ne 0) 
{
$NumberofProcs--
Start Powershell.exe -ArgumentList '"foreach ($loopnumber in 1..2147483647) {$result=1;foreach ($number in 1..2147483647) {$result = $result * $number};$result}"'
}
