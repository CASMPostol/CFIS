(*$O+*)
(*
 * 03-13-97 12:52pm: MM
 *      Zwiekszylem dlugosc nazwy pliku bo nie mozna podejrzec czego nie
 *      zamyka
 *)

IMPLEMENTATION MODULE FIO;

FROM Strings IMPORT
  Assign, Insert;
FROM SYSTEM IMPORT
  DOSCALL, ADDRESS, ADR, CODE, SETREG, AX,BX, CX, DS, DX, SWI, GETREG;
FROM RTSMain IMPORT
  Terminate, Status, InstallTermProc;
FROM Sounds IMPORT
  Sound, NoSound;

TYPE
  FileName = ARRAY [0..30] OF CHAR;

VAR
  lastErr: CARDINAL;
  numErr: CARDINAL;
  opened: CARDINAL;
  maxOpened: CARDINAL;

  Files    : ARRAY[5..100] OF FileName;



PROCEDURE Open( FileName : ARRAY OF CHAR ) : File;
CONST RWmode = 2;
VAR
  handle, error : CARDINAL;
  str : ARRAY[0..127] OF CHAR;
BEGIN
  Assign( FileName, str ); (* bo ten glupi Logitech nie dodaje 0 na koncu stringu *)
  DOSCALL(3DH, ADR(str),RWmode , handle, error);
  IF error<>0 THEN
(*    Terminate( Warning );*)
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
END Open;

PROCEDURE Create( FileName : ARRAY OF CHAR ) : File;
VAR
  handle, error : CARDINAL;
  str : ARRAY[0..127] OF CHAR;
BEGIN
  Assign( FileName, str ); (* bo ten glupi Logitech nie dodaje 0 na koncu stringu *)
  DOSCALL(3CH, ADR(str), 0, handle, error);
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

PROCEDURE Close(VAR f : File );
VAR
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

PROCEDURE Seek( f : File; Pos : LONGINT; Mode : SeekMode ) : LONGINT;
VAR
  q : RECORD
    CASE BOOLEAN OF
    | FALSE: lo : LONGINT;
    | TRUE:  loword,hiword : CARDINAL;
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
VAR rAX : CARDINAL;
BEGIN
(*  DOSCALL(READ, handle, BuffSize, ADR(buffer), validLength, error); *)
  SETREG(AX,3F00H);
  SETREG(BX,f);
  SETREG(DS,buff.SEGMENT);
  SETREG(DX,buff.OFFSET);
  SETREG(CX,Size);
  SWI(21H);
  GETREG(AX,rAX);
  RETURN rAX=Size;
END Read;

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
  str : ARRAY[0..127] OF CHAR;
BEGIN
  Assign( fn, str ); (* bo ten glupi Logitech nie dodaje 0 na koncu stringu *)
  DOSCALL(41H, ADR(str), error);
END Delete;

PROCEDURE CD( Path : ARRAY OF CHAR ) : BOOLEAN;
VAR
  error : CARDINAL;
  str : ARRAY[0..127] OF CHAR;
BEGIN
  Assign( Path, str ); (* bo ten glupi Logitech nie dodaje 0 na koncu stringu *)
  DOSCALL(3BH, ADR(str), error);
  RETURN error = 0;
END CD;

PROCEDURE MkDir( Path : ARRAY OF CHAR ) : BOOLEAN;
VAR
  error : CARDINAL;
  str : ARRAY[0..127] OF CHAR;
BEGIN
  Assign( Path, str ); (* bo ten glupi Logitech nie dodaje 0 na koncu stringu *)
  DOSCALL(39H, ADR(str), error);
  RETURN error = 0;
END MkDir;

PROCEDURE RmDir( Path : ARRAY OF CHAR );
VAR
  handle, error : CARDINAL;
  str : ARRAY[0..127] OF CHAR;
BEGIN
  Assign( Path, str ); (* bo ten glupi Logitech nie dodaje 0 na koncu stringu *)
  DOSCALL(3aH, ADR(str), error);
END RmDir;

PROCEDURE GetDir( VAR Path : ARRAY OF CHAR );
VAR
  handle, error : CARDINAL;
  str : ARRAY[0..127] OF CHAR;
BEGIN
  str[0] := 0C;
  DOSCALL(47H, 0, ADR(str), error);
  Assign( str, Path );
  Insert( '\', Path, 0 );
END GetDir;

PROCEDURE Rename( VAR dest, src : ARRAY OF CHAR ) : BOOLEAN;
VAR
  error : CARDINAL;
  old, new : ARRAY[0..127] OF CHAR;
BEGIN
  Assign( dest, new ); (* bo ten glupi Logitech nie dodaje 0 na koncu stringu *)
  Assign( src, old ); (* bo ten glupi Logitech nie dodaje 0 na koncu stringu *)
  DOSCALL(56H, ADR(old), ADR(new), error);
  RETURN error = 0;
END Rename;

PROCEDURE GetFileStamp( f:File; VAR D,M,Y, h,m,s : CARDINAL );
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
  DTASize     = 43;
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
  DTAType      = ARRAY [0..DTASize-1] OF CHAR;
  FileSpecType = ARRAY [0..65+FileSize] OF CHAR;

   (* one char longer than needed to introduce 0C for DOSCALLs *)


PROCEDURE DirQuery(    WildFileName : ARRAY OF CHAR;
                       a            : Attributes;
                       DirProc      : DirQueryProc );
VAR
  DTArea        : DTAType;
  FileSpec      : FileSpecType;
  LastBackSlash : CARDINAL;
  i,j           : CARDINAL;
  result        : CARDINAL;
  foundOne      : BOOLEAN;
  GoOn          : BOOLEAN;
  oldDTA        : ADDRESS;

BEGIN
  LastBackSlash:=255;
  i:=0;
  WHILE (i< HIGH(WildFileName)) AND (WildFileName[i]#0C) DO
    IF (WildFileName[i]="\") OR (WildFileName[i]=":") THEN LastBackSlash:=i END;
    INC(i)
  END;
  IF LastBackSlash#255 THEN
    FOR i:=0 TO LastBackSlash DO FileSpec[i]:=WildFileName[i] END;
    INC(LastBackSlash)
  ELSE
    LastBackSlash:=0;
  END;
  foundOne := FALSE;

  DOSCALL(GetDTAddr,oldDTA );
  DOSCALL(SetDTAddr,ADR(DTArea));
  DOSCALL(FindFirst,ADR(WildFileName),a,result);
  GoOn := TRUE;
  WHILE (result#18) AND (result#2) AND (result#3) (* see DOS 2.0/3.x Manual ! *)
        AND GoOn DO
    foundOne := TRUE;
    i:=LastBackSlash; j:= FileField;
    WHILE DTArea[j]#0C DO
      FileSpec[i] := DTArea[j];
      INC(i); INC(j)
    END;

    FileSpec[i]:=0C;
    DirProc(FileSpec,GoOn);
    IF GoOn THEN (* DOSCALL only after TRUE return from DirProc *)
      DOSCALL(FindNext,result);
    END;
  END;
  DOSCALL(SetDTAddr,oldDTA);
END DirQuery;


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
      Files[i][0] := 0C;
    END;
    InstallTermProc( Terminator );
  END InitFiles;

BEGIN
  InitFiles;
  lastErr := 0;
  opened := 0;
  maxOpened := 0;
  numErr := 0;
END FIO.
