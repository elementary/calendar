prefix=@CMAKE_INSTALL_PREFIX@
exec_prefix=${prefix}
libdir=${prefix}/@CMAKE_INSTALL_LIBDIR@
includedir=${prefix}/@CMAKE_INSTALL_INCLUDEDIR@
 
Name: Calendar
Description: Calendar headers
Version: @CORE_LIB_VERSION@
Libs: -lio.elementary.calendar
Cflags: -I${includedir}/io.elementary.calendar
Requires: gobject-2.0 gthread-2.0 glib-2.0 gio-2.0 gee-0.8 gtk+-3.0 granite libecal-1.2 libical gmodule-2.0
