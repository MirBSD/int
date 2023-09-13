@echo off
REM $MirOS: src/kern/include/mkt-int.bat,v 1.8 2023/09/13 00:55:12 tg Exp $
REM
REM (c) 2023 mirabilos (F) CC0
REM
set __VSCMD_ARG_NO_LOGO=1
set VSCMD_SKIP_SENDTELEMETRY=1
if not exist do-cl.bat goto dohelp
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
wsl /bin/sh mkt-int.sh %cxx% %x% "$(wslpath "%COMSPEC%")" /c do-cl.bat -DWINVER=0x0602 -D_WIN32_WINNT=0x0602 -DNTDDI_VERSION=NTDDI_WIN8 /Wall -D__STDC_WANT_SECURE_LIB__=1 /wd5045 -DMBSDINT_H_WANT_PTR_IN_SIZET -DMBSDINT_H_WANT_INT32 -DMBSDINT_H_WANT_LRG64 -DMBSDINT_H_WANT_SAFEC %args% /nologo
if errorlevel 1 goto doerror
del do-cl.bat
exit /b 0
:doerror
del do-cl.bat
exit /b 1
:dohelp
echo.
echo Call find-cl.bat first, with e.g. x86 or amd64 as parameter.
echo Afterwards, run mkt-int.bat with an optional first parameter
echo of -x when cross-compiling plus optional CL.EXE arguments.
echo Pass an initial -cxx before everything else to build as C++ not C.
echo.
exit /b 1
