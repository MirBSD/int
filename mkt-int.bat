@echo off
REM $MirOS: int/mkt-int.bat,v 1.2 2023/08/12 05:48:08 tg Exp $
REM
REM (c) 2023 mirabilos (F) CC0
REM
set __VSCMD_ARG_NO_LOGO=1
set VSCMD_SKIP_SENDTELEMETRY=1
for /F "usebackq tokens=*" %%i in (`"%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" -property installationPath`) do (set "VSINSTALLDIR=%%i\")
if "%1" == "" goto dohelp
echo @echo off >do-cl.bat
echo set __VSCMD_ARG_NO_LOGO=1 >>do-cl.bat
echo set VSCMD_SKIP_SENDTELEMETRY=1 >>do-cl.bat
REM echo call "%VSINSTALLDIR%Common7\Tools\VsDevCmd.bat" >>do-cl.bat
echo call "%VSINSTALLDIR%VC\Auxiliary\Build\vcvarsall.bat" %* >>do-cl.bat
echo cl %%* >>do-cl.bat
wsl /bin/sh mkt-int.sh "$(wslpath "%COMSPEC%")" /c do-cl.bat -DWINVER=0x0602 -D_WIN32_WINNT=0x0602 -DNTDDI_VERSION=NTDDI_WIN8 /Wall -D__STDC_WANT_SECURE_LIB__=1 /wd5045 /nologo
if errorlevel 1 goto doerror
del do-cl.bat
goto out
:doerror
del do-cl.bat
exit 1
:dohelp
"%VSINSTALLDIR%VC\Auxiliary\Build\vcvarsall.bat" /help
:out
