function Start-ffmpeg {
    # Handling command-line parameters
    param (
            [Parameter(Mandatory=$true)][string]$url,
            [Parameter(Mandatory=$true)][string]$name,
            [Parameter(Mandatory=$true)][string]$ext,
            [Parameter(Mandatory=$true)][string]$storage        
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

    # Log levels are:
    # quiet: -8, panic: 0, fatal: 8, error: 16, warning: 24, info: 32, verbose: 40, debug: 48, trace: 56
    $parameters = " -i $url -c:a copy -f segment -segment_time 00:10:00 -strftime 1 -strftime_mkdir 1 -segment_atclocktime 1 -reset_timestamps 1 -v warning -stats -loglevel warning -y $output"
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
    # Handling command-line parameters
    param (
        [Parameter(Mandatory=$true)][string]$name
    )
    $name = $name.Replace(" ","-")
    # Finding Process ID for specific window title
    $id = (Get-Process | Where-Object {$_.MainWindowTitle -eq "$name Logger"}).Id
    Write-Host (Get-Date -Format "yyyy/MM/dd HH:mm:ss") "Stopping" $name "Logger" -ForegroundColor DarkYellow
    Stop-Process -id $id
}

function Write-Log {
    param (
        [Parameter(Mandatory=$true)][string]$message,
        [Parameter(Mandatory=$false)][string]$color
    )
    $PSscript = Split-Path $MyInvocation.ScriptName -Leaf
    #$logfile = $currentdir + "\log\" + $(Get-Date -Format yyyy-MM-dd) + "-" + $MyInvocation.MyCommand.Name + ".log"
    #$LogFile = $currentdir + "\log\" + $(Get-Date -Format yyyy-MM-dd) + "-" + $PSscript + ".log"
    $LogFile = $currentdir + "\log\" + $(Get-Date -Format yyyy-MM-dd) + "-" + $cfg + ".log"
    $LogNow = Get-Date -Format HH:mm:ss.fff
    $message = "$LogNow : " + $message
    if (!($color)) {
        Write-Host $message    
    } else {
        Write-Host $message -ForegroundColor $color
    }
    $message | Out-File $LogFile -Append -Encoding "UTF8"
}

####################################################################################################################################
Clear-Host
Write-Host "`nff-Logger.ps1 Version 1.00.001 <r.ermakov@emg.fm> 2024-09-09 https://github.com/ykmn/ff-Logger `n"
# Check for Powershell Core
if ($PSVersionTable.PSEdition -eq "Core") {
    Write-Host "PowerShell Core detected, OK " -ForegroundColor DarkGreen -NoNewline
    Write-Host "// Press Ctrl+C to quit" -ForegroundColor DarkGray
} else {
    Write-Host "PowerShell Core is not detected. Please run script in PS Core!" -ForegroundColor DarkRed
    Write-Host "Use " -NoNewline -ForegroundColor DarkGray
    Write-Host "winget install Microsoft.PowerShell" -ForegroundColor White -NoNewline
    Write-Host " or https://github.com/PowerShell/PowerShell/releases" -ForegroundColor DarkGray
    Write-Host "to install Microsoft Powershell 7 `n" -ForegroundColor DarkGray
    break
}
$currentdir = Split-Path $MyInvocation.MyCommand.Path -Parent
# Defining stations
$stations = @(
@{ name = 'Autoradio Moscow';  url = 'https://pub0202.101.ru:8000/stream/air/aac/64/100';          ext = 'aac'; storage = 'D:\STORAGE' },
@{ name = 'Radio JAZZ';        url = 'https://nashe1.hostingradio.ru:80/jazz-128.mp3';             ext = 'mp3'; storage = 'D:\STORAGE' },
@{ name = 'Monte Carlo';       url = 'https://montecarlo.hostingradio.ru/montecarlo96.aacp';       ext = 'aac'; storage = 'D:\STORAGE' },
@{ name = 'Retro FM';          url = 'https://hls-01-regions.emgsound.ru/12_msk/playlist.m3u8';    ext = 'aac'; storage = 'D:\STORAGE' },
@{ name = 'Love Radio';        url = 'https://microit2.n340.ru:8443/VgMv0WV17ZVx1uuo_12_love_64';  ext = 'aac'; storage = 'D:\STORAGE' }
);


# Initial loggers start
$stations | ForEach-Object {
    Start-ffmpeg $_.url $_.name $_.ext $_.storage
}
$triggerTime = "00:00:00am"
Write-Host "There is" ((Get-Date -Date $triggerTime)-(Get-Date)) "before scheduled loggers re-launch.`n" -ForegroundColor DarkGray

# Infinite loop   
do {
    if ((Get-Date) -lt (Get-Date -Date $triggerTime)) {
    # Before trigger time: sleeping for the remaining time
        while ((Get-Date) -lt (Get-Date -Date $triggerTime)) {
            Write-Host "There is" ((Get-Date -Date $triggerTime)-(Get-Date)) "before scheduled loggers re-launch.`n" -ForegroundColor DarkGray
            (Get-Date -Date $triggerTime)-(Get-Date) | Start-Sleep
        }
        # Trigger here!
        Write-Host (Get-Date -Format "yyyy/MM/dd HH:mm:ss") "It's trigger time, restarting loggers:" -ForegroundColor Yellow
        $stations | ForEach-Object {
            Stop-ffmpeg $_.name
            Start-ffmpeg $_.url $_.name $_.ext $_.storage
        }
        Write-Host "There is" ((Get-Date -Date $triggerTime)-(Get-Date)) "before scheduled loggers re-launch.`n" -ForegroundColor DarkGray
    } else {
    #  After trigger time: check for running process"
        $stations | ForEach-Object {
            $n = $_.name.Replace(" ","-")
            $id = (Get-Process | Where-Object {$_.MainWindowTitle -eq "$n Logger"}).Id
            if (!($id)) {
                Write-Host (Get-Date -Format "yyyy/MM/dd HH:mm:ss") $_.name "Logger process not found" -ForegroundColor DarkRed
                Start-ffmpeg $_.url $_.name $_.ext $_.storage
                Write-Host "There is" ((Get-Date -Date $triggerTime)-(Get-Date)) "before scheduled loggers re-launch.`n" -ForegroundColor DarkGray
            }
        }
    }
} while ($true)
exit


