IMPLEMENTATION MODULE PI_DMEnaglowek;

FROM D_CommonTypes IMPORT
  ProceduraT;
FROM CommonTypes IMPORT
  NadajnikT, PolozenieGeo, Str99;
FROM V_Database IMPORT
  CurVor1, IleKierunkow;
FROM StdIO IMPORT
  sprintf, sprintf2;
FROM V_Oblot IMPORT
  SciezkaDoKataloguOpisuUst;
FROM PI_ArchDate IMPORT
  okTab, LoadData;
FROM Files IMPORT
  GoHomeDir;
FROM Strings IMPORT
  ConstAssign;
IMPORT
  V_CommonTypes, CommonData, D_results;



  PROCEDURE UstawSciezke(  );
    BEGIN
      SciezkaDoKataloguOpisuUst();
    END UstawSciezke;

  PROCEDURE DaneZBazyDanych( VAR Czestotliwosc : REAL;
                             VAR Deklinacja    : REAL;
                             VAR Polozenie     : PolozenieGeo );
    BEGIN
      Czestotliwosc := FLOAT( CurVor1.Czestotliwosc ) / 100.0;
      Deklinacja    := CurVor1.Deklinacja;
      Polozenie     := CurVor1.Polozenie;
    END DaneZBazyDanych;

  PROCEDURE NastepneDane( wid : WyznaczanieIDrukowanie );
    VAR
      Naglowek : Str99;
      p        : ProceduraT;
      i, f     : CARDINAL;
      d        : okTab;
      n        : NadajnikT;
      ByloCosZrobione : BOOLEAN;

      PROCEDURE Prom( P : CARDINAL ) : BOOLEAN;
        VAR
          n : NadajnikT;
        BEGIN
          ByloCosZrobione := FALSE;
          FOR n := nA TO nB DO
            CommonData.Nadajnik1 := n;
            CommonData.Promien := P;
            SciezkaDoKataloguOpisuUst();
            LoadData( d );
            GoHomeDir();
            IF d[TRUE] THEN
              ByloCosZrobione := TRUE;
              sprintf( Naglowek, "Pomiar DME na promieniu %dø", P );
              IF NOT wid( TRUE, n, Naglowek, FALSE ) THEN
                RETURN FALSE;
              END;
            ELSIF ByloCosZrobione THEN
              IF NOT wid( TRUE, n, Naglowek, TRUE ) THEN
                RETURN FALSE;
              END;
            END;
          END;
          RETURN TRUE;
        END Prom;

    BEGIN
      p := pOkragZakres;
      ByloCosZrobione := FALSE;
      FOR n := nA TO nB DO
        V_CommonTypes.Procedura := p;
        CommonData.Nadajnik1 := n;
        SciezkaDoKataloguOpisuUst();
        LoadData( d );
        GoHomeDir();
        IF d[TRUE] THEN
          ByloCosZrobione := TRUE;
          i := CARDINAL( D_results.anRes.PromienLubOrbita ) DIV 500;
          f := CARDINAL( D_results.anRes.PromienLubOrbita ) MOD 500 DIV 5;
          sprintf2( Naglowek, "Pomiar DME na orbicie %d.%02d NM", i, f );
          IF NOT wid( FALSE, n, Naglowek, FALSE ) THEN
            RETURN;
          END;
        ELSIF ByloCosZrobione THEN
          IF NOT wid( FALSE, n, Naglowek, TRUE ) THEN
            RETURN;
          END;
        END;
      END;

      p := pPromienZakres;
      V_CommonTypes.Procedura := p;
      FOR i := 1 TO CurVor1.IleKierunkow DO
        IF NOT Prom(CurVor1.Kierunki[i-1]) THEN
          RETURN;
        END;
      END;
      FOR i := 1 TO CurVor1.IleKierunkowDodatkowych DO
        IF NOT Prom(CurVor1.KierunkiDodatkowe[i-1]) THEN
          RETURN;
        END;
      END;
    END NastepneDane;



END PI_DMEnaglowek.

