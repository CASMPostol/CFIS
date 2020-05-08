(*.F- *)
(**********************************************************************
|  Title   : Analiza odcinkow wystapienia flagi (warunku)
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    30-05-97: M.POSTOL
|      w analizie odcinkow za poczatek podstawia pierwsza znana odleglosc 
|      a za koniec ostatnia
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)
(* IMPLEMENTATION *)

IMPLEMENTATION MODULE FlagAnal;

  IMPORT StdIO;
  
  FROM SYSTEM IMPORT
    WORD, ADDRESS, ADR;

  FROM CommonTypes IMPORT
    DisNilVal, SigNilVal, NumStrefy;

  FROM SpecConv  IMPORT
    Card500Str, Int100Str, ToStringProcT, GorszeBoMniejsze;
    
  FROM WorseBecause  IMPORT
    WorseBLessDis;

  PROCEDURE FlagErr_Anal
            ( VAR prevFlagState : BOOLEAN;
                  currFlagState : BOOLEAN;
              VAR flagErr       : FlagsTable;
                  dis           : WORD;
                  DisNilVal     : WORD;
                  zoneNr        : NumStrefy  );

  BEGIN
    WITH flagErr DO
    IF currFlagState AND NOT prevFlagState
    THEN
      IF w_IleOd < MAX( OdcinekIle )
      THEN
        INC( w_IleOd );
        WITH opis[w_IleOd] DO
          sector := zoneNr;
          pocz := dis;
          kon := dis;
        END (* with opis *);
      END (* if w_IleOd *);
    ELSIF currFlagState AND (w_IleOd > 0) AND (dis <> DisNilVal)
    (* prevFlagState *)
    THEN
      WITH opis[w_IleOd] DO
        IF pocz = DisNilVal THEN
          pocz := dis;
        END;
        kon := dis;
      END (* with opis *);
    END (* if currFlagState *);
    END (* with flagErr *);
    prevFlagState := currFlagState;
  END FlagErr_Anal;


  PROCEDURE InitFlagErr
            ( VAR flagErr : FlagsTable );

  VAR
    odcinekIdx : OdcinekNr;

  BEGIN
    WITH flagErr DO
      w_IleOd := MIN(OdcinekIle);
      FOR odcinekIdx := MIN( OdcinekNr ) TO MAX( OdcinekNr ) DO
        WITH flagErr.opis[odcinekIdx] DO
          sector := ns_no;
          pocz := WORD( DisNilVal );
          kon := WORD( DisNilVal );
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
        StdIO.sprintf3( str, " Odcinek %1d: od %s do %s", fracNum, 
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
  
END FlagAnal.
