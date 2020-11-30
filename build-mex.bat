@echo off

SETLOCAL

SET VS_VERSION=16
SET VS_YEAR=2019

SET VSCOMMUNITYCMD="C:\Program Files (x86)\Microsoft Visual Studio\%VS_YEAR%\Community\Common7\Tools\VsDevCmd.bat"
SET VSBUILDCMD="C:\Program Files (x86)\Microsoft Visual Studio\%VS_YEAR%\BuildTools\Common7\Tools\VsDevCmd.bat"
SET VSENTERPRISECMD="C:\Program Files (x86)\Microsoft Visual Studio\%VS_YEAR%\Enterprise\Common7\Tools\VsDevCmd.bat"

:: Set up Visual Studio environment variables
IF EXIST %VSCOMMUNITYCMD% CALL %VSCOMMUNITYCMD% -arch=amd64 && GOTO :BUILD
IF EXIST %VSBUILDCMD% CALL %VSBUILDCMD% -arch=amd64 && GOTO :BUILD
IF EXIST %VSENTERPRISECMD% CALL %VSENTERPRISECMD% -arch=amd64 && GOTO :BUILD
ECHO Error: Visual Studio install not found && EXIT /B 1

:BUILD

IF NOT DEFINED MATLAB_VER SET MATLAB_VER=R2019b

SET TRIPLET=x64-windows-static

SET PROJECT_DIR=GeneratedProjects\VS%VS_YEAR%
IF "%1"=="--clean" (
   echo Cleaning CMake Project
   rmdir %PROJECT_DIR% /s /q
   mkdir %PROJECT_DIR%
)

echo Generating CMake Project in: %PROJECT_DIR%
cmake -G"Visual Studio %VS_VERSION% %VS_YEAR%" -A x64 -H. -B%PROJECT_DIR%^
   -DNO_CUDA=1^
   -DMatlab_ROOT_DIR="%Matlab_ROOT_DIR%"^
   -DVCPKG_TARGET_TRIPLET=%TRIPLET%^
   -DMSVC_CRT_LINKAGE=static
if %ERRORLEVEL% GEQ 1 EXIT /B %ERRORLEVEL%

echo Building 64bit Project in Release mode
cmake --build %PROJECT_DIR%  --config RelWithDebInfo
if %ERRORLEVEL% GEQ 1 EXIT /B %ERRORLEVEL%