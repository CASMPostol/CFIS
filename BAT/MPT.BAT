@echo off
CALL \BAT\trs.bat

IF EXIST *.obj DEL *.obj >nul
IF EXIST *.ref del *.ref >nul
IF EXIST *.lst del *.lst >NUL

REN \vor.src\pi_*.obj pi_*.obk

m2make pt/B/A-/g+/e/pf=pattern.pat/x >m2make.txt
call cmdfile.bat

REN \vor.src\pi_*.obk pi_*.obj
CALL \bat\cpt.bat
