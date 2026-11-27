# NetCalc

Небольшое WinForms-приложение для Windows 11, которое вычисляет количество доступных IPv4-хостов по адресу и префиксу CIDR.

## Запуск из исходников

Требуется .NET 8 SDK:

```powershell
dotnet run --project .\NetCalc.csproj
```

В поле маски можно вводить префикс с косой чертой (`/24`) или без нее (`24`). Для обычных подсетей `/0`–`/30` количество доступных хостов не включает адрес сети и broadcast. Для `/31` учитываются оба адреса point-to-point-подсети, а `/32` содержит один адрес.

## Сборка и публикация

Release-сборка:

```powershell
dotnet build .\NetCalc.csproj -c Release
```

Для публикации под Windows x64 с зависимостью от установленного .NET 8 Desktop Runtime:

```powershell
dotnet publish .\NetCalc.csproj -c Release -r win-x64 --self-contained false
```

Файлы появятся в `.\bin\Release\net8.0-windows\win-x64\publish\`.

## Релиз через GitHub Actions

Workflow `.github/workflows/netcalc-release.yml` запускается только при отправке тега формата `netcalc/vX.Y.Z`. Например, чтобы выпустить версию `1.2.3`:

```powershell
git tag -a netcalc/v1.2.3 -m "NetCalc 1.2.3"
git push origin netcalc/v1.2.3
```

GitHub Actions соберет приложение и создаст GitHub Release с архивом `NetCalc-1.2.3-unsigned-win-x64.zip`. Архив содержит framework-dependent публикацию: для запуска нужен .NET 8 Desktop Runtime. Приложение не подписано; Smart App Control может его заблокировать.

Также workflow прикладывает `NetCalc-1.2.3-source.zip` только с отслеживаемыми Git файлами из `localtools/netcalc`. Автоматические ссылки GitHub **Source code (zip/tar.gz)** по-прежнему содержат весь репозиторий — изменить их состав нельзя.

## Подпись для Smart App Control

Чтобы приложение могло пройти Smart App Control, подпишите его действительным сертификатом для подписи кода от доверенного издателя, цепочка которого ведет к центру сертификации из Microsoft Trusted Root Program. Самоподписанный сертификат для этого не подходит. Подробности и альтернативы распространения описаны в документации Microsoft: [подпись для Smart App Control](https://learn.microsoft.com/en-us/windows/apps/develop/smart-app-control/code-signing-for-smart-app-control) и [варианты подписи приложений](https://learn.microsoft.com/en-us/windows/apps/package-and-deploy/code-signing-options).

Пример для сертификата, доступного в личном хранилище Windows (`CurrentUser\My`), и `signtool.exe` из Windows SDK. Заполните отпечаток сертификата и URL RFC 3161-службы штамповки, предоставленные издателем сертификата:

```powershell
$publish = ".\bin\Release\net8.0-windows\win-x64\publish"
$thumbprint = "<отпечаток сертификата>"
$timestampUrl = "<URL RFC 3161 от издателя сертификата>"

foreach ($file in @("$publish\NetCalc.exe", "$publish\NetCalc.dll")) {
    signtool sign /fd SHA256 /tr $timestampUrl /td SHA256 /sha1 $thumbprint $file
    if ($LASTEXITCODE -ne 0) {
        throw "Не удалось подписать файл: $file"
    }

    signtool verify /pa /v $file
    if ($LASTEXITCODE -ne 0) {
        throw "Не удалось проверить подпись файла: $file"
    }
}
```

Подписывайте готовые файлы после публикации и не изменяйте их после подписания. Для новых подписанных приложений SmartScreen все еще может показывать предупреждение, пока издатель или файл не наберет репутацию. Если программа нужна только на этом компьютере с отключенным Smart App Control, покупать сертификат для нее не требуется.
