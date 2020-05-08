(*.F- *)
(**********************************************************************
|  Title   : Hardware platform for flight inspection system
|  Author  : Mariusz Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    Rel 001 31.12.95: new
|    06-02-97: M.Postol
|      DGHInterface zwraca SigNilVal, gdy we analogowe jest poza zakresem,
|      do tej pory byl blad komunikacji
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 86 58 12, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE Hrdw_plt;

  FROM MathLib0 IMPORT
    real;

  FROM DGHIni IMPORT
    SignalNames;

  FROM NAVInterface IMPORT
    GetLocDev, GetGSDev, GetOmnibearing;

  FROM DGHInterface IMPORT
    DtaSignType, GetAnalogVal, GetCurrDataSign, GetBinaryVal;

  FROM Int_DME IMPORT
    DMEConvert;

  FROM Kalibracja IMPORT
    Lookup, OmnibearingV, InputSignal;

  FROM CommonTypes IMPORT
    (* CONST *) SigNilVal;

  PROCEDURE VOR_AGC_pc
            ( VAR val     : REAL;
              VAR val_cal : REAL;
              VAR dtaSign : DtaSignType;
                  channel : CommCh      ) : BOOLEAN;

  VAR
    lastVal : INTEGER;
    ok      : BOOLEAN;

  BEGIN
    IF channel = 0
    THEN
      IF NOT GetAnalogVal( AGCforNAVa, lastVal, dtaSign )
      THEN
        RETURN FALSE;
      END (* if *);
    ELSE
      IF NOT GetAnalogVal( AGCforNAVb, lastVal, dtaSign )
      THEN
        RETURN FALSE;
      END (* if *);
    END (* if channel *);
    IF lastVal = SigNilVal  THEN
      RETURN FALSE;
    END;
    val := real( lastVal );
    val_cal := Lookup( val, VorAgc, channel, ok );
    RETURN TRUE;
  END VOR_AGC_pc;

  PROCEDURE VOR_VAR_pc
            ( VAR val     : REAL;
              VAR val_cal : REAL;
              VAR dtaSign : DtaSignType;
                  channel : CommCh      ) : BOOLEAN;

  VAR
    lastVal : INTEGER;
    ok      : BOOLEAN;

  BEGIN
    IF channel = 0
    THEN
      IF NOT GetAnalogVal( VARa, lastVal, dtaSign )
      THEN
        RETURN FALSE;
      END (* if *);
    ELSE
      IF NOT GetAnalogVal( VARb, lastVal, dtaSign )
      THEN
        RETURN FALSE;
      END (* if *);
    END (* if channel *);
    IF lastVal = SigNilVal  THEN
      RETURN FALSE;
    END;
    val := real( lastVal );
    val_cal := Lookup( val, VorVarPrcMod, channel, ok );
    RETURN TRUE;
  END VOR_VAR_pc;

  PROCEDURE VOR_REF_pc
            ( VAR val     : REAL;
              VAR val_cal : REAL;
              VAR dtaSign : DtaSignType;
                  channel : CommCh      ) : BOOLEAN;

  VAR
    lastVal : INTEGER;
    ok      : BOOLEAN;

  BEGIN
    IF channel = 0
    THEN
      IF NOT GetAnalogVal( REFa, lastVal, dtaSign )
      THEN
        RETURN FALSE;
      END (* if *);
    ELSE
      IF NOT GetAnalogVal( REFb, lastVal, dtaSign )
      THEN
        RETURN FALSE;
      END (* if *);
    END (* if channel *);
    IF lastVal = SigNilVal  THEN
      RETURN FALSE;
    END;
    val := real( lastVal );
    val_cal := Lookup( val, VorRefPrcMod, channel, ok );
    RETURN TRUE;
  END VOR_REF_pc;

  PROCEDURE VOR_SUBCAR_pc
            ( VAR val     : REAL;
              VAR val_cal : REAL;
              VAR dtaSign : DtaSignType;
                  channel : CommCh      ) : BOOLEAN;

  VAR
    lastVal : INTEGER;
    ok      : BOOLEAN;

  BEGIN
    IF channel = 0
    THEN
      IF NOT GetAnalogVal( SUBCARa, lastVal, dtaSign )
      THEN
        RETURN FALSE;
      END (* if *);
    ELSE
      IF NOT GetAnalogVal( SUBCARb, lastVal, dtaSign )
      THEN
        RETURN FALSE;
      END (* if *);
    END (* if channel *);
    IF lastVal = SigNilVal  THEN
      RETURN FALSE;
    END;
    val := real( lastVal );
    val_cal := Lookup( val, SubcarPrcMod, channel, ok );
    RETURN TRUE;
  END VOR_SUBCAR_pc;

  PROCEDURE VOR_OMNIBERI_pc
            ( VAR val     : REAL;
              VAR val_cal : REAL;
              VAR dtaSign : DtaSignType;
                  channel : CommCh      ) : BOOLEAN;

  VAR
    lastVal : INTEGER;
    ok      : BOOLEAN;

  BEGIN
    IF NOT GetOmnibearing( channel + 1, lastVal )
    THEN
      RETURN FALSE;
    END (* if *);
    dtaSign := GetCurrDataSign( );
    val := real( lastVal ) / 100.0;
    IF val < 0.0    THEN
      val := val  +360.0
    END;
    val_cal := real( OmnibearingV( lastVal, channel, ok ) ) / 100.0;
    IF val_cal < 0.0  THEN
      val_cal := val_cal +360.0
    END;
    RETURN TRUE;
  END VOR_OMNIBERI_pc;

  PROCEDURE LOC_DEV_pc
            ( VAR val     : REAL;
              VAR val_cal : REAL;
              VAR dtaSign : DtaSignType;
                  channel : CommCh      ) : BOOLEAN;

  VAR
    lastVal : INTEGER;
    ok      : BOOLEAN;

  BEGIN
    IF NOT GetLocDev( channel + 1, lastVal )
    THEN
      RETURN FALSE;
    END (* if *);
    dtaSign := GetCurrDataSign( );
    val := real( lastVal );
    val_cal := Lookup( val, LocDev, channel, ok );
    RETURN TRUE;
  END LOC_DEV_pc;

  PROCEDURE GS_DEV_pc
            ( VAR val     : REAL;
              VAR val_cal : REAL;
              VAR dtaSign : DtaSignType;
                  channel : CommCh      ) : BOOLEAN;

  VAR
    lastVal : INTEGER;
    ok      : BOOLEAN;

  BEGIN
    IF NOT GetGSDev( ORD( channel ) + 1, lastVal )
    THEN
      RETURN FALSE;
    END (* if *);
    dtaSign := GetCurrDataSign( );
    val := real( lastVal );
    val_cal := Lookup( val, GsDev, channel, ok );
    RETURN TRUE;
  END GS_DEV_pc;

  PROCEDURE LOC_MOD_pc
            ( VAR val     : REAL;
              VAR val_cal : REAL;
              VAR dtaSign : DtaSignType;
                  channel : CommCh      ) : BOOLEAN;

  VAR
    lastVal : INTEGER;
    ok      : BOOLEAN;

  BEGIN (* LOC_MOD_pc *)
    IF channel = 0
    THEN
      IF NOT GetAnalogVal( MODforLOCa, lastVal, dtaSign )
      THEN
        RETURN FALSE;
      END (* if *);
    ELSE
      IF NOT GetAnalogVal( MODforLOCb, lastVal, dtaSign )
      THEN
        RETURN FALSE;
      END (* if *);
    END (* if channel *);
    IF lastVal = SigNilVal  THEN
      RETURN FALSE;
    END;
    val := real( lastVal );
    val_cal := Lookup( val, LocPrcMod, channel, ok );
    RETURN TRUE;
  END LOC_MOD_pc;

  PROCEDURE LOC_AGC_pc
            ( VAR val     : REAL;
              VAR val_cal : REAL;
              VAR dtaSign : DtaSignType;
                  channel : CommCh      ) : BOOLEAN;

  VAR
    lastVal : INTEGER;
    ok      : BOOLEAN;

  BEGIN
    IF channel = 0
    THEN
      IF NOT GetAnalogVal( AGCforNAVa, lastVal, dtaSign )
      THEN
        RETURN FALSE;
      END (* if *);
    ELSE
      IF NOT GetAnalogVal( AGCforNAVb, lastVal, dtaSign )
      THEN
        RETURN FALSE;
      END (* if *);
    END (* if channel *);
    IF lastVal = SigNilVal  THEN
      RETURN FALSE;
    END;
    val := real( lastVal );
    val_cal := Lookup( val, VorAgc, channel, ok );
    RETURN TRUE;
  END LOC_AGC_pc;

  PROCEDURE MKR_AGC_pc
            ( VAR val     : REAL;
              VAR val_cal : REAL;
              VAR dtaSign : DtaSignType;
                  channel : CommCh      ) : BOOLEAN;

  VAR
    lastVal : INTEGER;
    ok      : BOOLEAN;

  BEGIN
    IF channel = 0
    THEN
      IF NOT GetAnalogVal( AGCforMKRa, lastVal, dtaSign )
      THEN
        RETURN FALSE;
      END (* if *);
    ELSE
      IF NOT GetAnalogVal( AGCforMKRb, lastVal, dtaSign )
      THEN
        RETURN FALSE;
      END (* if *);
    END (* if channel *);
    IF lastVal = SigNilVal  THEN
      RETURN FALSE;
    END;
    val := real( lastVal );
    val_cal := Lookup( val, MkrAgc, channel, ok );
    RETURN TRUE;
  END MKR_AGC_pc;

  PROCEDURE GS_MOD_pc
            ( VAR val     : REAL;
              VAR val_cal : REAL;
              VAR dtaSign : DtaSignType;
                  channel : CommCh      ) : BOOLEAN;

  VAR
    lastVal : INTEGER;
    ok      : BOOLEAN;

  BEGIN
    IF channel = 0
    THEN
      IF NOT GetAnalogVal( MODforGSa, lastVal, dtaSign )
      THEN
        RETURN FALSE;
      END (* if *);
    ELSE
      IF NOT GetAnalogVal( MODforGSb, lastVal, dtaSign )
      THEN
        RETURN FALSE;
      END (* if *);
    END (* if channel *);
    IF lastVal = SigNilVal  THEN
      RETURN FALSE;
    END;
    val := real( lastVal );
    val_cal := Lookup( val, GsPrcMod, channel, ok );
    RETURN TRUE;
  END GS_MOD_pc;

  PROCEDURE GS_AGC_pc
            ( VAR val     : REAL;
              VAR val_cal : REAL;
              VAR dtaSign : DtaSignType;
                  channel : CommCh      ) : BOOLEAN;

  VAR
    lastVal : INTEGER;
    ok      : BOOLEAN;

  BEGIN
    IF channel = 0
    THEN
      IF NOT GetAnalogVal( AGCforGSa, lastVal, dtaSign )
      THEN
        RETURN FALSE;
      END (* if *);
    ELSE
      IF NOT GetAnalogVal( AGCforGSb, lastVal, dtaSign )
      THEN
        RETURN FALSE;
      END (* if *);
    END (* if channel *);
    IF lastVal = SigNilVal  THEN
      RETURN FALSE;
    END;
    val := real( lastVal );
    val_cal := Lookup( val, GsAgc, channel, ok );
    RETURN TRUE;
  END GS_AGC_pc;

  PROCEDURE DME_AGC_pc
            ( VAR val     : REAL;
              VAR val_cal : REAL;
              VAR dtaSign : DtaSignType;
                  channel : CommCh      ) : BOOLEAN;

  VAR
    lastVal : INTEGER;
    ok      : BOOLEAN;

  BEGIN
    IF channel = 0
    THEN
      IF NOT GetAnalogVal( AGCforDMEa, lastVal, dtaSign )
      THEN
        RETURN FALSE;
      END (* if *);
    ELSE
      IF NOT GetAnalogVal( AGCforDMEb, lastVal, dtaSign )
      THEN
        RETURN FALSE;
      END (* if *);
    END (* if channel *);
    IF lastVal = SigNilVal  THEN
      RETURN FALSE;
    END;
    val := real( lastVal );
    val_cal := Lookup( val, DmeAgc, channel, ok );
    RETURN TRUE;
  END DME_AGC_pc;

  PROCEDURE DME_Distance_pc
            ( VAR val     : REAL;
              VAR val_cal : REAL;
              VAR dtaSign : DtaSignType;
                  channel : CommCh      ) : BOOLEAN;

  VAR
    lastVal : INTEGER;
    ok      : BOOLEAN;
    address :SignalNames ;
      distanceBS : BITSET;
 
  BEGIN (* DME_Distance_pc *)
    IF channel = 0  THEN
      address := DMEDistanceA;
    ELSE
      address := DMEDistanceB;
    END;
    IF GetBinaryVal(address,
                    distanceBS,
                    dtaSign)
    THEN
      lastVal := DMEConvert(distanceBS);
    ELSE
      lastVal := MIN(INTEGER);
      RETURN FALSE;
    END (* if GetAnalogVal *);
    val := real( lastVal )/100.0;
    IF val > 199.0  THEN
      val := 199.0
    ELSIF val < 0.0 THEN
      val := 0.0;
    END;
    val_cal := val;
    RETURN TRUE;
  END DME_Distance_pc;

  PROCEDURE DME_SQUITTER_pc
            ( VAR val     : REAL;
              VAR val_cal : REAL;
              VAR dtaSign : DtaSignType;
                  channel : CommCh      ) : BOOLEAN;

  VAR
    lastVal : INTEGER;
    ok      : BOOLEAN;

  BEGIN
    IF channel = 0
    THEN
      IF NOT GetAnalogVal( SQUITTERforDMEa, lastVal, dtaSign )
      THEN
        RETURN FALSE;
      END (* if *);
    ELSE
      IF NOT GetAnalogVal( SQUITTERforDMEb, lastVal, dtaSign )
      THEN
        RETURN FALSE;
      END (* if *);
    END (* if channel *);
    IF lastVal = SigNilVal  THEN
      RETURN FALSE;
    END;
    val := real( lastVal );
    val_cal := Lookup( val, DmeSquitter, channel, ok );
    RETURN TRUE;
  END DME_SQUITTER_pc;

  PROCEDURE DME_RPL_pc
            ( VAR val     : REAL;
              VAR val_cal : REAL;
              VAR dtaSign : DtaSignType;
                   channel : CommCh      ) : BOOLEAN;

  VAR
    lastVal : INTEGER;
    ok      : BOOLEAN;

  BEGIN
    IF channel = 0
    THEN
      IF NOT GetAnalogVal( REPLYforDMEa, lastVal, dtaSign )
      THEN
        RETURN FALSE;
      END (* if *);
    ELSE
      IF NOT GetAnalogVal( REPLYforDMEb, lastVal, dtaSign )
      THEN
        RETURN FALSE;
      END (* if *);
    END (* if channel *);
    IF lastVal = SigNilVal  THEN
      RETURN FALSE;
    END;
    val := real( lastVal );
    val_cal := Lookup( val, DmePrcReply, channel, ok );
    RETURN TRUE;
  END DME_RPL_pc;

  PROCEDURE ADF_AGC_pc
            ( VAR val     : REAL;
              VAR val_cal : REAL;
              VAR dtaSign : DtaSignType;
                  channel : CommCh      ) : BOOLEAN;

  VAR
    lastVal : INTEGER;
    ok      : BOOLEAN;

  BEGIN
    IF channel = 0
    THEN
      IF NOT GetAnalogVal( AGCforADFa, lastVal, dtaSign )
      THEN
        RETURN FALSE;
      END (* if *);
    ELSE
      IF NOT GetAnalogVal( AGCforADFb, lastVal, dtaSign )
      THEN
        RETURN FALSE;
      END (* if *);
    END (* if channel *);
    IF lastVal = SigNilVal  THEN
      RETURN FALSE;
    END;
    val := real( lastVal );
    val_cal := Lookup( val, AdfAgc, channel, ok );
    RETURN TRUE;
  END ADF_AGC_pc;

  PROCEDURE ADF_SIN_pc
            ( VAR val     : REAL;
              VAR val_cal : REAL;
              VAR dtaSign : DtaSignType;
                  channel : CommCh      ) : BOOLEAN;

  VAR
    lastVal : INTEGER;

  BEGIN
    IF channel = 0
    THEN
      IF NOT GetAnalogVal( SINforADFa, lastVal, dtaSign )
      THEN
        RETURN FALSE;
      END (* if *);
    ELSE
      IF NOT GetAnalogVal( SINforADFb, lastVal, dtaSign )
      THEN
        RETURN FALSE;
      END (* if *);
    END (* if channel *);
    IF lastVal = SigNilVal  THEN
      RETURN FALSE;
    END;
    val := real( lastVal );
    val_cal := val;
    RETURN TRUE;
  END ADF_SIN_pc;

  PROCEDURE ADF_COS_pc
            ( VAR val     : REAL;
              VAR val_cal : REAL;
              VAR dtaSign : DtaSignType;
                  channel : CommCh      ) : BOOLEAN;

  VAR
    lastVal : INTEGER;

  BEGIN
    IF channel = 0
    THEN
      IF NOT GetAnalogVal( COSforADFa, lastVal, dtaSign )
      THEN
        RETURN FALSE;
      END (* if *);
    ELSE
      IF NOT GetAnalogVal( COSforADFb, lastVal, dtaSign )
      THEN
        RETURN FALSE;
      END (* if *);
    END (* if channel *);
    IF lastVal = SigNilVal  THEN
      RETURN FALSE;
    END;
    val := real( lastVal );
    val_cal := val;
    RETURN TRUE;
  END ADF_COS_pc;

  PROCEDURE VHF_AGC_pc
            ( VAR val     : REAL;
              VAR val_cal : REAL;
              VAR dtaSign : DtaSignType;
                  channel : CommCh      ) : BOOLEAN;

  VAR
    lastVal : INTEGER;
    ok      : BOOLEAN;

  BEGIN
    IF NOT GetAnalogVal( AGCforCOMa, lastVal, dtaSign )
    THEN
      RETURN FALSE;
    END (* if *);
    IF lastVal = SigNilVal  THEN
      RETURN FALSE;
    END;
    val := real( lastVal );
    val_cal := Lookup( val, VhfAgc, channel, ok );
    RETURN TRUE;
  END VHF_AGC_pc;

END Hrdw_plt.
