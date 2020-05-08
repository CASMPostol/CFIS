MODULE tst_avro;

  FROM RTSMain IMPORT
    Terminate, Status;

FROM CommonTypes IMPORT
   SigNilVal;
   
FROM VORO_avrage IMPORT 
   AVRdescription, OrbitDsc, ClearContainer, AVR10_AddSample, 
  OrbitDscClear;

FROM SpecConv  IMPORT
   AddAngle100;
PROCEDURE Fillin;
VAR
  kat       : INTEGER;
  avr       : OrbitDsc;
  muCont    : AVRdescription;
  katOrb    : INTEGER;
  
  
BEGIN
  katOrb := 0;
  ClearContainer(muCont);
  OrbitDscClear(avr);
  FOR kat := MAX(INTEGER)  TO MIN(INTEGER) BY -25 DO
    AVR10_AddSample(150, katOrb, muCont, avr);
    katOrb := AddAngle100(katOrb, 70);
  END;
END Fillin;

BEGIN
  Fillin;
  Terminate(Stopped);
END tst_avro.
