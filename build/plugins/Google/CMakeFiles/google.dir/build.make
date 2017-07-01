# CMAKE generated file: DO NOT EDIT!
# Generated by "Unix Makefiles" Generator, CMake Version 3.5

# Delete rule output on recipe failure.
.DELETE_ON_ERROR:


#=============================================================================
# Special targets provided by cmake.

# Disable implicit rules so canonical targets will work.
.SUFFIXES:


# Remove some rules from gmake that .SUFFIXES does not remove.
SUFFIXES =

.SUFFIXES: .hpux_make_needs_suffix_list


# Suppress display of executed commands.
$(VERBOSE).SILENT:


# A target that is always out of date.
cmake_force:

.PHONY : cmake_force

#=============================================================================
# Set environment variables for the build.

# The shell in which to execute make rules.
SHELL = /bin/sh

# The CMake executable.
CMAKE_COMMAND = /usr/bin/cmake

# The command to remove a file.
RM = /usr/bin/cmake -E remove -f

# Escaping for special characters.
EQUALS = =

# The top-level source directory on which CMake was run.
CMAKE_SOURCE_DIR = /home/cassidyjames/Projects/elementary/calendar

# The top-level build directory on which CMake was run.
CMAKE_BINARY_DIR = /home/cassidyjames/Projects/elementary/calendar/build

# Include any dependencies generated for this target.
include plugins/Google/CMakeFiles/google.dir/depend.make

# Include the progress variables for this target.
include plugins/Google/CMakeFiles/google.dir/progress.make

# Include the compile flags for this target's objects.
include plugins/Google/CMakeFiles/google.dir/flags.make

plugins/Google/GoogleBackend.c: plugins/Google/google_valac.stamp


plugins/Google/google_valac.stamp: ../plugins/Google/GoogleBackend.vala
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --blue --bold --progress-dir=/home/cassidyjames/Projects/elementary/calendar/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_1) "Generating GoogleBackend.c"
	cd /home/cassidyjames/Projects/elementary/calendar/build/plugins/Google && /usr/bin/valac -C -b /home/cassidyjames/Projects/elementary/calendar/plugins/Google -d /home/cassidyjames/Projects/elementary/calendar/build/plugins/Google --pkg=gconf-2.0 --pkg=gee-0.8 --pkg=gio-2.0 --pkg=granite --pkg=gtk+-3.0 --pkg=libecal-1.2 --pkg=libedataserver-1.2 --pkg=libedataserverui-1.2 --pkg=libical --pkg=libsoup-2.4 --pkg=gmodule-2.0 --pkg=maya-calendar --pkg=libsoup-2.4 --vapidir=/home/cassidyjames/Projects/elementary/calendar/vapi --target-glib=2.32 --thread --vapidir=/home/cassidyjames/Projects/elementary/calendar/build/core -g /home/cassidyjames/Projects/elementary/calendar/plugins/Google/GoogleBackend.vala
	cd /home/cassidyjames/Projects/elementary/calendar/build/plugins/Google && touch /home/cassidyjames/Projects/elementary/calendar/build/plugins/Google/google_valac.stamp

plugins/Google/CMakeFiles/google.dir/GoogleBackend.c.o: plugins/Google/CMakeFiles/google.dir/flags.make
plugins/Google/CMakeFiles/google.dir/GoogleBackend.c.o: plugins/Google/GoogleBackend.c
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/home/cassidyjames/Projects/elementary/calendar/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_2) "Building C object plugins/Google/CMakeFiles/google.dir/GoogleBackend.c.o"
	cd /home/cassidyjames/Projects/elementary/calendar/build/plugins/Google && /usr/bin/cc  $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -o CMakeFiles/google.dir/GoogleBackend.c.o   -c /home/cassidyjames/Projects/elementary/calendar/build/plugins/Google/GoogleBackend.c

plugins/Google/CMakeFiles/google.dir/GoogleBackend.c.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing C source to CMakeFiles/google.dir/GoogleBackend.c.i"
	cd /home/cassidyjames/Projects/elementary/calendar/build/plugins/Google && /usr/bin/cc  $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -E /home/cassidyjames/Projects/elementary/calendar/build/plugins/Google/GoogleBackend.c > CMakeFiles/google.dir/GoogleBackend.c.i

plugins/Google/CMakeFiles/google.dir/GoogleBackend.c.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling C source to assembly CMakeFiles/google.dir/GoogleBackend.c.s"
	cd /home/cassidyjames/Projects/elementary/calendar/build/plugins/Google && /usr/bin/cc  $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -S /home/cassidyjames/Projects/elementary/calendar/build/plugins/Google/GoogleBackend.c -o CMakeFiles/google.dir/GoogleBackend.c.s

plugins/Google/CMakeFiles/google.dir/GoogleBackend.c.o.requires:

.PHONY : plugins/Google/CMakeFiles/google.dir/GoogleBackend.c.o.requires

plugins/Google/CMakeFiles/google.dir/GoogleBackend.c.o.provides: plugins/Google/CMakeFiles/google.dir/GoogleBackend.c.o.requires
	$(MAKE) -f plugins/Google/CMakeFiles/google.dir/build.make plugins/Google/CMakeFiles/google.dir/GoogleBackend.c.o.provides.build
.PHONY : plugins/Google/CMakeFiles/google.dir/GoogleBackend.c.o.provides

plugins/Google/CMakeFiles/google.dir/GoogleBackend.c.o.provides.build: plugins/Google/CMakeFiles/google.dir/GoogleBackend.c.o


# Object files for target google
google_OBJECTS = \
"CMakeFiles/google.dir/GoogleBackend.c.o"

# External object files for target google
google_EXTERNAL_OBJECTS =

plugins/Google/libgoogle.so: plugins/Google/CMakeFiles/google.dir/GoogleBackend.c.o
plugins/Google/libgoogle.so: plugins/Google/CMakeFiles/google.dir/build.make
plugins/Google/libgoogle.so: core/libmaya-calendar.so.0.1
plugins/Google/libgoogle.so: plugins/Google/CMakeFiles/google.dir/link.txt
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --bold --progress-dir=/home/cassidyjames/Projects/elementary/calendar/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_3) "Linking C shared module libgoogle.so"
	cd /home/cassidyjames/Projects/elementary/calendar/build/plugins/Google && $(CMAKE_COMMAND) -E cmake_link_script CMakeFiles/google.dir/link.txt --verbose=$(VERBOSE)

# Rule to build all files generated by this target.
plugins/Google/CMakeFiles/google.dir/build: plugins/Google/libgoogle.so

.PHONY : plugins/Google/CMakeFiles/google.dir/build

plugins/Google/CMakeFiles/google.dir/requires: plugins/Google/CMakeFiles/google.dir/GoogleBackend.c.o.requires

.PHONY : plugins/Google/CMakeFiles/google.dir/requires

plugins/Google/CMakeFiles/google.dir/clean:
	cd /home/cassidyjames/Projects/elementary/calendar/build/plugins/Google && $(CMAKE_COMMAND) -P CMakeFiles/google.dir/cmake_clean.cmake
.PHONY : plugins/Google/CMakeFiles/google.dir/clean

plugins/Google/CMakeFiles/google.dir/depend: plugins/Google/GoogleBackend.c
plugins/Google/CMakeFiles/google.dir/depend: plugins/Google/google_valac.stamp
	cd /home/cassidyjames/Projects/elementary/calendar/build && $(CMAKE_COMMAND) -E cmake_depends "Unix Makefiles" /home/cassidyjames/Projects/elementary/calendar /home/cassidyjames/Projects/elementary/calendar/plugins/Google /home/cassidyjames/Projects/elementary/calendar/build /home/cassidyjames/Projects/elementary/calendar/build/plugins/Google /home/cassidyjames/Projects/elementary/calendar/build/plugins/Google/CMakeFiles/google.dir/DependInfo.cmake --color=$(COLOR)
.PHONY : plugins/Google/CMakeFiles/google.dir/depend

