@echo off
CALL BAT\GSA.BAT

IF EXIST *.obj DEL *.obj >nul
IF EXIST *.ref del *.ref >nul
IF EXIST *.lst del *.lst >NUL

ren LOC.SRC\pi_*.obj      pi_*.obk
ren LOC.SRC\L_Count.obj   L_Count.obk
ren LOC.SRC\L_Slupek.obj  L_Slupek.obk

ren gs.src\G_DACQ*.obj    G_DACQ*.obk

m2make ag/A-/b+/g+/e/pf=pattern.pat >m2make.txt
CALL cmdfile

ren LOC.SRC\pi_*.obk      pi_*.obj
ren LOC.SRC\L_Count.obk   L_Count.obj
ren LOC.SRC\L_Slupek.obk  L_Slupek.obj

ren gs.src\G_DACQ*.obk    G_DACQ*.obj

CALL \bat\cag
