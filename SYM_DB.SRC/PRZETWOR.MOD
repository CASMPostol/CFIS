IMPLEMENTATION MODULE Przetworniki;

FROM SYSTEM IMPORT
  Out;
FROM CommTypes IMPORT
  PacketType;
FROM Geo2Polar IMPORT
  PolozenieGeograficzne;
IMPORT
  GPS_Nadawanie, Teo_Nadawanie;
FROM GenericTypes IMPORT
  DeviceType, DeviceTypeSet;

CONST
  BASE         = 2C0H;
  VOR_LOC_AGC  = BASE+00H; (* kanal 0 *)
  GS_AGC       = BASE+02H; (* kanal 1 *)
  MKR_AGC      = BASE+04H; (* kanal 2 *)
  DME_AGC      = BASE+06H; (* kanal 3 *)
  ADF_AGC      = BASE+08H; (* kanal 4 *)
  ADF_SIN      = BASE+0AH; (* kanal 5 Bipolarny! *)
  ADF_COS      = BASE+0CH; (* kanal 6 Bipolarny! *)
  DME_SQUITTER = BASE+0EH; (* kanal 7 *)
  DME_REPLAY   = BASE+10H; (* kanal 8 *)
  VOR_REF      = BASE+12H; (* kanal 9 *)
  VOR_VAR      = BASE+14H; (* kanal 10 *)
  SUBCAR       = BASE+16H; (* kanal 11 *)

  _150HZ       = VOR_REF;
  _90HZ        = VOR_VAR;
  COMM_AGC     = VOR_LOC_AGC;
  OMNIBEARING  = DME_AGC;
  GS_DEV       = VOR_LOC_AGC;
  LOC_DEV      = GS_AGC;


  ILS_BIN      = BASE+18H; (* wyjscia binarne *)



INLINE PROCEDURE Out12( Port : CARDINAL; Value : CARDINAL );
BEGIN
  Out( Port, SHORTCARD( Value >> 8 ) );
  Out( Port+1, SHORTCARD( Value MOD 100H ));
END Out12;

INLINE PROCEDURE OutBin( Val : BYTE );
BEGIN
  Out( ILS_BIN+1, Val );
END OutBin;

PROCEDURE Out55( VAR a : ARRAY OF BYTE );
END Out55;

VAR
  Last : LONGCARD;
(*#save, data( volatile => on )*)
  Cur[ 040H:6CH ] : LONGCARD;
(*#restore*)

PROCEDURE OutGeo( VAR pg : PolozenieGeograficzne );
BEGIN
(*
(*#save, check(overflow=>off)*)
  IF Cur - Last < 37 THEN (* ok 2s *)
    RETURN;
  END;
  Last := Cur;
(*#restore*)
*)
  GPS_Nadawanie.SetLatitude( pg.Szerokosc );
  GPS_Nadawanie.SetLongitude( pg.Dlugosc );
  GPS_Nadawanie.Send;
END OutGeo;

PROCEDURE WystawSygnaly( VAR p : PacketData );
VAR
  i : CARDINAL;
BEGIN
  CASE p.Packet OF
  | ptIdle,
    ptStart,
    ptStop:
      FOR i := 0 TO 11 DO
        Out12( BASE+2*i, 0 );
      END;
      Out12( ADF_SIN, 2048 ); (* poziom 0 bipolarny *)
      Out12( ADF_COS, 2048 );
      OutBin( 0 );
      RETURN;
  | ptVORRadial,
    ptVOROrbit:
      WITH p.VorRec DO
        Out12( VOR_VAR, Var );
        Out12( VOR_REF, Ref );
        Out12( VOR_LOC_AGC, Agc );
        Out12( SUBCAR, Subcar );
(*%F Use_Hardware*)
        Out12( OMNIBEARING, Omnibearing );
(*%E*)
(*
        IF Theodolit_On IN p.dt THEN
          Out12( TELEMETRIA, p.ub.Azymut );
        END;
*)
      END;
  | ptGSPath,
    ptGSAngle:
      WITH p.GsRec DO
        OutBin( Bin );
(*%F Use_Hardware*)
        Out12( GS_DEV, DevGS );
(*%E*)
        Out12( GS_AGC, AgcGS );
        Out12( MKR_AGC, AgcMkr );
(*
        Out12( _150HZ, _150 );
        Out12( _90HZ, _90 );
*)
        Out12( _150HZ, ModLoc );
        Out12( _150HZ, ModLoc );
(*
        IF Theodolit_On IN p.dt THEN
          Out12( TELEMETRIA, p.ub.Elewacja );
        END;
*)
      END;
  | ptLOCPath,
    ptLOCAngle:
      WITH p.LocRec DO
        OutBin( Bin );
(*%F Use_Hardware*)
        Out12( LOC_DEV, DevLoc );
(*%E*)
        Out12( VOR_LOC_AGC, AgcLoc );
        Out12( MKR_AGC, AgcMkr );
(*
        Out12( _150HZ, _150 );
        Out12( _90HZ, _90 );
*)
        Out12( _150HZ, ModLoc );
        Out12( _90HZ, ModLoc );
(*
        IF Theodolit_On IN p.dt THEN
          Out12( TELEMETRIA, p.ub.Azymut );
        END;
*)
      END;
  | ptDME:
      WITH p.DmeRec DO
        Out12( DME_AGC, Agc );
        Out12( DME_REPLAY, Replay );
        Out12( DME_SQUITTER, Squitter );
        Out55( DME );
(*
        IF Theodolit_On IN p.dt THEN
          Out12( TELEMETRIA, p.ub.Azymut );
        END;
*)
      END;
  | ptADF, ptComm:
      WITH p.AdfRec DO
        Out12( ADF_AGC, AdfAgc );
        Out12( COMM_AGC, CommAgc );
        Out12( ADF_SIN, AdfSin );
        Out12( ADF_COS, AdfCos );
(*
        IF Theodolit_On IN p.dt THEN
          Out12( TELEMETRIA, p.ub.Azymut );
        END;
*)
      END;
  END;
(*
  Out12( DME_, p.ub.Odleglosc );
*)
  GPS_Nadawanie.SetError( NOT( GPS_On IN p.dt) );
  GPS_Nadawanie.SetDir( p.Dir );
  GPS_Nadawanie.SetHSpeed( p.Speed );
  GPS_Nadawanie.SetVSpeed( 0.0 );
  OutGeo( p.pg );
  Teo_Nadawanie.TSend( p.ub.AzymutR,
                       p.ub.ElewacjaR,
                       p.TeoEvent,
                       NOT( Theodolit_On IN p.dt ));
END WystawSygnaly;

BEGIN
  Last := 0;
END Przetworniki.
