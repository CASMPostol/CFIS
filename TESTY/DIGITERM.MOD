(*.F- *)
(**********************************************************************
|  Title   : Terminal dla kanalow RS z karty DIGI
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

MODULE DigiTerminal;

  IMPORT Terminal;
  
  FROM DigiRS IMPORT
    ReadString, WriteString, SetBaudRate;

  FROM Strings IMPORT
    Copy;
  FROM Terminal  IMPORT
    Write;
  
  CONST
    MaxTeoEvFil  = 3;
    Channel      = 5;

  PROCEDURE Analizer;


    PROCEDURE Rd
              ( VAR ch : CHAR ) : BOOLEAN;
    BEGIN
      RETURN ReadString(Channel, ch, 1) = 1;
    END Rd;

  VAR
    lastCh       : CHAR;
    
  BEGIN (* Analizer *)
    LOOP 
      IF Rd(lastCh)  THEN
        WriteString(Channel, lastCh, 1);
        Write(lastCh)
      END;
    END (* while Rd *);
  END Analizer;

BEGIN
  IF NOT SetBaudRate(Channel, 12, 8)
  THEN
    Terminal.WriteString("Kanal Digi nie mozna zainicjowac");
  END (* if *);
  Analizer;
END DigiTerminal.
