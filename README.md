
	#DESCRIPTION
	It's a good idea to periodically backup ADMX files and/or Group Policy configurations. Especially before updating your DC or importing new ADMX files. 
	This script makes that a little simpler and can be used to automate the process via a scheduled task if so desired. THis script automatically grabs the domain name of the Domain Controller you run it on
 
	#PARAMETER BackupPath 
	(Mandatory)
	-BackupPath {YourPathHere}: Provide the path where you would like this backup to be sent. 
    
	#PARAMETER ADMX
	-ADMX : Enables backing up both the local PolicyDefinitions folder and the SysVol PolicyDefinitions folder. 

	#PARAMETER GPO
	-GPO : Enables backing up all GroupPolicy Objects on the DC it is run on. Utilizes built-in Windows functions. 

	#EXAMPLE
	ADMXandGPO-Backup.ps1 -BackupPath "C:\DomainBackups" -GPO
	This command would backup Group Policy Objects to a folder created under C:\DomainBackups\  Based on the current date ex: C:\DomainBackups\GPOBackup-2024-02-25\
	A simple txt file will also be created called GPOBackupReport-2024-02-25.txt that contains a list of the GPOs backed up along with their GPO ID for reference

	#EXAMPLE
	ADMXandGPO-Backup.ps1 -BackupPath "C:\DomainBackups" -ADMX
	This command would only backup ADMX files to two different folders created under C:\DomainBackups\ based on the current date and what ADMX location it came from.
	EX: C:\DomainBackups\ADMX-2024-02-25\Local-ADMXBackup    and	  C:\DomainBackups\ADMX-2024-02-25\SYSVOL-ADMXBackup

	#EXAMPLE
	ADMXandGPO-Backup.ps1 -BackupPath "C:\DomainBackups" -GPO -ADMX
	This command would backup both Group Policy Objects and ADMX files to C:\DomainBackups\ 
	EX: C:\DomainBackups\GPOBackup-2024-02-25\ , C:\DomainBackups\ADMX-2024-02-25\Local-ADMXBackup  and  C:\DomainBackups\ADMX-2024-02-25\SYSVOL-ADMXBackup
