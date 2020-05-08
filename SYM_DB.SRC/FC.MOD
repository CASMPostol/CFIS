IMPLEMENTATION MODULE FC;

FROM App IMPORT
  Desktop;
FROM MsgBox IMPORT
  MessageBox, MsgOption, MsgOptions;
FROM stdio IMPORT
  sprintf;
IMPORT
  FlightCommon, Storage, Str;


PROCEDURE EnableCmds( b : BOOLEAN );
BEGIN
  FlightCommon.EnableCmds(Desktop, b );
END EnableCmds;

PROCEDURE Heap;
VAR
  s : ARRAY [0..255] OF CHAR;
BEGIN
  sprintf( s,
           3C+"Wolnej pamiëci jest jeszcze 0x%lx bajt¢w, a jednym kawaíku 0x%lx bajt¢w",
           LONGCARD(Storage.HeapTotalAvail( Storage.MainHeap ))*16,
           LONGCARD(Storage.HeapAvail( Storage.MainHeap ))*16 );
  MessageBox( s, NIL, MsgOptions{mfInformation, mfOKButton } );
END Heap;

PROCEDURE Copy( VAR d, s : ARRAY OF CHAR );
BEGIN
  Str.Copy( d, s );
END Copy;

PROCEDURE BadTeodolitSetup;
BEGIN
  MessageBox( 3C+"Teodolit jest ¶le ustawiony!",
              NIL,
              MsgOptions{mfWarning,mfOKButton} );
END BadTeodolitSetup;

PROCEDURE Odleglosc0;
BEGIN
  MessageBox( 3C+"Samolot nie moße lataç wok¢í wíasnej osi!",
              NIL,
              MsgOptions{mfError,mfOKButton} );
END Odleglosc0;

PROCEDURE TheodolitView( pk : PolozenieKatowe ) : PolozenieKatowe;
BEGIN
  RETURN FlightCommon.TheodolitView( pk );
END TheodolitView;

END FC.