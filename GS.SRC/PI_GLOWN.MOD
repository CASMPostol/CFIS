(*.F- *)
(**********************************************************************
|  Title   : Obsluga glownego ekranu sterujacego dla GS
|  Author  : M. Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    12-05-97: M.Postol
|      zmiana definicji ScannerI
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)
IMPLEMENTATION MODULE  PI_Glowny;

  FROM CommonTypes IMPORT
    OdnDlaPomOdlT, OdnDlaPomBleduT, CoMoznaZrobic, glownyEvent;

  FROM ScannerI IMPORT
    Start, Stop;

  FROM G_Oblot  IMPORT
    (* VAR *) CoRobimy,
    (* PROCEDURE *) InitLot;

  PROCEDURE GlownyEP( ) : glownyEvent;
  CONST
    AzymANieElew      = TRUE;
    LocationsTogether = TRUE;

  VAR
    result : glownyEvent;

  BEGIN
    Start(0, NOT AzymANieElew, LocationsTogether);
    IF NOT InitLot()
    THEN
      result := AbortGE;
    ELSE
      CASE CoRobimy  OF
        czTest:
          result := TestGE
        |
        czPomiar:
          result := AkceptGE
        |
        czDrukR:
          result := DrukujGE
        |
        czPlay:
          result := PlayGE
        |
        czPreview:
          result := PreviewGE
        |
        czRaportKoncowy:
          result := RaportKoncowyGE;
      END;
    END;
    Stop;
    RETURN result
  END GlownyEP;

END PI_Glowny.
