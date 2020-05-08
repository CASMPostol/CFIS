(*%T TV_NoDebug*)
(*# debug(vid=>off)*)
(*%E*)
(*%T InOneSegment *)
(*#call(seg_name=>TV)*)
(*%E*)
IMPLEMENTATION MODULE Collections;

FROM Streams IMPORT
  TStream;
FROM Lib IMPORT
  Move, SetReturnCode, Fill;
FROM Storage IMPORT
  ALLOCATE, DEALLOCATE;

  CLASS IMPLEMENTATION TCollection;

    PROCEDURE Init(ALimit, ADelta : CARDINAL);
    BEGIN
      Count := 0;
      Items := NIL;
      Limit := 0;
      Delta := ADelta;
      ShouldDelete := TRUE;
      SetLimit(ALimit);
    END Init;

    PROCEDURE Load(VAR S: TStream);
    VAR
      Lim   : CARDINAL;
      i     : CARDINAL;
    BEGIN
      S.Rd(Count);
      S.Rd(Lim);
      S.Rd(Delta);
      Limit := 0;
      SetLimit(Lim);
      FOR i := 0 TO Count-1 DO
        Items^[i] := GetItem(S)
      END;
    END Load;

    VIRTUAL PROCEDURE Done;
    BEGIN
      IF ShouldDelete THEN
        FreeAll();
      END;
      SetLimit(0);
      TObject.Done();
    END Done;

    PROCEDURE At(Index: CARDINAL): ADDRESS;
    BEGIN
      RETURN Items^[Index];
    END At;

    PROCEDURE AtDelete(Index: CARDINAL);
    BEGIN
      IF Index >= Count THEN
        Error(1,0);
      END;
      DEC(Count);
      Move(ADR(Items^[Index+1]), ADR(Items^[Index]), (Count-Index)*SIZE(ADDRESS));
    END AtDelete;

    PROCEDURE AtFree(Index: CARDINAL);
    VAR
      Item : ADDRESS;
    BEGIN
      Item := At( Index );
      AtDelete( Index );
      FreeItem( Item );
    END AtFree;

    PROCEDURE AtInsert(Index: CARDINAL; Item: ADDRESS);
    BEGIN
      IF Count = Limit THEN
        SetLimit(Count + Delta);
      END;
      Move(ADR(Items^[Index]), ADR(Items^[Index+1]), (Count-Index)*SIZE(ADDRESS));
      INC(Count);
      Items^[Index] := Item;
    END AtInsert;

    PROCEDURE AtPut(Index: CARDINAL; Item: ADDRESS);
    BEGIN
      Items^[Index] := Item;
    END AtPut;

    PROCEDURE Delete(Item: ADDRESS);
    BEGIN
      AtDelete( IndexOf(Item) );
    END Delete;

    PROCEDURE DeleteAll;
    BEGIN
      Count := 0;
    END DeleteAll;

    VIRTUAL PROCEDURE Error(Code, Info: INTEGER);
    BEGIN
      SetReturnCode(212 - VAL(SHORTCARD, Code));
      HALT;
    END Error;

    PROCEDURE FirstThat(Test: BoolProcAddr; arg : ADDRESS): ADDRESS;
    VAR
      i : CARDINAL;
    BEGIN
      FOR i := 0 TO Count-1 DO
        IF Test( Items^[i], arg ) THEN
            RETURN Items^[i];
        END;
      END;
      RETURN NIL;
    END FirstThat;

    PROCEDURE ForEach(Action: ProcAddr; arg : ADDRESS);
    VAR
      i : CARDINAL;
    BEGIN
      FOR i := 0 TO Count-1 DO
        Action( Items^[i], arg );
      END;
    END ForEach;

    PROCEDURE Free(Item: ADDRESS);
    BEGIN
      Delete( Item );
      FreeItem( Item );
    END Free;

    PROCEDURE FreeAll;
    VAR
      i : CARDINAL;
    BEGIN
      FOR i := 1 TO Count DO
        FreeItem( At(i-1) );
      END;
      Count := 0;
    END FreeAll;

    VIRTUAL PROCEDURE FreeItem(Item: ADDRESS);
    BEGIN
(*      DISPOSE(Item); *)
    END FreeItem;

    VIRTUAL PROCEDURE GetItem(VAR S: TStream): ADDRESS;
    BEGIN
      RETURN NIL;
    END GetItem;

    VIRTUAL PROCEDURE IndexOf(Item: ADDRESS): CARDINAL;
    VAR
      i : CARDINAL;
    BEGIN
      FOR i := 0 TO Count-1 DO
        IF Item = Items^[i] THEN
          RETURN i;
        END;
      END;
      Error(1,0);
    END IndexOf;

    VIRTUAL PROCEDURE Insert(Item: ADDRESS);
    BEGIN
      AtInsert( Count, Item );
    END Insert;

    PROCEDURE LastThat(Test: BoolProcAddr; arg : ADDRESS): ADDRESS;
    VAR
      i : CARDINAL;
    BEGIN
      FOR i := Count-1 TO 0 BY -1 DO
        IF Test( Items^[i], arg ) THEN
            RETURN Items^[i];
        END;
      END;
      RETURN NIL;
    END LastThat;

    PROCEDURE Pack;
    VAR
      OldItems : PItemList;
      i, OldCount : CARDINAL;
    BEGIN
      OldItems := Items;
      OldCount := Count;
      Count := 0;
      FOR i := 0 TO OldCount-1 DO
        IF OldItems^[i] # NIL THEN
          Items^[Count] := OldItems^[i];
          INC(Count);
        END;
      END;
    END Pack;

    VIRTUAL PROCEDURE PutItem(VAR S: TStream; Item: ADDRESS);
    END PutItem;

    VIRTUAL PROCEDURE SetLimit(ALimit: CARDINAL);
    VAR
      AItems : PItemList;
    BEGIN
      IF ALimit < Count THEN
        ALimit := Count;
      END;
      IF ALimit > MaxCollectionSize THEN
        ALimit := MaxCollectionSize;
      END;
      IF ALimit # Limit THEN
        IF ALimit = 0 THEN
          AItems := NIL;
        ELSE
          ALLOCATE(AItems, ALimit*SIZE(AItems^[0]));
          Fill( AItems, ALimit*SIZE(AItems^[0]), 0 );
          IF Count # 0 THEN
            Move(Items, AItems, Count*SIZE(AItems^[0]));
          END;
        END;
        IF Items # NIL THEN
          DEALLOCATE (Items, Limit*SIZE(Items^[0]));
        END;
        Items :=  AItems;
        Limit :=  ALimit;
      END;
    END SetLimit;

    PROCEDURE Store(VAR S: TStream);
    VAR
      i : CARDINAL;
    BEGIN
      S.Write(ADR(Count), SIZE(Count));
      S.Write(ADR(Limit), SIZE(Delta));
      S.Write(ADR(Delta), SIZE(Delta));
      FOR i := 0 TO Count DO
        PutItem(S, Items^[i] );
      END;
    END Store;

  BEGIN
  END TCollection;


END Collections.