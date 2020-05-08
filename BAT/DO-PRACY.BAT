del pttemp.*
xdel *.bak/s/n
xdel *.$$$/s/n
REM xdel *.pmd/s/n
DEL *.DAT
DEL *.txt
xdel *.{??/s/n
rem pkzip -u -ex rec -r -P *.def *.mod *.asm *.bat *.dib *.bmp *.ini *.cdr
rem pkzip -u -ex -r -P rec *.ini !!!!!!!!.!!! *.pat
rem pkzip -u -ex -r -P rec znaki.pl
rem copy/v rec.zip b:
rar u -mm -m5 -r rec *.def *.mod *.asm *.bat *.dib *.bmp *.cdr *.mnu *.VER TRTS\*.* SYM_DB.SRC\SYM_DAT\*.*
rar u -mm -m5 -r -xobl*.ini rec *.ini *.!!! *.pat znaki.pl rtsmo*.sym xms.obj xms.sym *.LIB *.mak *.PR database.exe
copy/v rec.rar a:
