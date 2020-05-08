(*.F- *)
(**********************************************************************
|  Title   : Program inicjacji stacji referencyjnej
|  Author  : 
|  System  : LOGITECH MODULA-2/86
|  History :
|  Rel. 001 21.01.1998: new
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 86 58 12, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)
MODULE Pig1;

  FROM RTSMain IMPORT
    Terminate, Status;


  FROM  POLoze IMPORT
    Polozenie;


FROM TypDanych IMPORT
    MainStates;

VAR
    mainState     : MainStates;

(* program glowny*)
    
BEGIN
  mainState :=StartMS;
  LOOP
    CASE mainState OF
          StartMS:
               Polozenie(mainState) ;
               (* wywolanie procedury glownej ekranu *)
          |
          KoniecMS:
               Terminate(Normal);               
               (* koniec programu *)
    END (* case mainState *);


  END (* loop *);
END Pig1.

