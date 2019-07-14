# Questions? Let me know what you think: aglamadrid19@gmail.com

# I'm merging fixes, send me a pull request.

# Thank you for taking the time to go over the Script

# 1 - The Script will capture Remote Computer Username and Password, then it would capture the Remote Computer IP, then it will try to connect
# 2 - If connection successful, it will capture the Username and Password for the SMTP server you will like to use to send the report email
# 3 - After that it will enter in a While Loop, if the ramUsageFunction ever returns a value higher than your loop condition, it will trigger the sendEmailFunction

# 4 - The sendEmailFunction will then capture the process/ram usage and send it over in an email (credentials capture in step 2) as HTML.

# Assumntions:
# We will be using WinRM to remote into the machine we want to monitor
# I'm not joined to a domain, so I added the machine I want to monitor to my Trusted Hosts

# Check Memory Usage Function (Using Get-CIMInstance Win32_OperatingSystem)
function MainFlowFunction {
    function ramUsageFunction {

        # Get Memory Usage (Total Memory, Free Physical Memory, Used Memory)
        $memoryUsageInfo = Get-CIMInstance Win32_OperatingSystem | Select @{Name='Total Memory';Expression={([math]::Round($_.'TotalVisibleMemorySize' / 1024))}},@{Name='Free Physical Memory';Expression={([math]::Round($_.'FreePhysicalMemory' / 1024))}},@{Name='Used Memory';Expression={([math]::Round(($_.'TotalVisibleMemorySize' - $_.'FreePhysicalMemory') / 1024))}};

        # Use MemoryUsageInfo to calculate RAM % Usage, this will be returned.
        $ramUsagePercent = [math]::Round($memoryUsageInfo.'Used Memory' * 100 / $memoryUsageInfo.'Total Memory');
        
        return [int]$ramUsagePercent;
    }

    function sendEmailFunction {
        # Get Server / Computer Name
        $serveName = $env:COMPUTERNAME;

        # Setting the email that will be sent

        # Set the email from
        $From = ""; 

        # Set the email to
        $To = "";

        #######
        # We might need this in the future
        # $Cc = "AThirdUser@somewhere.com"
        #######

        # Check if file to be attached exist (delete if it does exist)
        foreach ($file in Get-ChildItem)
        {
            if ($file.Name -eq "processReport.html")
            {
                Remove-Item processReport.html;
                break;
            };
        };

        # Email Configuration is set to use Gmail.com SMTP email.
        $Attachment = "processReport.html"
        # Get process list into HTML, Descending order
        Get-Process | Select-Object Name,@{Name='Process Memory Usage(MB)';Expression={([math]::Round($_.ws / 1024KB))}} | Sort-Object -Property 'Process Memory Usage(MB)' -Descending | ConvertTo-Html | Out-File processReport.html;
        $Subject = $serveName + " reached " + $ramUsagePercentPublic + "% of RAM usage (Report)";
        # $Body = Out-String -inputobject $toStoreBody;
        $SMTPServer = "smtp.gmail.com";
        $SMTPPort = "587";
        Send-MailMessage -From $From -to $To -Subject $Subject -Body "Report is attached (HTML)" -Attachments $Attachment -SmtpServer $SMTPServer -port $SMTPPort -UseSsl -Credential $emailCreds;
    };

    # Loop and get memory real time, break and execute SendEmail function after RAM usage memory > 80%
    function MonitorRAMFunction {
        # Clear Host
        Clear-Host;

        [int]$global:ramUsagePercentPublic = ramUsageFunction;

        while($ramUsagePercentPublic -le 95){
            if($ramUsagePercentPublic -le 95) {
                $ramUsagePercentPublic = ramUsageFunction;
                Write-Output "Memory usage is: " $ramUsagePercentPublic;
                # Wait 1 sec to continue while loop
                Start-Sleep -Seconds 1;
                # Clear Host
                Clear-Host;
                continue;
            }
            else {
                # Condition not met, RAM is high send email
                sendEmailFunction;
                # Email Sent
                break;
            }

        };
    };
    # MAIN FLOW HERE:
    
    # Get Email Credentialsclear
    Write-Output "Enter the credentials of the GMAIL account you will like to use to send email, after RAM usage goes over";
    $emailCreds = Get-Credential;

    MonitorRAMFunction;
}
# Clear host console:
Clear-Host;

# Input Remote Credentials
Write-Output "Enter the credentials to access Remote Host";
$remoteCreds = Get-Credential;

# Clear host console:
Clear-Host;

# Input Remote Host IP
$remoteHostIP = Read-Host -Prompt "What's the IP address of the host you want to monitor it's RAM?";

# Clear host console:
Clear-Host;

# Create Persistent Session
$remoteSession = New-PSSession -ComputerName $remoteHostIP -Credential $remoteCreds;

# Clear host console:
Clear-Host;

# Invoke Command in Remote Session (ramUsageFunction)
Invoke-Command -Session $remoteSession -ScriptBlock ${Function:MainFlowFunction};

# Close session
Remove-PSSession $remoteSession;