(*.F- *)
(**********************************************************************
|  Title   : Procedury realizacji drukowania dla VHF
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    08-12-96: created
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE PI_Drukuj;

  FROM H_Print IMPORT
    MakeRaport;

  PROCEDURE Druk
            (    Zestaw : BOOLEAN );
  BEGIN
    MakeRaport;
  END Druk;

END PI_Drukuj.
