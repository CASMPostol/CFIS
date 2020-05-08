del *.bak
del *.db?
del *.obj
del *.$$$
rar u samolot *.def *.mod *.pr *.bat *.ini *.dat *.lib *.dll *.!!!
rem rar u samolot symulator.exe database.exe
rem rar u samolot *.doc 
rem pkzip -u -ex samolot *.def *.mod *.pr *.bat *.ini *.dat *.lib *.dll *.!!!
rem pkzip -u -ex samolot symulator.exe database.exe
rem pkzip -ex samolot *.doc 
if [%1] == [] goto dyskB
copy samolot.rar %1
goto end
:dyskB
copy samolot.rar b:
:end
