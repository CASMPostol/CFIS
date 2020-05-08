(*.F- *)
(**********************************************************************
|  Title   : Polozenie urzadzenia
|  Author  : T. Rozmarynowski
|  System  : LOGITECH MODULA-2/86
|  History :
|    Rel 3.0. MPostol
|      
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 86 58 12, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)
MODULE ConvDB;

  FROM DB_Structure IMPORT
    TypUrzadzenia, ParametryIdentyf, ParametryPlikIni;

  FROM Ini IMPORT
    GetPrivateProfileString, WritePrivateProfileString;

  FROM NumberConversion IMPORT
    StringToCard, StringToInt, CardToString;

  FROM Strings IMPORT
    Concat;

  FROM StdIO IMPORT
    sprintf;

  PROCEDURE ZmienUrzadz
            (   );
  VAR  
    idx      : INTEGER;

  VAR
    GtypURZ         : TypUrzadzenia;
    ParamIdenty     : ParametryIdentyf;
        (* currState :State;*)


  PROCEDURE WstawObloty();
  TYPE
    OpisParametruIni = ARRAY [ 0 .. 20 ] OF CHAR;
  
  VAR
    parametr : OpisParametruIni;
    sekcja   : OpisParametruIni;
    ok       : BOOLEAN;
    ile      : INTEGER;
    idxUrz   : INTEGER;

  PROCEDURE ZmienOiekt
            (    Nazwa : ARRAY OF CHAR ): BOOLEAN;

    PROCEDURE ZmienUlamkiMinut
              ( Nazwa      : ARRAY OF CHAR;
                Parametr   : ARRAY OF CHAR;
                NazwaPliku : ARRAY OF CHAR;
                Parametr100: ARRAY OF CHAR): BOOLEAN;
    VAR
      bufor  : ARRAY [ 0 .. 15 ] OF CHAR;
      okZO   : BOOLEAN;
      ulamek : CARDINAL;

    BEGIN
      GetPrivateProfileString( Nazwa, Parametr, "", bufor, NazwaPliku);
      StringToCard( bufor, ulamek, okZO );
      IF okZO AND (ulamek <= 99)
      THEN
        CardToString(ulamek * 100, bufor, 4);
        WritePrivateProfileString( Nazwa, Parametr100, bufor, NazwaPliku);
      END;
      RETURN okZO
    END ZmienUlamkiMinut;
  
  BEGIN
    WITH ParamIdenty  DO
        RETURN ZmienUlamkiMinut( Nazwa, DlugoscSetne, NazwaPlikuOpisu, 
                                 DlugoscDTysieczne ) AND
               ZmienUlamkiMinut( Nazwa, SzerokoscSetne, NazwaPlikuOpisu, 
                                 SzerokoscDTysieczne  );
    
    END (* with *);
  END ZmienOiekt;

  BEGIN
    WITH ParamIdenty  DO
      GetPrivateProfileString( Lista, Ilosc, "0", parametr, NazwaPlikuOpisu );
      StringToInt( parametr, ile, ok );
      IF NOT ok
      THEN
        ile := 0;
      END (* if *);
      ok := FALSE;
      FOR idxUrz := 0 TO ile - 1 DO
        sprintf( parametr, "%d", idxUrz );
        Concat( Urzadz, parametr, sekcja );
        GetPrivateProfileString( Lista, sekcja, "", parametr, NazwaPlikuOpisu );
        IF ZmienOiekt(parametr) THEN
          
        END (* if *);
      END (* for i *);
    END (* WITH ParamIdenty *);
  END WstawObloty;
  
  BEGIN
    (* wybrany typ urzadzenia *)
    FOR idx := 0 TO 4 DO
    CASE idx OF
      0 :
        GtypURZ := LOC;
      |
      1 :
        GtypURZ := GS;
      |
      2 :
        GtypURZ := VOR;
      |
      3 :
        GtypURZ := ADF;
      |
      4 :
        GtypURZ := VHF;
      ELSE;
    END (* case idx *);
    ParametryPlikIni( GtypURZ, ParamIdenty );
    WstawObloty;   (* ustawienie obiektow dla typu urzadzenia *)
  END;
END ZmienUrzadz;

BEGIN
  ZmienUrzadz;
END ConvDB.
