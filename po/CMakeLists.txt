#
# po/CMakeLists.txt
# Copyright (C) 2012, 2013, Valama development team
#
# Valama is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Valama is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program.  If not, see <http://www.gnu.org/licenses/>.
#

include(Gettext)
if(XGETTEXT_FOUND)
  set(potfile "${CMAKE_CURRENT_SOURCE_DIR}/maya-calendar.pot")
  gettext_create_pot("${potfile}"
    SRCFILES
      "../core/Backends/*.vala"
      "../core/*.vala"
      "../core/Model/*.vala"
      "../core/Settings/*.vala"
      "../core/Utils/*.vala"
      "../daemon/*.vala"
      "../plugins/CalDAV/*.vala"
      "../plugins/Google/*.vala"
      "../src/EventEdition/*.vala"
      "../src/EventParser/*.vala"
      "../src/EventParser/Parsers/ParserDe.vala"
      "../src/EventParser/Parsers/*.vala"
      "../src/Grid/*.vala"
      "../src/Model/*.vala"
      "../src/SourceDialog/*.vala"
      "../src/Widgets/*.vala"
      "../src/*.vala"
    DESKTOPFILES
      ${CMAKE_BINARY_DIR}/data/${CMAKE_PROJECT_NAME}.desktop.in
    GSETTINGSFILES
        ${CMAKE_BINARY_DIR}/data/${CMAKE_PROJECT_NAME}.appdata.xml.in
  )
  option(UPDATE_PO "Update .po files." ON)
  if(UPDATE_PO)
    set(NOUPDATE)
  else()
    set(NOUPDATE "NOUPDATE")
  endif()
  option(INSTALL_INTLTOOL_MERGED "Copy intltoolized files into source tree." OFF)
  if(INSTALL_INTLTOOL_MERGED)
    set(DESKTOPFILES_INSTALL "DESKTOPFILES_INSTALL")
  else()
    set(DESKTOPFILES_INSTALL)
  endif()
  gettext_create_translations("${potfile}" ALL ${NOUPDATE} ${DESKTOPFILES_INSTALL})
endif()

# vim: set ai ts=2 sts=2 et sw=2
