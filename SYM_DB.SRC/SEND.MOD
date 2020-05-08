(*# define(OneComputerVersion=>on)*)
IMPLEMENTATION MODULE Send;

FROM Views IMPORT
  PPalette, TViewState, TViewStates;
FROM StaticTexts IMPORT
  PStaticText, TStaticText;
FROM FlightCommon IMPORT
  EnableTimer;
FROM Storage IMPORT
  ALLOCATE;
FROM MATHLIB IMPORT
  Sin, Cos, ATan2, M_PiBy2, M_Pi;
FROM GenericTypes IMPORT
  DeviceType, DeviceTypeSet;
FROM Geo2Polar IMPORT
  PolozenieKatowe;



IMPORT
  CommTypes, Objects, Drivers, Str, Data, Geo2Polar, DMEWrite;
(*%T OneComputerVersion *)
IMPORT
  Przetworniki;
(*%E*)
(*%F OneComputerVersion *)
IMPORT
  rs;
(*%E*)


(*%T Use_Hardware*)
FROM ArincService IMPORT
  WriteOmnibearing, WriteLOC, WriteGS, ARINCOwner;
FROM LocCommands IMPORT
  cmdARINC;
(*%E*)






CONST
  TRACK   = TRUE;
  MEMORY  = FALSE;



CONST
  COMM_PORT    = 2;
  HOW_OFTEN    = 3;
  WAITTICKS    = 100; (* ok. 5 sec *)

VAR
  Ticks    : CARDINAL;
  CommType : CommTypes.PacketType;
  Pakiet   : CommTypes.PacketData;
  Licznik  : CARDINAL;
  LotTrwa  : BOOLEAN;

CLASS Alarm (TStaticText);
(*%T Use_Hardware*)
  ARINC_nawalil : BOOLEAN;
(*%E*)
  PROCEDURE Init(VAR Bounds: Objects.TRect;
                     AText: ARRAY OF CHAR);
  VIRTUAL PROCEDURE GetPalette(): PPalette;
  VIRTUAL PROCEDURE HandleEvent( VAR e : Drivers.TEvent );
  VIRTUAL PROCEDURE Done;
END Alarm;

TYPE
  PAlarm = POINTER TO Alarm;


PROCEDURE SendPacket( pck : CommTypes.PacketType ); FORWARD;

CLASS IMPLEMENTATION Alarm ;

  PROCEDURE Init(VAR Bounds: Objects.TRect;
                     AText: ARRAY OF CHAR);
  BEGIN
    TStaticText.Init( Bounds, AText );
    EXCL( State, sfVisible );
(*%T Use_Hardware*)
    ARINC_nawalil := FALSE;
(*%E*)
    EnableTimer( ADR( SELF ), TRUE );
(*%F OneComputerVersion *)
    rs.Install( COMM_PORT );
    rs.Init( CommTypes.BAUD_RATE,
             CommTypes.WORD_LENGTH,
             CommTypes.PARITY,
             CommTypes.ONE_BIT_STOP,
             CommTypes.HANDSHAKE );
    SendPacket( CommTypes.ptIdle );
    SendPacket( CommTypes.ptIdle );
(*    rs.Break( WAIT_MSEC ); *)
(*%E*)
  END Init;


  VIRTUAL PROCEDURE GetPalette(): PPalette;
  BEGIN
    RETURN ADR(1C+0C);
  END GetPalette;

  VIRTUAL PROCEDURE HandleEvent( VAR e : Drivers.TEvent );
  BEGIN
(*%T Use_Hardware*)
    IF Drivers.evCommand IN e.What THEN
      IF e.Command = cmdARINC THEN
        ARINC_nawalil := e.InfoByte = 0;
        SetState( TViewStates{ sfVisible }, ARINC_nawalil );
      END;
    END;
(*%E*)
    IF Drivers.evTimer IN e.What THEN
(*%F OneComputerVersion *)
      IF rs.TxCount() # 0 THEN (* nie ma lacznosci *)
(*%E*)
(*%T OneComputerVersion *)
      IF FALSE THEN
(*%E*)
        IF Licznik > WAITTICKS THEN
          INCL( State, sfVisible );
          Licznik := 0;
        ELSE
          INC( Licznik );
        END;
      ELSE (* jest lacznosc *)
        Licznik := 0;
        EXCL( State, sfVisible );
        INC( Ticks, e.TicksPending );
        IF Ticks >= HOW_OFTEN THEN
          SendPacket( CommType );
          Ticks := Ticks MOD HOW_OFTEN;
        END;
      END;
    END;
  END HandleEvent;

  VIRTUAL PROCEDURE Done;
  BEGIN
    EnableTimer( ADR( SELF ),FALSE );
    SetType( CommTypes.ptStop );
    TStaticText.Done;
  END Done;

BEGIN
  ARINCOwner := ADR( SELF );
END Alarm;


VAR
  alarm    : PAlarm;





PROCEDURE SetType( pt : CommTypes.PacketType );
BEGIN
  IF pt = CommTypes.ptStop THEN
    SendPacket( CommTypes.ptStop );
    CommType := CommTypes.ptIdle;
  ELSE
    SendPacket( CommTypes.ptStart );
    CommType := pt;
  END;
END SetType;

PROCEDURE Insert( p : PGroup );
CONST
  AlarmText = "Brak komunikacji";
VAR
  Bounds : Objects.TRect;
BEGIN
  Bounds.Assign( 80-Str.Length(AlarmText), 0, 80, 1 );
  NEW( alarm );
  alarm^.Init( Bounds, AlarmText );
  p^.Insert( alarm );
END Insert;


PROCEDURE Delete;
BEGIN
  SendPacket( CommTypes.ptIdle );
END Delete;

PROCEDURE SetILSBin( VAR Bin : CommTypes.ILSBinType );
BEGIN
  Bin := CommTypes.ILSBinType{};
  IF Data.mInner IN Data.CurMarkers THEN
    INCL( Bin, CommTypes.MkrIn );
  END;
  IF Data.mMiddle IN Data.CurMarkers THEN
    INCL( Bin, CommTypes.MkrMid );
  END;
  IF Data.mOuter IN Data.CurMarkers THEN
    INCL( Bin, CommTypes.MkrOut );
  END;
  IF Data.AGC_GS_Akt < 7.5 THEN
    INCL( Bin, CommTypes.GsSflg );
  END;
  IF Data.AGC_VOR_LOC_Akt < 7.5 THEN
    INCL( Bin, CommTypes.NavSflg );
  END;
  IF GPS_On IN Data.Devices THEN
    INCL( Bin, CommTypes.Gps );
  END;
  IF Theodolit_On IN Data.Devices THEN
    INCL( Bin, CommTypes.Theodolit );
  END;
END SetILSBin;


PROCEDURE Bit12( r : LONGREAL ) : CARDINAL;
(* konwersja liczby 0..10 na 12 bitowy przetwornik *)
VAR
  c : CARDINAL;
BEGIN
  IF r < 0.0 THEN
    r := 0.0;
  END;
  c := TRUNC( r*409.60 );
  IF c > 0FFFH THEN
    c := 0FFFH;
  END;
  RETURN c;
END Bit12;

PROCEDURE Bit12Int( r : LONGREAL ) : CARDINAL;
(* konwersja liczby -5..+5 na 12 bitowy przetwornik *)
BEGIN
  RETURN Bit12( r+5.0 );
END Bit12Int;

PROCEDURE Isol( r : LONGREAL ) : SHORTCARD;
(* Wycina cyfre jednosci *)
VAR
  c : SHORTCARD;
BEGIN
  r := r - LONGREAL(TRUNC(r));
  c := SHORTCARD( r );
  RETURN c ;
END Isol;

PROCEDURE Mod360( r : LONGREAL ) : LONGREAL;
BEGIN
  WHILE r < 0.0 DO
    r := r+360.0;
  END;
  WHILE r >= 360.0 DO
    r := r - 360.0;
  END;
  RETURN r;
END Mod360;

PROCEDURE SendPacket( pck : CommTypes.PacketType );
VAR
  od : LONGREAL;
  pk : PolozenieKatowe;
BEGIN
  IF LotTrwa THEN
    Pakiet.Packet := pck;
  ELSE
    Pakiet.Packet := CommTypes.ptIdle;
  END;

  Data.AktualnePol.Pol2D.Kat := Mod360( Data.AktualnePol.Pol2D.Kat );

  CASE Pakiet.Packet OF
  | CommTypes.ptIdle,
    CommTypes.ptStart,
    CommTypes.ptStop:     (* nic *)
  | CommTypes.ptVORRadial,
    CommTypes.ptVOROrbit:
      WITH Pakiet.VorRec DO
(*  W przypadku gdy wysylwny jest blad
        Omnibearing := Bit12( Data.Omnibearing/36.0 ); (* kat dokola swiata na przedzial 0..10 *)
*)
(*%F Use_Hardware*)
        Omnibearing := Bit12( Mod360(Data.Omnibearing+Data.AktualnePol.Pol2D.Kat)/36.0 ); (* kat dokola swiata na przedzial 0..10 *)
(*%E*)
(*%T Use_Hardware*)
        WriteOmnibearing( Mod360(Data.Omnibearing+Data.AktualnePol.Pol2D.Kat) );
(*%E*)
        SetILSBin( Bin ); (* Wystawiamy NAV.SFLG *)
        Var := Bit12( Data.Var );
        Ref := Bit12( Data.Ref );
        Agc := Bit12( Data.AGC_VOR_LOC_Akt );
        Subcar := Bit12( Data.Subcar );
      END;
  | CommTypes.ptGSPath,
    CommTypes.ptGSAngle:
      WITH Pakiet.GsRec DO
        SetILSBin( Bin );
(*%T Use_Hardware*)
        WriteGS( Data.DevGS_Akt );
(*%E*)
(*%F Use_Hardware*)
        DevGS := Bit12Int( Data.DevGS_Akt/80.0 );
(*%E*)
        AgcGS := Bit12( Data.AGC_GS_Akt );
        _150  := Bit12( 5.0+Data.DevGS_Akt/80.0/2.0 );
        _90   := Bit12( 5.0-Data.DevGS_Akt/80.0/2.0 );
        IF Data.CurMarkers # Data.MarkerSet{} THEN
          AgcMkr := Bit12( Data.AGC_Mark_Akt );
        ELSE
          AgcMkr := Bit12( 10.0 );
        END;
        ModLoc := Bit12( Data.MOD_LOC_Akt  );
      END;
  | CommTypes.ptLOCPath,
    CommTypes.ptLOCAngle:
      WITH Pakiet.LocRec DO
        SetILSBin( Bin );
(*%T Use_Hardware*)
        WriteLOC( Data.DevLOC_Akt );
(*%E*)
(*%F Use_Hardware*)
        DevLoc := Bit12Int( Data.DevLOC_Akt/80.0 );
(*%E*)
        AgcLoc := Bit12( Data.AGC_VOR_LOC_Akt );
        _150  := Bit12( 5.0+Data.DevLOC_Akt/80.0/2.0 );
        _90   := Bit12( 5.0-Data.DevLOC_Akt/80.0/2.0 );
        IF Data.CurMarkers # Data.MarkerSet{} THEN
          AgcMkr := Bit12( Data.AGC_Mark_Akt );
        ELSE
          AgcMkr := Bit12( 10.0 );
        END;
        ModLoc := Bit12( Data.MOD_LOC_Akt  );
      END;
  | CommTypes.ptDME:
      WITH Pakiet.DmeRec DO
        Agc := Bit12( Data.AGC_DME_Akt );
        Squitter := Bit12( Data.Squitter_Akt );
        Replay := Bit12( Data.Replay_Akt );
        od := Data.AktualnePol.Pol2D.Odleglosc;

        (* 0-7 *)
        DME[0] :=       Isol( od*100.0 );     (* setne cz. mili *)
        (* 8-15 *)
        DME[1] := Isol( od/10.0 ) << 4+ (* dziesiatki mil *)
                  Isol( od );           (* mile *)
        (* 16-23 *)
        DME[2] :=  Isol( ABS(Data.LatKatowy.Predkosc) ) << 4+ (* PREDKOSC NIE WZGLEDEM DME tylko wzgledem rurki pitota *)
                   ORD(TRACK) << 3+
                   ORD(MEMORY) << 2+
                   Isol( od/100.0 );
        (* 24-31*)
        DME[3] := Isol( ABS(Data.LatKatowy.Predkosc)/100.0 ) << 4+
                  Isol( ABS(Data.LatKatowy.Predkosc)/10.0 );
        (* 32-39*)
        od := od/ABS(Data.LatKatowy.Predkosc); (* czas dolotu w h *)
        od := od*60.0;                    (* czas dolotu w min *)
        DME[4] := Isol( od/10.0)<< 4+ (* dziesiatki inut *)
                  Isol( od )          (* minuty *);

      END;
  | CommTypes.ptADF, CommTypes.ptComm:
      WITH Pakiet.AdfRec DO
        AdfAgc := Bit12( Data.AGC_ADF_Akt );
        CommAgc := Bit12( Data.AGC_Comm_Akt );
        od := Mod360( Data.AktualnePol.Pol2D.Kat -Pakiet.Dir+ Data.DevADF_Akt+180.0) ;
        AdfSin := Bit12Int( Sin( od *M_Pi/180.0 )*10.0 );
        AdfCos := Bit12Int( Cos( od *M_Pi/180.0)*10.0 );
      END
  END;
  Data.WidokZTeodolitu.Azymut := Mod360( Data.WidokZTeodolitu.Azymut );
  Pakiet.ub.Odleglosc := Bit12( Data.AktualnePol.Pol2D.Odleglosc / 6.0 ); (* Maksimum 60 mil *)
  Pakiet.ub.Azymut := Bit12( Data.WidokZTeodolitu.Azymut / 36.0 );
  Pakiet.ub.Elewacja := Bit12( Data.WidokZTeodolitu.Elewacja / 9.0 );
  Pakiet.ub.AzymutR := Data.WidokZTeodolitu.Azymut;
  Pakiet.ub.ElewacjaR := Data.WidokZTeodolitu.Elewacja;
(*
  IF NOT (Theodolit_On IN Data.Devices) THEN
    Pakiet.ub.ElewacjaR := -Pakiet.ub.ElewacjaR;
  END;
*)
  Pakiet.TeoEvent    := Data.TeoEvent;
  Pakiet.dt := Data.Devices;
  Data.AktualnePol.Pol2D.Kat := Mod360( Data.AktualnePol.Pol2D.Kat );
  pk := Data.AktualnePol.Pol2D;
  pk.Kat := pk.Kat - Data.Deklinacja;

  IF (Pakiet.Packet = CommTypes.ptGSPath ) OR
     (Pakiet.Packet = CommTypes.ptGSAngle )
  THEN
    pk.Odleglosc := pk.Odleglosc+Data.PoczatekPasa;
  END;
  Geo2Polar.Kat2Geo( pk, Pakiet.pg );

  Pakiet.Speed := ABS(Data.LatKatowy.Predkosc);

  IF Data.PoPromieniu THEN
    Pakiet.Dir := pk.Kat + 180.0;
  ELSE
    Pakiet.Dir := pk.Kat + 90.0;
  END;

  IF NOT Data.DoVoraLubRosnaceKaty THEN
    Pakiet.Dir := Pakiet.Dir + 180.0;
  END;
  Pakiet.Dir := Mod360( Pakiet.Dir );





(*%F OneComputerVersion *)
  rs.Send( Pakiet, SIZE( Pakiet ));
(*%E*)
(*%T OneComputerVersion *)
  Przetworniki.WystawSygnaly( Pakiet );
(*%E*)
  IF Pakiet.Packet # CommTypes.ptIdle THEN
    DMEWrite.Write( Data.AktualnePol.Pol2D.Odleglosc );
  END;
END SendPacket;

PROCEDURE Leci( SamolotLeci : BOOLEAN );
BEGIN
  LotTrwa := SamolotLeci;
END Leci;

BEGIN
  alarm := NIL;
  Ticks := 0;
  CommType := CommTypes.ptIdle;
  Licznik := 0;
  Leci( FALSE );
END Send.
