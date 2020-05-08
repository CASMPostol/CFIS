(*.F- *)
(**********************************************************************
|  Title   : GPIB Iterface
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    01-09-96: created
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 86 58 12, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE M_PGPIB;

  FROM SYSTEM IMPORT
    CODE;
  
  FROM Strings IMPORT
    CompareStr;
    
CONST
  ROMName = "---PCL-848--- VER 10";
VAR
  errNo[0D000H:0201AH]    : CARDINAL;
  ROMIdent[0D000H:01F80H] : ARRAY[0..19] OF CHAR;
  
  PROCEDURE IOCheck(): BOOLEAN;
  BEGIN
    RETURN errNo = 0;
  END IOCheck;

  PROCEDURE GPIBPresent(): BOOLEAN;
  BEGIN
    RETURN CompareStr(ROMIdent, ROMName) = 0;
  END GPIBPresent;
  
  PROCEDURE ieinit
            (    ioport  : INTEGER;
                 myaddr  : INTEGER;
                 setting : INTEGER);
  BEGIN
    CODE( 045H, 045H, 09AH, 000H, 004H, 000H, 0D0H, 04DH, 04DH );
  END ieinit; (* call D000:0400 *)

  PROCEDURE ieoutput
            (     addr : INTEGER;
              VAR tmp  : lstring );

  BEGIN
    CODE( 045H, 045H, 09AH, 003H, 004H, 000H, 0D0H, 04DH, 04DH );
  END ieoutput; (* call D000:0403 *)

  PROCEDURE ieenter
            (     addr  : INTEGER;
              VAR instr : lstring );

  BEGIN
    CODE( 045H, 045H, 09AH, 006H, 004H, 000H, 0D0H, 04DH, 04DH );
  END ieenter; (* call D000:0406 *)

  PROCEDURE ieabort;

  BEGIN
    CODE( 045H, 045H, 09AH, 009H, 004H, 000H, 0D0H, 04DH, 04DH );
  END ieabort; (* call D000:0409 *)

  PROCEDURE ieeol
            (     addr,
                  outeol    : INTEGER;
              VAR outeolstr : lstring;
                  ineol,
                  ineolb    : INTEGER );

  BEGIN
    CODE( 045H, 045H, 09AH, 00CH, 004H, 000H, 0D0H, 04DH, 04DH );
  END ieeol; (* call D000:040C *)

  PROCEDURE iedevclr
            (    addr : INTEGER );

  BEGIN
    CODE( 045H, 045H, 09AH, 00FH, 004H, 000H, 0D0H, 04DH, 04DH );
  END iedevclr; (* call D000:040F *)

  PROCEDURE iello;

  BEGIN
    CODE( 045H, 045H, 09AH, 012H, 004H, 000H, 0D0H, 04DH, 04DH );
  END iello; (* call D000:0412 *)

  PROCEDURE ielocal
            (    addr : INTEGER );

  BEGIN
    CODE( 045H, 045H, 09AH, 015H, 004H, 000H, 0D0H, 04DH, 04DH );
  END ielocal; (* call D000:0415 *)

  PROCEDURE ieppoll
            ( VAR response : INTEGER );

  BEGIN
    CODE( 045H, 045H, 09AH, 018H, 004H, 000H, 0D0H, 04DH, 04DH );
  END ieppoll; (* call D000:0418 *)

  PROCEDURE ieppollc
            (    addr,
                 config : INTEGER );

  BEGIN
    CODE( 045H, 045H, 09AH, 01BH, 004H, 000H, 0D0H, 04DH, 04DH );
  END ieppollc; (* call D000:041B *)

  PROCEDURE ieppollu
            (    addr : INTEGER );

  BEGIN
    CODE( 045H, 045H, 09AH, 01EH, 004H, 000H, 0D0H, 04DH, 04DH );
  END ieppollu; (* call D000:041E *)

  PROCEDURE ieremote
            (    addr : INTEGER );

  BEGIN
    CODE( 045H, 045H, 09AH, 021H, 004H, 000H, 0D0H, 04DH, 04DH );
  END ieremote; (* call D000:0421 *)

  PROCEDURE iesend
            ( VAR cmdstr : lstring );

  BEGIN
    CODE( 045H, 045H, 09AH, 024H, 004H, 000H, 0D0H, 04DH, 04DH );
  END iesend; (* call D000:0424 *)

  PROCEDURE iespoll
            (     addr     : INTEGER;
              VAR response : INTEGER );

  BEGIN
    CODE( 045H, 045H, 09AH, 027H, 004H, 000H, 0D0H, 04DH, 04DH );
  END iespoll; (* call D000:0427 *)

  PROCEDURE iestatus
            (     condition : INTEGER;
              VAR status    : INTEGER);

  BEGIN
    CODE( 045H, 045H, 09AH, 02AH, 004H, 000H, 0D0H, 04DH, 04DH );
  END iestatus; (* INC BP,2; call D000:042A, DEC BP,2 *)

  PROCEDURE ietimout
            (    timeset : INTEGER );

  BEGIN
    CODE( 045H, 045H, 09AH, 02DH, 004H, 000H, 0D0H, 04DH, 04DH );
  END ietimout; (* call D000:042D *)

  PROCEDURE ietrig
            (    addr : INTEGER );

  BEGIN
    CODE( 045H, 045H, 09AH, 030H, 004H, 000H, 0D0H, 04DH, 04DH );
  END ietrig; (* call D000:0430 *)

  PROCEDURE ieentera
            (    addr,
                 dataseg,
                 datalen : INTEGER );

  BEGIN
    CODE( 045H, 045H, 09AH, 033H, 004H, 000H, 0D0H, 04DH, 04DH );
  END ieentera; (* call D000:0433 *)

  PROCEDURE ieouta
            (    addr,
                 dataseg,
                 datalen : INTEGER );

  BEGIN
    CODE( 045H, 045H, 09AH, 036H, 004H, 000H, 0D0H, 04DH, 04DH );
  END ieouta; (* call D000:0436 *)

  PROCEDURE iedevice
            (    addr,
                 portno : INTEGER );

  BEGIN
    CODE( 045H, 045H, 09AH, 039H, 004H, 000H, 0D0H, 04DH, 04DH );
  END iedevice; (* call D000:0439 *)

END M_PGPIB.
