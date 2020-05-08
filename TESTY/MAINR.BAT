@ECHO OFF
:BEGIN
pmr.exe
IF ERRORLEVEL 4  GOTO DGPS
IF ERRORLEVEL 3  GOTO CallPMD
IF ERRORLEVEL 2  GOTO BazaDanych
IF ERRORLEVEL 0  GOTO END

:DGPS
PIG1
smartdrv/c
rem ADS FLUSh >NUL
GOTO BEGIN


:CallPMD
nc
smartdrv/c
rem ADS FLUSh >NUL
GOTO END

:BazaDanych
plkbd /alt:right /pl:latin2 >NUL
plega c:\utils\cp852alt.scr /mem:18 >NUL
database.exe
plega /u >NUL
plkbd /u >NUL
smartdrv/c >NUL
rem ADS FLUSh >NUL
GOTO BEGIN

:END
smartdrv/c > NUL
rem ADS FLUSh >NUL
