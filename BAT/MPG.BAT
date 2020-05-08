@echo off
call \BAT\GS.bat

IF EXIST *.obj DEL *.obj >nul
IF EXIST *.ref del *.ref >nul
IF EXIST *.lst del *.lst >NUL

ren LOC.SRC\pi*.obj       pi*.obk
ren LOC.SRC\L_Count.obj   L_Count.obk
ren LOC.SRC\L_Slupek.obj  L_Slupek.obk

m2make pg.mod/a-/e/b+/g+/pf=pattern.pat >make.txt
call cmdfile

ren LOC.SRC\pi*.obk       pi*.obj
ren LOC.SRC\L_Count.obk   L_Count.obj
ren LOC.SRC\L_Slupek.obk  L_Slupek.obj

call \bat\cpg
