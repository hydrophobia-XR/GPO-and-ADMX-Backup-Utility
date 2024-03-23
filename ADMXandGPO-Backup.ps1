<#
	.NOTES
	===========================================================================
		Created by: Hydrophobia-XR
		Created On: 1.2024
		Last Modified On: 3.23.2024
		Last Modified By: Hydrophobia-XR
		Filename: ADMXandGPO-Backup.ps1
	===========================================================================
	.DISCLAIMER:
	By using this content you agree to the following: This script may be used for legal purposes only. Users take full responsibility 
	for any actions performed using this script. The author accepts no liability for any damage caused by this script.  

	.DESCRIPTION
	It's a good idea to periodically backup ADMX files and/or Group Policy configurations. Especially before updating your DC or importing new ADMX files. 
	This script makes that a little simpler and can be used to automate the process via a scheduled task if so desired. THis script automatically grabs the domain name of the Domain Controller you run it on

	.PARAMETER BackupPath 
	(Mandatory)
	-BackupPath {YourPathHere}: Provide the path where you would like this backup to be sent. 
    
	.PARAMETER ADMX
	-ADMX : Enables backing up both the local PolicyDefinitions folder and the SysVol PolicyDefinitions folder. 

	.PARAMETER GPO
	-GPO : Enables backing up all GroupPolicy Objects on the DC it is run on. Utilizes built-in Windows functions. 

	.EXAMPLE
	ADMXandGPO-Backup.ps1 -BackupPath "C:\DomainBackups" -GPO
	This command would backup Group Policy Objects to a folder created under C:\DomainBackups\  Based on the current date ex: C:\DomainBackups\GPOBackup-2024-02-25\
	A simple txt file will also be created called GPOBackupReport-2024-02-25.txt that contains a list of the GPOs backed up along with their GPO ID for reference

	.EXAMPLE
	ADMXandGPO-Backup.ps1 -BackupPath "C:\DomainBackups" -ADMX
	This command would only backup ADMX files to two different folders created under C:\DomainBackups\ based on the current date and what ADMX location it came from.
	EX: C:\DomainBackups\ADMX-2024-02-25\Local-ADMXBackup    and	  C:\DomainBackups\ADMX-2024-02-25\SYSVOL-ADMXBackup

	.EXAMPLE
	ADMXandGPO-Backup.ps1 -BackupPath "C:\DomainBackups" -GPO -ADMX
	This command would backup both Group Policy Objects and ADMX files to C:\DomainBackups\ 
	EX: C:\DomainBackups\GPOBackup-2024-02-25\ , C:\DomainBackups\ADMX-2024-02-25\Local-ADMXBackup  and  C:\DomainBackups\ADMX-2024-02-25\SYSVOL-ADMXBackup

	.CHANGELOG
	3.23.2024 - Added Logging, Examples, additional notes and Descriptions. Functionalized commands 

	.TODO
	Done: Add logging
	More detailed feedback\
	Add verification that all ADMX files were backed up

#>

#################################### Parameters ###################################
[CmdletBinding()]
param (
	[Parameter(Mandatory = $true)][String]$BackupPath,
	[Parameter()][Switch]$ADMX,
	[Parameter()][Switch]$GPO
)
################################# EDITABLE VARIABLES #################################
#N/A for this script
################################# SET COMMON VARIABLES ################################
$ErrorActionPreference = "Stop"
$CurrentDate = Get-Date
$DomainInfo = Get-ADDomain
$DomainName = $DomainInfo.DNSRoot
#Gets list of update files
$CurrentDate = Get-Date
#Below variables used for creating logging
$TimeStampFormat = "yyyy-MM-dd HH:mm:ss"
$Computer = $Env:ComputerName
$User = $Env:UserName
$global:CurrentPath = split-path -Parent $PSCommandPath
$filename = "$Computer-$($CurrentDate.ToString("yyyy-MM-dd_HH.mm")).txt"
$logfile = $CurrentPath + "\Logs\$($CurrentDate.ToString("yyyy"))\$($CurrentDate.ToString("MM"))\" + $filename
#Used to track how long it takes updates to install
$sw = [Diagnostics.Stopwatch]::StartNew()
#################################### FUNCTIONS #######################################
Function Write-Log {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $false)][ValidateSet("Info", "WARN", "ERROR", "FATAL", "DEBUG")][string]$level = "INFO",
		[Parameter(Mandatory = $true)][string]$Message,
		[Parameter(Mandatory = $true)][string]$logfile
	)
	$Stamp = (Get-Date).ToString($TimeStampFormat)
	$Line = "$Stamp | $Level | $Message"
	Add-content $logfile -Value $Line
}

Function Set-LogFolders {
	$LogFolder = $CurrentPath + "\Logs\$($CurrentDate.ToString("yyyy"))\$($CurrentDate.ToString("MM"))"
	if (!(Test-Path $LogFolder)) {
		New-Item -Path $LogFolder -ItemType "directory" | out-null
		if (Test-Path $LogFolder) {
			Write-Output "$LogFolder created successfully"
		}
		else {
			Write-Output "Error creating path: $LogPath maybe try manual creation?"
		}
	}
}

<#
	.SYNOPSIS
		Function to backup ADMX files
	
	.DESCRIPTION
		Function backs up both ADMX files in C:\Windows\PolicyDefinitions and ADMX files under the C:\Windows\SYSVOL\sysvol\domainname\Policies\PolicyDefinitions directory

#>
function Backup-ADMX {
	if (!(Test-Path "$BackupPath\ADMX-$($CurrentDate.ToString("yyyy-MM-dd"))")) {
		Write-Log -level INFO -message "Backup path folder $BackupPath\ADMX-$($CurrentDate.ToString("yyyy-MM-dd")) doesn't exist, creating now" -logfile $logfile
		New-Item -Path "$BackupPath\ADMX-$($CurrentDate.ToString("yyyy-MM-dd"))" -ItemType "directory" | out-null
	}
	Write-Output "Backing up ADMX files from: C:\Windows\SYSVOL\sysvol\$DomainName\Policies\PolicyDefinitions"
	Write-Log -level INFO -message "Backing up ADMX files from: C:\Windows\SYSVOL\sysvol\$DomainName\Policies\PolicyDefinitions" -logfile $logfile
	robocopy /E /R:2 /W:10 /V /NDL /NFL  "C:\Windows\SYSVOL\sysvol\$DomainName\Policies\PolicyDefinitions"* "$BackupPath\ADMX-$($CurrentDate.ToString("yyyy-MM-dd"))\SYSVOL-ADMXBackup" | Out-Null
	Write-Output "Backing up ADMX files from: C:\Windows\PolicyDefinitions "
	Write-Log -level INFO -message "Backing up ADMX files from: C:\Windows\PolicyDefinitions" -logfile $logfile
	robocopy /E /R:2 /W:10 /V /NDL /NFL  "C:\Windows\PolicyDefinitions"* "$BackupPath\ADMX-$($CurrentDate.ToString("yyyy-MM-dd"))\Local-ADMXBackup" | Out-Null
	Write-Output "ADMX Backup completed"
	Write-Log -level INFO -message "ADMX Backup completed" -logfile $logfile
}

<#
	.SYNOPSIS
		Function to backup Group Policy Objects
	
	.DESCRIPTION
		Function backs up both Group Policy Objects via the built in Backup-gpo command

#>
function Start-GPOBackup {
	if (!(Test-Path "$BackupPath\GPOBackup-$($CurrentDate.ToString("yyyy-MM-dd"))\")) {
		Write-Log -level INFO -message "Backup path folder $BackupPath\GPOBackup-$($CurrentDate.ToString("yyyy-MM-dd")) doesn't exist, creating now" -logfile $logfile
		New-Item -Path "$BackupPath\GPOBackup-$($CurrentDate.ToString("yyyy-MM-dd"))\" -ItemType "directory" | out-null
	}
	Write-Output "Backing up Group Policy Objects..."
	Write-Log -level INFO -message "Backing up Group Policy Objects" -logfile $logfile
	Backup-gpo -path "$BackupPath\GPOBackup-$($CurrentDate.ToString("yyyy-MM-dd"))\" -ALL | Select-Object DisplayName,GpoId | Sort-Object -Property DisplayName | Out-File "$BackupPath\GPOBackupReport-$($CurrentDate.ToString("yyyy-MM-dd")).txt"
	Write-Output "GPO Backup completed"
}


#################################### EXECUTION #####################################
Set-LogFolders

Write-Log -level INFO -message "GPO/ADMX BACKUP SCRIPT, RUN BY $User ON $Computer" -logfile $logfile

If ($ADMX) {
	Write-Output "ADMX Backup was enabled"
	Write-Log -level INFO -message "ADMX Backup was enabled" -logfile $logfile
	Backup-ADMX
}
If ($GPO) {
	Write-Output "GPO Backup was enabled"
	Write-Log -level INFO -message "GPO Backup was enabled" -logfile $logfile
	if (!(Test-Path "$BackupPath\GPOBackup-$($CurrentDate.ToString("yyyy-MM-dd"))\")) {
		Write-Log -level INFO -message "Backup path folder $BackupPath\GPOBackup-$($CurrentDate.ToString("yyyy-MM-dd")) doesn't exist, creating now" -logfile $logfile
		New-Item -Path "$BackupPath\GPOBackup-$($CurrentDate.ToString("yyyy-MM-dd"))\" -ItemType "directory" | out-null
	}
	Write-Output "Backing up Group Policy Objects..."
	Write-Log -level INFO -message "Backing up Group Policy Objects" -logfile $logfile
	Backup-gpo -path "$BackupPath\GPOBackup-$($CurrentDate.ToString("yyyy-MM-dd"))\" -ALL
	Write-Output "GPO Backup completed"
}
Else {
	Write-Output "No options chosen please use -ADMX and/or -GPO"
	Write-Log -level INFO -message "No options chosen please use -ADMX and/or -GPO" -logfile $logfile
}

$sw.stop()
Write-Output "ADMX and GPO backup script ran for: $($sw.elapsed)"
Write-Log -level INFO -message "Total time to run $($sw.elapsed)." -logfile $logfile
