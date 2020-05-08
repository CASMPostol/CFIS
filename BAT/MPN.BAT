@echo off
call \bat\ndb.bat
@DEL *.obj >NUL
@del *.ref >NUL
@del \VHF.SRC\pi*.obj
m2make pN.mod/A-/b+/g+/e+/pf=pattern.pat >M2MAKE.txt
del *.lst >NUL
call cmdfile
call \bat\cpn
