arj u -r -v1440 -ya samolot *.mak *.def *.mod *.asm *.bat *.dib *.bmp *.ini *.cdr 
ARJ U -r -v1440 -ya samolot *.!!! *.PAT *.mnu znaki.pl XMS.* *.lib *.VER
PAUSE WRAZ 1 DYSKIETKE !!!!!!!!!!!
copy samolot.arj a:/v
IF NOT EXIST samolot.a01 GOTO END
PAUSE WRAZ 2 DYSKIETKE !!!!!!!!!!!
copy samolot.a01 a:/v
:END
