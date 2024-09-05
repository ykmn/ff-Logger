@echo off
cd /d "%~dp0"
echo [93m*   ff-Logger.bat[0m v1.00 2024-09-05 Roman Ermakov r.ermakov@emg.fm
echo Simple ffmpeg Logger for web-streams.
if "%1" neq "" goto:logger
echo.
::                               %1      %2          %3          %4
echo [93mUsage:[0m ff-Logger [url] ["station"] ["storage"] [filetype] 
echo All parameters are manadatory. If you have spaces in station name please "use quotes"!
echo You need ffmpeg.exe to be available on the PATH. Use winget install ffmpeg if you haven't.
echo.
echo [93mExample:[0m
echo ff-Logger https://webradio.com:8000/stream "My Radio" "D:\STORAGE" m4a
echo.
goto:eof

:logger
:: strip quotes on station name
set STATION=%2
set STATION=%STATION:"=%

:: check log folder
if not exist "LOG\%STATION%\." mkdir "LOG\%STATION%"
echo [93m* Purging logs older than 30 days[0m
forfiles /p "LOG" /s /d -30 /c "cmd /c del @file" > nul
echo [93m* Done.[0m

:: create storage folder
if not exist "%3\%STATION%\." mkdir "%3\%STATION%"

:loop
echo.
echo [92m* Running logger for %STATION% in separate window [0m

:: parsing standard russian date 
set YEAR=%DATE:~-4%
set MONTH=%DATE:~3,2%
if "%MONTH:~0,1%" == " " set MONTH=0%MONTH:~1,1%
set DAY=%DATE:~0,2%
if "%DAY:~0,1%" == " " set DAY=0%DAY:~1,1%
set HOUR=%TIME:~0,2%
if "%HOUR:~0,1%" == " " set HOUR=0%HOUR:~1,1%
set MINS=%TIME:~3,2%
set SECS=%TIME:~6,2%

set OUTPUT="%3\%STATION%\%%H-%%M.%4"
set FFREPORT=file=log/%STATION%/ff.%STATION%.%YEAR%%MONTH%%DAY%-%HOUR%%MINS%%SECS%.log:level=24
:: set FFREPORT=file=ffreport.log:level=24
:: Log levels are:
:: quiet: -8, panic: 0, fatal: 8, error: 16, warning: 24, info: 32, verbose: 40, debug: 48, trace: 56

start "%STATION% Logger" /wait ffmpeg.exe -i %1 -c:a copy -f segment -segment_time 00:10:00 -strftime 1 -reset_timestamps 1 -v "error" -stats -loglevel "info" %OUTPUT%


pause
echo [91m* %YEAR%.%MONTH%.%DAY% %TIME% Watchdog is restarting %STATION% logger in 3 seconds. [0m
choice /t 3 /c yq /CS /D y /M "Press y to continue, q to cancel:"
if %ERRORLEVEL% neq 1 ( exit ) else ( goto:loop )
exit
