(*.F- *)
(**********************************************************************
|  Title   : Program inicjacji stacji referencyjnej
|  Author  : T.Rozmarynowski
|  System  : LOGITECH MODULA-2/86
|  History :
|    09-02-1998: utworzony
|    17-05-2000: M.Postol
|      uzupelnienie komentarzy
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 86 58 12, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)
MODULE Pig1;

  FROM RTSMain IMPORT
    Terminate, Status;

  FROM URZadz  IMPORT
    Urzadzenie;

  FROM  POLoze1 IMPORT
    Polozenie;

  FROM CommonTypes IMPORT
      PolozenieGeo;


  FROM  INIcja IMPORT
      Inicjacja;

FROM TypDanych IMPORT
    MainStates,TypUrzadzenia;

VAR
    mainState     : MainStates;
    typURZ        : TypUrzadzenia;
    polozenie     : PolozenieGeo;
BEGIN
  mainState := UrzadzenieMS;
  typURZ := LOC;
  LOOP
    CASE mainState OF
          UrzadzenieMS :
               Urzadzenie(typURZ,mainState);
               (*mainState:=KoniecMS;*)
          |
          PolozenieMS:
               Polozenie(typURZ,mainState,polozenie) ;
          |
          InicjacjaMS:
               Inicjacja(mainState,polozenie) ;
          |
          KoniecMS:
               Terminate(Normal);               
    END (* case mainState *);


  END (* loop *);
  Terminate(Normal);
END Pig1.

