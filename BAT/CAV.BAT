@ECHO OFF
move v_dacqui.ref  vor.arc\
move v_dacqui.obj  vor.arc\

move d_dacqui.ref dme.arc\
move d_dacqui.obj dme.arc\

call \BAT\CASRC.bat
CALL \BAT\CPV.BAT
