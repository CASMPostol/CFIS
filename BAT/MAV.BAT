@echo off
CALL BAT\VORA.BAT

IF EXIST *.obj DEL *.obj >nul
IF EXIST *.ref del *.ref >nul
IF EXIST *.lst del *.lst >NUL

ren \dme.src\D_DACQ*.obj   D_DACQ*.obk
ren \vor.src\V_DACQ*.obj   V_DACQ*.obk
ren \VOR.SRC\PI_PA.OBJ     PI_PA.OBk
ren \SRC\SCANNERI.obj      SCANNERI.obk

m2make av/A-/b+/g+/e/pf=pattern.pat >m2make.txt
CALL cmdfile.bat

ren \dme.src\D_DACQ*.obk   D_DACQ*.obj
ren \vor.src\V_DACQ*.obk   V_DACQ*.obj
ren \VOR.SRC\PI_PA.OBk     PI_PA.OBJ
ren \SRC\SCANNERI.obk      SCANNERI.obj

CALL \bat\cav
