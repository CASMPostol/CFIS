MODULE Tst_Clearance;

FROM L_EvalProcedures  IMPORT
  Clearence_ConT, Clearence, Clearence_Clear;

FROM MathLib0 IMPORT
  entier, real;
  
FROM Kl_FGenerators IMPORT
  LookupM;
  
VAR
  con      : Clearence_ConT;
  xIdx     : INTEGER;
  alfa     : INTEGER;
  dev      : INTEGER;
  h175Mn   : INTEGER;
  h175Mx   : INTEGER;
  h150Mn   : INTEGER;
  function : ARRAY[0..9] OF REAL;
  Xref     : ARRAY[0..9] OF REAL;
  ok       : BOOLEAN;

  PROCEDURE InitFunc1;
  VAR
    idx: CARDINAL;
  BEGIN
    Xref[0] := -10000.0; function[0] := -2000.0;
    Xref[1] :=  -7000.0; function[1] := -2000.0;
    Xref[2] :=  -5000.0; function[2] :=  2000.0;
    Xref[3] :=  -3000.0; function[3] := -2000.0;
    Xref[4] :=  -2000.0; function[4] := -2000.0;
    Xref[5] :=  -2000.0; function[5] :=  2000.0;
    FOR idx := 5 TO 9 DO
      Xref[idx] := -Xref[9-idx]; function[idx] := -function[9-idx];
    END;
  END InitFunc1;
  

BEGIN;
  InitFunc1;
  Clearence_Clear(con, -1);
  FOR xIdx := -10000  TO 10000 BY 1 DO
    dev := entier(LookupM(real(xIdx), function, Xref, ok));
    Clearence(con, xIdx DIV 10, dev);
  END;
  Clearence_Clear(con, -1);
  FOR xIdx := 10000  TO -10000 BY -1 DO
    dev := entier(LookupM(real(xIdx), function, Xref, ok));
    Clearence(con, xIdx DIV 10, dev);
  END;
END Tst_Clearance.
