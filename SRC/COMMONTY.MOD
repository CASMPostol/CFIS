(*.F- *)
(**********************************************************************
|  Title   : Common types
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86 
|  History :
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE  CommonTypes;

  FROM Strings IMPORT
    ConstAssign;
    
  PROCEDURE GetRecName
            (VAR name : ARRAY OF CHAR; 
                 rec  : GlownyOdbiornikT);
  BEGIN
    IF rec = goA  THEN
      ConstAssign('A', name);
    ELSE
      ConstAssign('B', name);
    END;
  END GetRecName;

  PROCEDURE GetTranName
            (VAR name : ARRAY OF CHAR;
                 trn  : NadajnikT);
  BEGIN
    IF trn = nA  THEN
      ConstAssign('Nad: G', name);
    ELSE
      ConstAssign('Nad: Z', name);
    END;
  END GetTranName;

END CommonTypes.
