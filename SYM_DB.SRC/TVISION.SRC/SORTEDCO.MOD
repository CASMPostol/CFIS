(*%T TV_NoDebug*)
(*# debug(vid=>off)*)
(*%E*)
(*%T InOneSegment *)
(*#call(seg_name=>TV)*)
(*%E*)
IMPLEMENTATION MODULE SortedCollections;

FROM Streams IMPORT
  TStream;

  CLASS IMPLEMENTATION TSortedCollection;

    PROCEDURE Load(VAR S: TStream);
    BEGIN
      TCollection.Load( S );
      S.Rd(Duplicates);
    END Load;

    VIRTUAL PROCEDURE Compare(Key1, Key2: ADDRESS): INTEGER;
    BEGIN
      RETURN 0;
    END Compare;

    VIRTUAL PROCEDURE IndexOf(Item: ADDRESS): CARDINAL;
    VAR
      i : CARDINAL;
    BEGIN
      i := 0; (* Dostawienie moje *)
      IF Search( KeyOf(Item), i ) THEN
        RETURN MAX(CARDINAL);
      ELSE
        IF Duplicates THEN
          WHILE (i < Count) & (Item # Items^[i] ) DO
            INC(i);
          END;
        END;
        IF  i < Count THEN
          RETURN i;
        ELSE
          RETURN MAX(CARDINAL);
        END;
      END;
    END IndexOf;

    VIRTUAL PROCEDURE Insert(Item: ADDRESS);
    VAR
      i : CARDINAL;
    BEGIN
      IF NOT Search( KeyOf(Item), i ) OR Duplicates (* order dependency! *) THEN
         AtInsert( i, Item );
         (* must do Search before calling AtInsert *)
(*      ELSE
        AtInsert( Count, Item );*)
      END;
    END Insert;

    VIRTUAL PROCEDURE KeyOf(Item: ADDRESS): ADDRESS;
    BEGIN
      RETURN Item;
    END KeyOf;

    VIRTUAL PROCEDURE Search(Key: ADDRESS; VAR Index: CARDINAL): BOOLEAN;
    VAR
      l, h, i : INTEGER;
      c       : INTEGER;
      Res     : BOOLEAN;
    BEGIN
      Index := 0;
      IF Count = 0 THEN
        RETURN FALSE;
      END;
      l := 0;
      h := Count - 1;
      Res := FALSE;
      WHILE l <= h DO
        i := (l +  h) >> 1;
        c := Compare( KeyOf( Items^[i] ), Key );
        IF c < 0 THEN
          l := i + 1;
        ELSE
          h := i - 1;
          IF c = 0 THEN
            Res := TRUE;
            IF NOT Duplicates THEN
              l := i;
            END;
          END;
        END;
      END;
      Index := l;
      RETURN Res;
    END Search;

    PROCEDURE Store(VAR S: TStream);
    BEGIN
      TCollection.Store( S );
      S.Write(ADR(ORD(Duplicates)), SIZE(ORD(Duplicates)));
    END Store;

  BEGIN
    Duplicates := FALSE;
  END TSortedCollection;


END SortedCollections.