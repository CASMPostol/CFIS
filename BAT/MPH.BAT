@echo off
call \bat\vhf.bat
@DEL *.obj >NUL
@del *.ref >NUL
m2make ph.mod/A-/b+/g+/e+/pf=pattern.pat >M2MAKE.txt
del *.lst >NUL
call cmdfile
call \bat\cph
