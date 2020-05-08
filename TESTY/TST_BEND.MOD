
MODULE  Tst_bends;
  FROM L_CommonTypes IMPORT
    NumPunktu, NumStrefy, zoneBIdx_T, Boundary_T, category;
FROM  L_EvalProcedures IMPORT
  Bend_Descriptor, Bend_ClearContainer, KapaBuff_T, Bend_AddSample;

FROM MathLib0 IMPORT
  entier, real;
  
FROM Kl_FGenerators IMPORT
  LookupM;

FROM SpecConv  IMPORT
  GorszeBoDalszeOdZera;

  FROM CommonTypes  IMPORT
    SigNilVal;
VAR
  Container : Bend_Descriptor;
  ZoneBIdx  : zoneBIdx_T;
  KapaBuff  : KapaBuff_T;
  function  : ARRAY[0..5] OF REAL;
  Xref      : ARRAY[0..5] OF REAL;

  PROCEDURE InitFunc1;
  VAR
    idx: CARDINAL;
  BEGIN
    Xref[0] :=     0.0; function[0] :=    0.0;
    Xref[1] :=   498.0; function[1] :=    0.0;
    Xref[2] :=   500.0; function[2] :=  400.0;
    Xref[3] :=   558.0; function[3] :=  400.0;
    Xref[4] :=   560.0; function[4] :=    0.0;
    Xref[5] :=  5000.0; function[5] :=    0.0;
  END InitFunc1;

PROCEDURE  Kapa(dif: REAL): REAL;
BEGIN
  RETURN 0.0;
END Kapa;

PROCEDURE  Init_KapaBuff(VAR KapaBuff  : KapaBuff_T);
BEGIN
  KapaBuff[0] := Kapa;
  KapaBuff[1] := Kapa;
  KapaBuff[2] := Kapa;
  KapaBuff[3] := Kapa;
  KapaBuff[4] := Kapa;
END Init_KapaBuff;

PROCEDURE  Init_ZoneBIdx(VAR ZoneBIdx  : zoneBIdx_T);
BEGIN
  ZoneBIdx[0] := 0;
  ZoneBIdx[1] := 1000;
  ZoneBIdx[2] := 2000;
  ZoneBIdx[3] := 3000;
  ZoneBIdx[4] := 4000;
  ZoneBIdx[5] := 5000;
END Init_ZoneBIdx;

VAR
  idx       : CARDINAL;
  zone      : NumStrefy;
  dif       : INTEGER;
  boundP    : INTEGER;
  boundM    : INTEGER;
  centre    : INTEGER;
  bends     : INTEGER;
  bendsArr  : ARRAY NumStrefy OF INTEGER;
  ok        : BOOLEAN;

PROCEDURE  Init_bendsArr;
VAR zone: NumStrefy;
BEGIN
  FOR zone := MIN(NumStrefy) TO MAX(NumStrefy) DO
    bendsArr[zone] := SigNilVal;
  END;
END Init_bendsArr;
  
BEGIN
  InitFunc1;
  Init_KapaBuff( KapaBuff );
  Init_ZoneBIdx( ZoneBIdx );
  Init_bendsArr;
  Bend_ClearContainer(Container, ZoneBIdx, 3, KapaBuff);
  FOR idx := 0 TO 4999 DO
    zone := idx DIV 1000;
    dif := entier(LookupM(real(idx), function, Xref, ok));
    IF Bend_AddSample(dif, idx, idx, zone, boundP, boundM, centre, 
                      bends, Container)
    THEN
      GorszeBoDalszeOdZera(bendsArr[zone], bends);
    END;
  END;
END Tst_bends.
