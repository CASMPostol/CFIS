del *.bak
del *.$$$
pkzip -ex tvision *.de? *.mod *.pr *.bat *.a
rem pkzip -ex tvision *.def
if [%1] == [] goto dyskB
copy tvision.zip %1
goto end
:dyskB
copy tvision.zip b:
:end
