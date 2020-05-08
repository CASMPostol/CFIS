MODULE tst_az;

FROM L_EvalProcedures  IMPORT
  Azym_Clear, Azym_Addsmpl, Azym_ConT;
VAR
  cont        : Azym_ConT;
  idx : INTEGER;
  res : INTEGER;
BEGIN
  Azym_Clear(cont, 1500, 0);
  FOR idx := 3000 TO -3000 BY -1 DO
    Azym_Addsmpl(cont, idx DIV 5, idx-500, res);
  END;
END tst_az.
