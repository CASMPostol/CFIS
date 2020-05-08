
MODULE tst_rcon;  (* Trimble *) (* Priorytet 0*)

 FROM NumberConversion IMPORT
    StringToCard, StringToInt;
  
  FROM RealConversions IMPORT
        StringToReal;
    
  FROM Conversions IMPORT
	ConvertHex;
  FROM MathLib0 IMPORT
    entier, real;

  FROM Strings IMPORT
    Copy, CompareStr, Delete;
VAR
  str : ARRAY[0..14] OF CHAR;
  ok : BOOLEAN;
  r: REAL;
  
BEGIN
  str := "82400.0";
  StringToReal(str, r, ok);
END tst_rcon.
        		         
        		         
