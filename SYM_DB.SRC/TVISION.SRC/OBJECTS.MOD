(*%T TV_NoDebug*)
(*# debug(vid=>off)*)
(*%E*)
(*%T InOneSegment *)
(*#call(seg_name=>TV)*)
(*%E*)
IMPLEMENTATION MODULE Objects;

FROM Lib IMPORT
  Fill, Move, SetReturnCode;
FROM Str IMPORT
  Length, Delete, Copy, Slice;
IMPORT
  Str;
FROM Storage IMPORT
  ALLOCATE, DEALLOCATE;

  CLASS IMPLEMENTATION TObject;

  PROCEDURE Free;
(*  TObject.Free disposes of the object and calls the Done destructor. *)
  END Free;

  VIRTUAL PROCEDURE Done;
(*  TObject.Done performs the necessary cleanup and disposal for dynamic objects. *)
  END Done;

  BEGIN
(*
allocates space on the heap for the object and fills it with zeros.
It is called by all derived objects' constructors.
TStream and TStringList directly inherit their Init method from TObject.
þ NOTE: This will zero all fields in descendants.
*)
(*    Fill(ADR(SELF), SIZE(SELF), 0); *)
  END TObject;

  CLASS IMPLEMENTATION TRect;

    PROCEDURE Assign(XA, YA, XB, YB: INTEGER);
    BEGIN
      A.X := XA;
      A.Y := YA;
      B.X := XB;
      B.Y := YB;
    END Assign;

    PROCEDURE Move(ADX, ADY: INTEGER);
    BEGIN
      INC(A.X, ADX);
      INC(B.X, ADX);
      INC(A.Y, ADY);
      INC(B.Y, ADY);
    END Move;

    PROCEDURE Grow(ADX, ADY: INTEGER);
    BEGIN
      DEC(A.X, ADX);
      INC(B.X, ADX);
      DEC(A.Y, ADY);
      INC(B.Y, ADY);
    END Grow;

    PROCEDURE Intersect(R: TRect);
    BEGIN
      A.X := Max( A.X, R.A.X );
      A.Y := Max( A.Y, R.A.Y );
      B.X := Min( B.X, R.B.X );
      B.Y := Min( B.Y, R.B.Y );
    END Intersect;

    PROCEDURE Union(R: TRect);
    BEGIN
      A.X := Min( A.X, R.A.X );
      A.Y := Min( A.Y, R.A.Y );
      B.X := Max( B.X, R.B.X );
      B.Y := Max( B.Y, R.B.Y );
    END Union;

    PROCEDURE Contains(P: TPoint): BOOLEAN;
    BEGIN
      RETURN (P.X >= A.X) & (P.X < B.X) & (P.Y >= A.Y) & (P.Y < B.Y);
    END Contains;

    PROCEDURE Empty(): BOOLEAN;
    BEGIN
      RETURN ( A.X >= B.X) OR (A.Y >= B.Y );
    END Empty;

  BEGIN
  END TRect;

PROCEDURE DisposeStr(VAR P:PString);
BEGIN
  DEALLOCATE(P, Length(P^)+1);
END DisposeStr;

PROCEDURE NewStr(S: ARRAY OF CHAR): PString;
VAR
  p : PString;
BEGIN
  ALLOCATE(p, Length(S)+1);
  Copy(p^, S);
  RETURN p;
END NewStr;

END Objects.