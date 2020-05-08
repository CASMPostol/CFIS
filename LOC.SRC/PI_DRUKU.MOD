(*.F- *)
(**********************************************************************
|  Title   : Procedury realizacji drukowania
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    Rel 3.0. MPostol
|      Zmiana listy importowej - nowa definicja Czas.
|      Wywalilem niepotrzbny importy
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 686 25 47
|  mailto: techsupp@cas.com.pl
|  http: www.cas.com.pl
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE PI_Drukuj;

  IMPORT
    L_Print, DMEPrint;

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
