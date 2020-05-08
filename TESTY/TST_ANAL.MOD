MODULE Tst_Analiza;

FROM L_Count  IMPORT
  Analiza;
  
  VAR SyntResult      : INTEGER;

BEGIN
  Analiza(SyntResult);
  SyntResult := SyntResult;
END Tst_Analiza.
