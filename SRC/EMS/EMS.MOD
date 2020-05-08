(* $ R-*)
(*$S-*)
(* $ T-*)
(*$O+*)
IMPLEMENTATION MODULE EMS;

FROM SYSTEM IMPORT
  ADDRESS, ADR, SWI, SETREG, GETREG, AX,BX,CX,DX,DS, CODE;
FROM RTSMain IMPORT
  Terminate, Status, InstallTermProc;
FROM Sounds IMPORT
  Sound, NoSound;
IMPORT
  Terminal, NumberConversion;
  
CONST
  EMSInt = 67h;
TYPE
  ems = CARDINAL;
VAR
  Lista : ARRAY[0..64] OF BOOLEAN;
  
  
PROCEDURE Error( c : CARDINAL );
VAR
  ErrorS : ARRAY [0..127] OF CHAR;
  b	 : BOOLEAN;
BEGIN
  b := FALSE;
  CASE c OF
    80H:
      ErrorS := 'Internal EMS driver Error';
  | 81H:
      ErrorS := 'EMS Hardware failure';
  | 82H:
      ErrorS := 'EMS Busy';
  | 83H:
      ErrorS := 'Invalid EMS handle';
  | 84H:
      ErrorS := 'Undefined EMS function';
  | 85H:
      ErrorS := 'No more EMS handles available';
  | 86H:
      ErrorS := 'Error in save or restore of EMS map context';
  | 87H:
      ErrorS := 'Not enough EMS logical pages physically available';
  | 88H:
      ErrorS := 'Not enough EMS pages available';
  | 89H:
      ErrorS := 'Zero EMS allocation';
  | 8aH:
      ErrorS := 'Logical EMS page number out of range';
  | 8bH:
      ErrorS := 'Illegal EMS physical page number';
  | 8cH:
      ErrorS := 'EMS Mapping save area full';
  | 8dH:
      ErrorS := 'EMS Mapping context save failed (already saved)';
  | 8eH:
      ErrorS := 'EMS Mapping context restore failed (not saved)';
  | 8fH:
      ErrorS := 'EMS Subfunction parameter undefined';
  ELSE
      ErrorS := 'Other EMS Error';
      b := TRUE;
  END;
  Terminal.WriteString( ErrorS );
  IF b THEN
    Terminal.WriteString( '  (' );
    NumberConversion.NumToString( c, 16, ErrorS, 2 );
    Terminal.WriteString( ErrorS );
    Terminal.WriteString( 'H)' );
  END;
  Terminate( Warning );
END Error;

PROCEDURE GetFrameSegment():CARDINAL;
VAR
  ax,s : CARDINAL;
BEGIN
  SETREG(AX,04100H);
  SWI(EMSInt);
  GETREG(AX,ax);
  GETREG(BX,s);
  IF ax >=100H THEN
    Error( ax DIV 100H );
  END;
  RETURN s;
END GetFrameSegment;

PROCEDURE Close( e : ems );
VAR
  ax: CARDINAL;
BEGIN
  IF NOT Lista[e] THEN
    FOR ax := 0 TO 40000 DO
      Sound( 300+ax DIV 100 );
    END;
    NoSound;
    Terminate( Stopped );
  END;
  Lista[e] := FALSE;
  SETREG(AX,04500H);
  SETREG(DX,e);
  SWI(EMSInt);
  GETREG(AX,ax);
  IF ax >=100H THEN
    Error( ax DIV 100H );
  END;
END Close;

PROCEDURE GetFreePages():CARDINAL;
VAR ax,s : CARDINAL;
BEGIN
  SETREG(AX,04200H);
  SWI(EMSInt);
  GETREG(AX,ax);
  GETREG(BX,s);
  IF ax >=100H THEN
    Error( ax DIV 100H );
  END;
  RETURN s;
END GetFreePages;

PROCEDURE AllocatePages( NumOfPages : CARDINAL ) : ems;
VAR ax,s : CARDINAL;
BEGIN
  SETREG(AX,04300H);
  SETREG(BX, NumOfPages);
  SWI( EMSInt);
  GETREG(AX,ax);
  GETREG(DX,s);
  IF ax >=100H THEN
    Error( ax DIV 100H );
  END;
  Lista[s] := TRUE;
  RETURN s;
END AllocatePages;

PROCEDURE Map( e : ems; PageNum : CARDINAL; SubPage : CARDINAL );
VAR
  ax : CARDINAL;
BEGIN
  ax := SubPage+4400H;
  SETREG(AX,ax);
  SETREG(BX,PageNum);
  SETREG(DX, e);
  SWI( EMSInt );
  GETREG(AX,ax);
  IF ax >=100H THEN
    Error( ax DIV 100H );
  END;
END Map;

PROCEDURE Init;
VAR
  s : ARRAY[0..100] OF CHAR;
  a : ADDRESS;
  q, f : CARDINAL;
BEGIN
  FOR f := 0 TO HIGH( Lista ) DO
    Lista[f] := FALSE;
  END;
(*  RETURN;*)
  s := "EMMXXXX0";
  a := ADR(s);
  SETREG( DS, a.SEGMENT );
  SETREG( DX, a.OFFSET );
  SETREG( AX, 3d02h );
  SWI( 21H );
  GETREG( AX, f );
  CODE( 09ch, 058h );
  GETREG( AX, q );
  IF NOT ODD(q) THEN
    SETREG( BX, f );
    SETREG( AX, 4407h );
    SWI( 21H );
    GETREG( AX, q );
    IF q MOD 100H # 0 THEN
      SETREG( BX, f );
      SETREG( AX, 03e00h );
      SWI( 21H );
      RETURN;
    END;
  END;
  s := "Program wymaga zainstalowania sterownika EMS!$";
  SETREG( DS, a.SEGMENT );
  SETREG( DX, a.OFFSET );
  SETREG( AX, 900H );
  SWI( 21H );
  Terminate( Stopped );
END Init;


PROCEDURE ZwrocNieoddaneBloki;
VAR
  i, j : CARDINAL;
BEGIN
  FOR i := 0 TO HIGH( Lista ) DO
    IF Lista[i] THEN
      FOR j := 0 TO 40000 DO
        Sound( j DIV 4 );
      END;
      FOR j := 40000 TO 0 BY -1 DO
        Sound( j DIV 4 );
      END;
      NoSound;
      Close( i );
    END;
  END;
END ZwrocNieoddaneBloki;

BEGIN
  Init;  
  InstallTermProc( ZwrocNieoddaneBloki );
END EMS.
