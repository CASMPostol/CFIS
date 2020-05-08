(*.F- *)
(**********************************************************************
|  Title   : VOR Common types
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86 
|  History :
|    Rel 3.0. M.Postol
|      Zmiana definicji InitFlagErr
|      W NilDlaPOdleglosci odwrotnie byly wstawiane warosci NIL
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 686 25 47
|  mailto: techsupp@cas.com.pl
|  http: www.cas.com.pl
**********************************************************************)
(*.F+ *)
IMPLEMENTATION MODULE  D_CommonTypes;

  FROM SYSTEM IMPORT
    WORD;

  FROM CommonTypes IMPORT
    DisNilVal, SigNilVal;
    
  PROCEDURE NilDlaPOdleglosci
            ( procedura: ProceduraT) : WORD;
  BEGIN
    CASE procedura  OF
      pOkragBlad,pOkragZakres:
        RETURN WORD(SigNilVal);
      |
      pPromienBlad, pPromienZakres:
        RETURN WORD(DisNilVal);
    END;
  END NilDlaPOdleglosci;
                  
END D_CommonTypes.
