### SETUP FOR LOGGING ###
Function Log-Output
{
	Param([Parameter(Mandatory=$true)][PSObject[]]$message)
	Write-Output "[Output $(Get-Date)]$message"
}
Function Log-Info
{
	Param([Parameter(Mandatory=$true)][PSObject[]]$message)
	Write-Output "[Info $(Get-Date)]$message"
}
Function Log-Warning
{
	Param([Parameter(Mandatory=$true)][PSObject[]]$message)
	Write-Output "[Warning $(Get-Date)]$message"
}
Function Log-Error
{
	Param([Parameter(Mandatory=$true)][PSObject[]]$message)
	Write-Output "[Error $(Get-Date)]$message"
}
Function Log-Debug
{
	Param([Parameter(Mandatory=$true)][PSObject[]]$message)
	Write-Output "[Debug $(Get-Date)]$message"
}
		

$STATUS_SUCCESS = '[STATUS]::SUCCESS'
$STATUS_ERROR = '[STATUS]::ERROR'
###

### Add Get-Disk-Partitions function for KVM ###
function Get-Disk-Partitions()
{
	$partitionlist = $null
	$disklist = get-wmiobject Win32_diskdrive |Where-Object {$_.model -like 'Microsoft Virtual Disk'} 
	ForEach ($disk in $disklist)
	{
		$diskID = $disk.index
		$command = @"
		select disk $diskID
		online disk noerr
"@
		$command | diskpart | out-null

		$partitionlist += Get-Partition -DiskNumber $diskID
	}
	return $partitionlist
}
###

$partitionlist = Get-Disk-Partitions
$actionTaken = $false

forEach ( $partition in $partitionlist )
{
    $driveLetter = ($partition.DriveLetter + ":")
    $corruptFiles = "$driveLetter\Windows\System32\drivers\CrowdStrike\C-00000291*.sys"

    if (Test-Path -Path $corruptFiles) {
        Log-Info "Found crowdstrike files to cleanup, removing..."
        Remove-Item $corruptFiles
        $actionTaken = $true
    }
}

if ($actionTaken) {
    Log-Info "Successfully cleaned up crowdstrike files"
} else {
    Log-Warning "No bad crowdstrike files found"
}

return $STATUS_SUCCESS
