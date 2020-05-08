@ECHO OFF
move h_*.sym vhf.src\
move h_*.ref vhf.src\
move h_*.obj vhf.src\
move pi_*.sym src\
move pi_*.ref vhf.src\
move pi_*.obj vhf.src\
CALL CSRC.BAT
