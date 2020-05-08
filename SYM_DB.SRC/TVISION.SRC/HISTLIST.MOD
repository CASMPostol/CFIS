(*%T TV_NoDebug*)
(*# debug(vid=>off)*)
(*%E*)
(*%T InOneSegment *)
(*#call(seg_name=>TV)*)
(*%E*)
IMPLEMENTATION MODULE HistList;

FROM Objects IMPORT
  PString, String;
FROM Lib IMPORT
  IncAddr, AddAddr, Move, Fill;
FROM Str IMPORT
  Copy, Length, Compare;
FROM Storage IMPORT
  ALLOCATE, DEALLOCATE;


TYPE
  PHistRecord = POINTER TO THistRecord;
  THistRecord = RECORD
    ID : SHORTCARD;
    Str : String;
  END;

VAR
  HistoryAvail : CARDINAL;
  VP : ValidateProc;

  (*INLINE*) PROCEDURE UpdateAvail;
  BEGIN
    HistoryAvail := HistorySize - HistoryUsed;
  END UpdateAvail;

  PROCEDURE HistoryAdd(Id: SHORTCARD; VAR Str: ARRAY OF CHAR);
  VAR
    p : PHistRecord;
  BEGIN
    IF HistoryBlock = NIL THEN
      InitHistory;
    END;
    IF NOT VP( Id, Str ) THEN
      RETURN;
    END;
    IF Length(Str)+2 <= HistoryAvail THEN
      p := HistoryBlock;
      IncAddr(p, HistoryUsed);
      p^.ID := Id;
      Copy(p^.Str, Str);
      INC(HistoryUsed, Length(p^.Str)+2);
      UpdateAvail;
    END;
  END HistoryAdd;

  PROCEDURE HistoryDelete(Id: SHORTCARD; Str: ARRAY OF CHAR);
  VAR
    Sum : CARDINAL;
    h : PHistRecord;
    Size : CARDINAL;
  BEGIN
    Sum := 0;
    IF HistoryBlock = NIL THEN
      RETURN;
    END;
    h := HistoryBlock;
    LOOP
      IF Sum >= HistoryUsed THEN
        EXIT;
      END;
      Size := Length(h^.Str)+2;
      IF (h^.ID = Id) & (Compare(Str, h^.Str) = 0) THEN
        Move( AddAddr( h, Size ), h, HistorySize-Sum-Size );
        DEC( HistoryUsed, Size );
        UpdateAvail;
        RETURN;
      END;
      INC( Sum, Size );
      h := AddAddr(HistoryBlock, Sum);
    END;
  END HistoryDelete;

  PROCEDURE HistoryCount(Id: SHORTCARD): CARDINAL;
  VAR
    Count : CARDINAL;
    h : PHistRecord;
    Size : CARDINAL;
    Sum : CARDINAL;
  BEGIN
    Count := 0;
    Sum := 0;
    IF HistoryBlock = NIL THEN
      RETURN 0;
    END;
    h := HistoryBlock;
    WHILE Sum < HistoryUsed DO
      IF h^.ID = Id THEN
        INC( Count );
      END;
      Size := Length(h^.Str)+2;
      INC( Sum, Size );
      h := AddAddr(HistoryBlock, Sum);
    END;
    RETURN Count;
  END HistoryCount;

  PROCEDURE HistoryStr(Id: SHORTCARD; Index: CARDINAL): PString;
  VAR
    Str : PString;
    ix : CARDINAL;
    Sum : CARDINAL;
    Size : CARDINAL;
    p : PHistRecord;
  BEGIN
    Str := NIL;
    ix := 0;
    Sum := 0;
    IF HistoryBlock = NIL THEN
      RETURN Str;
    END;
    p := HistoryBlock;
    WHILE Sum < HistoryUsed DO
      IF p^.ID = Id THEN
        IF ix = Index THEN
          RETURN ADR(p^.Str);
        END;
        INC( ix );
      END;
      Size := Length(p^.Str)+2;
      INC( Sum, Size );
      p := AddAddr(HistoryBlock, Sum);
    END;
    RETURN Str;
  END HistoryStr;

  PROCEDURE HistorySort( Id : SHORTCARD );
  VAR
    i   : CARDINAL;
    j   : CARDINAL;
    cnt : CARDINAL;
    s,
    s1   : String;
  BEGIN
    cnt := HistoryCount( Id );
    IF cnt = 0 THEN
      RETURN;
    END;
    FOR i := 0 TO cnt-1 DO
      s := 0377C+0C;
      FOR j := 0 TO cnt-1-i DO
        Copy( s1, HistoryStr( Id, j )^ );
        IF Compare( s1, s ) = -1 THEN
          Copy( s, s1 );
        END;
      END;
      HistoryDelete( Id, s );
      HistoryAdd( Id, s );
    END;
  END HistorySort;

  PROCEDURE ClearHistory;
  BEGIN
    Fill( HistoryBlock, HistorySize, 0 );
    HistoryUsed := 0;
    UpdateAvail;
  END ClearHistory;

  PROCEDURE InitHistory;
  BEGIN
    IF HistoryBlock = NIL THEN
      ALLOCATE( HistoryBlock, HistorySize );
      ClearHistory;
    END;
  END InitHistory;

  PROCEDURE DoneHistory;
  BEGIN
    IF HistoryBlock # NIL THEN
      DEALLOCATE( HistoryBlock, HistorySize );
    END;
  END DoneHistory;

  PROCEDURE AlwaysTRUE( c : SHORTCARD; VAR a : ARRAY OF CHAR ) : BOOLEAN;
  BEGIN
    RETURN TRUE;
  END AlwaysTRUE;

   PROCEDURE SetValidateProc( p : ValidateProc; VAR old : ValidateProc );
   BEGIN
     old := VP;
     VP := p;
   END SetValidateProc;

BEGIN
   HistoryBlock := NIL;
   HistorySize:= 1024;
   HistoryUsed:= 0;
   UpdateAvail;
   VP := AlwaysTRUE;
END HistList.