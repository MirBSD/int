@echo off
REM $MirOS: int/mkt-int.bat,v 1.7 2023/09/13 00:54:10 tg Exp $
REM
REM (c) 2023 mirabilos (F) CC0
REM
set __VSCMD_ARG_NO_LOGO=1
set VSCMD_SKIP_SENDTELEMETRY=1
for /F "usebackq tokens=*" %%i in (`"%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" -property installationPath`) do (set "VSINSTALLDIR=%%i\")
set cxx=
set x=
set args=%*
if not "%1" == "-cxx" goto nocxx
set cxx=-cxx
set args=%args:~5%
shift
:nocxx
if not "%1" == "-x" goto nocross
set x=-x
set args=%args:~3%
shift
:nocross
if "%1" == "" goto dohelp
echo @echo off >do-cl.bat
echo set __VSCMD_ARG_NO_LOGO=1 >>do-cl.bat
echo set VSCMD_SKIP_SENDTELEMETRY=1 >>do-cl.bat
REM echo call "%VSINSTALLDIR%Common7\Tools\VsDevCmd.bat" >>do-cl.bat
echo call "%VSINSTALLDIR%VC\Auxiliary\Build\vcvarsall.bat" %args% >>do-cl.bat
echo cl %%* >>do-cl.bat
wsl /bin/sh mkt-int.sh %cxx% %x% "$(wslpath "%COMSPEC%")" /c do-cl.bat -DWINVER=0x0602 -D_WIN32_WINNT=0x0602 -DNTDDI_VERSION=NTDDI_WIN8 /Wall -D__STDC_WANT_SECURE_LIB__=1 /wd5045 -DMBSDINT_H_WANT_PTR_IN_SIZET -DMBSDINT_H_WANT_INT32 -DMBSDINT_H_WANT_LRG64 -DMBSDINT_H_WANT_SAFEC /nologo
if errorlevel 1 goto doerror
del do-cl.bat
exit /b 0
:doerror
del do-cl.bat
exit /b 1
:dohelp
call "%VSINSTALLDIR%VC\Auxiliary\Build\vcvarsall.bat" /help
echo.
echo Call this with e.g. x86 or amd64 as parameter, see above.
echo Or call with something like -x x86_arm for cross compilation.
echo Pass an initial -cxx before everything else to build as C++ not C.
echo.
exit /b 1
