MODULE tst_az0;

FROM L_EvalProcedures  IMPORT
  Az0_Clear, Dif0_Clear, AzDif0_Addsmpl, AzDif0_ConT;
VAR
  cont        : AzDif0_ConT;
  idx : INTEGER;
  res : INTEGER;
BEGIN
  res := MIN(INTEGER);
  Az0_Clear(cont, 400);
  FOR idx := 300 TO -0 BY -1 DO
    AzDif0_Addsmpl(cont, idx + 10, idx*10, res);
  END;
  FOR idx := -1 TO -300 BY -1 DO
    AzDif0_Addsmpl(cont, idx + 10, idx*10, res);
  END;
END tst_az0.
