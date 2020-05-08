(*%T TV_NoDebug*)
(*# debug(vid=>off)*)
(*%E*)
(*%T InOneSegment *)
(*#call(seg_name=>TV)*)
(*%E*)
IMPLEMENTATION MODULE StringCollections;

IMPORT
  Str, Objects, Storage;

  CLASS IMPLEMENTATION TStringCollection;

    VIRTUAL PROCEDURE Compare(Key1, Key2: ADDRESS): INTEGER;
    BEGIN
      RETURN Str.Compare(Objects.PString(Key1)^, Objects.PString(Key2)^);
    END Compare;

    VIRTUAL PROCEDURE FreeItem(Item: ADDRESS);
    BEGIN
      Objects.DisposeStr( Objects.PString(Item));
    END FreeItem;

    VIRTUAL PROCEDURE GetItem(VAR S: Streams.TStream): ADDRESS;
    BEGIN
      RETURN S.ReadStr(255);
    END GetItem;

    VIRTUAL PROCEDURE PutItem(VAR S: Streams.TStream; Item: ADDRESS);
    BEGIN
      S.WriteStr(Objects.PString(Item));
    END PutItem;

  BEGIN
  END TStringCollection;



END StringCollections.