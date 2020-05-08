IMPLEMENTATION MODULE ErrorMess[0]; (* priorytet po to, zeby mogl przerwac
                                     *  jak sie cos zapetli
                                     *)
IMPORT
  MANAGER, Timer, RTSMain, Strings;
FROM Messages IMPORT Message, NewMessage, Display, Acknowledge,
     AcknowledgeFirst;
FROM StdIO IMPORT
  sprintf;


  PROCEDURE MyErrorHand;
  TYPE 
     ErrT = RECORD
              Nr,blad : CARDINAL;
            END;
  VAR
    Last : MANAGER.ProcessPtr;
    bb   : ErrT; 
    ErrMess : Message;                       
  VAR
    str : ARRAY [0..50] OF CHAR;
                              
  BEGIN
    Last := NIL;
    LOOP
      MANAGER.WAITC( MANAGER.ErrorHandler );
      (* 
      IF MANAGER.ErrorQueue = Last THEN (* Ctrl+Break *)
        Timer.Wait( Timer.TInOneSecond());
        RTSMain.Terminate( RTSMain.Warning );
      END;
      *)
      bb.blad := ORD(MANAGER.ErrorQueue^.ProcessStatus);
      bb.Nr   := MANAGER.ErrorQueue^.OrdNr;
      sprintf( str, "Process nr: %d nie zyje! Przyczyna: %d", bb );
      NewMessage(ErrMess,str,BITSET(5555H));
      Display( ErrMess );
      Last := MANAGER.ErrorQueue;
    END;
  END MyErrorHand;

BEGIN
  MANAGER.STARTPROCESS(MyErrorHand,600H,0);
END ErrorMess.
