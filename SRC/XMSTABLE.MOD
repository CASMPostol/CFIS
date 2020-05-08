IMPLEMENTATION MODULE XMSTable;

IMPORT
  XMSService;
FROM Storage IMPORT
  ALLOCATE, DEALLOCATE;
FROM SYSTEM IMPORT
  WORD, SIZE, ADR;

TYPE
  XmsTable = POINTER TO TableDesc;
  TableDesc = RECORD
    IleJestPamieci : LONGINT;
    Elems    : CARDINAL;
    xms      : XMSService.XMS_Handle;
    Buf      : ARRAY[0..99] OF WORD;
    PrevIdx  : CARDINAL;
    StartIdx : CARDINAL;
  END;

PROCEDURE AssignNil( VAR h : XmsTable );
  BEGIN
    h := NIL;
  END AssignNil;


PROCEDURE Size( h : XmsTable ) : CARDINAL;
  BEGIN
    RETURN h^.Elems DIV 2;
  END Size;

PROCEDURE IsValid( VAR h : XmsTable ) : BOOLEAN;
  BEGIN
    RETURN h # NIL;
  END IsValid;

PROCEDURE Allocate( NrOfElems : CARDINAL ) : XmsTable;
  VAR
    t : XmsTable;
  BEGIN
    NEW( t );
    WITH t^ DO
      Elems := NrOfElems;
      IleJestPamieci := VAL( LONGINT, NrOfElems ) * 2L+4L+
                        VAL( LONGINT, SIZE( Buf )); (* na wypadek, gdyby ostatni bajt byl jedeynyw w ostatnim buforze*)
      xms := XMSService.Allocate(  IleJestPamieci );
      PrevIdx := MAX( CARDINAL );
    END;
    RETURN t;
  END Allocate;

PROCEDURE Deallocate( VAR h : XmsTable );
  BEGIN
    IF h # NIL THEN
      XMSService.Deallocate( h^.xms );
      DISPOSE( h );
      h := NIL;
    END;
  END Deallocate;

PROCEDURE PutElem( h : XmsTable; AtIdx : CARDINAL; val : WORD );
  VAR
    Part : CARDINAL;
  BEGIN
    WITH h^ DO
      Part := AtIdx DIV ( SIZE(Buf) DIV 2 );
      Map( h, Part );
      Buf[AtIdx-StartIdx] := val;
    END;
  END PutElem;

PROCEDURE GetElem( h : XmsTable; AtIdx : CARDINAL ) : WORD ;
  VAR
    Part : CARDINAL;
  BEGIN
    IF (h = NIL) THEN
      RETURN WORD(MIN(INTEGER));
    ELSE
      WITH h^ DO
        Part := AtIdx DIV ( SIZE(Buf) DIV 2 );
        Map( h, Part );
        RETURN Buf[AtIdx-StartIdx];
      END;
    END;
  END GetElem;

  PROCEDURE Map(     t  : XmsTable;
                     cp : CARDINAL );
  VAR
    from, to : XMSService.ExtMemPtr;
  BEGIN
    WITH t^ DO
      IF PrevIdx # cp THEN
        IF PrevIdx # MAX( CARDINAL ) THEN
          from.RealPtr := ADR( Buf );
          to.ProtectedPtr := VAL( LONGINT, PrevIdx )*VAL( LONGINT, SIZE(Buf) );
          XMSService.Copy( 0, from, xms, to, SIZE(Buf) );
        END;
        to.RealPtr := ADR( Buf );
        from.ProtectedPtr := VAL( LONGINT, cp )*VAL( LONGINT, SIZE(Buf) );
        XMSService.Copy( xms, from, 0, to, SIZE(Buf) );
        PrevIdx := cp;
        StartIdx := cp*(SIZE(Buf) DIV 2 );
      END;
    END;
  END Map;

END XMSTable.



