(*.F- *)
(**********************************************************************
|  Title   : Procedury zwiazane ze zbieraniem danych
|  Author  : D.Arendt
|  System  : LOGITECH MODULA-2/86
|  History :
|    12-03-96: M.Postol
|      Samp2Dis - calkowicie zmieniona
|    05-11-96:
|      UpdateDistMarks i UpdateAlfaMarks zle wywolanie do DisAddSample
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE DataCollect;

  IMPORT
    BlockOps, CommonTypes, SYSTEM, SpecConv, Marks, MANAGER;

  FROM SYSTEM IMPORT
    WORD;

  FROM CommonTypes IMPORT
    GlownyOdbiornikT, NilValC, SigNilVal, signTab;

  FROM SYSTEM IMPORT
    ADR, SIZE;

  FROM Polozenie IMPORT
    NoweCzesciOkregu, RresetCzesciOkregu;

  FROM SpecConv IMPORT
    GorszeBoProc;

  FROM Marks IMPORT
  (* TYPE *) AngMarksDsc, DisMarksDsc,
  (* PROCEDURE *) AngResetContiner, DisResetContiner, AngAddSample, 
                  DisAddSample;

  FROM NumberConversion IMPORT
    CardToString;
  
  FROM SpecConv IMPORT
    Ang100Str36Calk, Int100StrCalk;

  CONST
    Tablen     = 800;

  VAR
    Idx         : ARRAY BOOLEAN OF CARDINAL;
    angContiner : ARRAY BOOLEAN OF AngMarksDsc;
    disContiner : ARRAY BOOLEAN OF DisMarksDsc;
    marks_Con_D  : DisMarksDsc;
    marks_Con_A  : AngMarksDsc;

  MODULE tablice[0];

    FROM CommonTypes IMPORT
      signTab, NilValC, SigNilVal;

    FROM SYSTEM IMPORT
      ADR;
   
    FROM SpecConv IMPORT
      GorszeBoDalszeOdZera;

    FROM MANAGER IMPORT
      Assert;
      
    IMPORT
      (* CONST *) MaxIdx, 
      (* TYPE *) GlownyOdbiornikT, IdxTable, CardTab, ValDisTab,
                 GorszeBoProc, WORD, CardTabW, 
      (* VAR *) VAL1, VAL2, VAL3, VAL4,
      (* MODULE *) BlockOps;

    EXPORT
      Tablice800, InitTab, RedrawReq, SampleNr, Samp2Dis, VALX, Samp2Kat;

    TYPE
      assignProTab =
        ARRAY BOOLEAN OF GorszeBoProc;
      tabCntr      =
        ARRAY BOOLEAN OF CARDINAL;

    VAR
      samplediv : IdxTable;
      curr23    : ARRAY BOOLEAN OF [0 .. 1];  (* 0 to 2 1 to 3 *)
      IDX3      : IdxTable;
      IDX2      : IdxTable;
      Div3T     : IdxTable;
      Div2T     : IdxTable;
      div2n     : tabCntr;
      div3n     : tabCntr;
      ix2       : tabCntr;
      ix3       : tabCntr;
      procVAL1  : assignProTab;
      procVAL2     : assignProTab;
      procVAL3     : assignProTab;
      procVAL4     : assignProTab;
      samples      : tabCntr;
      VALX         : ValDisTab;
  

    PROCEDURE  SampleNr
               (     Pomiar       : BOOLEAN): CARDINAL;
    BEGIN
      RETURN samples[Pomiar];
    END SampleNr;
    
    PROCEDURE RedrawReq
              ( VAR ix            : CARDINAL;
                VAR by2or3        : CARDINAL;
                VAR currSamplediv : CARDINAL;
                    Pomiar        : BOOLEAN  ) : BOOLEAN;

    BEGIN
      IF curr23[Pomiar] = 0
      THEN
        ix := IDX2[Pomiar];
      ELSE
        ix := IDX3[Pomiar];
      END (* if curr23 *);
      by2or3 := curr23[Pomiar];
      currSamplediv := samplediv[Pomiar];
      RETURN FALSE;
    END RedrawReq;

    PROCEDURE Tablice800
              (     pomiar   : BOOLEAN;
                    val1     : signTab;
                    val2     : signTab;
                    val3     : signTab;
                    val4     : signTab;
                    xref     : WORD;
                VAR redraw   : BOOLEAN;
                VAR sampleNr : CARDINAL );
    VAR
      CHN : GlownyOdbiornikT;

      PROCEDURE UpdateNR;

      BEGIN
        IDX2[pomiar] := ix2[pomiar];
        IDX3[pomiar] := ix3[pomiar];
      END UpdateNR;

      PROCEDURE Shrink
                (     procVAL : GorszeBoProc;
                  VAR arr     : CardTab);
        (* av = wartosc srednia ev = wartosc NIL *)
      VAR
        i,
        mx : CARDINAL;
        ev : INTEGER;

      BEGIN
        ev := SigNilVal;
        FOR i := 1 TO MaxIdx DIV 2 DO
          mx := 2 * i;
          procVAL(arr[mx - 1], arr[mx]);
          arr[i] := arr[mx - 1];
        END (* for i *);
        mx := mx DIV 2;
        BlockOps.BlockSet(ADR(arr[mx + 1]), (MaxIdx - mx) * 2, ADR(ev), 2);
      END Shrink;

      PROCEDURE ShrinkX
                ( VAR arr     : CardTabW);
        (* av = wartosc srednia ev = wartosc NIL *)
      VAR
        i  : CARDINAL;
        mx : CARDINAL;
        ev : INTEGER;

      BEGIN
        ev := SigNilVal;
        FOR i := 1 TO MaxIdx DIV 2 DO
          mx := 2 * i;
          arr[i] := arr[mx];
        END (* for i *);
        mx := mx DIV 2;
        BlockOps.BlockSet(ADR(arr[mx + 1]), (MaxIdx - mx) * 2, ADR(ev), 2);
      END ShrinkX;


    BEGIN (* Tablice800 *)
      INC(div2n[pomiar]);
      INC(div3n[pomiar]);
      INC(samples[pomiar]);
      sampleNr := samples[pomiar];
      (* szukaj najGorszeBoMniejszej wartosci z kolejnych samplediv *)
      FOR CHN := goA TO goB DO
        procVAL1[pomiar](VAL1[pomiar, 0, CHN, ix2[pomiar]], val1[CHN]);
        procVAL2[pomiar](VAL2[pomiar, 0, CHN, ix2[pomiar]], val2[CHN]);
        procVAL3[pomiar](VAL3[pomiar, 0, CHN, ix2[pomiar]], val3[CHN]);
        procVAL4[pomiar](VAL4[pomiar, 0, CHN, ix2[pomiar]], val4[CHN]);
        procVAL1[pomiar](VAL1[pomiar, 1, CHN, ix3[pomiar]], val1[CHN]);
        procVAL2[pomiar](VAL2[pomiar, 1, CHN, ix3[pomiar]], val2[CHN]);
        procVAL3[pomiar](VAL3[pomiar, 1, CHN, ix3[pomiar]], val3[CHN]);
        procVAL4[pomiar](VAL4[pomiar, 1, CHN, ix3[pomiar]], val4[CHN]);
      END (* for CHN *);
      VALX[pomiar, 0, ix2[pomiar]] := xref;
      VALX[pomiar, 1, ix3[pomiar]] := xref;
      UpdateNR;
      (* zapis najgorszej wartosci do tablicy *)
      IF div2n[pomiar] >= Div2T[pomiar]
      THEN   (* przesun index *)
        IF ix2[pomiar] = MaxIdx
        THEN
        (* Shrink tables *)
          FOR CHN := goA TO goB DO
            Shrink(GorszeBoDalszeOdZera, VAL1[pomiar, 0, CHN]);
            Shrink(GorszeBoDalszeOdZera, VAL2[pomiar, 0, CHN]);
            Shrink(GorszeBoDalszeOdZera, VAL3[pomiar, 0, CHN]);
            Shrink(GorszeBoDalszeOdZera, VAL4[pomiar, 0, CHN]);
          END (* for ixx *);
          ShrinkX(VALX[pomiar, 0 ]);
          ix2[pomiar] := MaxIdx DIV 2;
          Div2T[pomiar] := Div2T[pomiar] * 2;
          IF samplediv[pomiar] = 1
          THEN
            samplediv[pomiar] := Div2T[pomiar];
          ELSE
            curr23[pomiar] := 1;   (* przestaw na trzy *)
            samplediv[pomiar] := Div3T[pomiar];
          END (* if samplediv *);
          UpdateNR;
          redraw := TRUE;
        END (* if ix2 *);
        div2n[pomiar] := 0;
        Assert(ix2[pomiar]*Div2T[pomiar] = samples[pomiar]);
        INC(ix2[pomiar]);
      END (* if div2n *);
      IF div3n[pomiar] >= Div3T[pomiar]
      THEN   (* przesun index *)
        IF ix3[pomiar] = MaxIdx
        THEN
        (* Shrink tables *)
          FOR CHN := goA TO goB DO
            Shrink(GorszeBoDalszeOdZera, VAL1[pomiar, 1, CHN]);
            Shrink(GorszeBoDalszeOdZera, VAL2[pomiar, 1, CHN]);
            Shrink(GorszeBoDalszeOdZera, VAL3[pomiar, 1, CHN]);
            Shrink(GorszeBoDalszeOdZera, VAL4[pomiar, 1, CHN]);
          END (* for CHN *);
          ShrinkX(VALX[pomiar, 1 ]);
          ix3[pomiar] := MaxIdx DIV 2;
          Div3T[pomiar] := Div3T[pomiar] * 2;
          curr23[pomiar] := 0;   (* przestaw na 0 *)
          samplediv[pomiar] := Div2T[pomiar];
          UpdateNR;
          redraw := TRUE;
        END (* if ix3 *);
        div3n[pomiar] := 0;
        Assert(ix3[pomiar]*Div3T[pomiar] = samples[pomiar]);
        INC(ix3[pomiar]);
      END (* if div3n *);
    END Tablice800;

    PROCEDURE InitTab
              (    pomiar : BOOLEAN;
                   proc1  : GorszeBoProc;
                   proc2  : GorszeBoProc;
                   proc3  : GorszeBoProc;
                   proc4  : GorszeBoProc );

    BEGIN (* InitTab *)
      procVAL1[pomiar] := proc1;
      procVAL2[pomiar] := proc2;
      procVAL3[pomiar] := proc3;
      procVAL4[pomiar] := proc4;
      ix2[pomiar] := 1;
      ix3[pomiar] := 1;
      div2n[pomiar] := 0;
      div3n[pomiar] := 0;
      IDX3[pomiar] := 0;
      IDX2[pomiar] := 0;
      Div3T[pomiar] := 3;
      Div2T[pomiar] := 1;
      samplediv[pomiar] := 1;
      curr23[pomiar] := 0;   (* znaczy tablica dzielenia przez 2 *)
      samples[pomiar] := 0;
    END InitTab;

  PROCEDURE Samp2Dis
            (    pomiar   : BOOLEAN;
                 sampleNr : CARDINAL ) : CARDINAL;

  BEGIN (* Samp2Dis *)
    IF sampleNr = NilValC
    THEN
      RETURN NilValC;
    END (* if sampleNr *);
    RETURN CARDINAL(VALX[ pomiar, curr23[pomiar], 
                          sampleNr DIV samplediv[pomiar] ]); 
  END Samp2Dis;
  
  PROCEDURE Samp2Kat
            (    pomiar   : BOOLEAN;
                 sampleNr : CARDINAL ) : INTEGER;
  BEGIN
    IF sampleNr = NilValC
    THEN
      RETURN SigNilVal;
    END (* if sampleNr *);
    RETURN INTEGER(VALX[pomiar, 
                        curr23[pomiar], 
                        sampleNr DIV samplediv[pomiar] ]); 
  END Samp2Kat;

  END tablice;
  PROCEDURE ResetMarks_A;
  BEGIN
    AngResetContiner(marks_Con_A);
  END ResetMarks_A;
  
  PROCEDURE ResetMarks_D;
  BEGIN
    DisResetContiner(marks_Con_D);
  END ResetMarks_D;

  PROCEDURE GetNextDMark
            (    pomiar     : BOOLEAN;
             VAR sampleNr   : CARDINAL;
             VAR currIdxStr : ARRAY OF CHAR;
                 Width      : CARDINAL ): BOOLEAN;
  VAR
    currIndex : CARDINAL;
  BEGIN
    WHILE sampleNr < SampleNr(pomiar) DO
      IF DisAddSample( Samp2Dis(pomiar, sampleNr), marks_Con_D, 
                       currIndex, Width)
      THEN
        CardToString( currIndex DIV 500, currIdxStr, 0);
        RETURN TRUE;
      END;
      INC( sampleNr );
    END;
    RETURN FALSE;
  END GetNextDMark;
  
  PROCEDURE GetNextAMark
            (    pomiar     : BOOLEAN;
             VAR sampleNr   : CARDINAL;
             VAR currIdxStr : ARRAY OF CHAR;
                 Width      : CARDINAL;
                 format360  : BOOLEAN ): BOOLEAN;
  VAR
    currIndex : INTEGER;
  BEGIN
    WHILE sampleNr < SampleNr(pomiar) DO
      IF AngAddSample( Samp2Kat(pomiar, sampleNr), marks_Con_A, 
                       currIndex, Width)
      THEN
        IF format360
        THEN
          Ang100Str36Calk(currIndex, currIdxStr, 0);
        ELSE
          Int100StrCalk(currIndex, currIdxStr, 0);
        END (* if Format360 *);
        RETURN TRUE;
      END;
      INC( sampleNr );
    END;
    RETURN FALSE;
  END GetNextAMark;
  
  PROCEDURE Start
            (    pomiar : BOOLEAN;
                 proc1  : GorszeBoProc;
                 proc2  : GorszeBoProc;
                 proc3  : GorszeBoProc;
                 proc4  : GorszeBoProc );
  VAR
    patt : INTEGER;

  BEGIN
    Idx[pomiar] := 0;
    BlockOps.BlockClear(ADR(VALX[pomiar]), SIZE(VALX[pomiar]));
    patt := SigNilVal;
    BlockOps.BlockSet(ADR(VAL1[pomiar]), SIZE(VAL1[pomiar]), ADR(patt), 2);
    VAL1[pomiar, 0, goA, 0] := Tablen;
    VAL1[pomiar, 0, goB, 0] := Tablen;
    VAL1[pomiar, 1, goA, 0] := Tablen;
    VAL1[pomiar, 1, goB, 0] := Tablen;
    BlockOps.BlockSet(ADR(VAL2[pomiar]), SIZE(VAL2[pomiar]), ADR(patt), 2);
    VAL2[pomiar, 0, goA, 0] := Tablen;
    VAL2[pomiar, 0, goB, 0] := Tablen;
    VAL2[pomiar, 1, goA, 0] := Tablen;
    VAL2[pomiar, 1, goB, 0] := Tablen;
    BlockOps.BlockSet(ADR(VAL3[pomiar]), SIZE(VAL3[pomiar]), ADR(patt), 2);
    VAL3[pomiar, 0, goA, 0] := Tablen;
    VAL3[pomiar, 0, goB, 0] := Tablen;
    VAL3[pomiar, 1, goA, 0] := Tablen;
    VAL3[pomiar, 1, goB, 0] := Tablen;
    BlockOps.BlockSet(ADR(VAL4[pomiar]), SIZE(VAL4[pomiar]), ADR(patt), 2);
    VAL4[pomiar, 0, goA, 0] := Tablen;
    VAL4[pomiar, 0, goB, 0] := Tablen;
    VAL4[pomiar, 1, goA, 0] := Tablen;
    VAL4[pomiar, 1, goB, 0] := Tablen;
    InitTab(pomiar, proc1, proc2, proc3, proc4);
    IF NOT pomiar
    THEN
      RresetCzesciOkregu()
    END (* if *);
  END Start;
  
  PROCEDURE ResetDataCollect
            (    pomiar : BOOLEAN;
                 proc1  : GorszeBoProc;
                 proc2  : GorszeBoProc;
                 proc3  : GorszeBoProc;
                 proc4  : GorszeBoProc );
  BEGIN
    AngResetContiner(angContiner[pomiar]);
    DisResetContiner(disContiner[pomiar]);
    Start(pomiar, proc1, proc2, proc3, proc4);
  END ResetDataCollect;
  
  PROCEDURE UpdTab800
            (     Pomiar       : BOOLEAN;
                  val1         : signTab;
                  val2         : signTab;
                  val3         : signTab;
                  val4         : signTab;
              VAR redraw       : BOOLEAN;
              VAR redrawM      : BOOLEAN;
                  XRef         : WORD;
                  ImportantDiv : CARDINAL;
                  XRefAlfa     : BOOLEAN  );
  
  PROCEDURE UpdateDistMarks
            (     pomiar       : BOOLEAN;
                  RefDis       : CARDINAL;
                  ImportantDiv : CARDINAL;
              VAR redrawM      : BOOLEAN  );
  VAR
    currIndex  : CARDINAL;

  BEGIN
    redrawM := FALSE;
    IF RefDis = NilValC
    THEN
      RETURN
    END (* if RefDis *);
    IF DisAddSample(RefDis, disContiner[pomiar], currIndex, 
                    ImportantDiv) 
    THEN
      redrawM := TRUE;
    END;
  END UpdateDistMarks;

  PROCEDURE UpdateAlfaMarks
            (     pomiar       : BOOLEAN;
                  AlfaRef      : INTEGER;
                  ImportantDiv : CARDINAL;
              VAR redrawM      : BOOLEAN  );

  VAR
    currIndex    : INTEGER;

  BEGIN (* UpdateAlfaMarks *)
    redrawM := FALSE;
    IF AlfaRef = SigNilVal
    THEN
      RETURN;
    END (* if AlfaRef *);
    IF AngAddSample(AlfaRef, angContiner[pomiar], currIndex, ImportantDiv) 
    THEN
      redrawM := TRUE;
    END;
    IF NOT pomiar THEN
       NoweCzesciOkregu(AlfaRef);
    END;
  END UpdateAlfaMarks;

  VAR
    sampleNr     : CARDINAL;
  BEGIN
    Tablice800(Pomiar, val1, val2, val3, val4, XRef, redraw, sampleNr);
    IF XRefAlfa
    THEN
      UpdateAlfaMarks(Pomiar, INTEGER(XRef), ImportantDiv, redrawM);
    ELSE
      UpdateDistMarks(Pomiar, CARDINAL(XRef), ImportantDiv, redrawM)
    END (* if XRefAlfa *);
  END UpdTab800;

  PROCEDURE NilProc
            ( VAR p1 : INTEGER;
                  p2 : INTEGER );

  BEGIN
  END NilProc;

BEGIN
  Start(FALSE, NilProc, NilProc, NilProc, NilProc);
  Start(TRUE, NilProc, NilProc, NilProc, NilProc);
END DataCollect.
