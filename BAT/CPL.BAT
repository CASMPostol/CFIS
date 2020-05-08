@ECHO OFF
move l_*.sym loc.src\
move l_*.ref loc.src\
move l_*.obj loc.src\
move pi_*.sym src\
move pi_*.ref loc.src\
move pi_*.obj loc.src\
CALL CDME.BAT
CALL CSRC.BAT
