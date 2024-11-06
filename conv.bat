@echo off
chcp 65001
setlocal EnableDelayedExpansion
@REM goto :STEP2_END
@REM FINAL_DELAY=다음 프레임을 반복하기 전 대기할 시간(초), 0.0이면 바로 다음 프레임을 반복. 일반적으로 0.5
set FINAL_DELAY=0.0
@REM FPS=대부분 10인데 특수한 경우에는 12fps
set FPS=10

if not exist "libs\pngquant.exe" (
  echo pngquant가 설치되어 있지 않습니다.
  echo https://pngquant.org/ 에서 pngquant를 다운로드 받아 libs 폴더에 넣어주세요.
  pause
  exit
)

ffmpeg -version > nul 2>&1
if errorlevel 1 (
  echo ffmpeg가 설치되어 있지 않습니다.
  echo https://ffmpeg.org/ 에서 ffmpeg를 설치해주세요.
  pause
  exit
)

magick -version > nul 2>&1
if errorlevel 1 (
  echo ImageMagick이 설치되어 있지 않습니다.
  echo https://imagemagick.org/script/download.php 에서 ImageMagick을 설치해주세요.
  pause
  exit
)

:INTRO
echo 이 스크립트는 카카오톡 이모티콘을 캡처해서 Discord 스티커에서 쓰이는 apng로 변환합니다.

echo 1) 새로운 이모티콘 녹화
echo 2) 기존 녹화 재사용 (기본값)

set /p CHOICE=번호를 입력하세요:
if "%CHOICE%" == "1" goto :PRE_Record
if "%CHOICE%" == "2" goto :STEP1
if "%CHOICE%" == "" goto :INTRO

:PRE_Record
echo 카카오톡에서 HiDPI를 200%로 설정하고 빈 채팅방을 만든 다음 이름을 %TEMP로 설정하세요.
echo 그런 다음 채팅방 배경을 background.jpg로 지정합니다.
echo 채팅방 크기를 가장 줄여주세요.
echo 그런 다음 녹화를 시작하고 이모티콘을 하나 보내면 됩니다.
echo 10초간 녹화를 시작하려면 엔터를 누르세요.
pause > nul
ffmpeg.exe -y -f dshow -f gdigrab -draw_mouse 0 -t 00:00:10 -i title="%%TEMP" -framerate 30 -vcodec libx264 -crf 0 -preset ultrafast output.mkv
if errorlevel 1 (
  echo 녹화에 실패했습니다. 다시 시도해주세요.
  goto :PRE_Record
)
echo 녹화가 완료되었습니다.
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
ffmpeg -i ./tmp1/output%%03d.png -pred mixed -filter_complex "[0:v]scale=iw*1.00:-1[resized];[resized]crop=240:240:477:385[cropped];[cropped]mpdecimate[decimated];[decimated]setpts=N/FRAME_RATE/TB[setpts]" -map "[setpts]" ./tmp2/output%%03d.png
echo 이미지를 프래임으로 잘랐습니다.
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
for /F "delims= " %%i in ('libs\magick identify -format ^"%%# %%%f\n^" tmp2\*.png') do (
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
  libs\pngquant.exe --force --verbose --speed=1 --quality=!qualitymin!-!qualitymax! -o ./tmp3/output!i!.png "%%X"
  @REM optipng !qualitymax! -o ./tmp3/output!i!.png "%%X"
  @REM .\optipng.exe -o7 output12.png -out aa.png
  )
libs\ffmpeg -framerate %FPS% -start_number 1  -i ./tmp3/output%%d.png -plays 0 -vf "mpdecimate,setpts=N/FRAME_RATE/TB,chromakey=color=#383c44:blend=0.002" -final_delay %FINAL_DELAY% -compression_level 9 -f apng -pix_fmt rgba output.png -y

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
pause