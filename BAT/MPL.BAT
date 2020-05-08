call \BAT\loc.bat

IF EXIST *.obj DEL *.obj >nul
IF EXIST *.ref del *.ref >nul
IF EXIST *.lst del *.lst >NUL

m2make pl.mod/a-/e/b+/g+/pf=opt_link.pat >m2make.txt

call cmdfile
call \bat\cpl.bat
