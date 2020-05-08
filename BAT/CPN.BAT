@ECHO OFF
move n_*.sym ndb.src\
move n_*.ref ndb.src\
move n_*.obj ndb.src\
move pi_*.sym src\
move pi_*.ref ndb.src\
move pi_*.obj ndb.src\
move vor*.sym vor.src\
move vor*.ref vor.src\
move vor*.obj vor.src\

CALL CSRC.BAT
