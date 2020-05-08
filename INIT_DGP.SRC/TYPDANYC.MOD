(*.F- *)
(**********************************************************************
|  Title   : Typy Danych
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86 
|  History :
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE  TypDanych;

PROCEDURE ParametryPlikIni (typURZ  :TypUrzadzenia;
                            VAR ParamIdenty :  ParametryIdentyf );
          BEGIN
     CASE typURZ OF
          LOC:
        ParamIdenty.NazwaPlikuOpisu:="lotnlist.ini";
        ParamIdenty.Urzadz:='Lotnisko_';
        ParamIdenty.Lista:='Lotniska';
        ParamIdenty.Ilosc:="Ilosc";
        ParamIdenty.Nazwa:=0C;
        ParamIdenty.DlugoscStopnie:='Dlugosc.Stopnie';
        ParamIdenty.DlugoscMinuty:='Dlugosc.Minuty';
        ParamIdenty.DlugoscSetne:='Dlugosc.Setne';
        ParamIdenty.SzerokoscStopnie:='Szerokosc.Stopnie';
        ParamIdenty.SzerokoscMinuty:='Szerokosc.Minuty';
        ParamIdenty.SzerokoscSetne:='Szerokosc.Setne';
        ParamIdenty.GPSKat:=0C;
        ParamIdenty.GPSOdleglosc:='Teodolit.Odleglosc.LOC';
        ParamIdenty.GPSWysokosc:=0C;
        ParamIdenty.Deklinacja:='Deklinacja';
        ParamIdenty.Czestotliwosc:='Czestotliwosc';
        ParamIdenty.Identyfikator:='Identyfikator';
          
          |
          GS:
        ParamIdenty.NazwaPlikuOpisu:="lotnlist.ini";
        ParamIdenty.Urzadz:='Lotnisko_';
        ParamIdenty.Lista:='Lotniska';
        ParamIdenty.Ilosc:="Ilosc";
        ParamIdenty.Nazwa:=0C;
        ParamIdenty.DlugoscStopnie:='Dlugosc.Stopnie';
        ParamIdenty.DlugoscMinuty:='Dlugosc.Minuty';
        ParamIdenty.DlugoscSetne:='Dlugosc.Setne';
        ParamIdenty.SzerokoscStopnie:='Szerokosc.Stopnie';
        ParamIdenty.SzerokoscMinuty:='Szerokosc.Minuty';
        ParamIdenty.SzerokoscSetne:='Szerokosc.Setne';
        ParamIdenty.GPSKat:=0C;
        ParamIdenty.GPSOdleglosc:='Teodolit.Odleglosc.GS';
        ParamIdenty.GPSWysokosc:=0C;
        ParamIdenty.Deklinacja:='Deklinacja';
        ParamIdenty.Czestotliwosc:='Czestotliwosc';
        ParamIdenty.Identyfikator:='Identyfikator';
          
          |
          VOR:
        ParamIdenty.NazwaPlikuOpisu:="vorlist.ini";
        ParamIdenty.Urzadz:='VOR';
        ParamIdenty.Lista:='Lista';
        ParamIdenty.Ilosc:="Ilosc";
        ParamIdenty.Nazwa:=0C;
        ParamIdenty.DlugoscStopnie:='Dlugosc.Stopnie';
        ParamIdenty.DlugoscMinuty:='Dlugosc.Minuty';
        ParamIdenty.DlugoscSetne:='Dlugosc.Setne';
        ParamIdenty.SzerokoscStopnie:='Szerokosc.Stopnie';
        ParamIdenty.SzerokoscMinuty:='Szerokosc.Minuty';
        ParamIdenty.SzerokoscSetne:='Szerokosc.Setne';
        ParamIdenty.GPSKat:='Teodolit.Kat';
        ParamIdenty.GPSOdleglosc:='Teodolit.Odleglosc';
        ParamIdenty.GPSWysokosc:=0C;
        ParamIdenty.Deklinacja:='Deklinacja';
        ParamIdenty.Czestotliwosc:='Czestotliwosc';
        ParamIdenty.Identyfikator:='Identyfikator';
          
          |
          ADF:
        ParamIdenty.NazwaPlikuOpisu:="ndblist.ini";
        ParamIdenty.Urzadz:='NDB';
        ParamIdenty.Lista:='Lista';
        ParamIdenty.Ilosc:="Ilosc";
        ParamIdenty.Nazwa:=0C;
        ParamIdenty.DlugoscStopnie:='Dlugosc.Stopnie';
        ParamIdenty.DlugoscMinuty:='Dlugosc.Minuty';
        ParamIdenty.DlugoscSetne:='Dlugosc.Setne';
        ParamIdenty.SzerokoscStopnie:='Szerokosc.Stopnie';
        ParamIdenty.SzerokoscMinuty:='Szerokosc.Minuty';
        ParamIdenty.SzerokoscSetne:='Szerokosc.Setne';
        ParamIdenty.GPSKat:=0C;
        ParamIdenty.GPSOdleglosc:=0C;
        ParamIdenty.GPSWysokosc:=0C;
        ParamIdenty.Deklinacja:='Deklinacja';
        ParamIdenty.Czestotliwosc:='Czestotliwosc';
        ParamIdenty.Identyfikator:='Identyfikator';

          
          |
          VHF:
        ParamIdenty.NazwaPlikuOpisu:="vhflist.ini";
        ParamIdenty.Urzadz:='VHF';
        ParamIdenty.Lista:='Lista';
        ParamIdenty.Ilosc:="Ilosc";
        ParamIdenty.Nazwa:=0C;
        ParamIdenty.DlugoscStopnie:='Dlugosc.Stopnie';
        ParamIdenty.DlugoscMinuty:='Dlugosc.Minuty';
        ParamIdenty.DlugoscSetne:='Dlugosc.Setne';
        ParamIdenty.SzerokoscStopnie:='Szerokosc.Stopnie';
        ParamIdenty.SzerokoscMinuty:='Szerokosc.Minuty';
        ParamIdenty.SzerokoscSetne:='Szerokosc.Setne';
        ParamIdenty.GPSKat:=0C;
        ParamIdenty.GPSOdleglosc:=0C;
        ParamIdenty.GPSWysokosc:=0C;
        ParamIdenty.Deklinacja:='Deklinacja';
        ParamIdenty.Czestotliwosc:=0C;
        ParamIdenty.Identyfikator:=0C;
           
  END;

          END ParametryPlikIni;
END TypDanych.

