if(NOT DEFINED PACKAGE_VENDOR)
    set(PACKAGE_VENDOR NextGIS)
endif()

if(NOT DEFINED PACKAGE_BUGREPORT)
    set(PACKAGE_BUGREPORT info@nextgis.com)
endif()


if(OSX_FRAMEWORK AND (BUILD_SHARED_LIBS OR BUILD_STATIC_LIBS))
  message(FATAL_ERROR "Only OSX_FRAMEWORK key or any or both BUILD_SHARED_LIBS
                       and BUILD_STATIC_LIBS keys are permitted")
endif()

if(OSX_FRAMEWORK)
  set(INSTALL_BIN_DIR "bin" CACHE INTERNAL "Installation directory for executables" FORCE)
  set(INSTALL_LIB_DIR "Library/Frameworks" CACHE INTERNAL "Installation directory for libraries" FORCE)
  set(INSTALL_INC_DIR "${INSTALL_LIB_DIR}/${PROJECT_NAME}.framework/Headers" CACHE INTERNAL "Installation directory for headers" FORCE)
  set(INSTALL_CMAKECONF_DIR ${INSTALL_LIB_DIR}/${PROJECT_NAME}.framework/Resources/CMake CACHE INTERNAL "Installation directory for cmake config files" FORCE)
  set(INSTALL_MAN_DIR ${INSTALL_LIB_DIR}/${PROJECT_NAME}.framework/Versions/${FRAMEWORK_VERSION}/Resources/man CACHE INTERNAL "Man files directory" FORCE)
  set(INSTALL_DOC_DIR ${INSTALL_LIB_DIR}/${PROJECT_NAME}.framework/Versions/${FRAMEWORK_VERSION}/Resources/doc CACHE INTERNAL "Documents files directory" FORCE)
  set(SKIP_INSTALL_HEADERS ON)
  set(SKIP_INSTALL_EXECUTABLES ON)
  set(SKIP_INSTALL_FILES ON)
  set(SKIP_INSTALL_EXPORT ON)
  set(BUILD_SHARED_LIBS ON)
  set(CMAKE_MACOSX_RPATH ON)
else()
  include(GNUInstallDirs)

  set(INSTALL_BIN_DIR ${CMAKE_INSTALL_BINDIR} CACHE INTERNAL "Installation directory for executables" FORCE)
  set(INSTALL_LIB_DIR ${CMAKE_INSTALL_LIBDIR} CACHE INTERNAL "Installation directory for libraries" FORCE)
  set(INSTALL_INC_DIR ${CMAKE_INSTALL_INCLUDEDIR} CACHE INTERNAL "Installation directory for headers" FORCE)
  set(INSTALL_CMAKECONF_DIR ${CMAKE_INSTALL_DATADIR}/${PROJECT_NAME}/CMake CACHE INTERNAL "Installation directory for cmake config files" FORCE)
  set(INSTALL_MAN_DIR ${CMAKE_INSTALL_MANDIR} CACHE INTERNAL "Man files directory" FORCE)
  set(INSTALL_DOC_DIR ${CMAKE_INSTALL_DOCDIR} CACHE INTERNAL "Installation directory for doc pages" FORCE)
endif()


include(CheckCCompilerFlag)
include(CheckCSourceCompiles)
include(CheckIncludeFile)
include(CheckTypeSize)
include(CheckFunctionExists)

if(CMAKE_GENERATOR_TOOLSET MATCHES "v([0-9]+)_xp")
    add_definitions(-D_WIN32_WINNT=0x0501)
endif()

# These are annoyingly verbose, produce false positives or don't work
# nicely with all supported compiler versions, so are disabled unless
# explicitly enabled.
option(extra-warnings "Enable extra compiler warnings" OFF)

# This will cause the compiler to fail when an error occurs.
option(fatal-warnings "Compiler warnings are errors" OFF)

# Check if the compiler supports each of the following additional
# flags, and enable them if supported.  This greatly improves the
# quality of the build by checking for a number of common problems,
# some of which are quite serious.
if(CMAKE_C_COMPILER_ID STREQUAL "GNU" OR
   CMAKE_C_COMPILER_ID MATCHES "Clang")
  set(test_flags
      -Wall
      -Winline
      -W
      -Wformat-security
      -Wpointer-arith
      -Wdisabled-optimization
      -Wno-unknown-pragmas
      -Wdeclaration-after-statement
      -fstrict-aliasing)
  if(extra-warnings)
    list(APPEND test_flags
        -Wfloat-equal
        -Wmissing-prototypes
        -Wunreachable-code)
  endif()
  if(fatal-warnings)
    list(APPEND test_flags
         -Werror)
  endif()
elseif(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
  set(test_flags)
  if(extra-warnings)
    list(APPEND test_flags
         /W4)
  else()
    list(APPEND test_flags
         /W3)
  endif()
  if (fatal-warnings)
    list(APPEND test_flags
         /WX)
  endif()
endif()

foreach(flag ${test_flags})
  string(REGEX REPLACE "[^A-Za-z0-9]" "_" flag_var "${flag}")
  set(test_c_flag "C_FLAG${flag_var}")
  CHECK_C_COMPILER_FLAG(${flag} "${test_c_flag}")
  if (${test_c_flag})
     set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${flag}")
  endif (${test_c_flag})
endforeach(flag ${test_flags})

if(MSVC)
    set(CMAKE_DEBUG_POSTFIX "d")
endif()

option(ld-version-script "Enable linker version script" ON)
# Check if LD supports linker scripts.
file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/conftest.map" "VERS_1 {
        global: sym;
};

VERS_2 {
        global: sym;
} VERS_1;
")
set(CMAKE_REQUIRED_FLAGS_SAVE ${CMAKE_REQUIRED_FLAGS})
set(CMAKE_REQUIRED_FLAGS ${CMAKE_REQUIRED_FLAGS} "-Wl,--version-script=${CMAKE_CURRENT_BINARY_DIR}/conftest.map")
check_c_source_compiles("int main(void){return 0;}" HAVE_LD_VERSION_SCRIPT)
set(CMAKE_REQUIRED_FLAGS ${CMAKE_REQUIRED_FLAGS_SAVE})
file(REMOVE "${CMAKE_CURRENT_BINARY_DIR}/conftest.map")
if (ld-version-script AND HAVE_LD_VERSION_SCRIPT)
  set(HAVE_LD_VERSION_SCRIPT TRUE)
else()
  set(HAVE_LD_VERSION_SCRIPT FALSE)
endif()

# Find libm, if available
find_library(M_LIBRARY m)

check_include_file(assert.h    HAVE_ASSERT_H)
check_include_file(dlfcn.h     HAVE_DLFCN_H)
check_include_file(fcntl.h     HAVE_FCNTL_H)
check_include_file(inttypes.h  HAVE_INTTYPES_H)
check_include_file(io.h        HAVE_IO_H)
check_include_file(limits.h    HAVE_LIMITS_H)
check_include_file(malloc.h    HAVE_MALLOC_H)
check_include_file(memory.h    HAVE_MEMORY_H)
check_include_file(search.h    HAVE_SEARCH_H)
check_include_file(stdint.h    HAVE_STDINT_H)
check_include_file(string.h    HAVE_STRING_H)
check_include_file(strings.h   HAVE_STRINGS_H)
check_include_file(sys/time.h  HAVE_SYS_TIME_H)
check_include_file(sys/types.h HAVE_SYS_TYPES_H)
check_include_file(unistd.h    HAVE_UNISTD_H)

# Inspired from /usr/share/autoconf/autoconf/c.m4
foreach(inline_keyword "inline" "__inline__" "__inline")
  if(NOT DEFINED C_INLINE)
    set(CMAKE_REQUIRED_DEFINITIONS_SAVE ${CMAKE_REQUIRED_DEFINITIONS})
    set(CMAKE_REQUIRED_DEFINITIONS ${CMAKE_REQUIRED_DEFINITIONS}
        "-Dinline=${inline_keyword}")
    check_c_source_compiles("
        typedef int foo_t;
        static inline foo_t static_foo() {return 0;}
        foo_t foo(){return 0;}
        int main(int argc, char *argv[]) {return 0;}"
      C_HAS_${inline_keyword})
    set(CMAKE_REQUIRED_DEFINITIONS ${CMAKE_REQUIRED_DEFINITIONS_SAVE})
    if(C_HAS_${inline_keyword})
      set(C_INLINE TRUE)
      set(INLINE_KEYWORD "${inline_keyword}")
    endif()
 endif()
endforeach()
if(NOT DEFINED C_INLINE)
  set(INLINE_KEYWORD)
endif()

# off_t and size_t checks omitted; not clear they are used at all
# Are off_t and size_t checks strictly necessary?

# Check if sys/time.h and time.h allow use together
check_c_source_compiles("
#include <sys/time.h>
#include <time.h>
int main(void){return 0;}"
  TIME_WITH_SYS_TIME)

# Check if struct tm is in sys/time.h
check_c_source_compiles("
#include <sys/types.h>
#include <time.h>

int main(void){
  struct tm tm;
  int *p = &tm.tm_sec;
  return !p;
}"
  TM_IN_SYS_TIME)

# Check type sizes
# NOTE: Could be replaced with C99 <stdint.h>
check_type_size("signed short" SIZEOF_SIGNED_SHORT)
check_type_size("unsigned short" SIZEOF_UNSIGNED_SHORT)
check_type_size("signed int" SIZEOF_SIGNED_INT)
check_type_size("unsigned int" SIZEOF_UNSIGNED_INT)
check_type_size("signed long" SIZEOF_SIGNED_LONG)
check_type_size("unsigned long" SIZEOF_UNSIGNED_LONG)
check_type_size("signed long long" SIZEOF_SIGNED_LONG_LONG)
check_type_size("unsigned long long" SIZEOF_UNSIGNED_LONG_LONG)
check_type_size("unsigned char *" SIZEOF_UNSIGNED_CHAR_P)

set(CMAKE_EXTRA_INCLUDE_FILES_SAVE ${CMAKE_EXTRA_INCLUDE_FILES})
set(CMAKE_EXTRA_INCLUDE_FILES ${CMAKE_EXTRA_INCLUDE_FILES} "stddef.h")
check_type_size("size_t" SIZEOF_SIZE_T)
check_type_size("ptrdiff_t" SIZEOF_PTRDIFF_T)
set(CMAKE_EXTRA_INCLUDE_FILES ${CMAKE_EXTRA_INCLUDE_FILES_SAVE})

macro(report_values)
  if(VERBOSE_OUTPUT)
  foreach(val ${ARGV})
    message(STATUS "${val} set to ${${val}}")
  endforeach()
  endif()
endmacro()

set(TIFF_INT8_T "signed char")
set(TIFF_UINT8_T "unsigned char")

set(TIFF_INT16_T "signed short")
set(TIFF_UINT16_T "unsigned short")

if(SIZEOF_SIGNED_INT EQUAL 4)
  set(TIFF_INT32_T "signed int")
  set(TIFF_INT32_FORMAT "%d")
elseif(SIZEOF_SIGNED_LONG EQUAL 4)
  set(TIFF_INT32_T "signed long")
  set(TIFF_INT32_FORMAT "%ld")
endif()

if(SIZEOF_UNSIGNED_INT EQUAL 4)
  set(TIFF_UINT32_T "unsigned int")
  set(TIFF_UINT32_FORMAT "%u")
elseif(SIZEOF_UNSIGNED_LONG EQUAL 4)
  set(TIFF_UINT32_T "unsigned long")
  set(TIFF_UINT32_FORMAT "%lu")
endif()

if(SIZEOF_SIGNED_LONG EQUAL 8)
  set(TIFF_INT64_T "signed long")
  set(TIFF_INT64_FORMAT "%ld")
elseif(SIZEOF_SIGNED_LONG_LONG EQUAL 8)
  set(TIFF_INT64_T "signed long long")
  if (MINGW)
    set(TIFF_INT64_FORMAT "%I64d")
  else()
    set(TIFF_INT64_FORMAT "%lld")
  endif()
endif()

if(SIZEOF_UNSIGNED_LONG EQUAL 8)
  set(TIFF_UINT64_T "unsigned long")
  set(TIFF_UINT64_FORMAT "%lu")
elseif(SIZEOF_UNSIGNED_LONG_LONG EQUAL 8)
  set(TIFF_UINT64_T "unsigned long long")
  if (MINGW)
    set(TIFF_UINT64_FORMAT "%I64u")
  else()
    set(TIFF_UINT64_FORMAT "%llu")
  endif()
endif()

if(SIZEOF_UNSIGNED_INT EQUAL SIZEOF_SIZE_T)
  set(TIFF_SIZE_T "unsigned int")
  set(TIFF_SIZE_FORMAT "%u")
elseif(SIZEOF_UNSIGNED_LONG EQUAL SIZEOF_SIZE_T)
  set(TIFF_SIZE_T "unsigned long")
  set(TIFF_SIZE_FORMAT "%lu")
elseif(SIZEOF_UNSIGNED_LONG_LONG EQUAL SIZEOF_SIZE_T)
  set(TIFF_SIZE_T "unsigned long")
  if (MINGW)
    set(TIFF_SIZE_FORMAT "%I64u")
  else()
    set(TIFF_SIZE_FORMAT "%llu")
  endif()
endif()

if(SIZEOF_SIGNED_INT EQUAL SIZEOF_UNSIGNED_CHAR_P)
  set(TIFF_SSIZE_T "signed int")
  set(TIFF_SSIZE_FORMAT "%d")
elseif(SIZEOF_SIGNED_LONG EQUAL SIZEOF_UNSIGNED_CHAR_P)
  set(TIFF_SSIZE_T "signed long")
  set(TIFF_SSIZE_FORMAT "%ld")
elseif(SIZEOF_SIGNED_LONG_LONG EQUAL SIZEOF_UNSIGNED_CHAR_P)
  set(TIFF_SSIZE_T "signed long long")
  if (MINGW)
    set(TIFF_SSIZE_FORMAT "%I64d")
  else()
    set(TIFF_SSIZE_FORMAT "%lld")
  endif()
endif()

if(NOT SIZEOF_PTRDIFF_T)
  set(TIFF_PTRDIFF_T "${TIFF_SSIZE_T}")
  set(TIFF_PTRDIFF_FORMAT "${SSIZE_FORMAT}")
else()
  set(TIFF_PTRDIFF_T "ptrdiff_t")
  set(TIFF_PTRDIFF_FORMAT "%ld")
endif()

#report_values(TIFF_INT8_T TIFF_INT8_FORMAT
#              TIFF_UINT8_T TIFF_UINT8_FORMAT
#              TIFF_INT16_T TIFF_INT16_FORMAT
#              TIFF_UINT16_T TIFF_UINT16_FORMAT
#              TIFF_INT32_T TIFF_INT32_FORMAT
#              TIFF_UINT32_T TIFF_UINT32_FORMAT
#              TIFF_INT64_T TIFF_INT64_FORMAT
#              TIFF_UINT64_T TIFF_UINT64_FORMAT
#              TIFF_SSIZE_T TIFF_SSIZE_FORMAT
#              TIFF_PTRDIFF_T TIFF_PTRDIFF_FORMAT)

# Nonstandard int types
check_type_size(INT8 int8)
set(HAVE_INT8 ${INT8})
check_type_size(INT16 int16)
set(HAVE_INT16 ${INT16})
check_type_size(INT32 int32)
set(HAVE_INT32 ${INT32})

# Check functions
set(CMAKE_REQUIRED_LIBRARIES_SAVE ${CMAKE_REQUIRED_LIBRARIES})
set(CMAKE_REQUIRED_LIBRARIES ${CMAKE_REQUIRED_LIBRARIES} ${M_LIBRARY})
check_function_exists(floor HAVE_FLOOR)
check_function_exists(pow   HAVE_POW)
check_function_exists(sqrt  HAVE_SQRT)
set(CMAKE_REQUIRED_LIBRARIES ${CMAKE_REQUIRED_LIBRARIES_SAVE})

check_function_exists(isascii    HAVE_ISASCII)
check_function_exists(memmove    HAVE_MEMMOVE)
check_function_exists(memset     HAVE_MEMSET)
check_function_exists(mmap       HAVE_MMAP)
check_function_exists(setmode    HAVE_SETMODE)
check_function_exists(strcasecmp HAVE_STRCASECMP)
check_function_exists(strchr     HAVE_STRCHR)
check_function_exists(strrchr    HAVE_STRRCHR)
check_function_exists(strstr     HAVE_STRSTR)
check_function_exists(strtol     HAVE_STRTOL)
check_function_exists(strtol     HAVE_STRTOUL)
check_function_exists(strtoull   HAVE_STRTOULL)
check_function_exists(getopt     HAVE_GETOPT)
check_function_exists(lfind      HAVE_LFIND)

# May be inlined, so check it compiles:
check_c_source_compiles("
#include <stdio.h>
int main(void) {
  char buf[10];
  snprintf(buf, 10, \"Test %d\", 1);
  return 0;
}"
  HAVE_SNPRINTF)

if(NOT HAVE_SNPRINTF)
  add_definitions(-DNEED_LIBPORT)
endif()

# CPU bit order
set(fillorder FILLORDER_MSB2LSB)
if(CMAKE_HOST_SYSTEM_PROCESSOR MATCHES "i.*86.*" OR
   CMAKE_HOST_SYSTEM_PROCESSOR MATCHES "amd64.*" OR
   CMAKE_HOST_SYSTEM_PROCESSOR MATCHES "x86_64.*")
  set(fillorder FILLORDER_LSB2MSB)
endif()
set(HOST_FILLORDER ${fillorder} CACHE STRING "Native CPU bit order")
mark_as_advanced(HOST_FILLORDER)

# CPU endianness
include(TestBigEndian)
test_big_endian(bigendian)
if (bigendian)
  set(bigendian ON)
else()
  set(bigendian OFF)
endif()
set(HOST_BIG_ENDIAN ${bigendian} CACHE STRING "Native CPU bit order")
mark_as_advanced(HOST_BIG_ENDIAN)
if (HOST_BIG_ENDIAN)
  set(HOST_BIG_ENDIAN 1)
else()
  set(HOST_BIG_ENDIAN 0)
endif()

# IEEE floating point
set(HAVE_IEEEFP 1 CACHE STRING "IEEE floating point is available")
mark_as_advanced(HAVE_IEEEFP)

report_values(CMAKE_HOST_SYSTEM_PROCESSOR HOST_FILLORDER
              HOST_BIG_ENDIAN HAVE_IEEEFP)

# C++ support
option(cxx "Enable C++ stream API building (requires C++ compiler)" ON)
set(CXX_SUPPORT FALSE)
if (cxx)
  enable_language(CXX)
  set(CXX_SUPPORT TRUE)
endif()

# OpenGL and GLUT
find_package(OpenGL)
find_package(GLUT)
set(HAVE_OPENGL FALSE)
if(OPENGL_FOUND AND OPENGL_GLU_FOUND AND GLUT_FOUND)
  set(HAVE_OPENGL TRUE)
endif()
# Purely to satisfy the generated headers:
check_include_file(GL/gl.h HAVE_GL_GL_H)
check_include_file(GL/glu.h HAVE_GL_GLU_H)
check_include_file(GL/glut.h HAVE_GL_GLUT_H)
check_include_file(GLUT/glut.h HAVE_GLUT_GLUT_H)
check_include_file(OpenGL/gl.h HAVE_OPENGL_GL_H)
check_include_file(OpenGL/glu.h HAVE_OPENGL_GLU_H)

# Win32 IO
set(win32_io FALSE)
if(WIN32)
  set(win32_io TRUE)
endif()
set(USE_WIN32_FILEIO ${win32_io} CACHE BOOL "Use win32 IO system (Microsoft Windows only)")
if (USE_WIN32_FILEIO)
  set(USE_WIN32_FILEIO TRUE)
else()
  set(USE_WIN32_FILEIO FALSE)
endif()

# Orthogonal features

# Strip chopping
option(strip-chopping "strip chopping (whether or not to convert single-strip uncompressed images to mutiple strips of specified size to reduce memory usage)" ON)
set(TIFF_DEFAULT_STRIP_SIZE 8192 CACHE STRING "default size of the strip in bytes (when strip chopping is enabled)")

set(STRIPCHOP_DEFAULT)
if(strip-chopping)
  set(STRIPCHOP_DEFAULT TRUE)
  if(TIFF_DEFAULT_STRIP_SIZE)
    set(STRIP_SIZE_DEFAULT "${TIFF_DEFAULT_STRIP_SIZE}")
  endif()
endif()

# Defer loading of strip/tile offsets
option(defer-strile-load "enable deferred strip/tile offset/size loading (experimental)" OFF)
set(DEFER_STRILE_LOAD ${defer-strile-load})

# CHUNKY_STRIP_READ_SUPPORT
option(chunky-strip-read "enable reading large strips in chunks for TIFFReadScanline() (experimental)" OFF)
set(CHUNKY_STRIP_READ_SUPPORT ${chunky-strip-read})

# SUBIFD support
set(SUBIFD_SUPPORT 1)

# Default handling of ASSOCALPHA support.
option(extrasample-as-alpha "the RGBA interface will treat a fourth sample with no EXTRASAMPLE_ value as being ASSOCALPHA. Many packages produce RGBA files but don't mark the alpha properly" ON)
if(extrasample-as-alpha)
  set(DEFAULT_EXTRASAMPLE_AS_ALPHA 1)
endif()

# Default handling of YCbCr subsampling support.
# See Bug 168 in Bugzilla, and JPEGFixupTestSubsampling() for details.
option(check-ycbcr-subsampling "enable picking up YCbCr subsampling info from the JPEG data stream to support files lacking the tag" ON)
if (check-ycbcr-subsampling)
  set(CHECK_JPEG_YCBCR_SUBSAMPLING 1)
endif()

if(UNIX AND NOT OSX_FRAMEWORK)
    # Generate pkg-config file
    set(prefix "${CMAKE_INSTALL_PREFIX}")
    set(exec_prefix "${CMAKE_INSTALL_PREFIX}")
    set(libdir "${CMAKE_INSTALL_FULL_LIBDIR}")
    set(includedir "${CMAKE_INSTALL_FULL_INCLUDEDIR}")
    configure_file(${CMAKE_CURRENT_SOURCE_DIR}/libtiff-4.pc.in
                   ${CMAKE_BINARY_DIR}/libtiff-4.pc)
endif()
