(*%T TV_NoDebug*)
(*# debug(vid=>off)*)
(*%E*)
(*%T InOneSegment *)
(*#call(seg_name=>TV)*)
(*%E*)
IMPLEMENTATION MODULE StringLists;

FROM Streams IMPORT
  TStream;
FROM Storage IMPORT
  ALLOCATE, DEALLOCATE;
FROM SYSTEM IMPORT
  TSIZE;
FROM Objects IMPORT
  String;
FROM Str IMPORT
  Length, Slice;

CONST
  MAXKEYS = 16;

  CLASS IMPLEMENTATION TStringList;

    PROCEDURE Load(VAR S: TStream);
    VAR
      StrSize : CARDINAL;
    BEGIN
     ip := ADR( S );
     S.Rd(StrSize);
     BasePos := S.GetPos();
     S.Seek( BasePos + VAL(LONGCARD, StrSize ));
     S.Rd( IndexSize );
     ALLOCATE(Index, IndexSize*TSIZE( TStrIndexRec ));
     S.Read( Index, IndexSize * SIZE( TStrIndexRec ) );
    END Load;

    VIRTUAL PROCEDURE Done;
    BEGIN
      DEALLOCATE (Index, IndexSize*TSIZE( TStrIndexRec ));
    END Done;

    PROCEDURE Get(Key: CARDINAL): String;
    VAR
      cur : CARDINAL;
      count : CARDINAL;
      sz    : SHORTCARD;
      Dest : String;
    BEGIN
      IF IndexSize = 0 THEN
        RETURN '';
      END;
      WHILE (Index^[cur].Key + MAXKEYS < Key) & (cur < IndexSize ) DO
        INC(cur);
      END;
      IF Index^[cur].Key + MAXKEYS < Key  THEN
        RETURN '';
      END;
      ip^.Seek( BasePos + VAL(LONGCARD, Index^[cur].Offset ));
      count := Key - Index^[cur].Key;
      LOOP
        ip^.Rd(sz);
        ip^.Read( ADR(Dest), ORD(sz) );
        Dest[ORD(sz)] := 0C;
        IF count = 0 THEN
          EXIT;
        END;
        DEC(count)
      END;
    END Get;

  BEGIN
  END TStringList;

  CLASS IMPLEMENTATION TStrListMaker;

    PROCEDURE Init(AStrSize, AIndexSize: CARDINAL);
    BEGIN
      StrSize := AStrSize;
      IndexSize := AIndexSize;
      ALLOCATE(Strings, AStrSize);
      ALLOCATE(Index, AIndexSize*SIZE(Index^[0]));
      StrPos := 0;
      IndexPos := 0;
    END Init;

    VIRTUAL PROCEDURE Done;
    BEGIN
      DEALLOCATE( Strings, StrSize );
      DEALLOCATE( Index, IndexSize*SIZE(Index^[0]));
      TObject.Done;
    END Done;

    PROCEDURE CloseCurrent;
    BEGIN
      IF Cur.Count # 0 THEN
        Index^[IndexPos] := Cur;
        INC(IndexPos);
        Cur.Count := 0;
      END;
    END CloseCurrent;

    PROCEDURE Put(Key: CARDINAL; str: ARRAY OF CHAR);
    VAR
      Len : CARDINAL;
    BEGIN
      IF ( Cur.Count = MAXKEYS ) OR ( Key # Cur.Key + Cur.Count ) THEN
        CloseCurrent();
      END;
      IF Cur.Count = 0 THEN
        Cur.Key := Key;
        Cur.Offset := StrPos;
      END;
      Len := Length( str );
      Strings^[StrPos] := CHR(Len);
      Slice(str, Strings^, StrPos+1, Len );
      INC(StrPos, Len+1);
      INC(Cur.Count);
    END Put;

    PROCEDURE Store(VAR S: TStream);
    BEGIN
     CloseCurrent();
     S.Wr(StrPos);
     S.Write( Strings, StrPos );
     S.Wr(IndexPos);
     S.Write( Index, IndexPos * TSIZE( TStrIndexRec ) );
    END Store;

  BEGIN
  END TStrListMaker;



END StringLists.