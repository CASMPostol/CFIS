(*.F- *)
(**********************************************************************
|  Title   : Wspolne dane opisujace parametry pomiaru 
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86 
|  History :
|    22-05-97: M.Postol
|      dopisalem inicjacje danych globalnych
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)
IMPLEMENTATION MODULE CommonData;

  FROM CommonTypes IMPORT
    OdnDlaPomBleduT, OdnDlaPomOdlT, NadajnikT, 
    GlownyOdbiornikT;
BEGIN
    NazwaUrzadz1         := '!';
    NazwaUrzadz2         := '!';
    NazwaOblotu          := '!';
    NazwaPlikuOpisu      := '!';
    (* zmienne inicjowane na ekranie Pomiarowym *)
    DME                  := FALSE;
    SciezkaOpisuPomiaru  := '!';
    OdnDlaPomBledu       := pbnieZdef;
    OdnDlaPomOdl         := poDMEA;
    Nadajnik1            := nA;
    Nadajnik2            := nA;
    GlownyOdbiornik      := goA;
    Promien              := 0;
    Orbita               := 0;;  (* w 0.002 Nm *)
    Predkosc             := 0.0;
    CisnienieOdniesienia := 1013.0;
END CommonData.
