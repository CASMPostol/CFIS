@echo off
CALL BAT\trsa.bat

IF EXIST *.obj DEL *.obj >nul
IF EXIST *.ref del *.ref >nul
IF EXIST *.lst del *.lst >NUL

ren \dme.src\D_DACQ*.obj D_DACQ*.obk
ren \vor.src\V_DACQ*.obj V_DACQ*.obk

m2make at/A-/b+/g+/e/pf=pattern.pat >m2make.txt
CALL cmdfile.bat

ren \dme.src\D_DACQ*.obk D_DACQ*.obj
ren \vor.src\V_DACQ*.obk V_DACQ*.obj

CALL \bat\cav.bat
