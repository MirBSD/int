@echo off
REM $MirOS: src/kern/include/find-cl.bat,v 1.3 2025/06/09 23:19:36 tg Exp $
REM
REM (c) mirabilos (F) MirBSD or CC0
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
echo.
echo Ok, do-cl.bat created.
echo.
exit /b 0
:dohelp
call "%VSINSTALLDIR%VC\Auxiliary\Build\vcvarsall.bat" /help
echo.
echo Call this with e.g. x86, amd64 or arm64 as parameter, see above.
echo.
exit /b 1
