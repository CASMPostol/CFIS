(*%T TV_NoDebug*)
(*# debug(vid=>off)*)
(*%E*)
(*%T InOneSegment *)
(*#call(seg_name=>TV)*)
(*%E*)
IMPLEMENTATION MODULE Streams;

FROM Objects IMPORT
  TObject, PObject, String, PString;
FROM Str IMPORT
  Length, Delete, Copy;
FROM Storage IMPORT
  ALLOCATE, DEALLOCATE;

  CLASS IMPLEMENTATION TStream;

    PROCEDURE CopyFrom(VAR S     : TStream;
                           Count : LONGCARD);
    VAR
      CopyBuffer : ARRAY [0..511] OF BYTE;

      PROCEDURE Copy(Count : CARDINAL);
      BEGIN
        S.Read(ADR(CopyBuffer), Count);
        Write(ADR(CopyBuffer), Count);
      END Copy;

    BEGIN
      WHILE Count >= SIZE(CopyBuffer) DO
        Copy(SIZE(CopyBuffer));
        DEC(Count, SIZE(CopyBuffer));
      END;
      Copy(VAL(CARDINAL, Count));
    END CopyFrom;

    VIRTUAL PROCEDURE Error(Code, Info: INTEGER);
    BEGIN
      IF StreamError # NULLPROC THEN
        StreamError;
      END;
    END Error;

    VIRTUAL PROCEDURE Flush;
    END Flush;

    PROCEDURE Get() : PObject;
    BEGIN
      RETURN NIL;
(* Cos tu powinno byc *)
    END Get;

    VIRTUAL PROCEDURE GetPos() : LONGCARD;
    BEGIN
      RETURN 0;
    END GetPos;

    VIRTUAL PROCEDURE GetSize(): LONGCARD;
    BEGIN
      RETURN 0;
    END GetSize;

    PROCEDURE Put(P: PObject);
    BEGIN
(* Cos tu powinno byc *)
    END Put;

    VIRTUAL PROCEDURE Read(Buf : ADDRESS; Count : CARDINAL);
    END Read;

    PROCEDURE Rd(VAR Buf : ARRAY OF BYTE);
    BEGIN
      Read(ADR(Buf), SIZE(Buf));
    END Rd;

    PROCEDURE ReadStr(MaxLen : CARDINAL): PString;
    VAR
      T : String;
      P : PString;
      i : CARDINAL;
    BEGIN
      i := 0;
      REPEAT
        Rd(T[i]);
        INC(i);
      UNTIL T[i-1] = 0C;
      IF Length(T) >= MaxLen THEN
        Delete(T, MaxLen-1, 0FFFH);
      END;
      ALLOCATE(P, Length(T)+1);
      Copy(P^, T);
      RETURN P;
    END ReadStr;

    PROCEDURE Reset;
    BEGIN
      Status := stOk;
      ErrorInfo := 0;
    END Reset;

    VIRTUAL PROCEDURE Seek(Pos: LONGCARD);
    END Seek;

    VIRTUAL PROCEDURE Truncate;
    END Truncate;

    VIRTUAL PROCEDURE Write(Buf : ADDRESS; Count : CARDINAL);
    END Write;

    PROCEDURE Wr(VAR Buf : ARRAY OF BYTE);
    BEGIN
      Write(ADR(Buf), SIZE(Buf));
    END Wr;

    PROCEDURE WriteStr(P: PString);
    BEGIN
      Write(P, Length(P^));
    END WriteStr;

  BEGIN
  END TStream;


BEGIN
  StreamError  := NULLPROC;
END Streams.