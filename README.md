# ff-Logger

![PowerShell](https://img.shields.io/badge/PowerShell-%235391FE.svg?style=for-the-badge&logo=powershell&logoColor=white)
[![Licence](https://img.shields.io/github/license/ykmn/ff-Logger?style=for-the-badge)](./LICENSE)
![Microsoft Windows](https://img.shields.io/badge/Microsoft-Windows-%FF5F91FF.svg?style=for-the-badge&logo=Microsoft%20Windows&logoColor=white)

> 2024.09.10 Roman Ermakov <r.ermakov@emg.fm>

Audio-logger with watchdog: record multiple web audio streams and/or sound from sound card inputs.

[[RU]](./readme-ru.md)

## Usage:
The set of recording channels is stored in the `stations.json` file.
Sample data in the `stations-demo.json` file :

```json
[
    {
        "name":"Audio Input 1",
        "url":"@device_cm_{33D9A762-90C8-11D0-BD43-00A0C911CE86}\\wave_{F84408DF-9C57-4C98-A66F-FBCC9EA194DD}",
        "ext":"mp3",
        "storage":"D:\\STORAGE",
        "bitrate":"64K"       
    },
    {
        "name":"Megapolis",
        "url":"https://megapolisfm.hostingradio.ru/megapolisfm96.aacp",
        "ext":"aac",
        "storage":"D:\\STORAGE"   
    },
    {
        "name":"Autoradio Moscow",
        "url":"https://pub0202.101.ru:8000/stream/air/aac/64/100",
        "ext":"mp3",
        "storage":"D:\\STORAGE",
        "bitrate":"96K"
    },
    {
        "name":"Radio JAZZ",
        "url":"https://nashe1.hostingradio.ru:80/jazz-128.mp3",
        "ext":"mp3",
        "storage":"D:\\STORAGE"   
    },
    {
        "name":"Monte Carlo",
        "url":"https://montecarlo.hostingradio.ru/montecarlo96.aacp",
        "ext":"aac",
        "storage":"D:\\STORAGE"   
    }
]
```

* `url` stream link or audio device name. You can get audio device name with
`ffmpeg -list_devices true -f dshow -i dummy`

* `name` recording channel name, used as subfolder name.
If you want to use spaces in channel name, put it in quotes (spaces will be replaced
to dashes).

* `ext` extension and type of recorded files.

    * For an Internet stream, it is advisable to use a file type that matches
the stream, i.e. mp3 for Icecast/mp3, aac for Icecast/aacp or HLS. In this case,
there will be no additional transcoding, and the stream will be saved to files as is.
If transcoding is required, specify a different extension **and** bitrate
(for example, to save an AAC stream to MP3, you can specify `ext='mp3'; bitrate='128K'`)

    * For the audio device, you can select 'mp3' or 'aac' and specify the required
bitrate (see below); also you can select 'wav', in this case the audio files
will be saved in PCM:44100/16/Stereo.

* `storage` the path to the folder where the recorded files will be stored.
A folder named `name` and folders as `2024-08-31` will be created inside.
Audio files will be saved as `15-00-00.aac` (hours-minutes-seconds)

* `bitrate` the bitrate in kbps (16K, 32K, 64K ... 320K).

    * **Must be specified** for the audio device input and mp3-aac formats.
However do not specify bitrate, if the audio input needs to be recorded as WAV/PCM.

    * **May be specified** for an Internet stream, if stream needs to be transcoded.
By default, web streams are saving in the format and with the bitrate of the stream.

Please note the double backslashes `\\` instead of the usual single backslash `\`
in paths and in audio devices. Single forward slashes `/` are ok.


### Important features

* The script must be run in PowerShell 7 (not built into Windows). It can be
installed with the command `winget install Microsoft.Powershell` or downloaded and installed from
[https://github.com/PowerShell/PowerShell/releases](https://github.com/PowerShell/PowerShell/releases)

* ffmpeg 7.0.2 or newer is required. It can be installed with the command
`winget install Gyan.FFmpeg` or downloaded and installed from
[https://www.ffmpeg.org/download.html#build-windows](https://www.ffmpeg.org/download.html#build-windows)
The executable file must be available in `PATH`.

* The script assigns a custom window title to each ffmpeg window, by which the script
tracks whether the process is running. If a window with this title isn't found,
the ffmpeg recording process is restarted.

* A new audio file is created every 10 minutes (specified in ` -segment_time 00:10:00` )

* ffmpeg starts with the display level ` -v warning `: in normal operation mode, the window
will only show one line statistics. For more detailed display of the ffmpeg status, replace it with ` -v info `
or ` -v verbose ` .

## Version history:
* 2024-09-06 - v1.00 Initial release.
* 2024-09-09 - v1.01 Added the option to record the sound card audio input.
* 2024-09-10 - v1.02 Parameters have been moved to the configuration file; added a progress bar for logger restart time.
* 2024-09-16 - v1.03 Process restart function was removed.
