@ECHO OFF
CALL \BAT\MPK.BAt
ECHO TWORZENIE PK ZAKONCZONE
if exist *.lst goto error

CALL \BAT\MPM.BAt
ECHO TWORZENIE PM ZAKONCZONE
if exist *.lst goto error

CALL \BAT\MPV.BAt
ECHO TWORZENIE PV ZAKONCZONE
if exist *.lst goto error

CALL \BAT\MPT.BAt
ECHO TWORZENIE PTT ZAKONCZONE
if exist *.lst goto error

CALL \BAT\MAT.BAt
ECHO TWORZENIE AT ZAKONCZONE
if exist *.lst goto error

CALL \BAT\MAV.BAt
ECHO TWORZENIE AV ZAKONCZONE
if exist *.lst goto error

CALL \BAT\MPL.BAt
ECHO TWORZENIE PL ZAKONCZONE
if exist *.lst goto error
CALL \BAT\MAL.BAt
ECHO TWORZENIE AL ZAKONCZONE
if exist *.lst goto error

CALL \BAT\MPG.BAt
ECHO TWORZENIE PG ZAKONCZONE
if exist *.lst goto error
CALL \BAT\MAG.BAt
ECHO TWORZENIE AG ZAKONCZONE
if exist *.lst goto error

CALL \BAT\MPN.BAt
ECHO TWORZENIE PN ZAKONCZONE
if exist *.lst goto error
CALL \BAT\MAN.BAt
ECHO TWORZENIE AN ZAKONCZONE
if exist *.lst goto error

CALL \BAT\MPH.BAt
ECHO TWORZENIE PH ZAKONCZONE
if exist *.lst goto error
CALL \BAT\MAH.BAt
ECHO TWORZENIE AH ZAKONCZONE
if exist *.lst goto error

ECHO TRWA TWORZENIE BAZY DANYCH
CALL \BAT\MDB.BAt
ECHO TWORZENIE BAZY DANYCH ZAKONCZONE
if NOT exist DATABASE.EXE goto error

MD VOR >NUL
MD TRS >NUL

MD ILS >NUL
MD GS  >NUL

MD NDB >NUL
MD VHF >NUL

GOTO END

:ERROR
@ECHO PRZYPADKOWO WYSTAPILY JAKIES BLEDY
PAUSE 
goto ret
:END
@ECHO **************************************************************************
@ECHO
@ECHO
@ECHO
@ECHO
@ECHO JESZCZE JEDEN PELEN SUKCES
@ECHO
@ECHO
@ECHO
@ECHO
@ECHO **************************************************************************

:RET
