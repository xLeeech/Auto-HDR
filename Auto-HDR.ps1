# Requires admin rights. Run once and forget.
# GitHub: https://github.com/xLeeech/Auto-HDR (example)

# Config
$checkInterval = 5 # Seconds between checks
$hdrKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\HDR"
$gpuUsageThreshold = 50 # GPU% threshold to assume game is running

# Main loop
while ($true) {
    # Check if any app is fullscreen via Windows Event Log
    $fullscreenEvent = Get-WinEvent -LogName "Microsoft-Windows-DxgKrnl/Operational" -MaxEvents 1 | 
                       Where-Object { $_.Id -eq 1000 } # Event ID 1000 = fullscreen change

    # Check GPU usage (games typically spike GPU)
    $gpuUsage = (Get-Counter "\GPU Engine(*)\Utilization Percentage").CounterSamples | 
                Where-Object { $_.InstanceName -like "*engtype_3D*" } | 
                Select-Object -ExpandProperty CookedValue

    # Determine if a game is likely running
    $isGameRunning = ($fullscreenEvent -ne $null) -or ($gpuUsage -ge $gpuUsageThreshold)

    # Toggle HDR
    $currentHDR = (Get-ItemProperty -Path $hdrKey -Name "UseHDR" -ErrorAction SilentlyContinue).UseHDR
    if ($isGameRunning -and $currentHDR -ne 1) {
        Set-ItemProperty -Path $hdrKey -Name "UseHDR" -Value 1
        Write-Output "HDR Enabled (Game Detected)"
        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
        Start-Process explorer
    } elseif (-not $isGameRunning -and $currentHDR -ne 0) {
        Set-ItemProperty -Path $hdrKey -Name "UseHDR" -Value 0
        Write-Output "HDR Disabled (No Game)"
        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
        Start-Process explorer
    }

    Start-Sleep -Seconds $checkInterval
}
