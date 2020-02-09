#Generate HAC Logins for Students that are Active.
#Craig Millsap - 2/8/2020

Param(
[parameter(Position=0,mandatory=$false,Helpmessage="Optional year input will default to current school year")]
$CurrentYear,
[parameter(Position=1,mandatory=$true,Helpmessage="Which buildings do you want to generate HAC logins for? Example:'1,2,3'")]
[String]$buildings = "13,15,703", #***Variable*** What Buildings. Specified as a comma separated string.
[parameter(Position=2,mandatory=$true,Helpmessage="Eschool username")]
[String] $username="SSOusername", #***Variable*** Change to default eschool usename
[parameter(Mandatory=$false,HelpMessage="File for ADE SSO Password")]
[string]$passwordfile="C:\Scripts\apscnpw.txt", #--- VARIABLE --- change to a file path for SSO password
[parameter(Position=0,mandatory=$false,Helpmessage="Specify the time to wait before running the task")]
[int]$addtime = "1" #Specify the time in minutes to wait to run task
)

Add-Type -AssemblyName System.Web

#encrypted password file.
If (Test-Path $passwordfile) {
    #$password = Get-Content $passwordfile | ConvertTo-SecureString -AsPlainText -Force
    $password = (New-Object pscredential "user",(Get-Content C:\Scripts\apscnpw.txt | ConvertTo-SecureString)).GetNetworkCredential().Password
}
Else {
    Write-Host("Password file does not exist! [$passwordfile]. Please enter a password to be saved on this computer for scripts") -ForeGroundColor Yellow
    Read-Host "Enter Password" -AsSecureString |  ConvertFrom-SecureString | Out-File $passwordfile
    $password = Get-Content $passwordfile | ConvertTo-SecureString -AsPlainText -Force
}

$baseUrl = "https://eschool40.esp.k12.ar.us/eSchoolPLUS40/"
$loginUrl = "https://eschool40.esp.k12.ar.us/eSchoolPLUS40/Account/LogOn?ReturnUrl=%2feSchoolPLUS40%2f"
$envUrl = "https://eschool40.esp.k12.ar.us/eSchoolPLUS40/Account/SetEnvironment/SessionStart"
$hacloginsurl = 'https://eschool40.esp.k12.ar.us/eSchoolPLUS40/HomeAccess/Utility/GenerateLogins'

if (-Not($CurrentYear)) {
    if ((Get-date).month -le "6") {
        $CurrentYear = (Get-date).year
    } else {
        $CurrentYear = (Get-date).year + 1
    }
}

#Login
$params = @{
    'UserName' = $username
    'Password' = $password
}
$response = Invoke-WebRequest -Uri $loginUrl -SessionVariable rb -Method POST -Body $params -ErrorAction Stop

#Set Environment
$params2 = @{
    'ServerName' = $response.ParsedHtml.getElementById('ServerName').value
    'EnvironmentConfiguration.Database' = $response.ParsedHtml.getElementById('EnvironmentConfiguration_Database').value
    'UserErrorMessage' = ''
    'EnvironmentConfiguration.SchoolYear' = $response.ParsedHtml.getElementById('EnvironmentConfiguration_SchoolYear').value
    'EnvironmentConfiguration.SummerSchool' = 'false'
    'EnvironmentConfiguration.ImpersonatedUser' = ''
}
$response2 = Invoke-WebRequest -Uri $envUrl -WebSession $rb -Method POST -Body $params2

#Generate HAC Logins

$params = @{
	'SearchType' = 'HACGENLOGINS'
	'SortType' = ''
	'SelectedBuildingsFlag' = 'SELECTED'
	'Buildings' = $buildings
	'SelectedBuildingsAll' = 'false'
	'SelectedTypes' = 'M'
	'SelectedTypesCheckAll' = 'false'
	'GenerateLoginsFlag' = 'L'
	'GenerateLoginsAsFlag' = '7'
	'OverrideExisting' = 'false'
	'TaskScheduler.CurrentTask.Classname' = 'Utilities4_0.CGenerateHACLogins'
	'TaskScheduler.CurrentTask.TaskDescription' = 'Generate HAC Logins & Passwords'
	'groupPredicate' = 'false'
	'Filter.Predicates[0].PredicateIndex' = '1'
	'tableKey' = 'reg'
	'Filter.Predicates[0].TableName' = 'reg'
	'columnKey' = 'reg.current_status'
	'Filter.Predicates[0].ColumnName' = 'current_status'
	'Filter.Predicates[0].DataType' = 'Char'
	'Filter.Predicates[0].Operator' = 'Equal'
	'Filter.Predicates[0].Value' = 'A'
	'Filter.Predicates[1].LogicalOperator' = 'And'
	'Filter.Predicates[1].PredicateIndex' = '2'
	'Filter.Predicates[1].DataType' = 'Char'
	'Filter.LoginId' = $username
	'Filter.SearchType' = 'HACGENLOGINS'
	'Filter.SearchNumber' = '0'
	'Filter.GroupingMask' = ''
	'TaskScheduler.CurrentTask.ScheduleType' = 'N'
	'TaskScheduler.CurrentTask.SchdInterval' = '1'
	'TaskScheduler.CurrentTask.ScheduledTimeTime' = (Get-Date).AddMinutes($addtime).ToString("hh:mm tt")
	'TaskScheduler.CurrentTask.ScheduledTimeDate' = Get-Date -UFormat %m/%d/%Y
	'TaskScheduler.CurrentTask.Monday' = 'false'
	'TaskScheduler.CurrentTask.Tuesday' = 'false'
	'TaskScheduler.CurrentTask.Wednesday' = 'false'
	'TaskScheduler.CurrentTask.Thursday' = 'false'
	'TaskScheduler.CurrentTask.Friday' = 'false'
	'TaskScheduler.CurrentTask.Saturday' = 'false'
	'TaskScheduler.CurrentTask.Sunday' = 'false'
}

$response3 = Invoke-WebRequest -Uri $hacloginsurl -WebSession $rb -Method POST -Body $params

$global:response = $response3

exit