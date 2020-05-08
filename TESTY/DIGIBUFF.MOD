MODULE digibuff;

FROM SYSTEM IMPORT AX, BX, CX, DX, ES, SWI, CODE, ADR, ADDRESS,
    SETREG, GETREG;

PROCEDURE  MarkError( channel        : CARDINAL);
VAR
  inBuffer: CARDINAL;
  
BEGIN
  SETREG(AX,1200H); (* funct 0FH *)
  SETREG(DX,channel);  
  CODE(55H (* push BP *));
  SWI(14H);
  CODE(5DH (* pop  BP *));
  GETREG(AX, inBuffer);
END MarkError;

BEGIN
  LOOP
    MarkError(0);
    MarkError(1);
    MarkError(3);
    MarkError(4);
  END;
END digibuff.
