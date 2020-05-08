(*%T TV_NoDebug*)
(*# debug(vid=>off)*)
(*%E*)
(*%T InOneSegment *)
(*#call(seg_name=>TV)*)
(*%E*)
IMPLEMENTATION MODULE Resources;

FROM Streams IMPORT
  TStream, PStream;
FROM Objects IMPORT
  PString, PObject, String, DisposeStr, NewStr;
FROM Storage IMPORT
  ALLOCATE, DEALLOCATE;
FROM Str IMPORT
  Length;
FROM SYSTEM IMPORT
  TSIZE;

TYPE
  PResourceItem = POINTER TO TResourceItem;
  TResourceItem = RECORD
    Pos : LONGCARD;
    Size : LONGCARD;
    Key  : PString;
  END;

  CLASS IMPLEMENTATION TResourceCollection;

    VIRTUAL PROCEDURE FreeItem(Item: ADDRESS);
    VAR
      p : PResourceItem;
    BEGIN
      p := Item;
      IF p # NIL THEN
        DisposeStr( p^.Key );
        DISPOSE(p);
      END;
    END FreeItem;

    VIRTUAL PROCEDURE GetItem(VAR S: TStream): ADDRESS;
    VAR
      obj : PResourceItem;
    BEGIN
      NEW(obj);
      S.Rd(obj^.Pos);
      S.Rd(obj^.Size);
      obj^.Key := S.ReadStr(255);
      RETURN obj;
    END GetItem;

    VIRTUAL PROCEDURE KeyOf(Item: ADDRESS): ADDRESS;
    BEGIN
      RETURN PResourceItem(Item)^.Key;
    END KeyOf;

    VIRTUAL PROCEDURE PutItem(VAR S: TStream; Item: ADDRESS);
    VAR
      p : PResourceItem;
    BEGIN
      p := Item;
      S.Wr(p^.Pos);
      S.Wr(p^.Size);
      S.WriteStr(p^.Key);
    END PutItem;

  BEGIN
  END TResourceCollection;

CONST
  rStreamMagic = 52504246H; (* 'FBPR' *)
TYPE
  Count_type = RECORD
    LastCount : CARDINAL;
    PageCount : CARDINAL;
  END;

  Info_type = RECORD
    InfoType : CARDINAL;
    InfoSize : LONGCARD;
  END;

  PHeader = POINTER TO THeader;
  THeader = RECORD
    Signature : CARDINAL;
    CASE :BOOLEAN OF
    | FALSE :
        Count : Count_type;
    | TRUE:
        Info : Info_type;
    END;
  END;

  CLASS IMPLEMENTATION TResourceFile;

    PROCEDURE Init(AStream: PStream);
    VAR
      Header : PHeader;
      Found  : BOOLEAN;
      Repeat : BOOLEAN;
      StreamSize : LONGCARD;
    BEGIN
      Stream := AStream;
      BasePos := Stream^.GetPos();
      StreamSize := Stream^.GetSize();
      NEW(Header);
      Found := FALSE;
      REPEAT
        Repeat := FALSE;
        IF BasePos <= (StreamSize - TSIZE(THeader)) THEN
          Stream^.Seek(BasePos);
          Stream^.Rd(Header^);
          IF Header^.Signature = 5A4DH THEN
            INC(BasePos, VAL(LONGCARD, Header^.Count.PageCount * 512 +
                                       Header^.Count.LastCount MOD 512));
            Repeat := TRUE;
          ELSIF Header^.Signature = 4246H THEN
            IF Header^.Info.InfoType = 5250H THEN
              Found := TRUE;
            ELSE
              INC(BasePos, Header^.Info.InfoSize + 8);
              Repeat := TRUE;
            END;
          END;
        END;
      UNTIL NOT Repeat;
      IF Found THEN
        Stream^.Seek(BasePos + TSIZE(LONGCARD) * 2);
        Stream^.Rd(IndexPos);
        Stream^.Seek(BasePos + IndexPos);
        NEW(Index);
        Index^.Load( Stream^ );
      ELSE
        IndexPos :=  SIZE(LONGCARD) * 3;
        NEW(Index);
        Index^.Init(0, 8);
      END;
    END Init;

    VIRTUAL PROCEDURE Done;
    BEGIN
      Flush();
      Index^.Done;
      DISPOSE( Index );
      Stream^.Done;
      DISPOSE(Stream);
    END Done;

    PROCEDURE Count() : CARDINAL;
    BEGIN
      RETURN Index^.Count;
    END Count;

    PROCEDURE Delete(Key: ARRAY OF CHAR);
    VAR
      i : CARDINAL;
    BEGIN
      IF Index^.Search( ADR(Key), i) THEN
        Index^.Free(Index^.At(i));
        Modified := TRUE;
      END;
    END Delete;

    PROCEDURE Flush;
    VAR
      lenRez : LONGCARD;
      mag : LONGCARD;
    BEGIN
      IF Modified THEN
        Stream^.Seek(BasePos + IndexPos);
        Stream^.Wr(Index);
        lenRez := Stream^.GetPos() - BasePos - SIZE(LONGCARD) * 2;
        Stream^.Seek(BasePos);
        mag := rStreamMagic;
        Stream^.Wr(mag);
        Stream^.Wr(lenRez);
        Stream^.Wr(IndexPos);
        Stream^.Flush();
        Modified := FALSE;
      END;
    END Flush;

    PROCEDURE Get(Key: ARRAY OF CHAR): PObject;
    VAR
      i : CARDINAL;
      p : ADDRESS;
    BEGIN
      IF Index^.Search(ADR(Key), i) THEN
        RETURN NIL;
      END;
      Stream^.Seek(BasePos + (PResourceItem(Index^.At(i)))^.Pos);
      Stream^.Read(ADR(p), SIZE(p));
      RETURN p;
    END Get;

    PROCEDURE KeyAt(I: INTEGER): String;
    BEGIN
      RETURN PResourceItem(Index^.At(I))^.Key^;
    END KeyAt;

    PROCEDURE Put(Item: PObject; Key: ARRAY OF CHAR);
    VAR
      i : CARDINAL;
      p : PResourceItem;
    BEGIN
      IF Index^.Search( ADR(Key), i) THEN
        p := Index^.At(i);
      ELSE
        NEW(p);
        p^.Key := NewStr(Key);
        Index^.AtInsert(i, p);
      END;
      p^.Pos := IndexPos;
      Stream^.Seek(BasePos + IndexPos);
      Stream^.Write(ADR(Item), SIZE(Item));
      IndexPos := Stream^.GetPos() - BasePos;
      p^.Size  := IndexPos - p^.Pos;
      Modified := TRUE;
    END Put;

    PROCEDURE SwitchTo(AStream: PStream; Pack: BOOLEAN): PStream;
    BEGIN
      RETURN NIL;
    END SwitchTo;

  BEGIN
  END TResourceFile;


END Resources.