MODULE TST_Cloct;

FROM HRD_Clock IMPORT
  Godzina, Data;
  VAR 
    h, m, s : CARDINAL;
    Y, M, D : CARDINAL;
    idx     : CARDINAL;
    
BEGIN
  FOR idx := 0 TO 10000 DO
    Data( Y, M, D, h, m, s );
  END;
END TST_Cloct.
