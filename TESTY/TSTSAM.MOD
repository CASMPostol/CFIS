MODULE Sam;
IMPORT RTK, DataAcquisition, VORRadial, RTSMain, Terminal, MANAGER, Timer;
IMPORT DebugPMD;

VAR
   ch : CHAR;

  PROCEDURE Main;
  VAR
     sc,pos : INTEGER; (* scale, pos = -1,0,1 *)
  BEGIN
  sc := 10000;
  pos := 0;
  LOOP
    Timer.Wait(1000);
    VORRadial.Show(sc,pos);
    sc := 0;
    pos := 0;
    IF Terminal.KeyPressed() THEN
      Terminal.Read(ch);
      IF ch=33C THEN
        RTSMain.Terminate(RTSMain.Stopped);
      ELSIF ch=0C THEN
        Terminal.Read(ch);
        IF ch=CHR(48H) THEN (* up *)
          sc := 1;
        ELSIF ch=CHR(50H) THEN (* down *)
          sc := -1;
        ELSIF ch=CHR(4BH) THEN (* left *)
          pos := -1;
        ELSIF ch=CHR(4DH) THEN (* right *)
          pos := 1;

        END;
        
      END;
    END;
  END;  
END Main;   
   
BEGIN
  MANAGER.STARTPROCESS(Main,400H,0);
  Timer.Wait(0FFFFH);
END Sam.
