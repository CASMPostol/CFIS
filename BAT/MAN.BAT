@echo off
CALL BAT\NDBA

IF EXIST *.obj DEL *.obj >nul
IF EXIST *.ref del *.ref >nul
IF EXIST *.lst del *.lst >NUL

REN  \NDB.src\N_DACQ*.obj  N_DACQ*.obk

m2make an/A-/b+/g+/e/pf=pattern.pat >m2make.txt
CALL cmdfile.bat

REN  \NDB.src\N_DACQ*.obk  N_DACQ*.obj

CALL \bat\can
