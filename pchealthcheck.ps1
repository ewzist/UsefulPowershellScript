# Automated Diagnostic & Repair Script for Help Desk
# Save this script as "Diagnostics.ps1" and run with administrative privileges.

# Function: Check Disk Space on C: Drive
function Check-DiskSpace {
    $disk = Get-PSDrive -Name C
    $freeGB = [math]::Round($disk.Free/1GB, 2)
    $usedGB = [math]::Round(($disk.Used)/1GB, 2)
    $totalGB = [math]::Round(($disk.Used + $disk.Free)/1GB, 2)
    Write-Output "Disk Space on C: drive: Used: $usedGB GB, Free: $freeGB GB, Total: $totalGB GB"
    if ($disk.Free -lt 10GB) {
        Write-Output "Warning: Less than 10GB free space on C: drive. Consider cleaning temporary files."
    } else {
        Write-Output "Disk space looks adequate."
    }
}

# Function: Check and Restart the Windows Update Service (wuauserv)
function Check-WindowsUpdateService {
    $service = Get-Service -Name wuauserv
    Write-Output "Windows Update Service status: $($service.Status)"
    if ($service.Status -ne 'Running') {
        Write-Output "Attempting to start Windows Update Service..."
        try {
            Start-Service -Name wuauserv -ErrorAction Stop
            $service = Get-Service -Name wuauserv
            Write-Output "New status: $($service.Status)"
        }
        catch {
            Write-Output "Failed to start Windows Update Service: $_"
			Write-Host "Running SFC /scannow..."
			Start-Process -FilePath "cmd.exe" -ArgumentList "/c sfc /scannow" -Wait

			# Run DISM /Online /Cleanup-Image /CheckHealth
			Write-Host "Running DISM /Online /Cleanup-Image /CheckHealth..."
			Start-Process -FilePath "cmd.exe" -ArgumentList "/c DISM /Online /Cleanup-Image /CheckHealth" -Wait

		    # Run DISM /Online /Cleanup-Image /ScanHealth
			Write-Host "Running DISM /Online /Cleanup-Image /ScanHealth..."
			Start-Process -FilePath "cmd.exe" -ArgumentList "/c DISM /Online /Cleanup-Image /ScanHealth" -Wait

			# Run DISM /Online /Cleanup-Image /RestoreHealth
			Write-Host "Running DISM /Online /Cleanup-Image /RestoreHealth..."
			Start-Process -FilePath "cmd.exe" -ArgumentList "/c DISM /Online /Cleanup-Image /RestoreHealth" -Wait
        }
    } else {
        Write-Output "Windows Update Service is running normally."
    }
}

# Function: Check Network Connectivity by pinging a reliable DNS (Google's 8.8.8.8)
function Check-NetworkConnectivity {
    $ESXhost = "8.8.8.8"
    Write-Output "Checking network connectivity to $host..."
    if (Test-Connection -ComputerName $host -Count 2 -Quiet) {
        Write-Output "Network connectivity is good."
    }
    else {
        Write-Output "Network connectivity issue detected. Please verify network settings."
    }
}

# Function: Check the Event Log for Error Events in the last hour
function Check-EventLogErrors {
    Write-Output "Checking for error events in the Application log from the last hour..."
    $time = (Get-Date).AddHours(-1)
    $errors = Get-EventLog -LogName Application -EntryType Error -After $time
    if ($errors.Count -gt 0) {
        Write-Output "Found $($errors.Count) error events in the Application log."
        $errors | Format-Table TimeGenerated, Source, Message -AutoSize
    }
    else {
        Write-Output "No recent error events found in the Application log."
    }
}

# Main Script Execution
Write-Output "Starting System Diagnostics..."
Check-DiskSpace
Check-WindowsUpdateService
Check-NetworkConnectivity
Check-EventLogErrors
Write-Output "Diagnostics completed."