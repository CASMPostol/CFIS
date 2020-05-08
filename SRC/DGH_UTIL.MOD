(*.F- *)
(**********************************************************************
|  Title   : DGH utilities
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    06-02-97: M.Postol
|      rozdzielilem wlaczanie LOC i GS aby zyskac na czasie cztania
|      DGHInterface zwraca SigNilVal, gdy we analogowe jest poza zakresem,
|      do tej pory byl blad komunikacji
|      wywalilem pozostalosci po komunikatach o uszkodzonych modulach
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE DGH_utils;

  FROM CommonTypes IMPORT
    (* TYPE *) GlownyOdbiornikT,
    (* CONST *) SigNilVal;

  FROM MathLib0 IMPORT
    real, entier;

  FROM DGHInterface IMPORT
    TurnOn, TurnOff, GetAnalogVal, DtaSignType, GetBinaryVal;

  FROM DGHIni IMPORT
    SignalNames;

  FROM Kalibracja IMPORT
    Lookup, OmnibearingV, InputSignal;

  FROM NAVInterface IMPORT
    GetLocDev, GetGSDev, GetOmnibearing;

  FROM Messages IMPORT
    Message, NewMessage, Display, DisposeMessage;

  FROM StdIO IMPORT
    sprintf;

  VAR
    address     : ARRAY InputSignal, GlownyOdbiornikT OF SignalNames;
    binAddress  : ARRAY BinInputSignal, GlownyOdbiornikT OF SignalNames;

  PROCEDURE TurnOffILSSig;

  BEGIN
    TurnOff(MODforLOCa);
    TurnOff(MODforLOCb);
    TurnOff(AGCforNAVa);
    TurnOff(AGCforNAVb);
    TurnOff(AGCforMKRa);
    TurnOff(AGCforMKRb);
    TurnOff(MODforGSa);
    TurnOff(MODforGSb);
    TurnOff(AGCforGSa);
    TurnOff(AGCforGSb);
    TurnOff(SFLGforNAVa);
    TurnOff(SFLGforNAVb);
    TurnOff(SFLGforGSa);
    TurnOff(SFLGforGSb);
    TurnOff(OutMKRa);
    TurnOff(OutMKRb);
    TurnOff(MidMKRa);
    TurnOff(MidMKRb);
    TurnOff(InnMKRa);
    TurnOff(InnMKRb);
    TurnOff(NAVaAudio);
    TurnOff(NAVbAudio);
    TurnOff(DMEDistanceA);
    TurnOff(DMEDistanceB);
  END TurnOffILSSig;

  PROCEDURE TurnOnLOCSig;

  BEGIN
    TurnOn(MODforLOCa);
    TurnOn(MODforLOCb);
    TurnOn(AGCforNAVa);
    TurnOn(AGCforNAVb);
    TurnOn(AGCforMKRa);
    TurnOn(AGCforMKRb);
    TurnOn(SFLGforNAVa);
    TurnOn(SFLGforNAVb);
    TurnOn(SFLGforGSa);
    TurnOn(SFLGforGSb);
    TurnOn(OutMKRa);
    TurnOn(OutMKRb);
    TurnOn(MidMKRa);
    TurnOn(MidMKRb);
    TurnOn(InnMKRa);
    TurnOn(InnMKRb);
    TurnOn(NAVaAudio);
    TurnOn(NAVbAudio);
  END TurnOnLOCSig;

  PROCEDURE TurnOnGSSig;

  BEGIN
    TurnOn(AGCforMKRa);
    TurnOn(AGCforMKRb);
    TurnOn(MODforGSa);
    TurnOn(MODforGSb);
    TurnOn(AGCforGSa);
    TurnOn(AGCforGSb);
    TurnOn(SFLGforNAVa);
    TurnOn(SFLGforNAVb);
    TurnOn(SFLGforGSa);
    TurnOn(SFLGforGSb);
    TurnOn(OutMKRa);
    TurnOn(OutMKRb);
    TurnOn(MidMKRa);
    TurnOn(MidMKRb);
    TurnOn(InnMKRa);
    TurnOn(InnMKRb);
    TurnOn(NAVaAudio);
    TurnOn(NAVbAudio);
  END TurnOnGSSig;

  PROCEDURE TurnOnVORSig;

  BEGIN
    TurnOn(AGCforNAVa);
    TurnOn(AGCforNAVb);
    TurnOn(VARa);
    TurnOn(VARb);
    TurnOn(REFa);
    TurnOn(REFb);
    TurnOn(SUBCARa);
    TurnOn(SUBCARb);
    TurnOn(SFLGforNAVa);
    TurnOn(SFLGforNAVb);
    TurnOn(NAVaAudio);
    TurnOn(NAVbAudio);
  END TurnOnVORSig;

  PROCEDURE TurnOffVORSig;

  BEGIN
    TurnOff(AGCforNAVa);
    TurnOff(AGCforNAVa);
    TurnOff(VARa);
    TurnOff(REFa);
    TurnOff(SUBCARa);
    TurnOff(VARb);
    TurnOff(REFb);
    TurnOff(SUBCARb);
    TurnOff(SFLGforNAVa);
    TurnOff(SFLGforNAVb);
    TurnOff(NAVbAudio);
    TurnOff(NAVbAudio);
  END TurnOffVORSig;

  PROCEDURE TurnOnDMESig;

  BEGIN
    TurnOn(AGCforDMEa);
    TurnOn(AGCforDMEb);
    TurnOn(SQUITTERforDMEa);
    TurnOn(SQUITTERforDMEb);
    TurnOn(REPLYforDMEa);
    TurnOn(REPLYforDMEb);
    TurnOn(DME_MEMa);
    TurnOn(DME_MEMb);
    TurnOn(DME_SRCa);
    TurnOn(DME_SRCb);
    TurnOn(DMEaAudio);
    TurnOn(DMEbAudio);
    TurnOn(DMEDistanceA);
    TurnOn(DMEDistanceB);
  END TurnOnDMESig;

  PROCEDURE TurnOffDMESig;

  BEGIN
    TurnOff(AGCforDMEa);
    TurnOff(AGCforDMEb);
    TurnOff(SQUITTERforDMEa);
    TurnOff(SQUITTERforDMEb);
    TurnOff(REPLYforDMEa);
    TurnOff(REPLYforDMEb);
    TurnOff(DME_MEMa);
    TurnOff(DME_MEMb);
    TurnOff(DME_SRCa);
    TurnOff(DME_SRCb);
    TurnOff(DMEaAudio);
    TurnOff(DMEbAudio);
    TurnOff(DMEDistanceA);
    TurnOff(DMEDistanceB);
  END TurnOffDMESig;

  PROCEDURE TurnOnADFSig;

  BEGIN
    TurnOn(AGCforADFa);
    TurnOn(SINforADFa);
    TurnOn(COSforADFa);
    TurnOn(AGCforADFb);
    TurnOn(SINforADFb);
    TurnOn(COSforADFb);
    TurnOn(ADFaAudio);
    TurnOn(ADFbAudio);
  END TurnOnADFSig;

  PROCEDURE TurnOffADFSig;

  BEGIN
    TurnOff(AGCforADFa);
    TurnOff(SINforADFa);
    TurnOff(COSforADFa);
    TurnOff(AGCforADFb);
    TurnOff(SINforADFb);
    TurnOff(COSforADFb);
    TurnOff(ADFaAudio);
    TurnOff(ADFbAudio);
  END TurnOffADFSig;

  PROCEDURE ReadValue
            ( VAR zm   : INTEGER;
                  S    : InputSignal;
                  CHN  : GlownyOdbiornikT;
                  prec : REAL             );

    PROCEDURE ReadAnalog
              (     sn  : SignalNames;
                VAR val : INTEGER     ) : BOOLEAN;
    VAR
      ds : DtaSignType;

    BEGIN
      RETURN GetAnalogVal(sn, val, ds);
    END ReadAnalog;
  VAR
    ok : BOOLEAN;

  BEGIN
    IF S = LocDev
    THEN
      IF NOT GetLocDev(ORD(CHN) + 1, zm)
      THEN
        zm := SigNilVal;
        RETURN
      END (* if *);
    ELSIF S = GsDev
    THEN
      IF NOT GetGSDev(ORD(CHN) + 1, zm)
      THEN
        zm := SigNilVal;
        RETURN
      END (* if *);
    ELSIF NOT ReadAnalog(address[S, CHN], zm)
    THEN
      zm := SigNilVal;
      RETURN
    END (* if zm *);
    IF zm = SigNilVal  THEN
      RETURN;
    END;
    zm := entier(Lookup(real(zm), S, ORD(CHN), ok) * prec);
    IF NOT ok
    THEN
      zm := SigNilVal;
    END (* if *);
  END ReadValue;

  PROCEDURE ReadOmniber
            ( VAR zm  : INTEGER;
                  rec : GlownyOdbiornikT );
  VAR
    ok : BOOLEAN;

  BEGIN
    IF NOT GetOmnibearing(ORD(rec) + 1, zm)
    THEN
      zm := SigNilVal;
    ELSE
      IF zm # SigNilVal
      THEN
        zm := OmnibearingV(zm, ORD(rec), ok);
        IF NOT ok
        THEN
          zm := SigNilVal;
        END (* if *);
      END (* if zm *);
    END (* if *);
  END ReadOmniber;

  PROCEDURE BinaryValSet
            (    sn  : BinInputSignal;
                 CHN : GlownyOdbiornikT ) : BOOLEAN;
  VAR
    ds   : DtaSignType;
    Btmp : BITSET;

  BEGIN
    IF GetBinaryVal(binAddress[sn, CHN], Btmp, ds)
    THEN
      RETURN 0 IN Btmp;
    ELSE
      RETURN FALSE;
    END (* if GetBinaryVal *);
  END BinaryValSet;

BEGIN
  address[LocAgc, goA] := AGCforNAVa;
  address[LocAgc, goB] := AGCforNAVb;
  address[LocPrcMod, goA] := MODforLOCa;
  address[LocPrcMod, goB] := MODforLOCb;
  address[LocDev, goA] := Terminator;
  address[LocDev, goB] := Terminator;
  address[MkrAgc, goA] := AGCforMKRa;
  address[MkrAgc, goB] := AGCforMKRb;
  address[GsPrcMod, goA] := MODforGSa;
  address[GsPrcMod, goB] := MODforGSb;
  address[GsDev, goA] := Terminator;
  address[GsDev, goB] := Terminator;
  address[GsAgc, goA] := AGCforGSa;
  address[GsAgc, goB] := AGCforGSb;
  address[VorRefPrcMod, goA] := REFa;
  address[VorRefPrcMod, goB] := REFb;
  address[VorVarPrcMod, goA] := VARa;
  address[VorVarPrcMod, goB] := VARb;
  address[SubcarPrcMod, goA] := SUBCARa;
  address[SubcarPrcMod, goB] := SUBCARb;
  address[VorAgc, goA] := AGCforNAVa;
  address[VorAgc, goB] := AGCforNAVb;
  address[DmeSquitter, goA] := SQUITTERforDMEa;
  address[DmeSquitter, goB] := SQUITTERforDMEb;
  address[DmePrcReply, goA] := REPLYforDMEa;
  address[DmePrcReply, goB] := REPLYforDMEb;
  address[AdfAgc, goA] := AGCforADFa;
  address[AdfAgc, goB] := AGCforADFb;
  address[VhfAgc, goA] := AGCforCOMa;
  address[VhfAgc, goB] := AGCforCOMa;
  address[DmeAgc, goA] := AGCforDMEa;
  address[DmeAgc, goB] := AGCforDMEb;
  binAddress[SFLGforNAV, goA] := SFLGforNAVa;
  binAddress[SFLGforNAV, goB] := SFLGforNAVb;
  binAddress[SFLGforGS, goA] := SFLGforGSa;
  binAddress[SFLGforGS, goB] := SFLGforGSb;
  binAddress[NAVAudio, goA] := NAVaAudio;
  binAddress[NAVAudio, goB] := NAVbAudio;
  binAddress[DME_SRC, goA] := DME_SRCa;
  binAddress[DME_SRC, goB] := DME_SRCb;
  binAddress[DME_MEM, goA] := DME_MEMa;
  binAddress[DME_MEM, goB] := DME_MEMb;
  binAddress[DMEAudio, goA] := DMEaAudio;
  binAddress[DMEAudio, goB] := DMEbAudio;
  binAddress[InnMKR, goA] := InnMKRa;
  binAddress[InnMKR, goB] := InnMKRb;
  binAddress[MidMKR, goA] := MidMKRa;
  binAddress[MidMKR, goB] := MidMKRb;
  binAddress[OutMKR, goA] := OutMKRa;
  binAddress[OutMKR, goB] := OutMKRb;
  binAddress[COMAudio, goA] := COMaAudio;
  binAddress[COMAudio, goB] := COMaAudio;
  binAddress[ADFAudio, goA] := ADFaAudio;
  binAddress[ADFAudio, goB] := ADFbAudio;
END DGH_utils.
