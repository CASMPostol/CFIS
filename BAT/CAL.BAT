@ECHO OFF
move l_dacqui.ref  loc.arc\
move l_dacqui.obj  loc.arc\

move d_dacqui.ref  dme.arc\
move d_dacqui.obj  dme.arc\

CALL \BAT\CASRC.BAT
call \bat\cpl.bat
