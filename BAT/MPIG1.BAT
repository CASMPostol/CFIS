@echo off
call \bat\DGPS.bat

IF EXIST *.obj DEL *.obj >nul
IF EXIST *.ref del *.ref >nul
IF EXIST *.lst del *.lst >NUL

m2make pig1.mod/A-/b+/g+/e/pf=pattern.pat >M2MAKE.txt
call cmdfile

call \bat\cpig1
