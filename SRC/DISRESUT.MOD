(*.F- *)
(**********************************************************************
|  Title   : Wspolne procedury dla obslugi wyswietlania wynikow analizy
|  Author  : MPostol
|  System  : LOGITECH MODULA-2/86
|  History :
|    Rel 3.0.
|      podzielilem procedure opisujaca odcinki WrFlagsTable
|      i wydzielilem WrFlagsTableWHeading aby opisywac odcinki 
|      nie analizowane na orbicie VOR
|     
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE DisResUtilities;

  FROM SpecConv IMPORT
    ToStringProcT;

  FROM Strings IMPORT
    Concat, Length;

  IMPORT
    StdIO;

  FROM SYSTEM IMPORT
    ADDRESS, ADR;

  FROM CommonTypes IMPORT
    GlownyOdbiornikT, GetRecName;

  FROM FlagAnal IMPORT
    GetNextFrac, FlagsTable, F_TablicaOdci, OdcinekIdx;

  FROM GrafTypes IMPORT
    RECT, BLUE, WHITE, GREEN;

  FROM HiLevGraf IMPORT
    FillRect, WrStr;

  FROM Strings IMPORT
    Assign;
    
  CONST
  (* uzyte kolory *)
    AN_Tlo   = BLUE;
    AN_Pasek = GREEN;

  PROCEDURE WriteTab
            ( VAR lineH    : LineNumT;
              VAR lineInfo : LineNumT );

  CONST
    liniaPocz = 40;
    bottomL   = 599;
  VAR
    Prostokat : RECT;
    line      : CARDINAL;

  BEGIN (* WriteTab *)
    lineH := liniaPocz;
    lineInfo := liniaPocz + 3 * Szerokosc;
    Prostokat.left := 0;
    Prostokat.right := 799;
    Prostokat.top := liniaPocz;
    Prostokat.bottom := bottomL;
    FillRect(Prostokat, AN_Tlo);
    line := lineInfo;
    WHILE line + Szerokosc - 1 <= bottomL DO
      Prostokat.top := line;
      Prostokat.bottom := line + Szerokosc - 1;
      FillRect(Prostokat, AN_Pasek);
      INC(line, 2 * Szerokosc);
    END (* while line *);
  END WriteTab;

  PROCEDURE WrS
            (    str  : ARRAY OF CHAR;
                 line : LineNumT;
                 col  : ColNumT       );

  BEGIN
    WrStr(str, col, line, WHITE, WHITE);
  END WrS;

  PROCEDURE WrSPlus
            (     str  : ARRAY OF CHAR;
              VAR line : LineNumT;
                  col  : ColNumT       );

  BEGIN
    IF (line < MAX( LineNumT ) - Szerokosc) THEN
      WrStr(str, col, line, WHITE, WHITE);
      INC(line, Szerokosc);
    END;
  END WrSPlus;

  PROCEDURE INCLine
            ( VAR line : LineNumT );

  BEGIN
    IF (line < MAX( LineNumT ) - Szerokosc) THEN
      INC(line, Szerokosc);
    END;
  END INCLine;

  PROCEDURE WrFlagsTableWHeading
            (     heading : ARRAY OF CHAR;
                  tab     : FlagsTable;
              VAR line    : LineNumT;
                  converP : ToStringProcT
             );
  VAR
    lineStr : ARRAY [0 .. ScreenMaxLen] OF CHAR;
    fracNum : OdcinekIdx;
    str     : ARRAY[ 0..40] OF CHAR;
    
  BEGIN (* WrFlagsTableWHeading *)
    fracNum := MIN(OdcinekIdx);
    Assign(heading, lineStr);
    LOOP
      IF NOT GetNextFrac(converP, tab, str, fracNum)
      THEN
        EXIT
      END (* if *);
      IF Length(lineStr) + Length(str) < ScreenMaxLen
      THEN
        Concat(lineStr, str, lineStr)
      END (* if Length *);
    END (* loop *);
    WrSPlus(lineStr, line, 0);
  END WrFlagsTableWHeading;

  PROCEDURE WrFlagsTable
            (     tab     : FlagsTable;
              VAR line    : LineNumT;
                  converP : ToStringProcT;
                  rec     : GlownyOdbiornikT );
  VAR
    lineStr : ARRAY [0 .. ScreenMaxLen] OF CHAR;
    str     : ARRAY [0 .. 45] OF CHAR;
    strAdr  : ADDRESS;

  BEGIN
    strAdr := ADR(str);
    GetRecName(str, rec);
    StdIO.sprintf(lineStr, 'Odb %s:', strAdr);
    WrFlagsTableWHeading(lineStr, tab, line, converP );
  END WrFlagsTable;

  PROCEDURE WrF_TablicaOdci
            (     heading : ARRAY OF CHAR;
                  tab     : F_TablicaOdci;
              VAR line    : LineNumT;
                  converP : ToStringProcT );
  VAR
    rec : GlownyOdbiornikT;

  BEGIN
    WrSPlus(heading, line, 0);
    FOR rec := MIN(GlownyOdbiornikT) TO MAX(GlownyOdbiornikT) DO
      WrFlagsTable(tab[rec], line, converP, rec);
    END (* for rec *);
  END WrF_TablicaOdci;

END DisResUtilities.
