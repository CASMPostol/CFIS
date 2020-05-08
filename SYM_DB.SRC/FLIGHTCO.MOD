IMPLEMENTATION MODULE FlightCommon;

FROM FlightUtil IMPORT
  GeoPtr;
FROM Geo2Polar IMPORT
  PolozenieGeograficzne, KatGeo, Kat2Geo;
FROM Objects IMPORT
  TRect;
FROM Storage IMPORT
  ALLOCATE, DEALLOCATE;
FROM stdio IMPORT
  sprintf;
FROM MATHLIB IMPORT
  ATan2, M_Pi, Sqrt, Cos, ACos;
FROM Drivers IMPORT
  EventType;
FROM Views IMPORT
  EnableCommands, DisableCommands, EnableCommand, DisableCommand,
  TCommandSet, Message;
FROM LocCommands IMPORT
  FirstCommand, LastCommand, cmStartFlight, cmStopFlight;
FROM MsgBox IMPORT
  MessageBox, MsgOption, MsgOptions;
(*
FROM App IMPORT
  Desktop;
*)
FROM Drivers IMPORT
  evMessage;
IMPORT
  Data, Send, Lib, TeoEvent;


  PROCEDURE Angle360( ang : LONGREAL ) : LONGREAL;
  BEGIN
    WHILE ang < 0.0 DO
      ang := ang+360.0;
    END;
    WHILE ang >= 360.0 DO
      ang := ang-360.0;
    END;
    RETURN ang;
  END Angle360;

  PROCEDURE SubTime( VAR a, b : FlightTime ) : LONGCARD;

    PROCEDURE TimeToSec100( VAR a : FlightTime ) : LONGCARD;
    BEGIN
      RETURN VAL( LONGCARD, a._100 )+
             VAL( LONGCARD, a.s    )*100+
             VAL( LONGCARD, a.m    )*6000+
             VAL( LONGCARD, a.h    )*360000;
    END TimeToSec100;

  BEGIN
    RETURN TimeToSec100(a)-TimeToSec100(b);
  END SubTime;

  PROCEDURE EnableTimer( p : PView; Enable : BOOLEAN );
  BEGIN
    WHILE p # NIL DO
      IF Enable THEN
        INCL( p^.EventMask, evTimer );
      ELSE
        EXCL( p^.EventMask, evTimer );
      END;
      p := p^.Owner;
    END;
  END EnableTimer;


  INLINE PROCEDURE Sqr( x : LONGREAL ) : LONGREAL;
  BEGIN
    RETURN x*x;
  END Sqr;

  PROCEDURE PolozenieG(     Dlg   : PDialog;
                            x, y  : CARDINAL;
                        VAR gp    : GeoPtr;
                            IdStr : ARRAY OF CHAR );
  VAR
    R : TRect;
    p : PStaticText;
  BEGIN
    R.Assign( x, y, x+3, y+1 );
    NEW( gp.Stopnie );
    gp.Stopnie^.Init( R, "" );
    Dlg^.Insert( gp.Stopnie );
    R.Assign( x+3, y, x+4, y+1 );
    NEW( p );
    p^.Init( R, "ø" );
    Dlg^.Insert( p );

    R.Assign( x+4, y, x+6, y+1 );
    NEW( gp.Minuty );
    gp.Minuty^.Init( R, "" );
    Dlg^.Insert( gp.Minuty );
    R.Assign( x+6, y, x+7, y+1 );
    NEW( p );
    p^.Init( R, "'" );
    Dlg^.Insert( p );

    R.Assign( x+7, y, x+9, y+1 );
    NEW( gp.Setne );
    gp.Setne^.Init( R, "" );
    Dlg^.Insert( gp.Setne );
    R.Assign( x+9, y, x+10, y+1 );
    NEW( p );
    p^.Init( R, IdStr );
    Dlg^.Insert( p );

  END PolozenieG;

  PROCEDURE GetPolozenieGs( Dlg : PDialog; y : CARDINAL; VAR gps : GeoPtrs );
  CONST
    x = 20;
  BEGIN
    PolozenieG( Dlg, x,    y, gps.Szerokosc, "N" );
    PolozenieG( Dlg, x+15, y, gps.Dlugosc,   "E" );
  END GetPolozenieGs;

  PROCEDURE GetPolozenieKatowe(     Dlg : PDialog;
                                    y : CARDINAL;
                                VAR ap : AnglePtr;
                                    Theodolit : BOOLEAN );
  CONST
    x = 20;
  VAR
    R : TRect;
    p : PStaticText;
  BEGIN
    R.Assign( x, y, x+10, y+1 );
    NEW( ap.Odleglosc );
    ap.Odleglosc^.Init( R, "" );
    Dlg^.Insert( ap.Odleglosc );
    R.Assign( x+10, y, x+12, y+1 );
    NEW( p );
    IF Theodolit THEN
      p^.Init( R, "ø" );
    ELSE
      p^.Init( R, "Mm" );
    END;
    Dlg^.Insert( p );

    R.Assign( x+15, y, x+25, y+1 );
    NEW( ap.Kat );
    ap.Kat^.Init( R, "" );
    Dlg^.Insert( ap.Kat);
    R.Assign( x+25, y, x+26, y+1 );
    NEW( p );
    p^.Init( R, "ø" );
    Dlg^.Insert( p );
    IF Theodolit THEN
      R.Assign( x-2, y, x, y+1 );
      NEW( p );
      p^.Init( R, "E=" );
      Dlg^.Insert( p );
      R.Assign( x+13, y, x+15, y+1 );
      NEW( p );
      p^.Init( R, "A=" );
      Dlg^.Insert( p );
    END;
  END GetPolozenieKatowe;

  PROCEDURE RamkaPolozenia( Dlg : PDialog; y : CARDINAL );
  CONST
    x=19;
  VAR
    p : PStaticText;
    r : TRect;
  BEGIN
    r.Assign( x, y, x+28, 4+y );
    NEW( p );
    p^.Init( r, "ÚÄPo’o§enieÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿"+15C+
                "³                          ³"+15C+
                "³                          ³"+15C+
                "ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ" );
    Dlg^.Insert( p );
  END RamkaPolozenia;



  PROCEDURE SetInt( p : PStaticText; fmt : ARRAY OF CHAR; val : INTEGER );
  VAR
    s : ARRAY [0..27] OF CHAR;
  BEGIN
    sprintf( s, fmt, val );
    p^.ChangeString( s );
  END SetInt;

  PROCEDURE SetFloat( p : PStaticText; fmt : ARRAY OF CHAR; val : LONGREAL );
  VAR
    s : ARRAY [0..27] OF CHAR;
  BEGIN
    sprintf( s, fmt, val );
    p^.ChangeString( s );
  END SetFloat;

  PROCEDURE SetGeo( VAR gp : GeoPtr; VAR pg : KatGeo );
  BEGIN
    SetInt( gp.Stopnie, "%3d", pg.Stopnie );
    SetInt( gp.Minuty,  "%02d", pg.Minuty  );
    SetInt( gp.Setne,   "%02d", pg.Setne   );
  END SetGeo;

  PROCEDURE SetGeos( VAR gp : GeoPtrs; pk : PolozenieKatowe );
  VAR
    pg : PolozenieGeograficzne;
  BEGIN
    pk.Kat := pk.Kat + Data.Deklinacja;
    Kat2Geo( pk, pg );
    SetGeo( gp.Szerokosc, pg.Szerokosc );
    SetGeo( gp.Dlugosc,   pg.Dlugosc   );
  END SetGeos;

  PROCEDURE SetAngle( VAR ap : AnglePtr; pk : PolozenieKatowe; Theodolit : BOOLEAN);
  BEGIN
    IF Theodolit THEN
      pk.Odleglosc :=ATan2( pk.Odleglosc, Data.AktualnePol.Wysokosc );
      pk.Odleglosc := pk.Odleglosc*180.0/M_Pi;
      IF pk.Odleglosc < 0.0 THEN
        pk.Odleglosc := 0.0;
      END;
      pk.Odleglosc := Angle360(pk.Odleglosc);
      Data.WidokZTeodolitu.Elewacja := pk.Odleglosc;
      IF Data.WidokZTeodolitu.Elewacja > 179.9 THEN
        Data.WidokZTeodolitu.Elewacja := 0.0;
      END;
      Data.WidokZTeodolitu.Azymut := pk.Kat;
    END;
    SetFloat( ap.Odleglosc, "%10lf", pk.Odleglosc );
    SetFloat( ap.Kat,       "%10lf", Angle360(pk.Kat)       );
  END SetAngle;

  PROCEDURE TheodolitView( pk : PolozenieKatowe ) : PolozenieKatowe;
  VAR
    t : PolozenieKatowe;
    kat : LONGREAL;
  BEGIN
(*
    IF pk.Kat < 2.0 THEN
      pk := pk;
    END;
*)
    IF Data.PolozenieTeodolitu.Odleglosc = 0.0 THEN
      t := pk;
    ELSE
      kat := ABS( pk.Kat - Data.PolozenieTeodolitu.Kat ); (* kat pomiedzy *)
      kat := kat*M_Pi/180.0;
      t.Odleglosc := Sqrt( Sqr( Data.PolozenieTeodolitu.Odleglosc )+
                           Sqr( pk.Odleglosc )-
                           2.0*Data.PolozenieTeodolitu.Odleglosc*pk.Odleglosc*Cos(kat)
                         );
      IF (t.Odleglosc = 0.0) OR (pk.Odleglosc = 0.0) THEN
        kat := 0.0;
      ELSE
        kat := ACos( ( Sqr( pk.Odleglosc ) +
                       Sqr( t.Odleglosc ) -
                       Sqr( Data.PolozenieTeodolitu.Odleglosc )
                     ) / (2.0*t.Odleglosc*pk.Odleglosc)
                   );
      END;
      kat := kat*180.0/M_Pi;
      IF Angle360( Data.PolozenieTeodolitu.Kat-pk.Kat ) < 180.0 THEN
        t.Kat := pk.Kat-kat;
      ELSE
        t.Kat := pk.Kat+kat;
      END;
    END;
    RETURN t;
  END TheodolitView;

  PROCEDURE EnableCmds( p : PView; Enable : BOOLEAN );
  VAR
    q, c : TCommandSet;
  BEGIN
    c := TCommandSet{ FirstCommand..LastCommand};
    q := TCommandSet{ cmStartFlight..cmStopFlight};
    IF Enable THEN
      EnableCommands( c );
      DisableCommands( q );
    ELSE
      DisableCommands( c );
      EnableCommands( q );
(*
      IF LotTrwa THEN
        EnableCommand( doStop );
        DisableCommand( doStart );
      ELSE
        EnableCommand( doStart );
        DisableCommand( doStop );
      END;
*)
      Lib.NoSound;
      Message( p,
               evMessage,
               cmStopFlight,
               NIL );
    END;
    TeoEvent.Enable( NOT Enable );
  END EnableCmds;

  PROCEDURE GetGS( d : LONGREAL ) : LONGREAL;
  BEGIN
    IF d < Data.InnerMarker.Odleglosc THEN
      RETURN Data.GlidingSlope1;
    ELSIF d > Data.OuterMarker.Odleglosc THEN
      RETURN Data.GlidingSlope3;
    ELSE
      RETURN Data.GlidingSlope2;
    END;
  END GetGS;

  PROCEDURE OnTheGround;
  BEGIN
    MessageBox( 3C+"Samolot wyl†dowa’",
                NIL,
                MsgOptions{mfInformation, mfOKButton } );
  END OnTheGround;

  PROCEDURE Leci( SamolotLeci : BOOLEAN );
  BEGIN
    Send.Leci( SamolotLeci );
  END Leci;

END FlightCommon.
