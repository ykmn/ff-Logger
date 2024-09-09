# ff-Logger

![PowerShell](https://img.shields.io/badge/PowerShell-%235391FE.svg?style=for-the-badge&logo=powershell&logoColor=white)
[![Licence](https://img.shields.io/github/license/ykmn/ff-Logger?style=for-the-badge)](./LICENSE)
![Microsoft Windows](https://img.shields.io/badge/Microsoft-Windows-%FF5F91FF.svg?style=for-the-badge&logo=Microsoft%20Windows&logoColor=white)


Логгер нескольких веб-аудиопотоков с функцией watchdog.

## Использование:

В файле `ff-Logger.ps1` необходимо в массив `$stations` в нужном количестве внести параметры подключения:

```
$stations = @(
@{ name = 'Autoradio Moscow';  url = 'https://pub0202.101.ru:8000/stream/air/aac/64/100';          ext = 'aac'; storage = 'D:\STORAGE' },
@{ name = 'Radio JAZZ';        url = 'https://nashe1.hostingradio.ru:80/jazz-128.mp3';             ext = 'mp3'; storage = 'D:\STORAGE' },
@{ name = 'Monte Carlo';       url = 'https://montecarlo.hostingradio.ru/montecarlo96.aacp';       ext = 'aac'; storage = 'D:\STORAGE' }
);
```

* `url=` ссылка на аудиопоток

* `station=` название потока, используется при создании папки.
Если хотите использовать название с пробелами, заключите его в кавычки.

* `ext=` расширение сохраняемых файлов. Желательно использовать тип файла соответствующий потоку,
т.е. mp3 для Icecast/mp3, aac для Icecast/aac, aac для HLS и т.д.

* `storage=` путь к папке, где будут сохраняться записанные файлы. В ней автоматически
будет создана папка с названием `name`, в которую будут сохраняться аудиофайлы
в формате `15-00-00.aac` (часы-минуты-секунды)

Обратите внимание, что в последнем элементе массива запятая после закрывающей фигурной скобки не нужна.


### Важные особенности

* Скрипт должен запускаться в PowerShell Core (который не встроенный в Windows, а "новый"). Его можно установить командой `winget install Microsoft.Powershell`
или скачать и установить с [https://github.com/PowerShell/PowerShell/releases](https://github.com/PowerShell/PowerShell/releases)

* Для работы требуется ffmpeg. Его можно установить командой `winget install Gyan.FFmpeg`
или скачать и установить с [https://www.ffmpeg.org/download.html#build-windows](https://www.ffmpeg.org/download.html#build-windows)
Исполняемый файл должен быть доступен в `PATH`.

* Скрипт назначает на каждое окно ffmpeg кастомный заголовок окна, по которому отслеживает запущен ли процесс.
Если окно с таким заголовком не найдено, процесс записи с ffmpeg запускается заново.

* Поскольку в ffmpeg не предусмотрено обновление переменных даты-времени "на лету", для того чтобы с наступлением новых суток
ffmpeg начал сохранять файлы в новую папку, его необходимо перезапустить. Время перезапуска указано
в `$triggerTime = "00:00:00am"`, т.е. ровно в полночь. Посольку за перезапуск требуется небольшое время, в записях будет короткий разрыв.

* Новый аудиофайл создаётся каждые 10 минут (задаётся в ` -segment_time 00:10:00` )

* ffmpeg запускается с уровнем отображения ` -v warning `, поэтому в нормальном режиме работы в окне будет только одна строчка со статистикой.
Если необходимо более подробное отображение состояния ffmpeg, замените на ` -v info ` или ` -v verbose ` .


## История версий:
* 2024-09-09 - v1.00 Начальная версия
