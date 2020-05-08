.HEAD
@ECHO OFF
.def
m2c {#.def/noa/B}
if exist *.lst goto error

.mod
m2c {#.MOD/noa}
if exist *.lst goto error

.link
ECHO TRWA LINKOWANIE i BEDZIE TRWAC JESZCZE CHWILE
m2l/SA/v/b/o # >lastlink.TXT
IF NOT EXIST #.EXE GOTO ERROR
GOTO end

.TAIL
@ECHO !!! NIC NOWEGO - WSZYSTKO JUZ ZROBIONE  !!!
GOTO END

:SKIPLINK
PAUSE ZLA WERSJA BIBLIOTEKI

:error
ECHO !!!!!!!   ERRORS   !!!!!!
PAUSE !!!! ERRORS !!!!
GOTO FINAL

:END
ECHO JESZCZE JEDEN PELEN SUKCES

:FINAL
