MODULE tst_avro;

  FROM RTSMain IMPORT
    Terminate, Status;

FROM VORO_avrage IMPORT 
  AVRdescription, PartIdx, ClearContainer, AddSample;
TYPE
  AvrOrbitDsc =
      ARRAY PartIdx OF REAL;
VAR

PROCEDURE Fillin;
VAR
  kat : INTEGER;
  muCont :  AVRdescription;
  avr : AvrOrbitDsc;
BEGIN
  ClearContainer(muCont);
  FOR kat := 0 TO 35 DO
    avr[ kat ] := 999.0;
  END;
  FOR kat := +18000 TO -18000 BY -57 DO
    IF AddSample(kat + 100, kat, muCont) THEN
      WITH muCont  DO
        avr[index] := srcSum / FLOAT(samples);
      END;
    END;
  END;
END Fillin;

BEGIN
  Fillin;
  Terminate(Stopped);
END tst_avro.
