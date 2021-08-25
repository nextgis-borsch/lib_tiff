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
endif(POLICY CMP0020)
if (POLICY CMP0042)
  cmake_policy(SET CMP0042 NEW)
endif(POLICY CMP0042)
# Use new variable expansion policy.
if (POLICY CMP0053)
  cmake_policy(SET CMP0053 NEW)
endif(POLICY CMP0053)
if (POLICY CMP0054)
  cmake_policy(SET CMP0054 NEW)
endif(POLICY CMP0054)

# Project definition
set(CMAKE_C_STANDARD 99)
project(tiff
        LANGUAGES C CXX)

set(CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake ${CMAKE_MODULE_PATH})

include(util)

check_version(LIBTIFF_MAJOR_VERSION LIBTIFF_MINOR_VERSION LIBTIFF_MICRO_VERSION LIBTIFF_ALPHA_VERSION SO_MAJOR SO_MINOR SO_REVISION)

set(VERSION "${LIBTIFF_MAJOR_VERSION}.${LIBTIFF_MINOR_VERSION}.${LIBTIFF_MICRO_VERSION}")

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

report_version(${PROJECT_NAME} "${VERSION} (${SO_VERSION})")

if(OSX_FRAMEWORK)
    set(FRAMEWORK_VERSION "${LIBTIFF_MAJOR_VERSION}")
endif()

# Compiler checks (warning flags, etc.)
include(CompilerChecks)

# Linker checks (version script, etc.)
include(LinkerChecks)

# Processor checks (endianness, fill order, floating point, etc.)
include(ProcessorChecks)

# Checks for headers
include(IncludeChecks)

# Checks for functions and other symbols
include(SymbolChecks)

# Standard installation paths
include(GNUInstallDirs)
# Documentation install directory (default to cmake project docdir)
set(LIBTIFF_DOCDIR "${CMAKE_INSTALL_DOCDIR}")

# CTest testing
enable_testing()

# Checks for type presence and size
include(TypeSizeChecks)

# Option for C++ libtiffxx library
include(CXXLibrary)

# Windows support
include(WindowsSupport)

# Orthogonal features
include(LibraryFeatures)

include(FindAnyProject)

find_anyproject(ZLIB)
set(ZLIB_SUPPORT 0)
if(ZLIB_FOUND)
  set(ZLIB_SUPPORT 1)
else()
  set(ZLIB_FOUND FALSE)
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
else()
  set(JPEG_FOUND FALSE)
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

# liblzma
find_anyproject(LibLZMA)
set(LZMA_SUPPORT 0)
if(LIBLZMA_FOUND)
  set(LIBLZMA_FOUND TRUE)
  set(LZMA_SUPPORT 1)
else()
  set(LIBLZMA_FOUND FALSE)
endif()

# 8/12-bit jpeg mode
find_anyproject(JPEG12 CMAKE_ARGS -DBUILD_JPEG_12=ON -DBUILD_APPS=OFF)
if (JPEG12_FOUND)
  set(JPEG_DUAL_MODE_8_12 1)
  find_file(LIBJPEG_12_PATH NAMES jpeglib.h PATHS ${JPEG12_INCLUDE_DIRS})
  set(LIBJPEG_12_PATH "${LIBJPEG_12_PATH}")
  add_definitions(-DLIBJPEG_12_PATH=${LIBJPEG_12_PATH})
  set(JPEG12_FOUND TRUE)
  message(STATUS "DD add_definitions(-DLIBJPEG_12_PATH=${LIBJPEG_12_PATH})")
else()
  set(JPEG12_FOUND FALSE)
endif()

# libwebp
find_anyproject(WEBP CMAKE_ARGS -DWEBP_BUILD_VWEBP=OFF -DWEBP_BUILD_CWEBP=OFF -DWEBP_BUILD_DWEBP=OFF)
if(WEBP_FOUND)
  set(WEBP_SUPPORT 1)
else()
  set(WEBP_SUPPORT 0)
endif()

set(PACKAGE_NAME ${PROJECT_NAME})
string(TOUPPER ${PACKAGE_NAME} PACKAGE_UPPER_NAME)

# Process subdirectories
add_subdirectory(port)
add_subdirectory(libtiff)
add_subdirectory(tools)
add_subdirectory(test)
add_subdirectory(man)
add_subdirectory(html)

message(STATUS "")
message(STATUS "Libtiff is now configured for ${CMAKE_SYSTEM}")
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
message(STATUS "  ZLIB support:                       Requested:${zlib} Availability:${ZLIB_FOUND} Support:${ZLIB_SUPPORT}")
if(ZLIB_SUPPORT)
  message(STATUS "  libdeflate support:                 Requested:${libdeflate} Availability:${DEFLATE_FOUND} Support:${LIBDEFLATE_SUPPORT}")
else()
  message(STATUS "  libdeflate support:                 Requested:${libdeflate} Availability:${DEFLATE_FOUND} Support:${LIBDEFLATE_SUPPORT} (Depends on ZLIB Support)")
endif()
if(ZLIB_SUPPORT)
  message(STATUS "  Pixar log-format algorithm:         Requested:${pixarlog} Availability:${ZLIB_FOUND} Support:${PIXARLOG_SUPPORT}")
else()
  message(STATUS "  Pixar log-format algorithm:         Requested:${pixarlog} Availability:${ZLIB_FOUND} Support:${PIXARLOG_SUPPORT} (Depends on ZLIB Support)")
endif()
message(STATUS "  JPEG support:                       Requested:${jpeg} Availability:${JPEG_FOUND} Support:${JPEG_SUPPORT}")
if(JPEG_SUPPORT)
  message(STATUS "  Old JPEG support:                   Requested:${old-jpeg} Availability:${JPEG_SUPPORT} Support:${OJPEG_SUPPORT}")
else()
  message(STATUS "  Old JPEG support:                   Requested:${old-jpeg} Availability:${JPEG_SUPPORT} Support:${OJPEG_SUPPORT} (Depends on JPEG Support)")
endif()
message(STATUS "  JPEG 8/12 bit dual mode:            Requested:${jpeg12} Availability:${JPEG12_FOUND} Support:${JPEG_DUAL_MODE_8_12}")
message(STATUS "  ISO JBIG support:                   Requested:${jbig} Availability:${JBIG_FOUND} Support:${JBIG_SUPPORT}")
message(STATUS "  LERC support:                       Requested:${lerc} Availability:${LERC_FOUND} Support:${LERC_SUPPORT}")
message(STATUS "  LZMA2 support:                      Requested:${lzma} Availability:${LIBLZMA_FOUND} Support:${LZMA_SUPPORT}")
message(STATUS "  ZSTD support:                       Requested:${zstd} Availability:${ZSTD_USABLE} Support:${ZSTD_SUPPORT}")
message(STATUS "  WEBP support:                       Requested:${webp} Availability:${WEBP_FOUND} Support:${WEBP_SUPPORT}")
message(STATUS "")
message(STATUS "  C++ support:                        ${cxx} (requested) ${CXX_SUPPORT} (availability)")
message(STATUS "")
# message(STATUS "  X Athena Widgets support:           ${HAVE_XAW}")
message(STATUS "  OpenGL support:                     ${HAVE_OPENGL}")
message(STATUS "")

add_custom_target(uninstall COMMAND ${CMAKE_COMMAND} -P ${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake)

# Export package ===============================================================

if(REGISTER_PACKAGE)
    # Export the package for use from the build-tree
    # (this registers the build-tree with a global CMake-registry)
    export(PACKAGE ${PACKAGE_UPPER_NAME})
endif()

# Archiving ====================================================================

set(CPACK_PACKAGE_NAME "${PACKAGE_NAME}")
set(CPACK_PACKAGE_VENDOR "${PACKAGE_VENDOR}")
set(CPACK_PACKAGE_VERSION "${VERSION}")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "${PACKAGE_NAME} Installation")
set(CPACK_PACKAGE_RELOCATABLE TRUE)
set(CPACK_ARCHIVE_COMPONENT_INSTALL ON)
set(CPACK_GENERATOR "ZIP")
set(CPACK_MONOLITHIC_INSTALL ON)
set(CPACK_STRIP_FILES TRUE)

# Get cpack zip archive name
get_cpack_filename(${VERSION} PROJECT_CPACK_FILENAME)
set(CPACK_PACKAGE_FILE_NAME ${PROJECT_CPACK_FILENAME})

include(CPack)
