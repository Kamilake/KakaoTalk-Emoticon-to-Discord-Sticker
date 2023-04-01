@echo off
chcp 65001
setlocal EnableDelayedExpansion
@REM goto :STEP2_END
@REM FINAL_DELAY=다음 프레임을 반복하기 전 대기할 시간(초), 0.0이면 바로 다음 프레임을 반복. 일반적으로 0.5
set FINAL_DELAY=0.0
@REM FPS=대부분 10인데 특수한 경우에는 12fps
set FPS=10
@REM CHOCO=1이면 Chocolatey를 사용하여 의존성을 자동으로 설치
set IS_CHOCO=0
@REM CHOCO=1이면 Chocolatey 설치 여부를 검사함
set CHOCO_CHECK=1

if %CHOCO_CHECK% == 1 (
  choco --version > nul 2>&1
  if errorlevel 0 (
    echo Chocolatey가 설치되어 있음을 확인하였습니다.
    echo 의존성 미설치를 확인하였을 때 자동 설치를 시도합니다.
    echo.
    if not "%1"=="am_admin" (
      echo Chocolatey를 사용하기 위해 관리자 권한를 요청합니다.
      powershell -Command "Start-Process -Verb RunAs -FilePath '%0' -ArgumentList 'am_admin'"
      exit /b
      echo.
    ) else (
      echo 관리자 권한이 확인 되었습니다.
      echo 패키지 관리자를 사용하여 의존성을 설치합니다.
      set IS_CHOCO=1
      echo.
    )
  )
)

if not exist "pngquant.exe" (
  if %IS_CHOCO% == 1 (
    echo pngquant 설치 시도 중...
    choco install pngquant -y > nul 2>&1
    if errorlevel 1 (
      echo Chocolatey를 사용한 설치에 실패했습니다.
      echo https://pngquant.org/ 에서 pngquant를 다운로드해 시스템에 설치하거나 %0 파일과 나란히 옆에 둬 주세요.
      pause
      exit
    )
    echo pngquant 설치가 완료되었습니다.
  ) else (
    echo pngquant가 설치되어 있지 않습니다.
    echo https://pngquant.org/ 에서 pngquant를 다운로드해 시스템에 설치하거나 %0 파일과 나란히 옆에 둬 주세요.
    pause
    exit
  )
)

ffmpeg -version > nul 2>&1
if errorlevel 1 (
  if %IS_CHOCO% == 1 (
    echo ffmpeg 설치 시도 중...
    choco install ffmpeg -y > nul 2>&1
    if errorlevel 1 (
      echo Chocolatey를 사용한 설치에 실패했습니다.
      echo https://ffmpeg.org/ 에서 ffmpeg를 설치해주세요.
      pause
      exit
    )
    echo ffmpeg 설치가 완료되었습니다.
  ) else (
    echo ffmpeg가 설치되어 있지 않습니다.
    echo https://ffmpeg.org/ 에서 ffmpeg를 설치해주세요.
    pause
    exit
  )
)

magick -version > nul 2>&1
if errorlevel 1 (
  if %IS_CHOCO% == 1 (
    echo ImageMagick 설치 시도 중...
    choco install ImageMagick -y > nul 2>&1
    if errorlevel 1 (
      echo Chocolatey를 사용한 설치에 실패했습니다.
      echo https://imagemagick.org/script/download.php 에서 ImageMagick을 설치해주세요.
      pause
      exit
    )
    echo ImageMagick 설치가 완료되었습니다.
  ) else (ㅛ
    echo ImageMagick이 설치되어 있지 않습니다.
    echo https://imagemagick.org/script/download.php 에서 ImageMagick을 설치해주세요.
    pause
    exit
  )
)

:INTRO
echo .
echo 이 스크립트는 카카오톡 이모티콘을 캡처해서 Discord 스티커에서 쓰이는 apng로 변환합니다.

echo 1) 새로운 이모티콘 녹화
echo 2) 기존 녹화 재사용 (기본값)

set /p CHOICE=번호를 입력하세요:
if "%CHOICE%" == "1" goto :PRE_Record
if "%CHOICE%" == "2" goto :STEP1
if "%CHOICE%" == "" goto :INTRO

:PRE_Record
echo ==== 사용방법 ====
echo .
echo 1. 카카오톡 HiDPI를 200%로 설정
echo 2. 그룹채팅방을 만들고 이름을 %%TEMP로 설정
echo 3. 그룹채팅방 배경을 #383c44로 지정 (Discord의 배경색을 캡처하세요.)
echo 4. 그룹채팅방 크기를 가장 줄여주세요.
echo 5. 이모티콘 선택 창에서 이모티콘을 한 번 눌러 텍스트 입력창 바로 위에 미리보기가 보이는 상태로 둬 주세요.
echo 6. 이모티콘 선택 창을 열어둔 상태로 기다려서 이모티콘이 움직이지 않게 해 주세요.
echo 7. 이제 엔터를 누르면 10초간 녹화가 시작됩니다. 녹화가 시작되고 바로(3초 이내) 이모티콘 전송 버튼을 누른 다음 녹화가 멈출 때까지 기다려 주세요.
echo .
echo 10초간 녹화를 시작하려면 엔터를 누르세요...
pause > nul
ffmpeg.exe -y -f dshow -f gdigrab -draw_mouse 0 -t 00:00:10 -i title="%%TEMP" -framerate 30 -vcodec libx264 -crf 0 -preset ultrafast output.mkv
if errorlevel 1 (
  echo 녹화에 실패했습니다. 다시 시도해주세요.
  goto :PRE_Record
)
echo 녹화가 완료되었습니다. 이제 창을 닫거나 만져도 됩니다.
pause


:STEP1
rmdir tmp1 /s /q
mkdir tmp1
ffmpeg -i .\output.mkv -pred mixed -vf "mpdecimate,setpts=N/FRAME_RATE/TB" -ss 00:00:00.6 ./tmp1/output%%03d.png

rem mkdir tmp2
rem ffmpeg -i ./tmp1/output%03d.png -pred mixed -filter_complex "[0:v]scale=iw*0.68:-1[resized];[resized]crop=250:250:105*0.68:445*0.68[cropped];[cropped]mpdecimate[decimated];[decimated]setpts=N/FRAME_RATE/TB[setpts]" -map "[setpts]" ./tmp2/output%03d.png

:STEP2
rmdir tmp2 /s /q
mkdir tmp2
ffmpeg -i ./tmp1/output%%03d.png -pred mixed -filter_complex "[0:v]scale=iw*1.00:-1[resized];[resized]crop=240:240:417:366[cropped];[cropped]mpdecimate[decimated];[decimated]setpts=N/FRAME_RATE/TB[setpts]" -map "[setpts]" ./tmp2/output%%03d.png
echo 이미지를 프래임으로 잘랐습니다.
set /p FINAL_DELAY=5.1. 필요하다면 마지막 프레임 이후 딜레이를 설정하세요. 이모티콘의 움직임이 끝나면서 가만히 멈춰 있는 장면이 있다면, 그 시간을 입력해주세요. 모르겠다면 그냥 엔터를 눌러주세요. (기본값: 0초, 카카오톡: 0.7초 0.0이면 바로 다음 프레임을 반복):
echo 이제 반복 구간을 찾아야 하는데, 자동으로 반복 구간을 찾을까요? (y/n)
set /p auto_deleter=
if "%auto_deleter%" == "y" (
  goto :START_AUTO_DELETER
)
echo tmp2 폴더를 열어서 파일을 정리하세요.
echo 이모티콘이 반복되는 부분은 삭제하세요.
echo 예를 들어 첫 이미지인 output001.png과 뒤에 있는 output005.png가 같다면 output005.png 뒤부터 전부 삭제하면 됩니다.
echo output001.png가 올바르지 않은 사진이라면 output001도 삭제해도 됩니다.
echo 반복되는 한 구간(너무 짧다면 두 구간)까지만 남겨두면 됩니다.
echo 삭제가 끝나면 아무 키나 누르세요.
pause
:STEP2_END
goto END_AUTO_DELETER
:START_AUTO_DELETER
set /a iter=1
set del_flag=0
for /F "delims= " %%i in ('magick identify -format ^"%%# %%%f\n^" tmp2\*.png') do (
  set "iter_pad=00!iter!"
  set hash=%%i
  set filename=output!iter_pad:~-3!.png
  if "!iter!" == "1" (
    set "fisrt_hash=!hash!"
  ) else (
    if "!hash!" == "!fisrt_hash!" (
      echo output001.png == !filename!
      set del_flag=1
    )
  )
  if "!del_flag!" == "1" (
    del tmp2\!filename!
  )


  set /a iter=!iter!+1
)
echo 반복 구간을 자동으로 찾았습니다.
pause
:END_AUTO_DELETER


setlocal EnableDelayedExpansion
set /a qualitymax=100
:STEP3
rmdir tmp3 /s /q
mkdir tmp3

set /a i=0
set /a qualitymin=!qualitymax!-20

FOR /R tmp2 %%X IN (*.png) DO (
  set /a i=!i!+1
  echo !i!
  SET PADDED=0!i!
  SET PADDED=!PADDED:~-2!
  pngquant.exe --force --verbose --speed=1 --quality=!qualitymin!-!qualitymax! -o ./tmp3/output!PADDED!.png "%%X"
  @REM optipng !qualitymax! -o ./tmp3/output!i!.png "%%X"
  @REM .\optipng.exe -o7 output12.png -out aa.png
  )
:STEP3_END


:STEP4
@REM goto STEP4_METHOD2
goto STEP4_METHOD1
:STEP4_METHOD1
set /a i=0
rmdir /S /Q tmp4
mkdir tmp4
FOR /R tmp3 %%X IN (*.png) DO (
  set /a i=!i!+1
  echo !i!
  @REM pngquant.exe --force --verbose --speed=1 -o ./tmp4/output!i!.png 
  magick convert "%%X" -transparent "srgba(50,51,55)" ./tmp4/output!i!.png
  @REM optipng !qualitymax! -o ./tmp3/output!i!.png "%%X"
  @REM .\optipng.exe -o7 output12.png -out aa.png
  )
ffmpeg -framerate %FPS% -start_number 1 -pix_fmt rgba -c:v png -i ./tmp4/output%%d.png -c:v apng -plays 0 -vf "format=rgba,mpdecimate,setpts=N/FRAME_RATE/TB,format=rgba" -final_delay %FINAL_DELAY% -compression_level 9 -f apng -pix_fmt rgba output.png -y
goto :STEP4_END
:STEP4_METHOD1_END

:STEP4_METHOD2
ffmpeg -framerate %FPS% -start_number 1 -pix_fmt rgba -i ./tmp4/output%%d.png -plays 0 -vf "format=rgba,mpdecimate,setpts=N/FRAME_RATE/TB,chromakey=color=0x383c44:blend=0.002:similarity=0.01,format=rgba" -final_delay %FINAL_DELAY% -compression_level 9 -f apng -pix_fmt rgba output.png -y
goto :STEP4_END
:STEP4_METHOD2_END

:STEP4_END


forfiles /C "cmd /c echo @fsize>filesize.txt" /M output.png
set /p FSIZE=<filesize.txt
echo 파일크기:%FSIZE%/512000
if %FSIZE% LSS 512000 (
  echo 파일크기가 512000보다 작습니다.
  echo 통과
  ) else (
  echo 파일크기가 512000보다 큽니다.
  echo 압축률을 높여서 다시 시도하기...
  echo qualitymin = !qualitymin!
  echo qualitymax = !qualitymax!
  set /a qualitymax=!qualitymax!-5
  @REM pause
  if !qualitymin! LSS 10 (
    echo 압축률이 너무 낮습니다.
    echo 종료
    pause
    exit
    )
  del output.png
  goto STEP3
  )
echo 완료.
echo qualitymin = !qualitymin!
echo qualitymax = !qualitymax!
echo 파일크기:%FSIZE%/512000
echo 변환을 마쳤습니다. output.png를 확인하세요.
echo 엔터를 누르면 종료됩니다...
pause > nul