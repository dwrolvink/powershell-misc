# ==============================================================================================#
#                                              INIT
# ==============================================================================================#
[reflection.assembly]::loadwithpartialname("System.Windows.Forms") | Out-Null


$Script:Process = $null
$Script:Terminate = $true

# ==============================================================================================#
#                                           Functions
# ==============================================================================================#

<# 
    This function handles the starting/stopping of jobs, and the interaction between the gui and the 
    jobs.
    It takes in a codeblock. Notice that the scope is limited to what is defined within the code block
    if you need more data, you should add an $argumentlist param, and pass it to Start-Job
#>
function Job-Handler(){
    param ($Caller,$JobCode)

    # Disable caller button, so the same job can't be started again while this one's running
    $Caller.Enabled = $false

    # Reset script termination so the cancel operation will have effect
    $script:terminate = $false;

    # We start the job, the output we collect later will be put in $output
    $job = Start-Job -ScriptBlock $JobCode
    $output = @()

    # Give focus back to form
    $form.Focus()

    # Keep collecting output from job as long as it's running.
    # without this receive-job loop, the progressbar won't update
    # without the doEvents() loop, the gui will lock up while it's running job_handler
    While($job.State -eq 'Running' -and $script:terminate -ne $true){
        [System.Windows.Forms.Application]::DoEvents() 
        $output += Receive-Job -Job $job
    }

    # We call stop-job, because we might've broken from the while loop through $script:terminate
    $job | Stop-Job

    # There might be data still not fetched after job cancellation, fetch this
    $output += Receive-Job -Job $job

    # Job's ended, reenable the caller button
    $Caller.Enabled = $True

    return $output
}

<#
    Function designed to take a while (and have continuous output).
    The job collects all output, and that data can be iteratively fetched during job execution.
    This means that if we cancel below code prematurely, we can still collect all the output up to
    that point.
    Made a function in a code block just to show it can be done. We can't call $script scope functions
    because the job is scoped to $global/$scriptblock.
#>
$cb_SlowlyIterate_Services = {

    Function SlowlyIterate-Services()
    {
        $Services = Get-Service
    
        $i = 0; foreach ($service in $Services)
        {
            $i++; Write-Progress -Activity "Cycle services" -Status $service.name -PercentComplete (100*$i/$Services.count)
            write-output ($service | select *)
            start-sleep -Milliseconds 20
        }
    }

    SlowlyIterate-Services
}

# ==============================================================================================#
#                                           GUI Actions
# ==============================================================================================#

# Cancel operation if running, otherwise close form
Function Invoke-Cancel()
{
    If ($script:terminate){
        $form.Close()
    } Else {
        $script:terminate = $true
    }
}

# When the submit button is clicked, start the slowiterate-services function
Function Invoke-Submit()
{
    Job-Handler -Caller $This -JobCode $cb_SlowlyIterate_Services | ?{$_.GetType().name -eq 'PSCustomObject'} | Out-GridView  
}


# ==============================================================================================#
#                                              FORM
# ==============================================================================================#

# [Form]
$form = New-Object System.Windows.Forms.Form
$form.StartPosition = "CenterScreen"
$form.Text          = 'GUI/Jobs demo'

# Text
$hi_there = New-Object  System.Windows.Forms.TextBox
$hi_there.Multiline = $true
$hi_there.Enabled = $false
$hi_there.Text      = @"
This demo is made to demonstrate a(n intentionally) slow task, running with a progressbar, while being able to call and cancel it using the GUI.
Clicking the cancel button when no task is running will close the GUI. [Output will be from start to end/point of cancellation.]
"@
$hi_there.Font      = "Microsoft Sans Serif,9"
$hi_there.Top       = 20
$hi_there.Left      = 20
$hi_there.Width     = 240
$hi_there.Height    = 120
$hi_there.Padding   = 1

# Start main task
$submit = New-Object  System.Windows.Forms.Button
$submit.Text      = "Submit"
$submit.Top       = 160
$submit.Left      = 32
$submit.Width     = 96
$submit.Height    = 20
$submit.Padding   = 1
$submit.TextAlign = "MiddleCenter"
$submit.add_click({   Invoke-Submit })

# Cancel operation if running, otherwise close form
$cancel = New-Object  System.Windows.Forms.Button
$cancel.Text      = "Cancel"
$cancel.Top       = 160
$cancel.Left      = 130
$cancel.Width     = 96
$cancel.Height    = 20
$cancel.Padding   = 1
$cancel.TextAlign = "MiddleCenter"
$cancel.add_click({ Invoke-Cancel })

# [/Form]
$form.Controls.Add($hi_there)
$form.Controls.Add($submit)
$form.Controls.Add($cancel)
$form.ShowDialog()| Out-Null

