IMPLEMENTATION MODULE PI_DMEnaglowek;

FROM L_CommonTypes IMPORT
  ProceduraT, StronaT, Procedura, Strona, CzyToJestPromien;
FROM CommonTypes IMPORT
  NadajnikT, PolozenieGeo, Str99;
FROM L_DataBase IMPORT
  Lotnisko;
FROM StdIO IMPORT
  sprintf, sprintf2;
FROM L_Oblot IMPORT
  SciezkaDoKataloguOpisu;
FROM PI_ArchDate IMPORT
  okTab, LoadData;
FROM Files IMPORT
  GoHomeDir;
FROM Strings IMPORT
  ConstAssign, Insert;
IMPORT
  CommonData, D_results, Tune, RealConversions, MANAGER, L_Print;


  PROCEDURE UstawSciezke(  );
    BEGIN
      SciezkaDoKataloguOpisu();
    END UstawSciezke;

  PROCEDURE DaneZBazyDanych( VAR Czestotliwosc : REAL;
                             VAR Deklinacja    : REAL;
                             VAR Polozenie     : PolozenieGeo );
    VAR
      s : Str99;
      ok : BOOLEAN;
    BEGIN
      Tune.ILSfrqString( Lotnisko.Czestotliwosc, s );
      RealConversions.StringToReal( s, Czestotliwosc, ok );
      MANAGER.Assert( ok );
      Deklinacja    := Lotnisko.Deklinacja;
      Polozenie     := Lotnisko.Polozenie;
    END DaneZBazyDanych;

  PROCEDURE NastepneDane( wid : WyznaczanieIDrukowanie );
    VAR
      Naglowek : Str99;
      p        : ProceduraT;
      s        : StronaT;
      d        : okTab;
      n        : NadajnikT;
      ByloCosZrobione : BOOLEAN;

    BEGIN
      FOR p := MIN( ProceduraT ) TO MAX( ProceduraT ) DO
        FOR s := sL75 TO sP75 DO
          ByloCosZrobione := FALSE;
          IF (s = sL75) OR (p <= pAlarmWaski_pA) OR (p = pMarker) THEN
            FOR n := nA TO nB DO
              Procedura := p;
              Strona := s;
              CommonData.Nadajnik1 := n;
              SciezkaDoKataloguOpisu();
              LoadData( d );
              GoHomeDir();
              IF d[TRUE] THEN
                ByloCosZrobione := TRUE;
                L_Print.NazwaProcedury( p, s, FALSE, Naglowek );
                Insert( "Pomiar DME na procedurze ", Naglowek, 0 );
                IF NOT wid( CzyToJestPromien(p), n, Naglowek, FALSE ) THEN
                  RETURN;
                END;
              ELSIF ByloCosZrobione THEN
                IF NOT wid( CzyToJestPromien(p), n, Naglowek, TRUE ) THEN
                  RETURN;
                END;
              END;
            END;
          END;
        END;
      END;
    END NastepneDane;



END PI_DMEnaglowek.

