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

    if ($url.Contains("@device")) { $parameters = " -f dshow -i audio=$url " }
    if ($url.Contains("http"))    { $parameters = " -i $url -c:a copy " }
    if ($_.bitrate)               { $parameters = $parameters + " -ar 44100 -ac 2 -ab " + $bitrate }
    
    $parameters = $parameters + " -f segment -segment_time 00:10:00 -strftime 1 -strftime_mkdir 1 -segment_atclocktime 1 -reset_timestamps 1 -v warning -stats -loglevel warning -y $output"
    # Log levels are:
    # quiet: -8, panic: 0, fatal: 8, error: 16, warning: 24, info: 32, verbose: 40, debug: 48, trace: 56
    
    #Write-Host "Parameters for $name :" $parameters -ForegroundColor DarkGray
    $parameters = $parameters.Split(" ") # lol
    Write-Host (Get-Date -Format "yyyy/MM/dd HH:mm:ss") "Starting" $name "Logger" -ForegroundColor DarkGreen
    $proc = Start-Process -filePath ffmpeg.exe -ArgumentList $parameters -Passthru -WindowStyle Normal
    
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
Write-Host "`nff-Logger.ps1 Version 1.01.001 <r.ermakov@emg.fm> 2024-09-09 https://github.com/ykmn/ff-Logger `n"
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
$stations = @(
#    @{ name = 'Audio Input 1';     url = '@device_cm_{33D9A762-90C8-11D0-BD43-00A0C911CE86}\wave_{F84408DF-9C57-4C98-A66F-FBCC9EA194DD}'; ext = 'mp3'; storage = 'D:\STORAGE';
#                                   bitrate = '64K'},
    @{ name = 'Megapolis';         url = 'https://megapolisfm.hostingradio.ru/megapolisfm96.aacp';   ext = 'aac'; storage = 'D:\STORAGE' },
    @{ name = 'Autoradio Moscow';  url = 'https://pub0202.101.ru:8000/stream/air/aac/64/100';        ext = 'aac'; storage = 'D:\STORAGE' },
    @{ name = 'Radio JAZZ';        url = 'https://nashe1.hostingradio.ru:80/jazz-128.mp3';           ext = 'mp3'; storage = 'D:\STORAGE' },
    @{ name = 'Monte Carlo';       url = 'https://montecarlo.hostingradio.ru/montecarlo96.aacp';     ext = 'aac'; storage = 'D:\STORAGE' }

);

# Initial loggers start
$stations | ForEach-Object {
    if ($_.bitrate) {
        Start-ffmpeg $_.url $_.name $_.ext $_.storage $_.bitrate    
    } else {
        Start-ffmpeg $_.url $_.name $_.ext $_.storage
    }
}

$triggerTime = "00:00:00am"
Write-Host "There is" ((Get-Date -Date $triggerTime).AddDays(1)-(Get-Date)) "before scheduled loggers re-launch.`n" -ForegroundColor DarkGray

# Infinite loop   
do {
    if ((Get-Date) -lt (Get-Date -Date $triggerTime)) {
    # Before trigger time: sleeping for the remaining time
        while ((Get-Date) -lt (Get-Date -Date $triggerTime)) {
            Write-Host "It is" ((Get-Date -Date $triggerTime).AddDays(1)-(Get-Date)) "before scheduled loggers re-launch.`n" -ForegroundColor DarkGray
            (Get-Date -Date $triggerTime)-(Get-Date) | Start-Sleep
        }
        # Trigger here!
        Write-Host (Get-Date -Format "yyyy/MM/dd HH:mm:ss") "It's trigger time, restarting loggers:" -ForegroundColor Yellow
        $stations | ForEach-Object {
            Stop-ffmpeg $_.name
            if ($_.format) {
                Start-ffmpeg $_.url $_.name $_.ext $_.storage $_.format    
            } else {
                Start-ffmpeg $_.url $_.name $_.ext $_.storage
            }
        }
        Write-Host "There is" ((Get-Date -Date $triggerTime).AddDays(1)-(Get-Date)) "before scheduled loggers re-launch.`n" -ForegroundColor DarkGray
    } else {
    #  After trigger time: check for running process"
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
                Write-Host "There is" ((Get-Date -Date $triggerTime).AddDays(1)-(Get-Date)) "before scheduled loggers re-launch.`n" -ForegroundColor DarkGray
            }
        }
    }
} while ($true)
exit
