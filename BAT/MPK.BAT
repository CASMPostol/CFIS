@echo off

IF EXIST *.obj DEL *.obj >nul
IF EXIST *.ref del *.ref >nul
IF EXIST *.lst del *.lst >NUL

m2make PK.mod/A-/b+/g+/e/pf=pattern.pat >M2MAKE.txt
call cmdfile

call \bat\CSRC.BAT
