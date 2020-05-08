(*.F- *)
(**********************************************************************
|  Title   : Modul strojenia odbiornikow nawigacyjnych
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|  Rel 001 27.01.1996: new
|          27.06.1996: M.Postol
|            zmiana przy wysylaniu odpowiadajaca zmianie w sprzecie - 
|            kontrola pracy DME
|          17.07.1996: M.Postol
|            TuneVOR_ILS blad przy wiliczniu F
|  Rel 3.0 MPostol
|    nie bylo ograniczen przy zmianie kanalow ILS
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 686 25 47
|  mailto: techsupp@cas.com.pl
|  http: www.cas.com.pl
|
**********************************************************************)
(*.F+ *)
IMPLEMENTATION MODULE Tune;

  FROM MANAGER IMPORT
    Assert;

  FROM SYSTEM IMPORT
    BYTE, INBYTE, OUTBYTE;

  FROM DGHInterface IMPORT
    DtaSignType, SetBinaryVal;

  FROM DGHIni IMPORT
    SignalNames;

  FROM SpecConv IMPORT
    Card100Str;

  FROM Strings IMPORT
    Concat;

  CONST
    OneByte    = FALSE;
    TwoBytes   = TRUE;
    PortA      = 1B0H;
    PortC      = PortA + 2;
    PortCont   = PortA + 3;
    Mode       = 253C;  (* 233C; *)
    WDLimit    = 100H;
    ADFAsel    = 0;
    ADFBsel    = 1;
    NAVlocAsel = 2;
    NAVgsAsel  = 3;
    NAVlocBsel = 4;
    NAVgsBsel  = 5;
    OnLevel    = {};
    OffLevel   = {0..7};

  TYPE
    set8             =
      SET OF [0 .. 7];
    NAVControlString =
      RECORD
        bits    :
          CHAR;
        synchro :
          set8;
        string  :
          ARRAY [0 .. 2] OF CHAR;
      END;

  VAR
    VORfreqCRT     : ARRAY ILSfrqIdx OF CARDINAL;
    GSfreqCRT      : ARRAY ILSfrqIdx OF CARDINAL;
    lastCPFlags    : BITSET;
    lastDMEfrqBits : ARRAY Receiver OF BITSET;

  PROCEDURE Send
            (    toBeSent : ARRAY OF BYTE ) : BOOLEAN;

  CONST
    strobe      = 5;
    bufferempty = 7;
  VAR
    control  : set8;
    id       : CARDINAL;
    watchDog : CARDINAL;

  BEGIN
    id := 0;
    watchDog := WDLimit;
    LOOP   (* Send *)
      DEC(watchDog);
      IF watchDog = 0
      THEN
        RETURN FALSE;
      END (* if *);
      INBYTE(PortC, control);
      IF (bufferempty IN control) AND (strobe IN control)
      THEN
        OUTBYTE(PortA, toBeSent[id]);
        INBYTE(PortC, control);
        INC(id);
        watchDog := WDLimit;
        IF id > HIGH(toBeSent)
        THEN
          RETURN TRUE;
        END (* if id *);
      END (* if *);
    END (* loop *);
    RETURN FALSE;
  END Send;

  PROCEDURE TurnOffADF
            (    rec : Receiver );

  BEGIN (* TurnOffADF *)
    CASE rec OF
      AReceiver :
        SetBinaryVal(ADFaON, OnLevel, OneByte);
      |
      BReceiver :
        SetBinaryVal(ADFbON, OnLevel, OneByte);
    END (* case rec *);
  END TurnOffADF;

  PROCEDURE TurnOffVOR_ILS
            (    rec : Receiver );

  BEGIN (* TurnOffVOR_ILS *)
    CASE rec OF
      AReceiver :
        SetBinaryVal(NAVaON, OnLevel, OneByte);
      |
      BReceiver :
        SetBinaryVal(NAVbON, OnLevel, OneByte);
    END (* case rec *);
  END TurnOffVOR_ILS;

  PROCEDURE TuneADF
            (     rec     : Receiver;
              VAR frq     : CARDINAL; (* in kHz *)
                  bfo     : BOOLEAN;
                  adfMode : BOOLEAN;
                  loc     : BOOLEAN  );

  TYPE
    ADFControlString =
      RECORD
        bits    :
          CHAR;
        synchro :
          set8;
        string  :
          ARRAY [0 .. 3] OF CHAR;
      END;
  VAR
    control : ADFControlString;
    npc     : CARDINAL;
    ns      : CARDINAL;
    nt      : CARDINAL;
    filter  : CARDINAL;
    recName : SignalNames;

  BEGIN
    IF frq >= 400
    THEN
      IF frq < 600
      THEN
        filter := 4;
      ELSIF frq < 900
      THEN
        filter := 2;
      ELSE
        filter := 1;
      END (* if *);
    ELSIF frq < 285
    THEN
      filter := 16;
    ELSE
      filter := 8;
    END (* if *);
    nt := frq + 12428;
    ns := 16 - nt MOD 16;
    npc := nt DIV 16 + 1 - ns DIV 16;
    ns := ns MOD 16;
    WITH control DO
      bits := CHAR(27);
      IF rec = AReceiver
      THEN
        recName := ADFaON;
        synchro := set8 {ADFAsel};
      ELSE
        recName := ADFbON;
        synchro := set8 {ADFBsel};
      END (* if rec *);
      string[0] := CHR(0E0H + ns * 2 + npc DIV 0800H);
      npc := npc MOD 0800H;
      string[1] := CHR(npc DIV 8);
      npc := npc MOD 8;
      string[2] := CHR(npc * 020H + filter MOD 20H);
      string[3] := CHR(ORD(bfo) * 80H + ORD(adfMode) * 040H + ORD(loc) * 020H);
    END (* with *);
    SetBinaryVal(recName, OffLevel, OneByte);
    Assert(Send(control));
  END TuneADF;

  PROCEDURE TuneILS
            (    rec            : Receiver;
                 frq            : ILSfrqIdx;
                 markerLowSense : BOOLEAN   );
  VAR
    ilsEnergName : SignalNames;
    mkrHLSenName : SignalNames;

    PROCEDURE TuneGS
              (    rec : Receiver;
                   frq : ILSfrqIdx );
    VAR
      control : NAVControlString;
      Npc     : CARDINAL;
      Ns      : CARDINAL;
      Nt      : CARDINAL;

    BEGIN (* TuneGS *)
      Nt := GSfreqCRT[frq] - 2 + 328 * 60;
      Npc := Nt DIV 16 + 1;
      Ns := 16 - Nt MOD 16;
      (* Npc := 1235; Ns := 13; *)
      WITH control DO
        bits := CHAR(19);
        IF rec = AReceiver
        THEN
          synchro := set8 {NAVgsAsel}
        ELSE
          synchro := set8 {NAVgsBsel}
        END (* if rec *);
        string[0] := CHR(5 * 20H + 2 * Ns + Npc DIV 0800H);
        Npc := Npc MOD 0800H;
        string[1] := CHR(Npc DIV 8);
        Npc := Npc MOD 8;
        string[2] := CHR(Npc * 020H);
      END (* with *);
      Assert(Send(control));
    END TuneGS;
  VAR
    currFrq : CARDINAL;

  BEGIN (* TuneILS *)
    currFrq := VORfreqCRT[frq];
    TuneVOR_ILS(rec, currFrq);
    IF rec = AReceiver
    THEN
      ilsEnergName := ILSaEnergize;
      mkrHLSenName := MKRaHiLoSense;
    ELSE
      ilsEnergName := ILSbEnergize;
      mkrHLSenName := MKRaHiLoSense;
    END (* if rec *);
    SetBinaryVal(ilsEnergName, OffLevel, OneByte);
    TuneGS(rec, frq);
    IF markerLowSense
    THEN
      SetBinaryVal(mkrHLSenName, OffLevel, OneByte);
    ELSE
      SetBinaryVal(mkrHLSenName, OnLevel, OneByte);
    END (* if markerLowSense *);
  END TuneILS;

  PROCEDURE SendDMECntrlWrd
            ( rec : Receiver   );

  VAR
    recName : SignalNames;
  BEGIN
    CASE rec OF
      AReceiver :
        recName := DMEaTune;
      |
      BReceiver :
        recName := DMEbTune;
    END (* case rec *);
    SetBinaryVal( recName, 
                  BITSET( CARDINAL(lastDMEfrqBits[rec]) * 2 + 
                          CARDINAL(lastCPFlags)
                        )     / {0..15}, 
                  TwoBytes );
  END SendDMECntrlWrd;

  PROCEDURE TuneDMEforVOR
            (     rec : Receiver;
              VAR frq : CARDINAL );
  VAR
    recName : SignalNames;

    PROCEDURE ConvertFrqTOControlWord
              (    frq : CARDINAL ) : BITSET;
    VAR
      factor : CARDINAL;

    BEGIN
      factor := frq MOD 100 * 2 DIV 10;
      IF ODD(factor)
      THEN
        DEC(factor);
      ELSE
        INC(factor);
      END (* if ODD *);
      frq := frq DIV 100 - 108;
      IF frq > 25
      THEN
        DEC(frq, 4);
      END (* if frq *);
      RETURN BITSET(frq * 20H + factor);
    END ConvertFrqTOControlWord;

  BEGIN (* TuneDMEforVOR *)
    lastDMEfrqBits[ rec ] := ConvertFrqTOControlWord(frq);
    SendDMECntrlWrd( rec );
  END TuneDMEforVOR;

  PROCEDURE TuneDMEforILS
            (    rec : Receiver;
                 frq : ILSfrqIdx );
  VAR
    currFrq : CARDINAL;

  BEGIN
    currFrq := VORfreqCRT[frq];
    TuneDMEforVOR(rec, currFrq);
  END TuneDMEforILS;

  PROCEDURE TuneVOR
            (     rec : Receiver;
              VAR frq : CARDINAL
                    (* in 0.01MHz *) );
  VAR
    ilsEnergName : SignalNames;

  BEGIN
    TuneVOR_ILS(rec, frq);
    IF rec = AReceiver
    THEN
      ilsEnergName := ILSaEnergize;
    ELSE
      ilsEnergName := ILSbEnergize;
    END (* if rec *);
    SetBinaryVal(ilsEnergName, OnLevel, OneByte);
  END TuneVOR;

  PROCEDURE TuneVOR_ILS
            (     rec : Receiver;
              VAR frq : CARDINAL
                    (* in 0.01MHz *) );
  VAR
    control : NAVControlString;
    Nt      : CARDINAL;
    Npc     : CARDINAL;
    Ns      : CARDINAL;
    recName : SignalNames;

  BEGIN (* TuneVOR_ILS *)
    IF frq < 10800
    THEN
      frq := 10800;
    ELSIF frq > 13595
    THEN
      frq := 13595
    ELSIF (frq > 11795) AND (frq < 13300)
    THEN
      frq := 11795
    END (* if frq *);
    Nt := (frq - 1110) DIV 5;
    IF (Nt MOD 16) <> 0  THEN
      Npc := Nt DIV 16 + 1;
      Ns := 16 - Nt MOD 16;
    ELSE
      Npc := Nt DIV 16;
      Ns := 0;
    END;
    WITH control DO
      bits := CHAR(19);
      IF rec = AReceiver
      THEN
        recName := NAVaON;
        synchro := set8 {NAVlocAsel};
      ELSE
        recName := NAVbON;
        synchro := set8 {NAVlocBsel};
      END (* if rec *);
      string[0] := CHR(1 * 20H + 2 * Ns + Npc DIV 0800H);
      Npc := Npc MOD 0800H;
      string[1] := CHR(Npc DIV 8);
      Npc := Npc MOD 8;
      string[2] := CHR(Npc * 020H);
    END (* with *);
    SetBinaryVal(recName, OffLevel, OneByte);
    Assert(Send(control));
  END TuneVOR_ILS;

  PROCEDURE ILSfrqString
            (     frq : ILSfrqIdx;
              VAR str : ARRAY OF CHAR );

  BEGIN
    Card100Str(VORfreqCRT[frq], str, 6);
    Concat(str, ' MHz', str);
  END ILSfrqString;

  PROCEDURE ILSIncFch
            ( VAR fch : ILSfrqIdx;
                  by  : CARDINAL  );

  BEGIN
    WHILE (fch <MAX(ILSfrqIdx)) AND (by >0) DO
      INC(fch);
      DEC(by);
    END (* if fch *);
  END ILSIncFch;

  PROCEDURE ILSDecFch
            ( VAR fch : ILSfrqIdx;
                  by  : CARDINAL  );

  BEGIN
    WHILE (fch > MIN(ILSfrqIdx) ) AND (by > 0) DO
      DEC(fch);
      DEC(by);
    END (* if fch *);
  END ILSDecFch;

  PROCEDURE VORIncFch
            ( VAR fch : CARDINAL;
                  by  : CARDINAL );

  BEGIN
    INC(fch, by);
    IF (fch > 11795) AND (fch < 13300)
    THEN
      fch := 13300;
    ELSIF (fch > 13595)
    THEN
      fch := 13595;
    END (* if fch *);
  END VORIncFch;

  PROCEDURE VORDecFch
            ( VAR fch : CARDINAL;
                  by  : CARDINAL );

  BEGIN
    DEC(fch, by);
    IF fch < 10800
    THEN
      fch := 10800;
    ELSIF (fch < 13300) AND (fch > 11795)
    THEN
      fch := 11795;
    END (* if fch *);
  END VORDecFch;

  PROCEDURE IncADFFch
            ( VAR fch : CARDINAL;
                  by  : CARDINAL );

  BEGIN
    INC(fch, by);
    IF fch > 1799
    THEN
      fch := 1799;
    END (* if fch *);
  END IncADFFch;

  PROCEDURE DecADFFch
            ( VAR adfCurrFrq : CARDINAL;
                  by         : CARDINAL );

  BEGIN
    IF adfCurrFrq < 190 + by
    THEN
      adfCurrFrq := 190;
    ELSE
      DEC(adfCurrFrq, by);
    END (* if fch *);
  END DecADFFch;

  PROCEDURE SetCPFlags( LOC_SFLG : BOOLEAN;
                        GS_SFLG  : BOOLEAN;
                        TO_SFLG  : BOOLEAN;
                        FROM_SFLG: BOOLEAN;
                        force    : BOOLEAN );

  CONST
    LOC_SFLGpos  = 0CH;
    GS_SFLGpos   = 0BH;
    TO_SFLGpos   = 0EH;
    FROM_SFLGpos = 0DH;
  VAR
    myBitset : BITSET;

  BEGIN (* SetCPFlags *)
    myBitset := {};
    IF TO_SFLG <> FROM_SFLG
    THEN
      IF TO_SFLG
      THEN
        INCL(myBitset, TO_SFLGpos);
      ELSE
        INCL(myBitset, FROM_SFLGpos);
      END (* if TO_SFLG *);
    END (* if TO_SFLG *);
    IF LOC_SFLG
    THEN
      INCL(myBitset, LOC_SFLGpos);
    END (* if LOC_SFLG *);
    IF GS_SFLG
    THEN
      INCL(myBitset, GS_SFLGpos);
    END (* if GS_SFLG *);
    IF force OR (lastCPFlags <> myBitset)  THEN
      lastCPFlags := myBitset;
      SendDMECntrlWrd(AReceiver);
      SendDMECntrlWrd(BReceiver);
    END;
  END SetCPFlags;

BEGIN
  lastCPFlags := BITSET {};
  lastDMEfrqBits[AReceiver] := BITSET {};
  lastDMEfrqBits[BReceiver] := BITSET {};
  OUTBYTE(PortCont, Mode);
  VORfreqCRT[0] := 10810;
  GSfreqCRT[0] := (33470 - 32800) * 6 DIV 10;
  VORfreqCRT[1] := 10815;
  GSfreqCRT[1] := (33455 - 32800) * 6 DIV 10;
  VORfreqCRT[2] := 10830;
  GSfreqCRT[2] := (33410 - 32800) * 6 DIV 10;
  VORfreqCRT[3] := 10835;
  GSfreqCRT[3] := (33395 - 32800) * 6 DIV 10;
  VORfreqCRT[4] := 10850;
  GSfreqCRT[4] := (32990 - 32800) * 6 DIV 10;
  VORfreqCRT[5] := 10855;
  GSfreqCRT[5] := (32975 - 32800) * 6 DIV 10;
  VORfreqCRT[6] := 10870;
  GSfreqCRT[6] := (33050 - 32800) * 6 DIV 10;
  VORfreqCRT[7] := 10875;
  GSfreqCRT[7] := (33035 - 32800) * 6 DIV 10;
  VORfreqCRT[8] := 10890;
  GSfreqCRT[8] := (32930 - 32800) * 6 DIV 10;
  VORfreqCRT[9] := 10895;
  GSfreqCRT[9] := (32915 - 32800) * 6 DIV 10;
  VORfreqCRT[10] := 10910;
  GSfreqCRT[10] := (33140 - 32800) * 6 DIV 10;
  VORfreqCRT[11] := 10915;
  GSfreqCRT[11] := (33125 - 32800) * 6 DIV 10;
  VORfreqCRT[12] := 10930;
  GSfreqCRT[12] := (33200 - 32800) * 6 DIV 10;
  VORfreqCRT[13] := 10935;
  GSfreqCRT[13] := (33185 - 32800) * 6 DIV 10;
  VORfreqCRT[14] := 10950;
  GSfreqCRT[14] := (33260 - 32800) * 6 DIV 10;
  VORfreqCRT[15] := 10955;
  GSfreqCRT[15] := (33245 - 32800) * 6 DIV 10;
  VORfreqCRT[16] := 10970;
  GSfreqCRT[16] := (33320 - 32800) * 6 DIV 10;
  VORfreqCRT[17] := 10975;
  GSfreqCRT[17] := (33305 - 32800) * 6 DIV 10;
  VORfreqCRT[18] := 10990;
  GSfreqCRT[18] := (33380 - 32800) * 6 DIV 10;
  VORfreqCRT[19] := 10995;
  GSfreqCRT[19] := (33365 - 32800) * 6 DIV 10;
  VORfreqCRT[20] := 11010;
  GSfreqCRT[20] := (33440 - 32800) * 6 DIV 10;
  VORfreqCRT[21] := 11015;
  GSfreqCRT[21] := (33425 - 32800) * 6 DIV 10;
  VORfreqCRT[22] := 11030;
  GSfreqCRT[22] := (33500 - 32800) * 6 DIV 10;
  VORfreqCRT[23] := 11035;
  GSfreqCRT[23] := (33485 - 32800) * 6 DIV 10;
  VORfreqCRT[24] := 11050;
  GSfreqCRT[24] := (32960 - 32800) * 6 DIV 10;
  VORfreqCRT[25] := 11055;
  GSfreqCRT[25] := (32945 - 32800) * 6 DIV 10;
  VORfreqCRT[26] := 11070;
  GSfreqCRT[26] := (33020 - 32800) * 6 DIV 10;
  VORfreqCRT[27] := 11075;
  GSfreqCRT[27] := (33005 - 32800) * 6 DIV 10;
  VORfreqCRT[28] := 11090;
  GSfreqCRT[28] := (33080 - 32800) * 6 DIV 10;
  VORfreqCRT[29] := 11095;
  GSfreqCRT[29] := (33065 - 32800) * 6 DIV 10;
  VORfreqCRT[30] := 11110;
  GSfreqCRT[30] := (33170 - 32800) * 6 DIV 10;
  VORfreqCRT[31] := 11115;
  GSfreqCRT[31] := (33155 - 32800) * 6 DIV 10;
  VORfreqCRT[32] := 11130;
  GSfreqCRT[32] := (33230 - 32800) * 6 DIV 10;
  VORfreqCRT[33] := 11135;
  GSfreqCRT[33] := (33215 - 32800) * 6 DIV 10;
  VORfreqCRT[34] := 11150;
  GSfreqCRT[34] := (33290 - 32800) * 6 DIV 10;
  VORfreqCRT[35] := 11155;
  GSfreqCRT[35] := (33275 - 32800) * 6 DIV 10;
  VORfreqCRT[36] := 11170;
  GSfreqCRT[36] := (33350 - 32800) * 6 DIV 10;
  VORfreqCRT[37] := 11175;
  GSfreqCRT[37] := (33335 - 32800) * 6 DIV 10;
  VORfreqCRT[38] := 11190;
  GSfreqCRT[38] := (33110 - 32800) * 6 DIV 10;
  VORfreqCRT[39] := 11195;
  GSfreqCRT[39] := (33095 - 32800) * 6 DIV 10;
END Tune.
