MODULE tstpmd;

  IMPORT DebugPMD, Semafory;
  
  FROM MANAGER IMPORT
    STARTPROCESS, InitS, InitC, SIGNAL, SEND, WAITS, WAITC, Assert, Condition;

  FROM Timer IMPORT
    Wait, TInOneSecond;

  FROM DigiRS IMPORT
    ReadString, WriteString, SetBaudRate;

FROM Messages IMPORT
  Message, NewMessage, Display, Acknowledge, AcknowledgeFirst;

  CONST
    GPSChannel   = 4;

VAR
   Nie_mozna_uruchomic_kanalu_GPS : Message;

  PROCEDURE Trimble2(  );
  TYPE
    str63 = ARRAY[0..63] OF CHAR;
  VAR
    bufor : str63;
    t : CARDINAL;
    ok : BOOLEAN;
    c  : CHAR;

  PROCEDURE GetStrFromGps( VAR s : str63 ) : BOOLEAN;
  VAR
  BEGIN
    REPEAT
      Wait(MAX(CARDINAL));
    UNTIL s[0] >= ' ';
    RETURN TRUE;
  END GetStrFromGps;

  BEGIN
    LOOP
      IF GetStrFromGps( bufor ) THEN
      ELSE
      END;
    END;
  END Trimble2;

VAR
   UslugaZajeta : Semafory.Semafor;
BEGIN
  Semafory.Init( UslugaZajeta );
  Semafory.Register( UslugaZajeta );
  IF NOT SetBaudRate( GPSChannel, 96, 8 ) THEN
    NewMessage(Nie_mozna_uruchomic_kanalu_GPS,
               "Nie mo¾na uruchomi† kanaˆu GPS",
                BITSET(9090H) );
    Display( Nie_mozna_uruchomic_kanalu_GPS );
  END;
  STARTPROCESS( Trimble, 0C00H, 0 );
  LOOP
  END;
END tstpmd.
