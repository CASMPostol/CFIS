MODULE TSP;

  IMPORT
    MANAGER;
  FROM SumPrint IMPORT
    DoIt, OznaczenieSamolotu, Odpowiedzialny, typ, RodzajBadania,
    NrOdbPokl, DataPomiaru, DataKalibracji, TypOdbiornika;
  FROM RTSMain IMPORT
    Terminate, Status;
  FROM Database IMPORT
    LoadVorData;

VAR
  s1, s2 : ARRAY [0..15] OF CHAR;
BEGIN
  s1 := "Lipiny";
  s2 := "1";
  OznaczenieSamolotu := "SP-MMM";
  Odpowiedzialny := "Grzegorz Brzeczyszczykiewicz";
  typ := okresowe;
  NrOdbPokl := 1234;
  TypOdbiornika := "ABC";
  DataPomiaru.d := 12;
  DataPomiaru.m := 11;
  DataPomiaru.y := 96;
  DataKalibracji := DataPomiaru;
  LoadVorData( s1, s2 );
  DoIt;
  Terminate( Stopped );
END TSP.
