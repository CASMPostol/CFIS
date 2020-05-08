IMPLEMENTATION MODULE DB_Common;

FROM Objects IMPORT
  TRect;
FROM Storage IMPORT
  ALLOCATE, DEALLOCATE;
FROM Labels IMPORT
  PLabel;
FROM StaticTexts IMPORT
  PStaticText;
FROM InputLines IMPORT
  PInputLine, TInputLine;


    PROCEDURE SetBlock( VAR d         : TDialog;
                            LabelText : ARRAY OF CHAR;
                        VAR b         : Blok;
                            Ozn       : ARRAY OF CHAR;
                            y         : CARDINAL );
    VAR
      R : TRect;
      l : PLabel;
      st : PStaticText;
    BEGIN
      R.Assign( 15, y, 20, y+1 );
      NEW( b.Stopnie );
      b.Stopnie^.Init( R, 5, 0, 89 );

      R.Assign( 21, y, 26, y+1 );
      NEW( b.Minuty );
      b.Minuty^.Init( R, 5, 0, 59 );
      b.Minuty^.SetFormat( "%02d" );

      R.Assign( 27, y, 32, y+1 );
      NEW( b.Setne );
      b.Setne^.Init( R, 5, 0, 99 );
      b.Setne^.SetFormat( "%02d" );

      d.Insert( b.Stopnie );
      d.Insert( b.Minuty );
      d.Insert( b.Setne );

      R.Assign( 2, y, 14, y+1 );
      NEW( l );
      l^.Init( R, LabelText, b.Stopnie );
      d.Insert( l );

      R.Assign( 20, y, 21, y+1);
      NEW( st );
      st^.Init( R, "ø" );
      d.Insert( st );

      R.Assign( 26, y, 27, y+1);
      NEW( st );
      st^.Init( R, "'" );
      d.Insert( st );

      R.Assign( 32, y, 33, y+1);
      NEW( st );
      st^.Init( R, Ozn );
      d.Insert( st );

    END SetBlock;

    PROCEDURE SetBlock1(VAR d         : TDialog; 
                        LabelText     : ARRAY OF CHAR;
                        VAR b         : Blok;
                        Ozn           : ARRAY OF CHAR;
                        x,y           : CARDINAL );

    VAR
      R : TRect;
      l : PLabel;
      st : PStaticText;


    BEGIN
      R.Assign( x+13, y, x+18, y+1 );
      NEW( b.Stopnie );
      b.Stopnie^.Init( R, 5, 0, 89 );

      R.Assign( x+19, y, x+24, y+1 );
      NEW( b.Minuty );
      b.Minuty^.Init( R, 5, 0, 59 );
      b.Minuty^.SetFormat( "%02d" );

      R.Assign( x+25, y, x+32, y+1 );
      NEW( b.Setne );
      b.Setne^.Init( R, 5, 0, 9999 );
      b.Setne^.SetFormat( "%04d" );

      d.Insert( b.Stopnie );
      d.Insert( b.Minuty );
      d.Insert( b.Setne );

      R.Assign( x, y, x+12, y+1 );
      NEW( l );
      l^.Init( R, LabelText, b.Stopnie );
      d.Insert( l );

      R.Assign( x+18, y, x+19, y+1);
      NEW( st );
      st^.Init( R, "ø" );
      d.Insert( st );

      R.Assign( x+24, y, x+25, y+1);
      NEW( st );
      st^.Init( R, "." );
      d.Insert( st );
      
      R.Assign( x+32, y, x+33, y+1);
      NEW( st );
      st^.Init( R, "'" );
      d.Insert( st );

      R.Assign( x+33, y, x+34, y+1);
      NEW( st );
      st^.Init( R, Ozn );
      d.Insert( st );

    END SetBlock1;

    PROCEDURE SetReal(VAR d         : TDialog;   
                       LabelText : ARRAY OF CHAR;
                       VAR p         : PRealInputLine;
                           max       : LONGREAL;
                           dodatnie  : BOOLEAN;
                           x, y      : CARDINAL      );
VAR
    R : TRect;
    n : PInputLine;
    l : PLabel;

    BEGIN
      R.Assign( x+13, y, x+30, y+1 );
      NEW( p );
      IF dodatnie THEN
        p^.Init( R, 15, 0.0, max );
      ELSE
        p^.Init( R, 15, -max, max );
      END;
      p^.SetFormat( "%.2lf" );
      d.Insert( p );

      R.Assign( x, y, x+13, y+1 );
      NEW( l );
      l^.Init( R, LabelText, p );
      d.Insert( l );

    END SetReal;


    PROCEDURE SetBlockGPS(VAR d         : TDialog;
                          VAR GPS       : BlokGPS;
                       x,y              : CARDINAL );

 (*                     VAR d         : TDialog; 
                        LabelText     : ARRAY OF CHAR;
                        VAR b         : Blok;
                        Ozn           : ARRAY OF CHAR;*)
 

    VAR
      R : TRect;
      l : PLabel;
      st : PStaticText;

BEGIN
          R.Assign( x, y, x+34, y+4 );

      NEW( st );
      st^.Init( R, "Õ                               Í¸"+15C+12C+
                   "³                                ³"+15C+12C+
                   "³                                ³"+15C+12C+
                   "À¯Parametry GPS®ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ" );
    d.Insert( st );
    
      SetReal(d, "K~¥~t", GPS.Kat, 359.99,TRUE,x+1,y );
      R.Assign( x+31, y, x+32, y+1 );
      NEW( st );
      st^.Init( R,"ø" );
      d.Insert( st );


      SetReal(d, "Odleg~ˆ~o˜†", GPS.Odleglosc, 100.0,TRUE,x+1,y+1 );
      R.Assign( x+31, y+1,x+32, y+2 );
      NEW( st );
      st^.Init( R, "m" );
      d.Insert( st );

      SetReal(d, "Wys~o~kosc", GPS.Wysokosc, 3000.0,TRUE,x+1,y+2 );
      R.Assign( x+31, y+2, x+32, y+3);
      NEW( st );
      st^.Init( R, "m" );
      d.Insert( st );


END SetBlockGPS;



END DB_Common.
