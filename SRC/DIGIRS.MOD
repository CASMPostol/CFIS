(*.F- *)
(**********************************************************************
|  Title   : Obsluga karty DIGI PC/Xe 
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86 
|  History :
|    09-07-97: M.Postol
|      wywalilem semafor
|    15-12-97: M.Postol
|      zmienilem wyznaczanie minWrBufLength, bo dlugosc stringu w WriteString
|      byla ograniczona do 15
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)
IMPLEMENTATION MODULE DigiRS[8];

FROM SYSTEM IMPORT AX, BX, CX, DX, ES, SWI, CODE, ADR, ADDRESS,
    SETREG, GETREG;

FROM MANAGER IMPORT
  Assert;
  FROM SpecConv  IMPORT
    GorszeBoMniejsze;
    
TYPE
  WriteError = (NoError, TimeOut, CountErr);
VAR
  minWrBufLength: INTEGER;
  (* semafor: CARDINAL; *)
  
  PROCEDURE  GetWrBufLength(channel : CARDINAL): CARDINAL;
  VAR
    inBuffer: CARDINAL;
  BEGIN
    SETREG(AX,1200H); (* funct 0FH *)
    SETREG(DX,channel);  
    CODE(55H (* push BP *));
    SWI(14H);
    CODE(5DH (* pop  BP *));
    GETREG(AX, inBuffer);
    Assert(inBuffer < MAX(INTEGER));
    RETURN inBuffer;
  END GetWrBufLength;
  
PROCEDURE  MarkError(error : WriteError;
           sent            : CARDINAL;
           toBeSent        : CARDINAL;
           channel        : CARDINAL);
VAR
  inBuffer: CARDINAL;
  
BEGIN
  inBuffer := GetWrBufLength(channel);
  Assert(FALSE);
END MarkError;

PROCEDURE ReadString (    channel : CARDINAL;
                      VAR buff : ARRAY OF CHAR;
                      count : CARDINAL)             : CARDINAL;
VAR
   cl : CARDINAL;  
   a  : ADDRESS;                 
BEGIN
  (* DEC(semafor); *)
  IF count>HIGH(buff)+1 THEN
    count := HIGH(buff)+1;
  END;
  a := ADR( buff);
  SETREG(AX,0F00H); (* funct 0FH *)
  SETREG(BX,a.OFFSET);
  SETREG(ES,a.SEGMENT );
  SETREG(CX, count ); 
  SETREG(DX,channel);  
  CODE(55H (* push BP *));
  SWI(14H);
  CODE(5DH (* pop  BP *));
  GETREG(AX, cl);
  IF cl > 300 THEN
    cl := 0; (* to na wypadek, jakby nie bylo driver'a *)
  END;
  (* INC(semafor); *)
  RETURN cl;
END ReadString;
                     
PROCEDURE WriteString(    channel : CARDINAL;
                      VAR buff : ARRAY OF CHAR;
                      count : CARDINAL);
VAR
   cl : CARDINAL;
   error : CARDINAL;
   a  : ADDRESS;            
BEGIN
  (* DEC(semafor); *)
  GorszeBoMniejsze(minWrBufLength, GetWrBufLength(channel));
  IF count > ORD(minWrBufLength)  THEN
    MarkError(CountErr, MAX(CARDINAL), count, channel);
  END;
  a := ADR(buff);
  SETREG(AX,0E00H); (* funct 0EH *)
  SETREG(BX,a.OFFSET);
  SETREG(ES,a.SEGMENT );
  SETREG(CX, count ); 
  SETREG(DX,channel);  
  CODE(55H (* push BP *));
  SWI(14H);
  CODE(5DH (* pop  BP *));
  GETREG(AX, cl);
  GETREG(DX, error);
  IF cl > 30 THEN
    (* INC(semafor); *)
    RETURN; (* to na wypadek, jakby nie bylo driver'a *)
  END;
  IF DX >= 0FF00H THEN
    MarkError(TimeOut, cl, count, channel);
  ELSIF cl <> count THEN
    MarkError(CountErr, cl, count, channel);
  END (* if *);
  (* INC(semafor); *)
END WriteString;

PROCEDURE SetBaudRate( channel : CARDINAL;bauds100,NrOfBits : CARDINAL) : BOOLEAN;
    
VAR cl : CARDINAL;
BEGIN
  CASE bauds100 OF
       3 : cl := 2
  |    6 : cl := 3
  |   12 : cl := 4
  |   24 : cl := 5
  |   48 : cl := 6
  |   96 : cl := 7
  |  192 : cl := 8
  |  384 : cl := 9
  |  576 : cl :=10
  |  768 : cl :=11
  | 1152 : cl :=12
  ELSE
    RETURN FALSE;
  END;       
  INC(cl,100H*(NrOfBits-5)); (* 5..8 *)
  SETREG(AX,0400H); (* funct 4 *)
  SETREG(BX,0000H); (* no parity, 1 stop *)
  SETREG(CX, cl  ); (* nrofbits,  speed *)
  SETREG(DX,channel);  
  CODE(55H (* push BP *));
  SWI(14H);
  CODE(5DH (* pop  BP *));
  GETREG(AX, cl);
  cl := (cl DIV 100H);
  IF cl#0FFH THEN
    SETREG(AX,2000H); (* funct 20H, disable time-outs *)
    SETREG(DX,channel);  
    CODE(55H (* push BP *));
    SWI(14H);
    CODE(5DH (* pop  BP *));
    GETREG(AX, cl);
    RETURN TRUE;
  ELSE
    RETURN FALSE;
  END;  
END SetBaudRate;

BEGIN
  minWrBufLength := MAX(INTEGER);
  (* semafor := 1; *)
END DigiRS.
