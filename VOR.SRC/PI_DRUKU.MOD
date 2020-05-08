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
    DMEPrint, VORPrint;

  PROCEDURE Druk( Zestaw : BOOLEAN );
    BEGIN
      IF Zestaw THEN
        DMEPrint.Raport( );
      ELSE
        VORPrint.Raport( TRUE );
      END;
    END Druk;

END PI_Drukuj.
