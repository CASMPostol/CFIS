
MODULE ArincTs;

FROM ARINC IMPORT 
  ShortCardinal, Data, ChannelNu,  ReInitialize,  WriteTXParity, 
  WriteTXChannel, WriteTXLabel, WriteTXData, WriteTXRate, WriteKillTime, 
  WriteCardMode, ReadConfiguration, ReadTXSlot, ReadRXSlot;

  VAR
    disableMask : BITSET;
    speedMask   : BITSET;
    fineMode    : BOOLEAN;
    killTime    : CARDINAL;
    slot        : ShortCardinal;
    label       : ShortCardinal;
    data        : Data;
    rate        : CARDINAL;
    chan        : ChannelNu;
    mode        : ShortCardinal;

BEGIN
  IF NOT ReadConfiguration( disableMask, speedMask, fineMode, killTime )
  THEN
    killTime := killTime;
  END (* if *);
  slot := 1;
  IF NOT ReadTXSlot( slot, label, data, rate, chan )
  THEN
    killTime := killTime;
  END (* if *);
  IF NOT ReadRXSlot( slot, label, data, rate, chan, mode )
  THEN
    killTime := killTime;
  END (* if *);

END ArincTs.
