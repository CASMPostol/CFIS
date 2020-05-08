del pttemp.*
xdel cmdfile.bat/s/n
xdel *.bak/s/n
xdel *.$$$/s/n
xdel *.{??/s/n
xdel *.FM?/s/n
xdel *.LST/s/n
xdel *.DEC/s/n
xdel *.txt/s/n
xdel *.lst/s/n
xdel cmdfile.bat/s/n
ARJ u -r -xobl*.ini pmd_ARCH *.def *.mod *.ini *.bat *.mnu
ARJ u -r  pmd_ARCH *.xrm *.map *.exe *.ref
ARJ u -r  dump *.PMD *.P0? *.P1? *.P2? *.P3?
