(*$O+*)
(*.F- *)
(**********************************************************************
|  Title   :  
|  Author  : 
|  System  : LOGITECH MODULA-2/86 
|  History :
|    03-13-97 12:52pm: MM
|      Zwiekszylem dlugosc nazwy pliku bo nie mozna podejrzec czego nie
|      zamyka
|    Rel. 3.11. MPostol
|      - Dopisale procedure ReadExt ny zwracala faktyczna ilosc przeczytanych 
|        bajtow.
|      - Zmienielem DirQuery aby umozliwic zwracanie samej nazwy pliku bez
|        sciezki
|      - otwieranie plikow zrobilem z wykorzystaniem funkcji 6CH, gdzie mozna
|        zadeklarowac, aby nie uzywal INT24 jako procedury obslugi bledow
|        krytycznych.
|    Rel. 3.14: MPostol
|      - Procedura DirQuery zwraca rezyltat, jesli FALSE to w trakcie 
|        realizacji wystapil blad operacji dyskowej.
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 686 25 47
|  mailto: techsupp@cas.com.pl
|  http: www.cas.com.pl
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE FIO;

FROM Strings IMPORT
  Assign, Insert;

FROM SYSTEM IMPORT
  DOSCALL, ADDRESS, WORD, ADR, CODE, SETREG, AX, BX, CX, SI, DI, DS, DX, SWI, 
  GETREG;

FROM RTSMain IMPORT
  Terminate, Status, InstallTermProc;

FROM Sounds IMPORT
  Sound, NoSound;

FROM SoftIntHandlingManager IMPORT
  PrivateHandler, SetEventHandler, CriticalErrorHandler;
  
TYPE
  FileName = ARRAY [0..30] OF CHAR;

VAR
  lastErr          : CARDINAL;
  numErr           : CARDINAL;
  opened           : CARDINAL;
  maxOpened        : CARDINAL;
  Files            : ARRAY[5..100] OF FileName;
  CriticalErrorRec : PrivateHandler;

PROCEDURE Open
          ( FileName : ARRAY OF CHAR ) : File;
VAR
  status  : CARDINAL;
  handle  : CARDINAL;
  error   : CARDINAL;
  str     : ARRAY[0..127] OF CHAR;
  strAdr  : ADDRESS;
  
BEGIN
  Assign( FileName, str ); (* bo ten glupi Logitech nie dodaje 0 na koncu stringu *)
  (* DOSCALL(3DH, ADR(str), RWmode , handle, error); *)
  strAdr := ADR(str);
  SETREG(AX,   6C00H );
  SETREG(BX, {13, 1} ); (* nou use INT24, sharing compatible, read/write   *)
  SETREG(CX, {     } ); (* create attribute                                *)
  SETREG(DX,     01H ); (* Open file if it exists, otherwise fail the call *)
  SETREG(DS, strAdr.SEGMENT );
  SETREG(SI, strAdr.OFFSET  );
  SWI(21H);
  CODE(
    08BH, 0F8H,  (* MOV   DI,AX *)
    072H, 002H,  (* JB    048D  *)
    031H, 0FFH   (* XOR   DI,DI *)
    );
  GETREG(DI, error  );
  GETREG(AX, handle );
  GETREG(CX, status );
  IF error<>0 THEN
    lastErr := error;
    INC( numErr );
    RETURN 0FFFFH;
  ELSE
    INC(opened);
    IF opened > maxOpened THEN
      maxOpened := opened;
    END;
    Assign( FileName, Files[handle] );
    RETURN handle;
  END;
END Open;

PROCEDURE Create
          (     FileName : ARRAY OF CHAR ) : File;
VAR
  handle  : CARDINAL;
  error   : CARDINAL;
  status  : CARDINAL;
  str     : ARRAY[0..127] OF CHAR;
  strAdr  : ADDRESS;
  
BEGIN
  Assign( FileName, str ); (* bo ten glupi Logitech nie dodaje 0 na koncu stringu *)
  (* DOSCALL(3CH, ADR(str), 0, handle, error);*)
  strAdr := ADR(str);
  SETREG(AX, 6C00H          );
  SETREG(BX, {13, 1}        );
  SETREG(CX, {     }        );
  SETREG(DX, 012H           );
  SETREG(DS, strAdr.SEGMENT );
  SETREG(SI, strAdr.OFFSET  );
  SWI(21H);
  CODE(
    08BH, 0F8H,  (* MOV   DI,AX *)
    072H, 002H,  (* JB    048D  *)
    031H, 0FFH   (* XOR   DI,DI *)
    );
  GETREG(DI, error);
  GETREG(AX, handle);
  GETREG(CX, status);
  IF error <> 0 THEN
    lastErr := error;
    INC(numErr);
    RETURN 0FFFFH;
  ELSE
    INC(opened);
    IF opened > maxOpened THEN
      maxOpened := opened;
    END;
    Assign( FileName, Files[handle] );
    RETURN handle;
  END;
END Create;

PROCEDURE Close
          ( VAR f : File );
BEGIN
  IF f = MAX(CARDINAL) THEN
    RETURN;
  END;
  DEC(opened);
  SETREG(AX,3E00H);
  SETREG(BX,f);
  SWI(21H);
  Files[f] := 0C;
  f:=MAX(CARDINAL);
END Close;

PROCEDURE Seek
          (     f    : File; 
                Pos  : LONGINT; 
                Mode : SeekMode ) : LONGINT;
VAR
  q : 
    RECORD
      CASE BOOLEAN OF
      | FALSE: lo             : LONGINT;
      | TRUE:  loword, hiword : CARDINAL;
      END;
    END;
  rax : CARDINAL;
  
BEGIN
(*    DOSCALL(LSEEK, handle, 0, highpos, lowpos, highpos, lowpos, error); *)
  q.lo := Pos;
  rax := ORD(Mode)+4200H;
  SETREG(AX,rax);
  SETREG(BX,f);
  SETREG(CX,q.hiword);
  SETREG(DX,q.loword);
  SWI(21H);
  GETREG(AX,q.loword);
  GETREG(DX,q.hiword);
  RETURN q.lo;
END Seek;

PROCEDURE Write( f: File; buff : ADDRESS; Size : CARDINAL ) : BOOLEAN;
VAR RSize, error : CARDINAL;
BEGIN
  DOSCALL(40H, f, Size, buff, RSize , error);
  RETURN Size=RSize;
END Write;

PROCEDURE Read( f: File; buff : ADDRESS; Size : CARDINAL ) : BOOLEAN;
CONST
  READ = 3FH; 
VAR 
  rAX   : CARDINAL;
  error : CARDINAL;
BEGIN
  DOSCALL(READ, f, Size, buff, rAX, error);
  RETURN rAX = Size;
END Read;

PROCEDURE ReadExt
          (     f        : File; 
                buff     : ADDRESS; 
                Size     : CARDINAL;
            VAR rSize    : CARDINAL) : CARDINAL;
CONST
  READ = 3FH; 

VAR 
  rAX   : CARDINAL;
  error : CARDINAL;

BEGIN
  DOSCALL(READ, f, Size, buff, rAX, error);
  rSize      := rAX;
  RETURN error;
END ReadExt;

PROCEDURE Length ( f: File ) : LONGINT;
VAR
  lenHi, lenLo, oldPosHi, oldPosLo : CARDINAL;

BEGIN
  SETREG(AX,4201H);
  SETREG(BX,f);
  SETREG(CX,0);
  SETREG(DX,0);
  SWI(21H);		(* Zapamietaj stara pozycje pointera w pliku *)
  GETREG(DX,oldPosHi);
  GETREG(AX,oldPosLo);
  SETREG(AX,4202H);
  SETREG(BX,f);
  SETREG(CX,0);
  SETREG(DX,0);
  SWI(21H);		(* Przesun pointer na koniec pliku *)
  GETREG(DX,lenHi);
  GETREG(AX,lenLo);
  SETREG(AX,4200H);
  SETREG(BX,f);
  SETREG(CX,0);
  SETREG(DX,0);
  SWI(21H);		(* Przesun pointer an poczatek pliku *)
  SETREG(AX,4201H);
  SETREG(BX,f);
  SETREG(CX,oldPosHi);
  SETREG(DX,oldPosLo);
  SWI(21H);		(* Odtworz stara pozycje pointera w pliku *)
  RETURN VAL(LONGINT,lenHi)*10000H + VAL(LONGINT,lenLo);
END Length;

PROCEDURE EOF ( f: File ) : BOOLEAN;
VAR
  lenHi, lenLo, oldPosHi, oldPosLo : CARDINAL;

BEGIN
  SETREG(AX,4201H);
  SETREG(BX,f);
  SETREG(CX,0);
  SETREG(DX,0);
  SWI(21H);		(* Zapamietaj stara pozycje pointera w pliku *)
  GETREG(DX,oldPosHi);
  GETREG(AX,oldPosLo);

  SETREG(AX,4202H);
  SETREG(BX,f);
  SETREG(CX,0);
  SETREG(DX,0);
  SWI(21H);		(* Przesun pointer na koniec pliku *)
  GETREG(DX,lenHi);
  GETREG(AX,lenLo);

  SETREG(AX,4200H);
  SETREG(BX,f);
  SETREG(CX,oldPosHi);
  SETREG(DX,oldPosLo);
  SWI(21H);		(* Odtworz stara pozycje pointera w pliku *)
  RETURN (oldPosHi = lenHi) & (oldPosLo = lenLo )
END EOF;

PROCEDURE Delete( fn : ARRAY OF CHAR );
VAR
  error : CARDINAL;
  str   : ARRAY[0..127] OF CHAR;
BEGIN
  Assign( fn, str ); (* bo ten glupi Logitech nie dodaje 0 na koncu stringu *)
  DOSCALL(41H, ADR(str), error);
END Delete;

PROCEDURE CD
          ( Path : ARRAY OF CHAR ) : BOOLEAN;
VAR
  error : CARDINAL;
  str : ARRAY[0..127] OF CHAR;

BEGIN
  Assign( Path, str ); (* bo ten glupi Logitech nie dodaje 0 na koncu stringu *)
  DOSCALL(3BH, ADR(str), error);
  RETURN error = 0;
END CD;

PROCEDURE MkDir
          ( Path : ARRAY OF CHAR ) : BOOLEAN;
VAR
  error : CARDINAL;
  str : ARRAY[0..127] OF CHAR;
BEGIN
  Assign( Path, str ); (* bo ten glupi Logitech nie dodaje 0 na koncu stringu *)
  DOSCALL(39H, ADR(str), error);
  RETURN error = 0;
END MkDir;

PROCEDURE RmDir
          ( Path : ARRAY OF CHAR );
VAR
  handle, error : CARDINAL;
  str : ARRAY[0..127] OF CHAR;
BEGIN
  Assign( Path, str ); (* bo ten glupi Logitech nie dodaje 0 na koncu stringu *)
  DOSCALL(3aH, ADR(str), error);
END RmDir;

PROCEDURE GetDir
          ( VAR Path : ARRAY OF CHAR );
VAR
  handle, error : CARDINAL;
  str : ARRAY[0..127] OF CHAR;
BEGIN
  str[0] := 0C;
  DOSCALL(47H, 0, ADR(str), error);
  Assign( str, Path );
  Insert( '\', Path, 0 );
END GetDir;

PROCEDURE Rename
          ( VAR dest, src : ARRAY OF CHAR ) : BOOLEAN;
VAR
  error : CARDINAL;
  old, new : ARRAY[0..127] OF CHAR;
BEGIN
  Assign( dest, new ); (* bo ten glupi Logitech nie dodaje 0 na koncu stringu *)
  Assign( src, old );  (* bo ten glupi Logitech nie dodaje 0 na koncu stringu *)
  DOSCALL(56H, ADR(old), ADR(new), error);
  RETURN error = 0;
END Rename;

PROCEDURE GetFileStamp
          ( f:File; VAR D,M,Y, h,m,s : CARDINAL );
VAR
  data, time : CARDINAL;
BEGIN
  SETREG( BX, f );
  SETREG( AX, 05700H );
  SWI( 021H );
  GETREG( CX, time );
  GETREG( DX, data );
  D := data MOD 32;
  M := data DIV 32 MOD 16;
  Y := (data DIV (32*16)) + 1980;
  s := time MOD 32 * 2;
  m := time DIV 32 MOD 64;
  h := time DIV (32*64);
END GetFileStamp;

CONST  (* The elements of the DTArea *)
  DriveSize   =  2; (* Drive letter + ":" *)
  FileSize    = 13; (* filename + "." + extension + 0C *)
  FileField   = 30; (* position in DTArea of beginning of filename *)
       (* DOS function numbers *)
  SetDTAddr   = 1AH;
  GetDTAddr   = 2FH;
  FindFirst   = 4EH;
  FindNext    = 4FH;
  DELETE      = 41H;
  RENAME      = 56H;

TYPE
  (* implementation dependent record *) 
  DTAType      = 
    RECORD
      Reserved   : ARRAY[0..20] OF CHAR;  (* OFFSET = 0   SIZE = 21 *)
      FileAttrib : Attributes;            (* OFFSET = 15H SIZE =  1 *)
      Time       : WORD;                  (* OFFSET = 16H SIZE =  2 *)
      Date       : WORD;                  (* OFFSET = 18H SIZE =  2 *)
      Size       : LONGINT;               (* OFFSET = 1AH SIZE =  4 *) 
      FileName   : T_FileName;            (* OFFSET = 1EH SIZE = 13 *)
    END;
    FileSpecType = ARRAY [0..65+FileSize] OF CHAR;

   (* one char longer than needed to introduce 0C for DOSCALLs *)

PROCEDURE DirQuery
          (    wildFileName : ARRAY OF CHAR;
               Attr         : Attributes;
               DirProc      : DirQueryProc;
               addPath      : BOOLEAN): BOOLEAN;
  (* Szuka wszystkich plikow o wzorcu w wildFileName i ustawionych atrybutach w
     w Attr. Dla kadego znalezionege pliku wywolywana jest procedura DirProc,  
     ktora przekazuje nazwe. Nazwa zawiera sciezke zawarta w wildFileName 
     jesli addPath
  *)

VAR
  DTArea        : DTAType;
  FileSpec      : FileSpecType;
  LastBackSlash : CARDINAL;
  i,j           : CARDINAL;
  result        : CARDINAL;
  GoOn          : BOOLEAN;
  oldDTA        : ADDRESS;

BEGIN
  i := 0;
  LastBackSlash := 0;
  IF addPath THEN
    LastBackSlash := 255;
    WHILE (i < HIGH(wildFileName) ) AND (wildFileName[i] # 0C) DO
      IF (wildFileName[i]="\") OR (wildFileName[i]=":") THEN 
        LastBackSlash := i 
      END;
      INC(i)
    END;
    IF LastBackSlash # 255 THEN
      FOR i:=0 TO LastBackSlash DO 
        FileSpec[i] := wildFileName[i] 
      END;
      INC(LastBackSlash)
    ELSE 
      LastBackSlash:=0;
    END;
  END (* IF *);

  DOSCALL(GetDTAddr, oldDTA );
  DOSCALL(SetDTAddr, ADR(DTArea));
  DOSCALL(FindFirst, ADR(wildFileName), Attr, result);
  GoOn := TRUE;
  WHILE (result = 0) AND GoOn
  DO
    WITH DTArea DO
      FileSpec[LastBackSlash] := 0C;
      Insert(FileName, FileSpec, i);
      DirProc(FileSpec, FileAttrib, GoOn);
    END (* WITH DTArea *);
    IF GoOn THEN (* DOSCALL only after TRUE return from DirProc *)
      DOSCALL(FindNext, result);
    END;
  END;
  DOSCALL(SetDTAddr, oldDTA);
  RETURN GoOn AND ( (result = 18) OR (result = 2) OR (result = 3) )
END DirQuery;

  (*$S-*)
  (*$T-*)
  (*$R-*)

PROCEDURE  CriticalErrorHandlerProc;
VAR
  DIReg : WORD;
  AXReg : WORD;
BEGIN
  SETREG(AX, 03); (* return and indicate fail call *)
END CriticalErrorHandlerProc;

  (*$S=*)
  (*$T=*)
  (*$R=*)

PROCEDURE Terminator(  );
  VAR
    i,j : CARDINAL;
  BEGIN
    FOR i := 5 TO HIGH(Files) DO
      IF Files[i][0] # 0C THEN
        FOR j := 0 TO 40000 DO
          Sound( j DIV 8 );
        END;
        FOR j := 40000 TO 0 BY -1 DO
          Sound( j DIV 2 );
        END;
        NoSound;
      END;
    END;
  END Terminator;

  PROCEDURE InitFiles(  );
  VAR
    i : CARDINAL;
  BEGIN
    FOR i := 5 TO HIGH(Files) DO
      Files[i, 0] := 0C;
    END;
    SetEventHandler( CriticalErrorRec, CriticalErrorHandlerProc, 
                     CriticalErrorHandler);
    InstallTermProc( Terminator );
  END InitFiles;
 
  
BEGIN
  InitFiles;
  lastErr := 0;
  opened := 0;
  maxOpened := 0;
  numErr := 0;
END FIO.
