(*%T TV_NoDebug*)
(*# debug(vid=>off)*)
(*%E*)
(*%T InOneSegment *)
(*#call(seg_name=>TV)*)
(*%E*)
IMPLEMENTATION MODULE ParamTexts;

FROM Objects IMPORT
  TRect;
FROM Streams IMPORT
  TStream;
FROM stdio IMPORT
  sprintf;

  CLASS IMPLEMENTATION TParamText;

    PROCEDURE Init(VAR Bounds: TRect;
                       AText: ARRAY OF CHAR;
                       AParamCount: INTEGER);
    BEGIN
      TStaticText.Init( Bounds, AText);
      ParamCount := AParamCount;
    END Init;

    PROCEDURE Load(VAR S: TStream);
    BEGIN
      TStaticText.Load(S);
    END Load;

    VIRTUAL PROCEDURE DataSize(): CARDINAL;
    BEGIN
      RETURN ParamCount * SIZE(ADDRESS);
    END DataSize;

    VIRTUAL PROCEDURE GetText(VAR S: ARRAY OF CHAR);
    BEGIN
      IF Text = NIL THEN
        S[0] := 0C;
      ELSE
        sprintf( S, Text^, ParamList );
      END;
    END GetText;

    VIRTUAL PROCEDURE SetData(VAR Rec : ARRAY OF BYTE);
    BEGIN
      ParamList := ADR(Rec);
    END SetData;

    PROCEDURE Store(VAR S: TStream);
    BEGIN
      TStaticText.Store(S);
    END Store;

  BEGIN
    ParamList := NIL;
  END TParamText;


END ParamTexts.