# Init Log
Start-Transcript -Path 'C:/Script/terraform-sql.txt' -append
#$DebugPreference = 'Continue'
$VerbosePreference = 'Continue'
$InformationPreference = 'Continue'

# Initialize Hard Drives
Get-Disk | Where partitionstyle -eq 'raw' | Initialize-Disk -PartitionStyle MBR -PassThru | New-Partition -AssignDriveLetter -UseMaximumSize | Format-Volume -FileSystem NTFS -Confirm:$false

# Assign Disks
Get-Partition -DiskNumber 3 | Set-Partition -NewDriveLetter ${sql_logs_drive}
Get-Partition -DiskNumber 2 | Set-Partition -NewDriveLetter ${sql_data_drive}
  
# Create SQL Data
$DataDirectory = '${sql_data_drive}:/${sql_data_folder}'
Set-Volume -DriveLetter ${sql_data_drive} -NewFileSystemLabel 'SQL Data'
New-Item $DataDirectory -ItemType 'directory' -Force
  
# Create SQL Backup
$BackupDirectory = '${sql_data_drive}:/${sql_data_folder}/Backup'
New-Item $BackupDirectory -ItemType 'directory' -Force
  
# Create SQL Logs
$LogDirectory = '${sql_logs_drive}:/${sql_logs_folder}'
Set-Volume -DriveLetter ${sql_logs_drive} -NewFileSystemLabel 'SQL Logs'
New-Item $LogDirectory -ItemType 'directory' -Force

# Root SQL 2019 Key 
$SQLRegKeyPath = 'HKLM:/Software/Microsoft/Microsoft SQL Server/MSSQL15.MSSQLSERVER/MSSQLServer'
  
# Update Data Registry
$DataRegKeyName = 'DefaultData'
If ((Get-ItemProperty -Path $SQLRegKeyPath -Name $DataRegKeyName -ErrorAction SilentlyContinue) -eq $null) {
  New-ItemProperty -Path $SQLRegKeyPath -Name $DataRegKeyName -PropertyType String -Value $DataDirectory
} Else {
  Set-ItemProperty -Path $SQLRegKeyPath -Name $DataRegKeyName -Value $DataDirectory
}

# Update Log Registry
$LogRegKeyName = 'DefaultLog'
If ((Get-ItemProperty -Path $SQLRegKeyPath -Name $LogRegKeyName -ErrorAction SilentlyContinue) -eq $null) {
  New-ItemProperty -Path $SQLRegKeyPath -Name $LogRegKeyName -PropertyType String -Value $LogDirectory
} Else {
  Set-ItemProperty -Path $SQLRegKeyPath -Name $LogRegKeyName -Value $LogDirectory
}

# Update Backup Registry
$BackupRegKeyName = 'BackupDirectory'
If ((Get-ItemProperty -Path $SQLRegKeyPath -Name $BackupRegKeyName -ErrorAction SilentlyContinue) -eq $null) {
  New-ItemProperty -Path $SQLRegKeyPath -Name $BackupRegKeyName -PropertyType String -Value $BackupDirectory
} Else {
  Set-ItemProperty -Path $SQLRegKeyPath -Name $BackupRegKeyName -Value $BackupDirectory
}

# Restart SQL Service
Stop-Service -Name 'MSSQLSERVER'
Start-Service -Name 'MSSQLSERVER'

# Stop Log
Stop-Transcript
