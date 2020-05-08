@echo off
CALL BAT\LOCA

IF EXIST *.obj DEL *.obj >nul
IF EXIST *.ref del *.ref >nul
IF EXIST *.lst del *.lst >NUL

ren \dme.src\D_DACQ*.obj  D_DACQ*.obk

ren \loc.src\L_DACQ*.obj  L_DACQ*.obk
ren \loc.SRC\PI_PA.OBJ    PI_PA.Obk

ren \SRC\SCANNERI.obj     SCANNERI.obk

m2make al/A-/b+/g+/e/pf=opt_link.pat >m2make.txt
CALL cmdfile.BAT

ren \dme.src\D_DACQ*.obk  D_DACQ*.obj

ren \loc.src\L_DACQ*.obk  L_DACQ*.obj
ren \loc.SRC\PI_PA.Obk    PI_PA.OBJ

ren \SRC\SCANNERI.obk     SCANNERI.obj 

CALL \bat\cal
