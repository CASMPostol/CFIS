@ECHO OFF
move v_*.sym vor.src\
move v_*.ref vor.src\
move v_*.obj vor.src\
move vor*.sym vor.src\
move vor*.ref vor.src\
move vor*.obj vor.src\
move pi_*.sym src\
move pi_*.ref vor.src\
move pi_*.obj vor.src\
CALL CDME.BAT
CALL CSRC.BAT
