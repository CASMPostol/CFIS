(*%T TV_NoDebug*)
(*# debug(vid=>off)*)
(*%E*)
(*%T InOneSegment *)
(*#call(seg_name=>TV)*)
(*%E*)
IMPLEMENTATION MODULE ListBoxes;

FROM Collections IMPORT
  PCollection;
FROM ScrollBars IMPORT
  PScrollBar;
FROM Objects IMPORT
  TRect, String, PString;
FROM Streams IMPORT
  TStream;
FROM Str IMPORT
  Copy, Delete;

TYPE
  PListBoxRec = POINTER TO TListBoxRec;
  TListBoxRec = RECORD
    List : PCollection;
    Selection : CARDINAL;
  END;

  CLASS IMPLEMENTATION TListBox;

    PROCEDURE Init(VAR Bounds: TRect;
                       ANumCols: CARDINAL;
                       AScrollBar: PScrollBar);
    BEGIN
      TListViewer.Init( Bounds, ANumCols, NIL, AScrollBar);
      List := NIL;
      SetRange(0);
    END Init;

    PROCEDURE Load(VAR S: TStream);
    BEGIN
      TListViewer.Load( S );
      List^.Load( S );
    END Load;

    VIRTUAL PROCEDURE DataSize(): CARDINAL;
    BEGIN
      RETURN SIZE(TListBoxRec);
    END DataSize;

    VIRTUAL PROCEDURE GetData(VAR Rec : ARRAY OF BYTE);
    VAR
      p : PListBoxRec;
    BEGIN
      p := ADR(Rec);
      p^.List := List;
      p^.Selection := Focused;
    END GetData;

    VIRTUAL PROCEDURE GetText( Item: INTEGER;
                               MaxLen: INTEGER): String;
    VAR
      s : String;
    BEGIN
      IF List # NIL THEN
        Copy (s, PString(List^.At(Item))^);
      ELSE
        s[0] := 0C;
      END;
      Delete(s, MaxLen, 0FFFH);
      RETURN s;
    END GetText;

    VIRTUAL PROCEDURE Done;
    BEGIN
      List^.FreeAll;
      TListViewer.Done;
    END Done;

    VIRTUAL PROCEDURE NewList(AList: PCollection);
    BEGIN
      IF List # NIL THEN
        List^.FreeAll;
      END;
      List := AList;
      IF AList # NIL THEN
        SetRange( AList^.Count);
      ELSE
        SetRange(0);
      END;
      IF Range > 0 THEN
        FocusItem(0);
      END;
      DrawView;
    END NewList;

    VIRTUAL PROCEDURE SetData(VAR Rec: ARRAY OF BYTE);
    VAR
      p : PListBoxRec;
    BEGIN
      p := ADR(Rec);
      NewList(p^.List);
      FocusItem(p^.Selection);
      DrawView;
    END SetData;

    PROCEDURE Store(VAR S: TStream);
    BEGIN
      TListViewer.Store( S );
      List^.Store( S );
    END Store;

  BEGIN
  END TListBox;


END ListBoxes.