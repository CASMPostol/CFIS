(*.F- *)
(**********************************************************************
|  Title   : Obsluga glownego ekranu sterujacego dla Vora trasowego
|  Author  : M.Morawski
|  System  : LOGITECH MODULA-2/86
|  History :
|    15-12-96: M.Postol
|      Zmiana definicji ScannerI
|    13-05-97: M.Postol
|      Zmiana definicji ScannerI
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)
IMPLEMENTATION MODULE  PI_Glowny;

  FROM CommonTypes IMPORT
    OdnDlaPomOdlT, OdnDlaPomBleduT, glownyEvent;

  FROM ScannerI IMPORT
    Start, Stop;

  FROM T_Oblot  IMPORT
    (* TYPE *) CoMoznaZrobic,
    (* VAR *) CoRobimy,
    (* PROCEDURE *) InitLot;

  CONST
    AzymANieElew  = TRUE;

  PROCEDURE GlownyEP( ) : glownyEvent;
  VAR
    result : glownyEvent;

  BEGIN
    Start(0, AzymANieElew, TRUE);
    IF NOT InitLot( )
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
          result := PlayGE;
        |
        czPreview:
          result := PreviewGE;
      END;
    END;
    Stop;
    RETURN result
  END GlownyEP;

END PI_Glowny.
