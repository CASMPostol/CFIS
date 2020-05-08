IMPLEMENTATION MODULE Logo;

FROM Objects IMPORT
  TRect;
FROM Views IMPORT
  TViewOption, TViewOptions, ofCentered;
FROM Dialogs IMPORT
  PDialog;
FROM Winds IMPORT
  WindowFlags, WindowFlags, wfClose;
FROM StaticTexts IMPORT
  PStaticText;
FROM Storage IMPORT
  ALLOCATE;


CONST
  Cas1=    ' €€€€€€            €€           €€€€€€    '+15C+
           '€€    €€          €€€€         €€    €€   '+15C+
           '€€               €€  €€        €€         '+15C+
           '€€              €€    €€        €€        '+15C+
           '€€              €€€€€€€€         €€€€     ';
  Cas2=    '€€              €€    €€            €€    '+15C+
           '€€              €€    €€             €€   '+15C+
           '€€    €€        €€    €€       €€    €€   '+15C+
           ' €€€€€€    €    €€    €€  €     €€€€€€   €';




PROCEDURE ShowLogo( Desktop : PGroup; Open : BOOLEAN ) : PDialog;
VAR
  R : TRect;
  Dlg : PDialog;
  Text : PStaticText;
BEGIN
  R.Assign( 0, 0, 60, 20 );
  NEW( Dlg );
  WITH Dlg^ DO
    IF Open THEN
      Init( R, "Poczekaj chwilkë-czytanie wartoûci poczÜtkowych" );
    ELSE
      Init( R, "Poczekaj chwilkë-zapisywanie wartoûci poczÜtkowych" );
    END;
    Options := Options+ofCentered ;
    EXCL( Flags, wfClose );

    R.Assign( 9, 2, 58, 7 );
    NEW( Text );
    Text^.Init( R, Cas1 );
    Insert( Text );

    R.Assign( 9, 7, 58, 11 );
    NEW( Text );
    Text^.Init( R, Cas2 );
    Insert( Text );

    R.Assign( 9, 11, 58, 12 );
    NEW( Text );
    Text^.Init( R, 3C+'COMPUTER-BASED AUTOMATION SYSTEMS' );
    Insert( Text );
(*
    R.Assign( 9, 13, 58, 14 );
    NEW( Text );
    Text^.Init( R, 3C+'94-050 ú¢d¶, ul. Krzemieniecka 2' );
    Insert( Text );

    R.Assign( 9, 15, 58, 17 );
    NEW( Text );
    Text^.Init( R, 3C+'tel: (42) 86-58-12 wew. 123'+15C+
                   3C+'     (42) 87-80-44         ' );
    Insert( Text );

    R.Assign( 9, 17, 58, 18 );
    NEW( Text );
    Text^.Init( R, 3C+'fax: (42) 84-48-40         ' );
    Insert( Text );
*)
  END;
  Desktop^.Insert( Dlg );
  RETURN Dlg;
END ShowLogo;

END Logo.
