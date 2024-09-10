function Start-ffmpeg {
    param (
            [Parameter(Mandatory=$true)][string]$url,
            [Parameter(Mandatory=$true)][string]$name,
            [Parameter(Mandatory=$true)][string]$ext,
            [Parameter(Mandatory=$true)][string]$storage,
            [Parameter(Mandatory=$false)][string]$bitrate       
    )
    # Creating folders set
    $today = Get-Date -Format "yyyy-MM-dd"
    $tomorrow = (Get-Date(Get-Date).AddDays(1) -Format "yyyy-MM-dd")
    $name = $name.Replace(" ","-")    # because spaces are split option in parameters later
    if (!(Test-Path $storage))                 { New-Item -Path $storage                 -Force -ItemType Directory | Out-Null }
    if (!(Test-Path $storage\$name))           { New-Item -Path $storage\$name           -Force -ItemType Directory | Out-Null }
    if (!(Test-Path $storage\$name\$today))    { New-Item -Path $storage\$name\$today    -Force -ItemType Directory | Out-Null }
    if (!(Test-Path $storage\$name\$tomorrow)) { New-Item -Path $storage\$name\$tomorrow -Force -ItemType Directory | Out-Null }
    $output = $storage+"\"+$name+"\$today"+"\%H-%M-%S."+$ext

    if ($url.Contains("@device")) { $parameters = " -f dshow -i audio=$url" }
    if ($url.Contains("http"))    { $parameters = " -i $url" }
    if ($bitrate)                 { $parameters = $parameters + " -ar 44100 -ac 2 -ab " + $bitrate }
                             else { $parameters = $parameters + " -c:a copy" }
    
    $parameters = $parameters + " -f segment -segment_time 00:10:00 -strftime 1 -strftime_mkdir 1 -segment_atclocktime 1 -reset_timestamps 1 -v warning -stats -loglevel warning -y $output"
    # Log levels are:
    # quiet: -8, panic: 0, fatal: 8, error: 16, warning: 24, info: 32, verbose: 40, debug: 48, trace: 56
    
    #Write-Host "ffmpeg parameters for $name :" $parameters -ForegroundColor DarkGray
    $parameters = $parameters.Split(" ") # lol because of Start-Process ArgumentList
    Write-Host (Get-Date -Format "yyyy/MM/dd HH:mm:ss") "Starting" $name "Logger" -ForegroundColor DarkGreen
    $proc = Start-Process -filePath ffmpeg.exe -ArgumentList $parameters -Passthru -WindowStyle Minimized
    
    # Wait for a quirk: adding window title
    Add-Type -Type @"
using System;
using System.Runtime.InteropServices;
namespace WT {
   public class Temp {
      [DllImport("user32.dll")]
      public static extern bool SetWindowText(IntPtr hWnd, string lpString); 
   }
}
"@
    Start-Sleep -Milliseconds 200
    [wt.temp]::SetWindowText($proc.MainWindowHandle, "$name Logger") | Out-Null
}
    
function Stop-ffmpeg {
    param (
        [Parameter(Mandatory=$true)][string]$name
    )
    $name = $name.Replace(" ","-")
    # Finding Process ID for specific window title
    $id = (Get-Process | Where-Object {$_.MainWindowTitle -eq "$name Logger"}).Id
    Write-Host (Get-Date -Format "yyyy/MM/dd HH:mm:ss") "Stopping" $name "Logger" -ForegroundColor DarkYellow
    Stop-Process -id $id
}



####################################################################################################################################
Clear-Host
Write-Host "`nff-Logger.ps1 Version 1.02.001 <r.ermakov@emg.fm> 2024-09-10 https://github.com/ykmn/ff-Logger `n"
# Check for Powershell Core
if ($PSVersionTable.PSEdition -eq "Core") {
    Write-Host "PowerShell Core detected, OK " -ForegroundColor DarkGreen -NoNewline
    Write-Host "// Press Ctrl+C to quit" -ForegroundColor DarkGray
} else {
    Write-Host "PowerShell Core is not detected. Please run script with PS Core!" -ForegroundColor DarkRed
    Write-Host "Use " -NoNewline -ForegroundColor DarkGray
    Write-Host "winget install Microsoft.PowerShell" -ForegroundColor White -NoNewline
    Write-Host " or https://github.com/PowerShell/PowerShell/releases" -ForegroundColor DarkGray
    Write-Host "to install Microsoft Powershell 7 `n" -ForegroundColor DarkGray
    break
}

# Defining stations
# If you need to list audio devices, use
# ffmpeg -list_devices true -f dshow -i dummy
$currentdir = Split-Path $MyInvocation.MyCommand.Path -Parent
if (!(Test-Path $currentdir\stations.json)) {
    Write-Host "Configuration file not found." -ForegroundColor Red
    Break
}
# Reading JSON
$stations = Get-Content -Raw -Path $currentdir\stations.json | ConvertFrom-Json
Write-Host "Use the following configuration file:" -ForegroundColor DarkGreen
$stations

# Initial loggers start
$stations | ForEach-Object {
    if ($_.bitrate) {
        Start-ffmpeg $_.url $_.name $_.ext $_.storage $_.bitrate    
    } else {
        Start-ffmpeg $_.url $_.name $_.ext $_.storage
    }
}

$triggerTime = "00:00:01am"
# Infinite loop   
do {
    if ((Get-Date -Format "HH:mm:ss") -eq (Get-Date -Date $triggerTime -Format "HH:mm:ss")) {
        # It's trigger time!
        Write-Host (Get-Date -Format "yyyy/MM/dd HH:mm:ss") "It's a trigger time, restarting loggers" -ForegroundColor Yellow
        $stations | ForEach-Object {
            Stop-ffmpeg $_.name
        }
    }

    # It's not trigger time
    if ($((Get-Date)-(Get-Date -Date $triggerTime)) -lt 0) {
        # Trigger time is in future
        $progress = (Get-Date -Date $triggerTime)-(Get-Date)
    } else {
        # Trigger time was in past, so set trigger to next day
        $progress = (Get-Date -Date $triggerTime).AddDays(1)-(Get-Date)
    }
    # Show progress
    $percent = [math]::Round((100 - ($progress.TotalSeconds * 100 / 86400)),2)
    Write-Progress -Activity "Time left until loggers restart: " -Status $('{0:hh\:mm\:ss}' -f $progress) -PercentComplete $percent

    # Check for running process
    $stations | ForEach-Object {
        $n = $_.name.Replace(" ","-")
        $id = (Get-Process | Where-Object {$_.MainWindowTitle -eq "$n Logger"}).Id
        if (!($id)) {
            Write-Host (Get-Date -Format "yyyy/MM/dd HH:mm:ss") $_.name "Logger process not found" -ForegroundColor DarkRed
            if ($_.bitrate) {
                Start-ffmpeg $_.url $_.name $_.ext $_.storage $_.bitrate    
            } else {
                Start-ffmpeg $_.url $_.name $_.ext $_.storage
            }
        }
    }

} while ($true)

exit

<#
Versions:

* 2024-09-06 - v1.00 Начальная версия.
* 2024-09-09 - v1.01 Добавлена возможность записи с аудиовхода звуковой карты, что уж там.
* 2024-09-10 - v1.02 Параметры каналов записи вынесены в файл конфигурации; добавлен прогресс-бар времени перезапуска логгеров.
#>