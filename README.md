# RAMMonitoringTool
## I'm merging fixes, send me a pull request.
PowerShell Script to monitor RAM usage in Remote Computer.

### Quick Description

1 - The Script will capture Remote Computer Username and Password, then it will capture the Remote Computer IP, then it will try to connect

2 - If connection successful, it will capture the Username and Password for the SMTP server you will like to use to send the report email

3 - After that it will enter in a While Loop, if the ramUsageFunction ever returns a value higher than your loop condition, it will trigger the sendEmailFunction

4 - The sendEmailFunction will then capture the process/ram usage and send it over in an email (credentials capture in step 2) as HTML.
