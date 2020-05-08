(*.F- *)
(**********************************************************************
|  Title   : Procedury realizacji drukowania
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE PI_Drukuj;

  IMPORT
    L_Print, DMEPrint, L_DataBase, L_Oblot;

  FROM L_CommonTypes IMPORT
    (* VAR *) Procedura;
    
  FROM CommonData IMPORT
    Orbita;

  FROM CommonTypes IMPORT
    (* TYPE *)TimeAndDate;

  FROM L_CommonTypes  IMPORT
    ProceduraT;

  FROM EventsMng IMPORT
    RodzUrzadzenia;

  FROM Czas IMPORT
    GetTimeAndDate;

  PROCEDURE Druk
            (    Zestaw : BOOLEAN );
  BEGIN
    IF NOT Zestaw THEN
      L_Print.MakeRaport;
    ELSE
      DMEPrint.Raport;
    END;
  END Druk;

END PI_Drukuj.
