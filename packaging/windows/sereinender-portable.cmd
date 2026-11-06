@echo off
rem Runs Sereinender with its data beside this file. Security software can deny an unsigned build any
rem write inside the user profile (ERROR_ACCESS_DENIED), and then the cache, saved logins and the
rem diagnostic log all stay read-only. Put this file next to sereinender.exe and start Sereinender with it.
setlocal
set "ROOT=%~dp0"
if not exist "%ROOT%sereinender.exe" (
	echo Put this file next to sereinender.exe.
	exit /b 1
)
if not exist "%ROOT%data" mkdir "%ROOT%data"
set "SEREINENDER_DATA_DIR=%ROOT%data"
start "" "%ROOT%sereinender.exe" %*
endlocal
