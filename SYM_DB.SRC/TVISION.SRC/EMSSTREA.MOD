(*%T TV_NoDebug*)
(*# debug(vid=>off)*)
(*%E*)
(*%T InOneSegment *)
(*#call(seg_name=>TV)*)
(*%E*)
IMPLEMENTATION MODULE EMSStreams;


  CLASS IMPLEMENTATION TEmsStream;

    PROCEDURE Init(MinSize, MaxSize: LONGCARD);
    END Init;

    VIRTUAL PROCEDURE Done;
    END Done;

    VIRTUAL PROCEDURE GetPos(): LONGCARD;
    BEGIN
      RETURN 0;
    END GetPos;

    VIRTUAL PROCEDURE GetSize(): LONGCARD;
    BEGIN
      RETURN 0;
    END GetSize;

    VIRTUAL PROCEDURE Read(Buf : ADDRESS; Count : CARDINAL);
    END Read;

    VIRTUAL PROCEDURE Seek(Pos: LONGCARD);
    END Seek;

    VIRTUAL PROCEDURE Truncate;
    END Truncate;

    VIRTUAL PROCEDURE Write(Buf : ADDRESS; Count : CARDINAL);
    END Write;

  BEGIN
  END TEmsStream;


BEGIN
  EmsCurPage   := 0FFFFH;
  EmsCurHandle := 0FFFFH;
END EMSStreams.