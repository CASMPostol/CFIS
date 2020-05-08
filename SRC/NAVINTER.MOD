(*.F- *)
(**********************************************************************
|  Title   : Interface for NAV receiver
|  Author  : Mariusz Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|     01.11.95: Mariusz Postol
|       zwraca dla LOC i GS DEV nie przliczona
|     27.04.96: M.Postol
|       sprawdza dla LOC i GS czy przychodza pakiety
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 86 58 12, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE NAVInterface;

  FROM ARINC IMPORT
    ShortCardinal, Data, ChannelNu, ReadConfiguration, ReadRXSlot;

  FROM CommonTypes IMPORT
    NilValI;
    
  FROM MathLib0 IMPORT
    entier, real;

  CONST
    OmniberLab = 146;
    LOCDevLab  = 123;
    GSDevLab   = 124;

  PROCEDURE GetOmnibearing
            (     receiver : ChannelNu;
              VAR val      : INTEGER   ) : BOOLEAN;

  CONST
    Mul = 180.0 / 4096.0;

  VAR
    data     : Data;
    label    : ShortCardinal;
    speed    : ShortCardinal;
    rate     : CARDINAL;
    omni     : INTEGER;
    omniReal : REAL;
  BEGIN
    IF ReadRXSlot( OmniberLab, label, data, rate, receiver, speed )
       AND ( rate > 3 )
    THEN
      omni := ORD( data[1] ) + ( ORD( data[2] ) MOD 32 ) * 256;
      IF omni > 4095  THEN
        omni := -( 2*4096 - omni )
      END;
      IF omni < 0  THEN
        omniReal := real( omni ) * Mul + 180.0;
      ELSE
        omniReal := real( omni ) * Mul - 180.0;
      END;
      val := entier( omniReal * 100.0 );
      RETURN TRUE
    END (* if ReadRXSlot *);
    val := NilValI;
    RETURN FALSE;
  END GetOmnibearing;

  PROCEDURE GetLocDev
            (     receiver : ChannelNu;
              VAR val      : INTEGER   ) : BOOLEAN;

  VAR
    data  : Data;
    label : ShortCardinal;
    speed : ShortCardinal;
    rate    : CARDINAL;

  BEGIN
    IF ReadRXSlot( LOCDevLab, label, data, rate, receiver, speed )
       AND ( rate > 3 )
    THEN
      val := ORD( data[1] ) + ( ORD( data[2] ) MOD 32 ) * 100H;
      IF val > 4095  THEN
        val := -( 2*4096 - val )
      END;
      RETURN TRUE
    END (* if ReadRXSlot *);
    val := NilValI;
    RETURN FALSE;
  END GetLocDev;

  PROCEDURE GetGSDev
            (     receiver : ChannelNu;
              VAR val      : INTEGER   ) : BOOLEAN;

  VAR
    data  : Data;
    label : ShortCardinal;
    speed : ShortCardinal;
    rate  : CARDINAL;

  BEGIN
    IF ReadRXSlot( GSDevLab, label, data, rate, receiver, speed )
       AND ( rate > 3 )
    THEN
      val := ORD( data[1] ) + ( ORD( data[2] ) MOD 32 ) * 100H;
      IF val > 4095  THEN
        val := -( 2*4096 - val )
      END;
      RETURN TRUE
    END (* if ReadRXSlot *);
    val := NilValI;
    RETURN FALSE;
  END GetGSDev;

  VAR
    disableMask,
    speedMask   : BITSET;
    fineMode    : BOOLEAN;
    killTime    : CARDINAL;

BEGIN
  IF NOT ReadConfiguration( disableMask, speedMask, fineMode, killTime )
  THEN
  END (* if *);
END NAVInterface.
