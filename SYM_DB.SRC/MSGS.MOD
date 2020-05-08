IMPLEMENTATION MODULE Msgs;

FROM MsgBox IMPORT
  MsgOption, MsgOptions, MessageBox;

  PROCEDURE Poza_100NM();
  BEGIN
    MessageBox( "Samolot wylecial poza ograniczenie (100nm)",
                NIL,
                MsgOptions{ mfInformation, mfOKButton } );
  END Poza_100NM;

END Msgs.
