(*.F- *)
(**********************************************************************
|  Title   : Typy Danych
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    Rel. 3.0. Wprowadzilem do oprogramowania systemu
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 686 25 47
|  mailto: techsupp@cas.com.pl
|  http: www.cas.com.pl
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE DB_Structure;

FROM Strings IMPORT
  Assign;

PROCEDURE ParametryPlikIni
          (     typURZ      : TypUrzadzenia;
            VAR ParamIdenty : ParametryIdentyf );

PROCEDURE Podstaw
          ( VAR ParamIdenty     : ParametryIdentyf;
                nazwaPlikuOpisu : ARRAY OF CHAR;
                urzadz          : ARRAY OF CHAR;
                lista           : ARRAY OF CHAR;
                gPSKat          : ARRAY OF CHAR; 
                gPSOdleglosc    : ARRAY OF CHAR );
BEGIN
  WITH ParamIdenty DO
    Assign( nazwaPlikuOpisu, NazwaPlikuOpisu);
    Assign( urzadz, Urzadz);
    Assign( lista, Lista );
    Ilosc:="Ilosc";
    DlugoscStopnie      := 'Dlugosc.Stopnie';
    DlugoscMinuty       := 'Dlugosc.Minuty';
    DlugoscSetne        := 'Dlugosc.Setne';
    DlugoscDTysieczne   := 'Dlugosc.DTysieczne';
    SzerokoscStopnie    := 'Szerokosc.Stopnie';
    SzerokoscMinuty     := 'Szerokosc.Minuty';
    SzerokoscSetne      := 'Szerokosc.Setne';
    SzerokoscDTysieczne := 'Szerokosc.DTysieczne';
    Assign(gPSKat, GPSKat);
    Assign( gPSOdleglosc, GPSOdleglosc);
    GPSWysokosc:=0C;
    Deklinacja:='Deklinacja';
    Czestotliwosc:='Czestotliwosc';
    Identyfikator:='Identyfikator';
  END (* WITH ParamIdenty *);
END Podstaw;

BEGIN
  CASE typURZ OF
    LOC:
      Podstaw(ParamIdenty, "lotnlist.ini", 'Lotnisko_', 'Lotniska', 0C, 
              'Teodolit.Odleglosc.LOC');
    |
    GS:
      Podstaw(ParamIdenty, "lotnlist.ini", 'Lotnisko_', 'Lotniska', 0C,
              'Teodolit.Odleglosc.GS');
    |
    VOR:
      Podstaw(ParamIdenty, "vorlist.ini", 'VOR', 'Lista', 'Teodolit.Kat', 
              'Teodolit.Odleglosc');
    |
    ADF:
      Podstaw(ParamIdenty, "ndblist.ini", 'NDB', 'Lista', "", "");
    |
    VHF:
      Podstaw(ParamIdenty, "vhflist.ini", 'VHF', 'Lista', "", "")
  END;
END ParametryPlikIni;

END DB_Structure.
