@echo off
CALL BAT\VHFA

IF EXIST *.obj DEL *.obj
IF EXIST *.ref DEL *.ref
IF EXIST *.lst DEL *.lst

REN \VHF.SRC\H_DACQ*.obj   H_DACQ*.obk

m2make aH/A-/b+/g+/e/pf=pattern.pat >m2make.txt
CALL cmdfile.BAT

REN \VHF.SRC\H_DACQ*.OBK   H_DACQ*.OBJ

CALL \bat\CAH.BAT
