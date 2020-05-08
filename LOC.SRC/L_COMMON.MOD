(*.F- *)
(**********************************************************************
|  Title   : LOC Common types
|  Author  : M.Postol
|  System  : LOGITECH MODULA-2/86
|  History :
|
|  Copyright (C), CAS LODZ POLAND.
|  TEL: 42' 862 547, 42' 87 80 44 FAX/TEL: 42' 84 48 40
|
**********************************************************************)
(*.F+ *)

IMPLEMENTATION MODULE L_CommonTypes;

  FROM CommonTypes IMPORT
    SigNilVal, DisNilVal;

  FROM SYSTEM IMPORT
    WORD;

  PROCEDURE SuccNumPunktu
            (    pt : NumPunktu ) : NumPunktu;

  BEGIN
    RETURN VAL(NumPunktu, ORD(pt) + 1);
  END SuccNumPunktu;

  PROCEDURE PrvNumPunktu
            (    pt : NumPunktu ) : NumPunktu;

  BEGIN
    RETURN VAL(NumPunktu, ORD(pt) - 1);
  END PrvNumPunktu;

  PROCEDURE SuccNumStrefy
            (    pt : NumStrefy ) : NumStrefy;

  BEGIN
    RETURN VAL(NumStrefy, ORD(pt) + 1);
  END SuccNumStrefy;

  PROCEDURE GetNumStrefy
            (    pt : NumPunktu ) : NumStrefy;

  BEGIN
    RETURN VAL(NumStrefy, ORD(pt));
  END GetNumStrefy;

  PROCEDURE GetNumStrefyEp
            (    endPt : NumPunktu ) : NumStrefy;

  BEGIN
    RETURN VAL(NumStrefy, ORD(endPt) - 1);
  END GetNumStrefyEp;

  PROCEDURE GetZoneBoundPt
            ( VAR begPT     : NumPunktu;
              VAR endPt     : NumPunktu;
                  aktStrefa : NumStrefy );

  BEGIN
    begPT := VAL(NumPunktu, ORD(aktStrefa));
    endPt := VAL(NumPunktu, ORD(aktStrefa) + 1);
  END GetZoneBoundPt;

  PROCEDURE CzyToJestPromien
            (    procedure : ProceduraT ) : BOOLEAN;

  BEGIN
    RETURN (procedure < pSzer_i_Osi_pB) OR (procedure = pMarker) OR
    (procedure = pRownowagaModulacji) OR (procedure = pFazowanie);
  END CzyToJestPromien;

  PROCEDURE InitSignalDsc
            ( VAR signal : SignalDsc );

  BEGIN
    WITH signal DO
      val := SigNilVal;
      pos := WORD(DisNilVal);
    END (* with signal *);
  END InitSignalDsc;

END L_CommonTypes.
