@echo off
CALL BAT\VHFA

IF EXIST *.obj DEL *.obj
IF EXIST *.ref DEL *.ref
IF EXIST *.lst DEL *.lst

REN \VHF.SRC\PI_PA.OBJ     PI_PA.OBk
REN \VHF.SRC\H_DACQ*.obj   H_DACQ*.obk
REN \SRC\SCANNERI.obj      SCANNERI.obk

m2make aH/A-/b+/g+/e/pf=pattern.pat >m2make.txt
CALL cmdfile.BAT

REN \VHF.SRC\PI_PA.OBk     PI_PA.OBJ
REN \VHF.SRC\H_DACQ*.OBK   H_DACQ*.OBJ
REN \SRC\SCANNERI.OBK      SCANNERI.OBJ

CALL \bat\CAH.BAT
