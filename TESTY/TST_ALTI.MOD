MODULE  tst_altime;

FROM AltInterface  IMPORT
  ALTConvert;

VAR
  wys: INTEGER;
  
BEGIN
  wys := ALTConvert(BITSET(ORD( 32C))/{0..15}); (*   0 *)
  wys := ALTConvert(BITSET(ORD( 41C))/{0..15}); (*  27 *)
  wys := ALTConvert(BITSET(ORD(141C))/{0..15}); (*  28 *)
  wys := ALTConvert(BITSET(ORD(341C))/{0..15}); (* 107 *)

END tst_altime.
