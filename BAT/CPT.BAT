@ECHO OFF
move t_*.sym trs.src\
move t_*.ref trs.src\
move t_*.obj trs.src\
move pi_*.sym src\
move pi_*.ref trs.src\
move pi_*.obj trs.src\
CALL CPV
