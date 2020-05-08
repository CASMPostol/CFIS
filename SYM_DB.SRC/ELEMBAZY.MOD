
IMPLEMENTATION MODULE ElemBazy;

FROM IntInputLines IMPORT
  PIntInputLine;
FROM RealInputLines IMPORT
  PRealInputLine;


    PROCEDURE SetReal1(     LabelText : ARRAY OF CHAR;
                       VAR p         : PRealInputLine;
                           max       : LONGREAL;
                           dodatnie  : BOOLEAN;
                           x, y      : CARDINAL      );
    BEGIN
      R.Assign( x+13, y, x+30, y+1 );
      NEW( p );
      IF dodatnie THEN
        p^.Init( R, 15, 0.0, max );
      ELSE
        p^.Init( R, 15, -max, max );
      END;
      p^.SetFormat( "%.2lf" );
      Insert( p );

      R.Assign( x, y, x+13, y+1 );
      NEW( l );
      l^.Init( R, LabelText, p );
      Insert( l );

    END SetReal1;

    PROCEDURE SetInt1(     LabelText : ARRAY OF CHAR;
                       VAR p         : PIntInputLine;
                           x, y      : CARDINAL      );
    BEGIN
      R.Assign( x+13, y, x+30, y+1 );
      NEW( p );
      p^.Init( R, 15, -180, 359 );
      p^.SetFormat( "%03d" );
      Insert( p );

      R.Assign( x, y, x+13, y+1 );
      NEW( l );
      l^.Init( R, LabelText, p );
      Insert( l );

    END SetInt1;
    
PROCEDURE BazaGPS    (GPS,poczat

BEGIN
        R.Assign( 38, 2, 72, 6 );
      NEW( st );
      st^.Init( R, "Õ                               Í¸"+15C+12C+
                   "³                                ³"+15C+12C+
                   "³                                ³"+15C+12C+
                   "À¯Parametry GPS®ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ" );
    Insert( st );

      SetReal1( "K~¥~t", GPSKat, 359.99,TRUE,39,2 );
      R.Assign( 69, 2, 70, 3 );
      NEW( st );
      st^.Init( R,"ø" );
      Insert( st );

      SetReal1( "Odleg~ˆ~o˜†", GPSOdleglosc, 100.0,TRUE,39,3 );
      R.Assign( 69, 3, 70, 4 );
      NEW( st );
      st^.Init( R, "m" );
      Insert( st );

     SetReal1( "Wys~o~kosc", GPSWysokosc, 3000.0,TRUE,39,4 );
      R.Assign( 69, 4, 70, 5);
      NEW( st );
      st^.Init( R, "m" );
      Insert( st );
END BazaGPS;

END ElemBazy.