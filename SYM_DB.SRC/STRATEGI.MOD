IMPLEMENTATION MODULE Strategia;

FROM SYSTEM IMPORT
  Registers;
FROM Lib IMPORT
  Dos, Terminate;

VAR
  StaraStrategia : CARDINAL;
  StaryCh        : CARDINAL;
  OldChain       : PROC;

  PROCEDURE SetStrategia( Mode : CARDINAL ) ;
  VAR
    r : Registers;
  BEGIN
    r.AX := 5801H;
    r.BX := Mode;
    Dos( r );
  END SetStrategia;

  PROCEDURE GetStrategia( ) : CARDINAL ;
  VAR
    r : Registers;
  BEGIN
    r.AX := 5800H;
    Dos( r );
    RETURN r.AX;
  END GetStrategia;

  PROCEDURE SetChain( Mode : CARDINAL ) ;
  VAR
    r : Registers;
  BEGIN
    r.AX := 5803H;
    r.BX := Mode;
    Dos( r );
  END SetChain;

  PROCEDURE GetChain( ) : CARDINAL ;
  VAR
    r : Registers;
  BEGIN
    r.AX := 5802H;
    Dos( r );
    RETURN r.AX MOD 256;
  END GetChain;


  PROCEDURE Terminator(  );
  BEGIN
    SetStrategia(StaraStrategia);
    SetChain(StaryCh);
    OldChain;
  END Terminator;

PROCEDURE Init;
BEGIN
  StaraStrategia := GetStrategia();
  StaryCh        := GetChain();
  SetStrategia(80H);
  SetChain(1);
  Terminate( Terminator, OldChain );
END Init;



BEGIN
  Init;
END Strategia.
