@ECHO OFF
call \BAT\loc.bat
DEL *.obj >NUL
del *.ref >NUL
m2make pl.mod/a-/e/b+/g+/pf=opt_link.pat >make.txt
del *.lst >NUL
call cmdfile
call \bat\cpl
