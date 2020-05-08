MODULE T;

TYPE
  PRec = POINTER TO TRec;
  TRec = RECORD
    Next : PRec;
    Prev : PRec;
    Val  : CARDINAL;
  END;

VAR
  A, B, C : TRec;
  P : PRec;
BEGIN
  P := ADR(A);
  A.Next := ADR(B);
  A.Prev := NIL;
  A.Val := 100;
  B.Next := ADR(C);
  B.Prev := ADR(A);
  B.Val := 200;
  C.Prev := ADR(B);
  C.Next := NIL;
  C.Val := 300;
  P := P;
END T.
