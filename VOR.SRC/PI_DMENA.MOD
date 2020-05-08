(*.F- *)
(**********************************************************************
|  Title   : DMA - Raport koncowy modul pomocniczy  
|  Author  : M.Morawski
|  System  : LOGITECH MODULA-2/86 
|  History :
|    Rel.3.02 M.Postol
|      nie byly drukowane rapoprty koncowe DMA, poniewaz zasiegi DMA sa 
|      robione na pomiarach bledow. Musieli by robic osobne pomiary dla DMA.
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 686 25 47
|  mailto: techsupp@cas.com.pl
|  http: www.cas.com.pl
|
**********************************************************************)
(*.F+ *)
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

  PROCEDURE NastepneDane
            (     wid : WyznaczanieIDrukowanie );
    VAR
      Naglowek        : Str99;
      proc            : ProceduraT;
      i, f            : CARDINAL;
      d               : okTab;
      nd_nadidx       : NadajnikT;
      ByloCosZrobione : BOOLEAN;

        PROCEDURE Prom
                  (    P : CARDINAL ) : BOOLEAN;
        VAR
          nadidx : NadajnikT;
        BEGIN
          ByloCosZrobione := FALSE;
          FOR nadidx := nA TO nB DO
            CommonData.Nadajnik1 := nadidx;
            CommonData.Promien   := P;
            SciezkaDoKataloguOpisuUst();
            LoadData( d );
            GoHomeDir();
            IF d[TRUE] THEN
              ByloCosZrobione := TRUE;
              sprintf( Naglowek, "Pomiar DME na promieniu %dø", P );
              IF NOT wid( TRUE, nadidx, Naglowek, FALSE ) THEN
                RETURN FALSE;
              END;
            ELSIF ByloCosZrobione THEN
              IF NOT wid( TRUE, nadidx, Naglowek, TRUE ) THEN
                RETURN FALSE;
              END;
            END;
          END;
          RETURN TRUE;
        END Prom;

    BEGIN (* NastepneDane *)
      FOR proc := pOkragBlad TO pOkragZakres DO
        ByloCosZrobione := FALSE;
        FOR nd_nadidx := nA TO nB DO
          V_CommonTypes.Procedura :=  proc;
          CommonData.Nadajnik1 := nd_nadidx;
          SciezkaDoKataloguOpisuUst();
          LoadData( d );
          GoHomeDir();
          IF d[TRUE] THEN
            ByloCosZrobione := TRUE;
            i := CARDINAL( D_results.anRes.PromienLubOrbita ) DIV 500;
            f := CARDINAL( D_results.anRes.PromienLubOrbita ) MOD 500 DIV 5;
            sprintf2( Naglowek, "Pomiar DME na orbicie %d.%02d NM", i, f );
            IF NOT wid( FALSE, nd_nadidx, Naglowek, FALSE ) THEN
              RETURN;
            END;
          ELSIF ByloCosZrobione THEN
            IF NOT wid( FALSE, nd_nadidx, Naglowek, TRUE ) THEN
              RETURN;
            END;
          END;
        END;
      END (* FOR *);
      FOR proc := pPromienBlad TO pPromienZakres DO
        V_CommonTypes.Procedura := proc;
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
      END (* FOR *);
    END NastepneDane;

END PI_DMEnaglowek.
