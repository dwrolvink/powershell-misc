
# RESTART SERVICE ON MULTIPLE COMPUTERS
#
# Takes ServiceName, Computer list, login credential
#
# Script tries to log in to every computer in the computer list using the given Credential
# It then tries to restart the service using Invoke-Command
# 
# Optionally, you can execute the bottom foreach to first check when the services were started 
# (and thus if they need restarting at all)



# Config
$ServiceName = 'SplunkForwarder'
$Computers = @('hws-epvw-cpr301','hws-iavw-cpr202','hws-iavw-cpr302','hws-ipbw-cvm301')
$Credential = Get-Credential

# Restart service on all computers
foreach ($computer in $computers)
{
    Write-Host "`n" $computer

    # Test Powershell Remoting
    $res = Test-WsMan $computer -ErrorAction SilentlyContinue

    # No error connecting
    if ($res)
    {
        # Restart service
        Invoke-Command -ComputerName $computer -ScriptBlock { Restart-Service -Name $args[0] } -credential $Credential -ArgumentList $ServiceName
    }
    # Error connecting
    else
    {
        Write-Host "Could not connect to " $computer -ForegroundColor Red
    }
}


# [Optional] Check time when the service was start.
foreach ($computer in $computers)
{
    Write-Host "`n" $computer -ForegroundColor Cyan

    # Test Powershell Remoting
    $res = Test-WsMan $computer -ErrorAction SilentlyContinue

    # No error connecting
    if ($res)
    {
        Invoke-Command -ComputerName $computer -credential $Credential -ArgumentList $ServiceName -ScriptBlock{ 
            (Get-EventLog -LogName “System” -Source “Service Control Manager” -EntryType “Information” -Message (“*"+$args[0]+"*running*”) -Newest 1).TimeGenerated 
        } 
    }
    # Error connecting
    else
    {
        write-host "Could not connect to " $computer -ForegroundColor Red
    }
}




