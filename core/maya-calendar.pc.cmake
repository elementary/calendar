prefix=@CMAKE_INSTALL_PREFIX@
exec_prefix=${prefix}
libdir=${prefix}/@CMAKE_INSTALL_LIBDIR@
includedir=${prefix}/@CMAKE_INSTALL_INCLUDEDIR@
 
Name: Maya
Description: Maya headers
Version: @CORE_LIB_VERSION@
Libs: -lmaya-calendar
Cflags: -I${includedir}/maya-calendar
Requires: gobject-2.0 gthread-2.0 glib-2.0 gio-2.0 gee-0.8 gtk+-3.0 granite libecal-1.2 libical gmodule-2.0
