echo %1
timeout 15 /nobreak

CALL :PARENT_PATH "%~dp0" PARENT_ROOT
CALL :PARENT_PATH "%PARENT_ROOT%" PARENT_ROOT
echo Parent Root is: %PARENT_ROOT%

timeout 15 /nobreak


C:\imageJ\ij.jar -port0 -macro %PARENT_ROOT%\ImageJ\NM_DQA.ijm %PARENT_ROOT%\Millen_%1\,1,1

timeout 15 /nobreak

%PARENT_ROOT%\skript\updateResults.vbs Millenium_MPS %PARENT_ROOT%\Millen_%1\

GOTO :EOF

:PARENT_PATH
:: use temp variable to hold the path, so we can substring
SET PARENT_PATH=%~dp1
:: strip the trailing slash, so we can call it again to get its parent
SET %2=%PARENT_PATH:~0,-1%
GOTO :EOF
