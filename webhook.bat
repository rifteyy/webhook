@echo off
setlocal enabledelayedexpansion
  where curl.exe >nul 2>&1
    if !errorlevel! equ 1 (
        echo          ERROR: cURL is not installed
        echo You can download curl at https://curl.se/windows/
        exit /b 1
    ) else (
        set curl=curl.exe
)
call :removequotes %*

for %%a in ("" "--help" "-help" "help" "/help" "?" "usage" "-usage" "--usage") do (
	if /i "%%~a"=="!arg[1]!" call :help&exit /b 1
)
call :checksilent %*
if /i "%1"=="--import" (
	endlocal
	set "@webhook=call "%~f0""
	exit /b 0
)

if /i "%1"=="--message" (
	set "message=!arg[2]!"
	set "name=!arg[4]!"
	set "webhook=!arg[5]!"
	call :parse
	call :checkwebhook !arg[5]!
	if NOT "!respcode!"=="200" (echo ERROR: Invalid webhook&exit /b 1)
	for /f %%a in ('!curl! -w "%%{http_code}" --insecure -H "Content-Type: application/json" -d "{\"username\": \"!name!\", \"content\":\"!message!\"}" !webhook! -s -o /dev/null') do (
		if "!silent!"=="false" (
		if NOT "%%a"=="204" (echo ERROR: Response code %%a&exit /b 1) else (echo Sent message.&exit /b 0)
		)
		exit /b 0
	)	
)
if /i "%1"=="--check" (
	call :checkwebhook !arg[2]!
	if "!silent!"=="false" (
		if "!respcode!"=="200" (echo Webhook found&exit /b 0) else (echo Webhook not found&exit /b 1)
	) else (
	if "!respcode!"=="200" (exit /b 0) else (exit /b 1)
	)
)
if /i "%1"=="--info" (
	set "webhook=!arg[2]!"
	call :checkwebhook !webhook!
	if NOT "!respcode!"=="200" echo ERROR: Invalid webhook&exit /b 1
	2>nul >nul del /f /q "temp.json"
	!curl! --insecure --silent !arg[2]! -o "temp.json"
	for /f "delims=" %%q in (temp.json) do set "string=%%q"
	call :parseTempjson
	echo USERNAME=!name!
	echo ID=!id!
	echo AVATAR=!avatar!
	echo CHANNEL_ID=!channel_id!
	echo GUILD_ID=!guild_id!
	echo APP_ID=!application_id!
	echo WEBHOOK_TOKEN=!token!
	2>nul >nul del /f /q "temp.json"
	exit /b 0
)
if /i "%1"=="--delete" (
	set "webhook=!arg[2]!"
	call :checkwebhook !webhook!
	if NOT "!respcode!"=="200" echo ERROR: Invalid webhook&exit /b 1
	!curl! --silent -X "DELETE" !webhook!
	call :checkwebhook !webhook!
	if "!silent!"=="false" (
	if NOT "!respcode!"=="200" (echo Successfully deleted.&exit /b 0) else (echo Could not be deleted.&exit /b 1)
	)
	exit /b 0
)
if /i "%1"=="--embed" (
	2>nul >nul del /f /q "%~dp0data.json"
	set "message=!arg[2]!"
	set "name=!arg[4]!"
	set "webhook=!arg[5]!"
	call :checkwebhook !arg[5]!
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
	for /f %%a in ('!curl! --request POST --write-out "%%{http_code}" --silent --header "Content-Type: application/json" -d @data.json !arg[5]!') do set "responsecode=%%a"
	if "!silent!"=="false" (
	if "!responsecode!"=="204" (echo Successfully sent embed.& 2>nul >nul del /f /q "%~dp0data.json"&exit /b 0) else (echo ERROR: Embed could not be sent.&2>nul >nul del /f /q "%~dp0data.json"&exit /b 1)
	)
	del /f /q "%~dp0data.json" 2>nul >nul
	exit /b 0
)
if /i "%1"=="--file" (
	set "fullpath=!arg[2]!"
	set "name=!arg[4]!"
	set "webhook=!arg[5]!"
	call :parse
	call :checkwebhook !arg[5]!
	if NOT "!respcode!"=="200" echo ERROR: Invalid webhook&exit /b 1
	for /f %%a in ('!curl! -w "%%{http_code}" --output /dev/null -F "payload_json={\"username\": \"!name!\", \"content\": \" \"}" -F "file1=@!fullpath!" !webhook! -s -o /dev/null') do (
		if "!silent!"=="false" (
		if NOT "%%a"=="200" (echo ERROR: Response code %%a&exit /b 1) else (echo Sent file.&exit /b 0)
		)
		exit /b 0
	)	
)
if /i "%1"=="--url" (
	2>nul >nul del /f /q "%~dp0data.json"
	set "url=!arg[2]!"
	set "title=!arg[3]!"
	set "name=!arg[5]!"
	set "webhook=!arg[6]!"	
	call :parse
	call :checkwebhook !arg[6]!
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
	if "!silent!"=="false" (
	if "!responsecode!"=="204" (echo Successfully sent URL.&2>nul >nul del /f /q "%~dp0data.json"&exit /b 0) else (echo ERROR: URL could not be sent.&2>nul >nul del /f /q "%~dp0data.json"&exit /b 1)
	) else (
	del /f /q "%~dp0data.json" 2>nul >nul
	exit /b 0
	)
)
if /i "%1"=="--name" (
	set "message=!arg[4]!"
	call :parse
	call :checkwebhook !arg[2]!
	if NOT "!respcode!"=="200" echo ERROR: Invalid webhook&exit /b 1
	for /f %%a in ('!curl! -w "%%{http_code}" -H "Content-Type: application/json" -X PATCH -d "{\"name\": \"!message!\"}" !arg[2]! -s -o /dev/null') do (
		if "!silent!"=="false" (
		if NOT "%%a"=="200" (echo ERROR: Response code %%a&exit /b 1) else (echo Changed name of webhook to '!message!'&exit /b 0)
		)
	)
)
if "%1"=="--avatarmsg" (
	set "message=!arg[2]!"
	set "name=!arg[4]!"
	set "webhook=!arg[5]!"
	call :parse
	for /f %%a in ('!curl! -w "%%{http_code}" -k -H "Content-type: application/json" -X POST !webhook! -d "{\"avatar_url\":\"!arg[6]!\",\"content\":\"!message!\",\"username\":\"!name!\"}" -s -o /dev/null') do (
		if "!silent!"=="false" (
		if NOT "%%a"=="204" (echo ERROR: Response code %%a&exit /b 1) else (echo Sent message.&exit /b 0)
		)
	)	
)
if "%1"=="--avatar" (
		set "webhook=!arg[2]!"
		call :checkwebhook !webhook!
		if NOT "!respcode!"=="200" echo ERROR: Invalid webhook&exit /b 1
		2>nul >nul del /f /q "temp.json"
		!curl! --insecure --silent !arg[2]! -o "temp.json"
		for /f "delims=" %%q in (temp.json) do set "string=%%q"
		del /f /q "temp.json" 2>nul >nul
		call :parseTempjson
		if "!avatar!"=="null" (
			if "!silent!"=="false" (echo Webhook does not have avatar&exit /b 1) else (exit /b 1)
		) 

		if "!arg[3]!"=="--download" (
		if exist "%~dp0avatar.png" echo ERROR: avatar.png exists, please delete/rename and retry&exit /b 1
		!curl! --insecure --silent https://cdn.discordapp.com/avatars/!id!/!avatar!.png?size=1024 -o "avatar.png"
		if exist "avatar.png" (echo Avatar downloaded and saved as "avatar.png"&exit /b 0)  else (echo ERROR: File could not be downloaded&exit /b 1)
		) else (
		echo AVATAR_ID=!avatar!
		echo URL=https://cdn.discordapp.com/avatars/!id!/!avatar!.png?size=1024
		exit /b 0
	)
)

if /i "!arg[1]!"=="--image" (
	2>nul >nul del /f /q "%~dp0data.json"
	set "url=!arg[2]!"
	set "name=!arg[4]!"
	set "webhook=!arg[5]!"	
	call :parse
	call :checkwebhook !arg[5]!
	if NOT "!respcode!"=="200" echo ERROR: Invalid webhook&exit /b 1
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
	if "!silent!"=="false" (
		if NOT "!responsecode!"=="204" (
		echo ERROR: Image could not be sent.
		2>nul >nul del /f /q "%~dp0data.json"
		exit /b 1
		) else (
		echo Successfully sent image.
		2>nul >nul del /f /q "%~dp0data.json"
		exit /b 0
	)
	2>nul >nul del /f /q "%~dp0data.json"
	exit /b 0
	)
)
if /i "!arg[1]!"=="--mention" (
	set "message1=!arg[3]!"
	set "id=!arg[4]!"
	set "message2=!arg[5]!
	set "name=!arg[6]!"
	if "!arg[7]!"=="--role" (
		set "id=^^<@^^&!id!^^>"
)
	if "!arg[7]!"=="--user" (
		set "id=^^<@!id!^^>"
)
	call :checkwebhook !arg[2]!
	if NOT "!respcode!"=="200" echo ERROR: Invalid webhook&exit /b 1
	for /f %%a in ('!curl! -w "%%{http_code}" --insecure -H "Content-Type: application/json" -d "{\"username\": \"!name!\", \"content\":\"!message1! !id! !message2!\"}" !arg[2]! -s -o /dev/null') do (
		if "!silent!"=="false" (
		if NOT "%%a"=="204" (echo ERROR: Response code %%a&exit /b 1) else (echo Sent message.&exit /b 0)
		)
	)
)


:help
echo.
echo WEBHOOK.BAT # Library for executing Discord Webhooks without authorization made in Batch file
echo.
echo Commands:
echo  --help^|?^|-help^|/help                                           # View this help page
echo  --message   "content" --username "username" webhook             # Send message
echo  --avatarmsg "content" --username "username" webhook avatarlink  # Send message with an avatar on link
echo  --check     webhook                                             # Check if webhook exists, sets errorlevel ^(0^|1^)
echo  --info      webhook                                             # Get webhook information
echo  --avatar    webhook ^<--download^>                                # Gets URL of avatar ^<downloads as avatar.png^>
echo  --delete    webhook                                             # Delete webhook
echo  --embed     "content" --username "username" webhook             # Send embed to a webhook
echo  --url       "url" "title" --username "username" webhook         # Send URL embed to a webhook
echo  --image     "url" --username "username" webhook                 # Send image embed to a webhook
echo  --file      "fullpath"--username "username" webhook             # Upload a file to a webhook
echo  --name      webhook --username "username"                       # Change username of a webhook
echo  --mention   webhook "message" ^<user_id/role_id^> "message"       # Mention user/role ^(continue on next line^)
echo              "username" ^<--role/--user^>                          #
echo  --silent    ^<arguments^|commands^> --silent                       # Perform commands silently, type behind command
echo.
echo Examples:
echo  call %~nx0 --message "Hello World\nNext line test\nAnother line" --username "Test Webhook" https://discord.com/api/webhooks/*
echo  call %~nx0 --avatarmsg "Hello" --username "Avatar Bot" https://discord.com/api/webhooks/* https://i.imgur.com/oBPXx0D.png
echo  call %~nx0 --check  https://discord.com/api/webhooks/*
echo  call %~nx0 --info   https://discord.com/api/webhooks/*
echo  call %~nx0 --delete https://discord.com/api/webhooks/*
echo  call %~nx0 --avatar https://discord.com/api/webhooks/*
echo  call %~nx0 --avatar https://discord.com/api/webhooks/* --download
echo  call %~nx0 --embed "Embed test" --username "Embed Webhook Test" https://discord.com/api/webhooks/*
echo  call %~nx0 --file "%windir%\System32\cmd.exe" --username "File Webhook Test" https://discord.com/api/webhooks/*
echo  call %~nx0 --url "https://google.com" "Click here" --username "Test URL" https://discord.com/api/webhooks/*
echo  call %~nx0 --image "https://i.imgur.com/ZGPxFN2.jpg" --username "Image Test" https://discord.com/api/webhooks/*
echo  call %~nx0 --name https://discord.com/api/webhooks/* --username "Changed username"
echo  call %~nx0 --mention https://discord.com/api/webhooks/* "Hey" user_id ", how are you?" "Cutie pie" --user
echo  call %~nx0 --mention https://discord.com/api/webhooks/* "Hey" role_id ", how are you?" "Cutie pie" --role
echo  call %~nx0 --message "Hello World" --username "Test Webhook" https://discord.com/api/webhooks/* --silent
echo  call %~nx0 --delete https://discord.com/api/webhooks/* --silent
echo.
echo      NOTE: This utility is not made by official authors of Discord
echo        If you would like to learn more about Discord API's, visit
echo          https://discord.com/developers/docs/resources/webhook
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

:checksilent
echo %* | findstr /C:"--silent">nul && (
	set silent=true
	) || (
	set silent=false
	)
exit /b 0

:removequotes
set "arg[1]=%1"
set "arg[2]=%2"
set "arg[3]=%3"
set "arg[4]=%4"
set "arg[5]=%5"
set "arg[6]=%6"
set "arg[7]=%7"
set "arg[8]=%8"
set "arg[9]=%9"
if defined arg[1] set "arg[1]=%arg[1]:"=%"
if defined arg[2] set "arg[2]=%arg[2]:"=%"
if defined arg[3] set "arg[3]=%arg[3]:"=%"
if defined arg[4] set "arg[4]=%arg[4]:"=%"
if defined arg[5] set "arg[5]=%arg[5]:"=%"
if defined arg[6] set "arg[6]=%arg[6]:"=%"
if defined arg[7] set "arg[7]=%arg[7]:"=%"
if defined arg[8] set "arg[8]=%arg[8]:"=%"
if defined arg[9] set "arg[9]=%arg[9]:"=%"
exit /b 0
