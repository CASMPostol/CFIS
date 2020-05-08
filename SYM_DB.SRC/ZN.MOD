MODULE Zn;

FROM Lib IMPORT
  Intr, IncAddr, AddAddr, Move;
FROM SYSTEM IMPORT
  Registers, Seg, Ofs;

FROM FIO IMPORT
  Create, WrBin, Close, File;

  PROCEDURE FindROMFontAddr() : ADDRESS;
  VAR
     R : Registers;
  BEGIN
    R.AX := 1130H; (* return char font info *)
    R.BH := 6H;    (* for font 8x16 *)
    Intr( R, 10H );
    RETURN [R.ES:R.BP];
  END FindROMFontAddr;

VAR
  f : ADDRESS;
  F : File;

  PROCEDURE Save( a : CHAR );
  VAR
    Adr : POINTER TO ARRAY[0..15] OF BYTE;
    Tablica : ARRAY[0..15] OF BYTE;
  BEGIN
    Adr := [Seg(f^) : Ofs(f^)+ORD(a)*16 ];
    Move( Adr, ADR( Tablica ), 16 );
    WrBin( F, Tablica, 16 );
  END Save;

BEGIN
  f := FindROMFontAddr();
  F := Create( 'znaki.pl' );
  Save( '•' );
  Save( 'Ü' );
  Save( '©' );
  Save( 'à' );
  Save( '‰' );
  Save( '¢' );
  Save( 'ò' );
  Save( 'æ' );
  Save( '´' );
  Save( '§' );
  Save( 'è' );
  Save( '®' );
  Save( 'ù' );
  Save( '„' );
  Save( '‡' );
  Save( 'ó' );
  Save( 'Ω' );
  Save( 'ç' );
  Close( F );
END Zn.