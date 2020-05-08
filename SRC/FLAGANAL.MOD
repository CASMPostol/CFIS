(*.F- *)
(**********************************************************************
|  Title   : Analiza odcinkow wystapienia flagi (warunku)
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    30-05-97: M.POSTOL
|      w analizie odcinkow za poczatek podstawia pierwsza znana odleglosc 
|      a za koniec ostatnia
|    Rel 3.0. M.Postol
|      Wprowadzono eleminacj najkrotszych odcinkow
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 686 25 47
|  mailto: techsupp@cas.com.pl
|  http: www.cas.com.pl
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE FlagAnal;

  IMPORT StdIO;
  
  FROM SYSTEM IMPORT
    WORD, ADDRESS, ADR;

  FROM CommonTypes IMPORT
    DisNilVal, SigNilVal, NumStrefy;

  FROM SpecConv  IMPORT
    ToStringProcT, GorszeBoMniejsze, AddAngle100, 
    SubAngle100, AddDis, SubDis;
    
  FROM WorseBecause  IMPORT
    WorseBLessDis;
    
  PROCEDURE FlagErr_Anal
            ( VAR prevFlagState : BOOLEAN;
                  currFlagState : BOOLEAN;
              VAR flagErr       : FlagsTable;
                  dis           : WORD;
                  zoneNr        : NumStrefy );

    PROCEDURE UsunNajmniejszy;
    VAR
      odcIdx     : OdcinekNr;
      minDlugosc : CARDINAL;
      minOdc     : OdcinekNr;
      
    BEGIN (* UsunNajmniejszy *)
      WITH flagErr  DO
        minDlugosc := MAX(CARDINAL);
        FOR odcIdx := MIN(OdcinekNr) TO w_IleOd DO
          WITH opis[odcIdx] DO
            IF dlugosc < minDlugosc  THEN
              minOdc := odcIdx;
              minDlugosc := dlugosc;
            END (* IF dlugosc *);
          END; (* WITH opis *)
        END; (* FOR odcIdx *)
        WITH opis[minOdc]  DO
          IF katANieOdleglosc  THEN
            w_KatRazem := AddAngle100( 
                            ABS(SubAngle100(INTEGER(pocz), INTEGER(kon))), 
                            w_KatRazem);
          ELSE
            w_OdlegloscRazem := AddDis(
                                     SubDis( CARDINAL(pocz), CARDINAL(kon)), 
                                     w_OdlegloscRazem )
          END;
        END;
        FOR odcIdx :=  minOdc TO w_IleOd-1 DO
          opis[odcIdx] := opis[odcIdx+1]
        END; (* FOR odcIdx *)
        INC(W_IleRazem);
      END; (* WITH flagErr *)
    END UsunNajmniejszy;
    
  BEGIN (* FlagErr_Anal *)
    WITH flagErr DO
      IF currFlagState AND NOT prevFlagState
      THEN
        IF w_IleOd = MAX( OdcinekIle )
        THEN
          UsunNajmniejszy;
        ELSE
          INC( w_IleOd );
        END (* if w_IleOd *);
        WITH opis[w_IleOd] DO
          sector  := zoneNr;
          pocz    := dis;
          kon     := dis;
          dlugosc := 0;
        END (* with opis *);
      ELSIF currFlagState
      THEN  (* prevFlagState *)
        (* Assert(w_IleOd > 0); *)
        WITH opis[w_IleOd] DO
          kon := dis;
          INC(dlugosc);
        END (* with opis *);
      END (* if currFlagState *);
    END (* with flagErr *);
    prevFlagState := currFlagState;
  END FlagErr_Anal;

  PROCEDURE InitFlagErr
            ( VAR flagErr          : FlagsTable;
                  (* inicjowana tablica *)
                  KatANieOdleglosc : BOOLEAN
                  (* TRUE jesli w procedurze odniesienim X jest kat *)
             );
  VAR
    odcinekIdx : OdcinekNr;
    nilValForProc    : WORD;
    
  BEGIN
    WITH flagErr DO
      w_IleOd          := MIN(OdcinekIle);
      W_IleRazem       := 0;
      katANieOdleglosc := KatANieOdleglosc;
      IF KatANieOdleglosc THEN
        w_KatRazem     := 0;
        nilValForProc  := WORD(SigNilVal);
      ELSE
        w_OdlegloscRazem := 0;
        nilValForProc    := WORD(DisNilVal);
      END;
      FOR odcinekIdx := MIN( OdcinekNr ) TO MAX( OdcinekNr ) DO
        WITH opis[odcinekIdx] DO
          sector  := ns_no;
          nilVal  := nilValForProc;
          pocz    := nilValForProc;
          kon     := nilValForProc;
          dlugosc := 0;
        END (* with flagErr.opis *);
      END (* for odcinekIdx *);
    END (* with flagErr *);
  END InitFlagErr;

  PROCEDURE GetNextFrac
            (     converP           : ToStringProcT;
                  flagErr           : FlagsTable;
              VAR str               : ARRAY OF CHAR;
              VAR fracNum           : OdcinekIdx     ) : BOOLEAN;

  TYPE
    Str9 =
      ARRAY [ 0 .. 9 ] OF CHAR;

  VAR
    s1 : Str9;
    s2 : Str9;
    a1 : ADDRESS;
    a2 : ADDRESS;

  BEGIN
    WITH flagErr DO
      IF (fracNum > w_IleOd) OR (fracNum > MAX(OdcinekNr))
      THEN
        RETURN FALSE;
      END (* if fracNum *);
      WITH opis[fracNum] DO
        a1 := ADR( s1 );
        a2 := ADR( s2 );
        converP( INTEGER( pocz ), s1, 5 );
        converP( INTEGER( kon ),  s2, 5 );
        StdIO.sprintf3( str, "%1d:[%s-%s]; ", fracNum, 
                        a1, a2 );
      END;
    END (* with flagErr *);
    IF fracNum < MAX(OdcinekIdx)  THEN
      INC( fracNum );
    END;
    RETURN TRUE;
  END GetNextFrac;
  
  PROCEDURE MinPoczKonSig
            (     flagErr : FlagsTable ): INTEGER;
  VAR
    odcIdx : OdcinekNr;
    res    : INTEGER;
  BEGIN
    res := SigNilVal;
    WITH flagErr DO
      IF w_IleOd > 0
      THEN
        FOR odcIdx := MIN(OdcinekNr) TO w_IleOd DO
          GorszeBoMniejsze(res, INTEGER(opis[odcIdx].kon) );
          GorszeBoMniejsze(res, INTEGER(opis[odcIdx].pocz) );
        END;
      END (* if w_IleOd *);
    END (* with odcinki_20uV *);
    RETURN res;
  END MinPoczKonSig;
  
  PROCEDURE MinPoczKonDis
            (     flagErr : FlagsTable ): CARDINAL;
  VAR
    odcIdx : OdcinekNr;
    res    : CARDINAL;
  BEGIN
    res := DisNilVal;
    WITH flagErr DO
      IF w_IleOd > 0
      THEN
        FOR odcIdx := MIN(OdcinekNr) TO w_IleOd DO
          WorseBLessDis(res, CARDINAL(opis[odcIdx].kon) );
          WorseBLessDis(res, CARDINAL(opis[odcIdx].pocz) );
        END;
      END (* if w_IleOd *);
    END (* with odcinki_20uV *);
    RETURN res;
  END MinPoczKonDis;

  PROCEDURE SumaDlugosciSig
            (     flagErr : FlagsTable ): INTEGER;
  VAR
    odcIdx : OdcinekNr;
    res    : INTEGER;
  BEGIN
    WITH flagErr DO
      res := w_KatRazem;
      IF w_IleOd > 0
      THEN
        FOR odcIdx := MIN(OdcinekNr) TO w_IleOd DO
          res := 
              AddAngle100( ABS( SubAngle100( INTEGER(opis[odcIdx].pocz), 
                                             INTEGER(opis[odcIdx].kon))), 
                           res );
        END;
      END (* if w_IleOd *);
    END (* with odcinki_20uV *);
    RETURN res;
  END SumaDlugosciSig;
  
BEGIN
END FlagAnal.
