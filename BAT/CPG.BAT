@ECHO OFF
move g_*.sym gs.src\
move g_*.ref gs.src\
move g_*.obj gs.src\
move pi_*.sym src\
move pi_*.ref gs.src\
move pi_*.obj gs.src\
move L_Count.obj  gs.src\
move L_Count.ref  gs.src\
move L_Slupek.obj gs.src\
move L_Slupek.ref gs.src\
CALL CPL
