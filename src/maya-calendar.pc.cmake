prefix=@PREFIX@
exec_prefix=@DOLLAR@{prefix}
libdir=@DOLLAR@{prefix}/lib
includedir=@DOLLAR@{prefix}/include/
 
Name: Maya
Description: Maya headers  
Version: 0.2  
Libs: -lmaya-calendar
Cflags: -I@DOLLAR@{includedir}/maya-calendar
Requires: glib-2.0 gio-2.0 gee-0.8 libpeas-1.0 gtk+-3.0 granite libecalendar-1.2 libedataserver-1.2 libical
