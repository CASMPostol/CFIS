MODULE DGHTest;

IMPORT DebugPMD;

FROM DGHIni IMPORT 
  SignalNames,signals;

FROM DGHInterface IMPORT 
  DtaSignType, GetCurrDataSign, WaitForNewData, TurnOff, TurnOn, GetAnalogVal,
  GetBinaryVal, SetAnalogVal, SetBinaryVal;

FROM Terminal IMPORT
  Read, KeyPressed, ReadAgain, ReadString, Write, WriteString, WriteLn;

FROM BitWordOps IMPORT
  WordXor;

FROM InOut IMPORT
  WriteCard, WriteInt;

IMPORT RTSMain, DGHInterface, Random, InOut;

FROM Timer IMPORT
  Wait;

VAR
  analog 	: INTEGER;
  analogOut	: INTEGER;
  binary	: BITSET;
  binaryOut	: CARDINAL;
  DataSign1,
  DataSign2,
  DataSign3,
  DataSign4 	: DtaSignType;
  digi 		: CARDINAL;
  counter	: INTEGER;

BEGIN (* DGHTest *)
  analog :=0;
  binary := {};
  digi := 0;
  TurnOn(MODforLOCa);
  TurnOn(CockpitCPLOCNeedle);
  TurnOn(OutMKRb);
  TurnOn(CockpitDisplay);
  DataSign1 := GetCurrDataSign();
  DataSign2 := DataSign1;
  DataSign3 := DataSign1;
  DataSign4 := DataSign1;
(*  Random.RandomInit(100);*)
  counter := 0;
  analogOut := +9999;
  REPEAT
    INC(counter);
    IF counter = 20 THEN
      counter := 0;
      IF analogOut > 100  THEN
        analogOut := 0;
      ELSE
        analogOut := +9999;
      END (* if *);
    END;
    WriteLn;
    WriteString("AOut = ");
    WriteInt(analogOut, 4);
    WriteString("     AIn = ");
    (*
    analogOut := 10000 * Random.RandomReal();
    *)
    SetAnalogVal(CockpitCPLOCNeedle, analogOut, DataSign1);
    WaitForNewData(DataSign1);
    WaitForNewData(DataSign2);
    IF GetAnalogVal(MODforLOCa, analog, DataSign2) THEN
      WriteInt(analog, 4);
    ELSE 
      WriteString('****');
    END;
    binary := BITSET(digi);
    WaitForNewData(DataSign3);
    SetBinaryVal(CockpitDisplay, binary, DataSign3);
    WriteString("          DOut = ");
    WriteCard(digi, 3);
    WriteString("     DIn = ");
    WaitForNewData(DataSign4);
    IF GetBinaryVal(OutMKRb, binary, DataSign4) THEN
      binaryOut:=CARDINAL(WordXor(binary, 081FFH));
      WriteCard(binaryOut, 3);
    ELSE 
      WriteString('***');
    END;
    INC(digi);
    IF digi>19 THEN
      digi:=0;
    END;
  UNTIL  KeyPressed();
  RTSMain.Terminate(RTSMain.Stopped);
END DGHTest.