# CMake build for libtiff
# Run "cmake" to generate the build files for your platform
#
# Copyright © 2015 Open Microscopy Environment / University of Dundee
# Written by Roger Leigh <rleigh@codelibre.net>
#
# Permission to use, copy, modify, distribute, and sell this software and
# its documentation for any purpose is hereby granted without fee, provided
# that (i) the above copyright notices and this permission notice appear in
# all copies of the software and related documentation, and (ii) the names of
# Sam Leffler and Silicon Graphics may not be used in any advertising or
# publicity relating to the software without the specific, prior written
# permission of Sam Leffler and Silicon Graphics.
#
# THE SOFTWARE IS PROVIDED "AS-IS" AND WITHOUT WARRANTY OF ANY KIND,
# EXPRESS, IMPLIED OR OTHERWISE, INCLUDING WITHOUT LIMITATION, ANY
# WARRANTY OF MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE.
#
# IN NO EVENT SHALL SAM LEFFLER OR SILICON GRAPHICS BE LIABLE FOR
# ANY SPECIAL, INCIDENTAL, INDIRECT OR CONSEQUENTIAL DAMAGES OF ANY KIND,
# OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS,
# WHETHER OR NOT ADVISED OF THE POSSIBILITY OF DAMAGE, AND ON ANY THEORY OF
# LIABILITY, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE
# OF THIS SOFTWARE.

cmake_minimum_required(VERSION 2.8.12 FATAL_ERROR)

# Default policy is from 2.8.12
cmake_policy(VERSION 2.8.12)
# Set MacOSX @rpath usage globally.
if (POLICY CMP0020)
  cmake_policy(SET CMP0020 NEW)
endif()
# Use new variable expansion policy.
if (POLICY CMP0053)
  cmake_policy(SET CMP0053 NEW)
endif()
if (POLICY CMP0054)
  cmake_policy(SET CMP0054 NEW)
endif()

# Project version
project(tiff C)

set(CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake ${CMAKE_MODULE_PATH})

include(util)

set(LIBTIFF_MAJOR_VERSION)
set(LIBTIFF_MINOR_VERSION)
set(LIBTIFF_MICRO_VERSION)
set(LIBTIFF_ALPHA_VERSION)
set(SO_MAJOR)
set(SO_MINOR)
set(SO_REVISION)

check_version(LIBTIFF_MAJOR_VERSION LIBTIFF_MINOR_VERSION LIBTIFF_MICRO_VERSION LIBTIFF_ALPHA_VERSION SO_MAJOR SO_MINOR SO_REVISION)

set(VERSION "${LIBTIFF_MAJOR_VERSION}.${LIBTIFF_MINOR_VERSION}.${LIBTIFF_MICRO_VERSION}")
set(tiff_VERSION "${VERSION}")
set(tiff_VERSION_MAJOR "${LIBTIFF_MAJOR_VERSION}")
set(tiff_VERSION_MINOR "${LIBTIFF_MINOR_VERSION}")
set(tiff_VERSION_PATCH "${LIBTIFF_MICRO_VERSION}")

# the other tiff_VERSION_* variables are set automatically
set(tiff_VERSION_ALPHA "${LIBTIFF_ALPHA_VERSION}")
# Library version (unlike libtool's baroque scheme, WYSIWYG here)
set(SO_COMPATVERSION "${SO_MAJOR}")
set(SO_VERSION "${SO_MAJOR}.${SO_MINOR}.${SO_REVISION}")

# For autotools header compatibility
set(PACKAGE_NAME "LibTIFF Software")
set(PACKAGE_TARNAME "${PROJECT_NAME}")
set(PACKAGE_VERSION "${PROJECT_VERSION}${tiff_VERSION_ALPHA}")
set(PACKAGE_STRING "${PACKAGE_NAME} ${PACKAGE_VERSION}")
set(PACKAGE_BUGREPORT "tiff@lists.maptools.org")

report_version(${PROJECT_NAME} ${SO_VERSION})    

# enable_testing()

macro(current_date var)
  if(UNIX)
    execute_process(COMMAND "date" +"%Y%m%d" OUTPUT_VARIABLE ${var})
  endif()
endmacro()

current_date(RELEASE_DATE)

macro(extra_dist)
  foreach(file ${ARGV})
    file(RELATIVE_PATH relfile "${PROJECT_SOURCE_DIR}"
         "${CMAKE_CURRENT_SOURCE_DIR}/${file}")
    list(APPEND EXTRA_DIST "${relfile}")
  endforeach()
  set(EXTRA_DIST "${EXTRA_DIST}" PARENT_SCOPE)
endmacro()

set(EXTRA_DIST
  HOWTO-RELEASE
  Makefile.vc
  SConstruct
  autogen.sh
  configure.com
  nmake.opt
  libtiff-4.pc.in)
  
include(configure)  

configure_file(${CMAKE_MODULE_PATH}/cmake_uninstall.cmake.in ${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake IMMEDIATE @ONLY)

# Large file support
if (UNIX)
  # This might not catch every possibility catered for by
  # AC_SYS_LARGEFILE.
  add_definitions(-D_FILE_OFFSET_BITS=64)
  set(FILE_OFFSET_BITS 64)
endif()

# Documentation install directory (default to cmake project docdir)
set(LIBTIFF_DOCDIR "${CMAKE_INSTALL_FULL_DOCDIR}")

# Options to enable and disable internal codecs

option(ccitt "support for CCITT Group 3 & 4 algorithms" ON)
set(CCITT_SUPPORT ${ccitt})

option(packbits "support for Macintosh PackBits algorithm" ON)
set(PACKBITS_SUPPORT ${packbits})

option(lzw "support for LZW algorithm" ON)
set(LZW_SUPPORT ${lzw})

option(thunder "support for ThunderScan 4-bit RLE algorithm" ON)
set(THUNDER_SUPPORT ${thunder})

option(next "support for NeXT 2-bit RLE algorithm" ON)
set(NEXT_SUPPORT ${next})

option(logluv "support for LogLuv high dynamic range algorithm" ON)
set(LOGLUV_SUPPORT ${logluv})

# Option for Microsoft Document Imaging
option(mdi "support for Microsoft Document Imaging" ON)
set(MDI_SUPPORT ${mdi})

include(find_anyproject)

find_anyproject(ZLIB)
set(ZLIB_SUPPORT 0)
if(ZLIB_FOUND)
  set(ZLIB_SUPPORT 1)
endif()
set(ZIP_SUPPORT ${ZLIB_SUPPORT})
# Option for Pixar log-format algorithm

# Pixar log format
option(pixarlog "support for Pixar log-format algorithm (requires Zlib)" ON)
set(PIXARLOG_SUPPORT FALSE)
if (ZLIB_SUPPORT)
  if(pixarlog)
    set(PIXARLOG_SUPPORT TRUE)
  endif()
endif()

# JPEG
find_anyproject(JPEG)
set(JPEG_SUPPORT FALSE)
if(JPEG_FOUND)
  set(JPEG_SUPPORT TRUE)
endif()

option(old-jpeg "support for Old JPEG compression (read-only)" ON)
set(OJPEG_SUPPORT FALSE)
if (JPEG_SUPPORT)
  if (old-jpeg)
    set(OJPEG_SUPPORT TRUE)
  endif()
endif()

# JBIG-KIT
find_anyproject(JBIG)
set(JBIG_SUPPORT 0)
if(JBIG_FOUND)
  set(JBIG_FOUND TRUE)
  set(JBIG_SUPPORT 1)
else()
  set(JBIG_FOUND FALSE)
endif()

set(CMAKE_REQUIRED_LIBRARIES_SAVE ${CMAKE_REQUIRED_LIBRARIES})
set(CMAKE_REQUIRED_INCLUDES_SAVE ${CMAKE_REQUIRED_INCLUDES})
set(CMAKE_REQUIRED_INCLUDES ${CMAKE_REQUIRED_INCLUDES} ${JBIG_INCLUDE_DIR})
set(CMAKE_REQUIRED_LIBRARIES ${CMAKE_REQUIRED_LIBRARIES} ${JBIG_LIBRARY})
check_function_exists(jbg_newlen HAVE_JBG_NEWLEN)
set(CMAKE_REQUIRED_LIBRARIES ${CMAKE_REQUIRED_LIBRARIES_SAVE})
set(CMAKE_REQUIRED_INCLUDES ${CMAKE_REQUIRED_INCLUDES_SAVE})

# liblzma
find_anyproject(LibLZMA)
set(LZMA_SUPPORT 0)
if(LIBLZMA_FOUND)
  set(LZMA_SUPPORT 1)
endif()

# 8/12-bit jpeg mode
find_anyproject(JPEG12)
if (JPEG12_FOUND)
  set(JPEG_DUAL_MODE_8_12 1)
  set(LIBJPEG_12_PATH "\"${JPEG12_INCLUDE_DIR}/jpeglib.h\"")
  add_definitions(-DLIBJPEG_12_PATH="${JPEG12_INCLUDE_DIR}/jpeglib.h")
endif()

# Includes used by libtiff (and tests)
if(ZLIB_INCLUDE_DIRS)
  list(APPEND TIFF_INCLUDES ${ZLIB_INCLUDE_DIRS})
endif()
if(JPEG_INCLUDE_DIR)
  list(APPEND TIFF_INCLUDES ${JPEG_INCLUDE_DIR})
endif()
if(JPEG12_INCLUDE_DIR)
  list(APPEND TIFF_INCLUDES ${JPEG12_INCLUDE_DIR})
endif()
if(JBIG_INCLUDE_DIR)
  list(APPEND TIFF_INCLUDES ${JBIG_INCLUDE_DIR})
endif()
if(LIBLZMA_INCLUDE_DIRS)
  list(APPEND TIFF_INCLUDES ${LIBLZMA_INCLUDE_DIRS})
endif()

# Libraries required by libtiff
set(TIFF_LIBRARY_DEPS)
if(M_LIBRARY)
  list(APPEND TIFF_LIBRARY_DEPS ${M_LIBRARY})
endif()
if(ZLIB_LIBRARIES)
  list(APPEND TIFF_LIBRARY_DEPS ${ZLIB_LIBRARIES})
endif()
if(JPEG_LIBRARIES)
  list(APPEND TIFF_LIBRARY_DEPS ${JPEG_LIBRARIES})
endif()
if(JPEG12_LIBRARIES)
  list(APPEND TIFF_LIBRARY_DEPS ${JPEG12_LIBRARIES})
endif()
if(JBIG_LIBRARIES)
  list(APPEND TIFF_LIBRARY_DEPS ${JBIG_LIBRARIES})
endif()
if(LIBLZMA_LIBRARIES)
  list(APPEND TIFF_LIBRARY_DEPS ${LIBLZMA_LIBRARIES})
endif()

if(TARGET_LINK_LIB)
    list(APPEND TIFF_LIBRARY_DEPS ${TARGET_LINK_LIB})
endif()

report_values(TIFF_INCLUDES TIFF_LIBRARY_DEPS)

# Process subdirectories
add_subdirectory(port)
add_subdirectory(libtiff)
add_subdirectory(man)
add_subdirectory(html)

#message(STATUS "EXTRA_DIST: ${EXTRA_DIST}")
set(zlib ON)
set(jpeg ON)
set(jpeg12 ON)
set(jbig ON)
set(lzma ON)

if(VERBOSE_OUTPUT)
message(STATUS "")
message(STATUS "Libtiff is now configured for ${host}")
message(STATUS "")
message(STATUS "  Installation directory:             ${prefix}")
message(STATUS "  Documentation directory:            ${LIBTIFF_DOCDIR}")
message(STATUS "  C compiler:                         ${CMAKE_C_COMPILER}")
message(STATUS "  C++ compiler:                       ${CMAKE_CXX_COMPILER}")
message(STATUS "  Build shared libraries:             ${BUILD_SHARED_LIBS}")
message(STATUS "  Enable linker symbol versioning:    ${HAVE_LD_VERSION_SCRIPT}")
message(STATUS "  Support Microsoft Document Imaging: ${mdi}")
message(STATUS "  Use win32 IO:                       ${USE_WIN32_FILEIO}")
message(STATUS "")
message(STATUS " Support for internal codecs:")
message(STATUS "  CCITT Group 3 & 4 algorithms:       ${ccitt}")
message(STATUS "  Macintosh PackBits algorithm:       ${packbits}")
message(STATUS "  LZW algorithm:                      ${lzw}")
message(STATUS "  ThunderScan 4-bit RLE algorithm:    ${thunder}")
message(STATUS "  NeXT 2-bit RLE algorithm:           ${next}")
message(STATUS "  LogLuv high dynamic range encoding: ${logluv}")
message(STATUS "")
message(STATUS " Support for external codecs:")
message(STATUS "  ZLIB support:                       ${zlib} (requested) ${ZLIB_FOUND} (availability)")
message(STATUS "  Pixar log-format algorithm:         ${pixarlog} (requested) ${PIXARLOG_SUPPORT} (availability)")
message(STATUS "  JPEG support:                       ${jpeg} (requested) ${JPEG_FOUND} (availability)")
message(STATUS "  Old JPEG support:                   ${old-jpeg} (requested) ${JPEG_FOUND} (availability)")
message(STATUS "  JPEG 8/12 bit dual mode:            ${jpeg12} (requested) ${JPEG12_FOUND} (availability)")
message(STATUS "  ISO JBIG support:                   ${jbig} (requested) ${JBIG_FOUND} (availability)")
message(STATUS "  LZMA2 support:                      ${lzma} (requested) ${LIBLZMA_FOUND} (availability)")
message(STATUS "")
message(STATUS "  C++ support:                        ${cxx} (requested) ${CXX_SUPPORT} (availability)")
message(STATUS "")
# message(STATUS "  X Athena Widgets support:           ${HAVE_XAW}")
message(STATUS "  OpenGL support:                     ${HAVE_OPENGL}")
message(STATUS "")
endif()

add_custom_target(uninstall COMMAND ${CMAKE_COMMAND} -P ${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake)

