MODULE Tst_Eval;

FROM L_EvalProcedures  IMPORT 
  Avr_ConT, AV_Addsmpl, AV_Clear;

VAR
  idx   : INTEGER;
   cont : Avr_ConT;
   res  : INTEGER;
BEGIN
  AV_Clear(cont);
  FOR idx := -100 TO 100 DO
    res := AV_Addsmpl(cont, idx);
  END;
END Tst_Eval.
