@echo off
setlocal enabledelayedexpansion
where curl.exe 2>nul >nul
if %errorlevel%==0 (
for /f %%a in ('where curl.exe') do set "curl=%%a"
) else (
echo ERROR: cURL.exe not found.
echo Please download the application and try again.
exit /b 1
)
if /i "%1"=="" call :help&exit /b 1
if /i "%1"=="--help" call :help&exit /b 1
if /i "%1"=="--sendmsg" (
	set "message=%2"
	set "name=%4"
	set "webhook=%5"
	call :parse
	call :checkwebhook %5
	if NOT "!respcode!"=="200" (echo ERROR: Invalid webhook&exit /b 1)
	!curl! --silent --insecure -H "Content-Type: application/json" -d "{\"username\": \"!name!\", \"content\":\"!message!\"}" !webhook!
	if not errorlevel 0 (echo ERROR: Errorlevel different than 0.) else (echo Successfully sent message.)
	exit /b 0
)
if /i "%1"=="--check" (
	call :checkwebhook %2
	if "!respcode!"=="200" (exit /b 0) else (exit /b 1)
)
if /i "%1"=="--info" (
	2>nul >nul del /f /q "temp.json"
	!curl! --insecure --silent %2 -o "temp.json"
	for /f "delims=" %%q in (temp.json) do set "string=%%q"
	call :parseTempjson
	echo Username     !name!
	echo Channel ID   !channel_id!
	echo Guild ID     !guild_id!
	echo App ID       !application_id!
	echo Guild Token  !token!
	exit /b 0
)
if /i "%1"=="--delete" (
	set "webhook=%2"
	call :checkwebhook !webhook!
	if NOT "!respcode!"=="200" echo ERROR: Invalid webhook&exit /b 1
	!curl! --silent -X "DELETE" !webhook!
	call :checkwebhook !webhook!
	if NOT "!respcode!"=="200" (echo Successfully deleted.&exit /b 0) else (echo Could not be deleted.&exit /b 1)
)

if /i "%1"=="--embed" (
	2>nul >nul del /f /q "%~dp0data.json"
	set "message=%2"
	set "name=%4"
	set "webhook=%5"
	call :checkwebhook %5
	if NOT "!respcode!"=="200" echo ERROR: Invalid webhook&exit /b 1
	call :parse
	(
		echo {
		echo "username": "!name!",
		echo   "embeds": [{
		echo     "title": "",
		echo     "description": "!message!"
		echo   }]
		echo }
	) >> "%~dp0data.json"
	for /f %%a in ('!curl! --request POST --write-out "%%{http_code}" --silent --header "Content-Type: application/json" -d @data.json %5') do set "responsecode=%%a"
	if "!responsecode!"=="204" (echo Successfully sent embed.& 2>nul >nul del /f /q "%~dp0data.json"&exit /b 0) else (echo ERROR: Embed could not be sent.&2>nul >nul del /f /q "%~dp0data.json"&exit /b 1)
)
if /i "%1"=="--file" (
	set "fullpath=%2"
	set "name=%4"
	set "webhook=%5"
	call :parse
	call :checkwebhook %5
	if NOT "!respcode!"=="200" echo ERROR: Invalid webhook&exit /b 1
	!curl! ^
	--silent --output /dev/null ^
  	-F "payload_json={\"username\": \"!name!\", \"content\": \" \"}" ^
  	-F "file1=@!fullpath!" ^
	!webhook!
	if not errorlevel 0 (echo ERROR: Errorlevel different than 0.) else (echo Successfully sent file.)
	exit /b 0
)
if /i "%1"=="--url" (
	2>nul >nul del /f /q "%~dp0data.json"
	set "url=%2"
	set "title=%3"
	set "name=%5"
	set "webhook=%6"	
	call :parse
	call :checkwebhook %6
	if NOT "!respcode!"=="200" echo ERROR: Invalid webhook&exit /b 1
	(
		echo {
		echo   "embeds": [{
		echo     "title": "!title!",
		echo     "url": "!url!"
		echo  }]
		echo }
	) >> "%~dp0data.json"
	for /f %%a in ('!curl! --request POST --write-out "%%{http_code}" --silent --header "Content-Type: application/json" -d @data.json !webhook!') do set "responsecode=%%a"
	if "!responsecode!"=="204" (echo Successfully sent URL.&2>nul >nul del /f /q "%~dp0data.json"&exit /b 0) else (echo ERROR: URL could not be sent.&2>nul >nul del /f /q "%~dp0data.json"&exit /b 1)
)
if /i "%1"=="--image" (
	2>nul >nul del /f /q "%~dp0data.json"
	set "url=%2"
	set "name=%4"
	set "webhook=%5"	
	call :parse
	call :checkwebhook %5
	if NOT "!respcode!"=="200" (
	echo ERROR: Invalid webhook 
	exit /b 1
	)
	(
		echo {
		echo   "embeds": [{
		echo     "image": {
		echo       "url": "https://i.imgur.com/ZGPxFN2.jpg"
		echo     }
		echo   }]
		echo }
	) >> "%~dp0data.json"

	for /f %%a in ('!curl! --request POST --write-out "%%{http_code}" --silent --header "Content-Type: application/json" -d @data.json !webhook!') do set "responsecode=%%a"
	if NOT "!responsecode!"=="204" (
	echo ERROR: Image could not be sent.
	2>nul >nul del /f /q "%~dp0data.json"
	exit /b 1
	) else (
	echo Successfully sent image.
	2>nul >nul del /f /q "%~dp0data.json"
	exit /b 0
)

:help
echo.
echo WEBHOOK.BAT # Library for using Discord webhooks easily
echo.
echo Commands:
echo --help                                                     # View this help page
echo --sendmsg "content" --username "username" webhook          # Send message
echo --check   webhook                                          # Check if webhook exists, sets errorlevel ^(0^|1^)
echo --info    webhook                                          # Get webhook information
echo --delete  webhook                                          # Delete webhook
echo --embed   "content" --username "username" webhook          # Send embed to a webhook
echo --file    "fullpath"--username "username" webhook          # Upload a file to a webhook
echo --url     "url" "title" --username "username" webhook      # Send URL embed to a webhook
echo --image   "url" --username "username" webhook              # Send image embed to a webhook
echo.
echo Examples:
echo call %~nx0 --sendmsg "Hello World" --username "Test Webhook" https://discord.com/api/webhooks/*
echo call %~nx0 --check  https://discord.com/api/webhooks/*
echo call %~nx0 --info   https://discord.com/api/webhooks/*
echo call %~nx0 --delete https://discord.com/api/webhooks/*
echo call %~nx0 --embed "Embed test" --username "Embed Webhook Test" https://discord.com/api/webhooks/*
echo call %~nx0 --file "%windir%\System32\cmd.exe" --username "File Webhook Test" https://discord.com/api/webhooks/*
echo call %~nx0 --url "https://google.com" "Click here" --username "Test URL" https://discord.com/api/webhooks/*
echo call %~nx0 --image "https://i.imgur.com/ZGPxFN2.jpg" --username "Image Test" https://discord.com/api/webhooks/*
echo.
echo      NOTE: This utility is not made by official authors of Discord
echo        If you would like to learn more about Discord API's, visit
echo            https://birdie0.github.io/discord-webhooks-guide/

exit /b 0

:checkwebhook
for /f %%a in ('!curl! -o /dev/null -s -w "%%{http_code}\n" %1') do set respcode=%%a
exit /b 0

:parse
set "message=%message:"=%"
set "name=%name:"=%"
set "url=%url:"=%"
set "title=%title:"=%"
exit /b 0

:parseTempjson
set string=%string:"=%
set "string=%string:~2,-2%"
set "string=%string:: ==%"
set "%string:, =" & set "%"
exit /b 0
