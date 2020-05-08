(*.F- *)
(**********************************************************************
|  Title   : Screen Utilities device dependent for VHF
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|    08-12-96: created
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE PI_ScrUtility;

  IMPORT
    H_Slupek;

  FROM CommonTypes IMPORT
    SlupekNr;

  FROM GrafTypes IMPORT
    RECT, POINT;

  FROM HiLevGraf IMPORT
    HDIB;

  FROM ScreenCTypes IMPORT
    SkalaWpionieOpis;

  VAR

  PROCEDURE ShowScreenDIB
            (     Pomiar     : BOOLEAN;
                  Src        : RECT;
                  Dest       : POINT;
              VAR screeenDIB : HDIB    );

  BEGIN
    H_Slupek.ShowScreenDIB(Src, Dest, screeenDIB);
  END ShowScreenDIB;

  PROCEDURE ShowCursorDIB
            (    Pomiar : BOOLEAN;
                 Src    : RECT;
                 Dest   : POINT   );

  BEGIN
    H_Slupek.ShowCursorDIB(Src, Dest);
  END ShowCursorDIB;

  PROCEDURE WykSlup
            (    slupek : SlupekNr;
                 Pomiar : BOOLEAN;
                 dib    : HDIB     );

  BEGIN
  END WykSlup;

  PROCEDURE UpdateSlupki;

  BEGIN
  END UpdateSlupki;

  PROCEDURE DisposeSlupki;

  BEGIN
  END DisposeSlupki;

  PROCEDURE NapiszSygnaly
            (    Pomiar : BOOLEAN );

  BEGIN
    H_Slupek.NapiszSygnaly;
  END NapiszSygnaly;

  PROCEDURE Init_ScrUtility
            (    Pomiar : BOOLEAN );

  BEGIN
  END Init_ScrUtility;

  PROCEDURE IniSkale
            ( VAR skalaWpionie : SkalaWpionieOpis;
                  Zakres       : BOOLEAN          );

  BEGIN
    H_Slupek.IniSkale(skalaWpionie);
  END IniSkale;

  PROCEDURE GetRegionWykG
            (     Zakres : BOOLEAN;
              VAR rec    : RECT    ) : BOOLEAN;

  BEGIN
    RETURN FALSE;
  END GetRegionWykG;

  PROCEDURE GetRegionWyk1
            (     Zakres : BOOLEAN;
              VAR rec    : RECT    ) : BOOLEAN;

  BEGIN
    RETURN FALSE;
  END GetRegionWyk1;

  PROCEDURE GetRegionWyk2
            (     Zakres : BOOLEAN;
              VAR rec    : RECT    ) : BOOLEAN;

  BEGIN
    RETURN FALSE;
  END GetRegionWyk2;

  PROCEDURE GetRegionWyk3
            (     Zakres : BOOLEAN;
              VAR rec    : RECT    ) : BOOLEAN;

  BEGIN
    RETURN FALSE;
  END GetRegionWyk3;

END PI_ScrUtility.
