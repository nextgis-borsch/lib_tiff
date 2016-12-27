################################################################################
# Project:  Lib TIFF
# Purpose:  CMake build scripts
# Author:   Dmitry Baryshnikov, dmitry.baryshnikov@nexgis.com
################################################################################
# Copyright (C) 2015, NextGIS <info@nextgis.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.
################################################################################

function(check_version major minor micro alpha so_major so_minor so_rev)

    # Read version information from configure.ac.
    FILE(READ "${CMAKE_SOURCE_DIR}/configure.ac" configure)
    STRING(REGEX REPLACE ";" "\\\\;" configure "${configure}")
    STRING(REGEX REPLACE "\n" ";" configure "${configure}")
    foreach(line ${configure})
      foreach(var LIBTIFF_MAJOR_VERSION LIBTIFF_MINOR_VERSION LIBTIFF_MICRO_VERSION LIBTIFF_ALPHA_VERSION
              LIBTIFF_CURRENT LIBTIFF_REVISION LIBTIFF_AGE)
        if(NOT ${var})
          string(REGEX MATCH "^${var}=(.*)" ${var}_MATCH "${line}")
          if(${var}_MATCH)
            string(REGEX REPLACE "^${var}=(.*)" "\\1" ${var} "${line}")
          endif()
        endif()
      endforeach()
    endforeach()

    math(EXPR _SO_MAJOR "${LIBTIFF_CURRENT} - ${LIBTIFF_AGE}")
    set(_SO_MINOR "${LIBTIFF_AGE}")
    set(_SO_REVISION "${LIBTIFF_REVISION}")

    #message(STATUS "Building tiff version ${LIBTIFF_MAJOR_VERSION}.${LIBTIFF_MINOR_VERSION}.${LIBTIFF_MICRO_VERSION}${LIBTIFF_ALPHA_VERSION}")
    #message(STATUS "libtiff library version ${_SO_MAJOR}.${_SO_MINOR}.${_SO_REVISION}")

    set(${major} ${LIBTIFF_MAJOR_VERSION} PARENT_SCOPE)
    set(${minor} ${LIBTIFF_MINOR_VERSION} PARENT_SCOPE)
    set(${micro} ${LIBTIFF_MICRO_VERSION} PARENT_SCOPE)
    set(${alpha} ${LIBTIFF_ALPHA_VERSION} PARENT_SCOPE)

    set(${so_major} ${_SO_MAJOR} PARENT_SCOPE)
    set(${so_minor} ${_SO_MINOR} PARENT_SCOPE)
    set(${so_rev} ${_SO_REVISION} PARENT_SCOPE)

    # Store version string in file for installer needs
    file(TIMESTAMP ${CMAKE_SOURCE_DIR}/configure.ac VERSION_DATETIME "%Y-%m-%d %H:%M:%S" UTC)
    file(WRITE ${CMAKE_BINARY_DIR}/version.str "${_SO_MAJOR}.${_SO_MINOR}.${_SO_REVISION}\n${VERSION_DATETIME}")

endfunction(check_version)


function(report_version name ver)

#    if(NOT WIN32)
      string(ASCII 27 Esc)
      set(BoldYellow  "${Esc}[1;33m")
      set(ColourReset "${Esc}[m")
#    endif()

    message(STATUS "${BoldYellow}${name} version ${ver}${ColourReset}")

endfunction()


# macro to find packages on the host OS
macro( find_exthost_package )
    if(CMAKE_CROSSCOMPILING)
        set( CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER )
        set( CMAKE_FIND_ROOT_PATH_MODE_LIBRARY NEVER )
        set( CMAKE_FIND_ROOT_PATH_MODE_INCLUDE NEVER )
        if( CMAKE_HOST_WIN32 )
            SET( WIN32 1 )
            SET( UNIX )
        elseif( CMAKE_HOST_APPLE )
            SET( APPLE 1 )
            SET( UNIX )
        endif()
        find_package( ${ARGN} )
        SET( WIN32 )
        SET( APPLE )
        SET( UNIX 1 )
        set( CMAKE_FIND_ROOT_PATH_MODE_PROGRAM ONLY )
        set( CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY )
        set( CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY )
    else()
        find_package( ${ARGN} )
    endif()
endmacro()


# macro to find programs on the host OS
macro( find_exthost_program )
    if(CMAKE_CROSSCOMPILING)
        set( CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER )
        set( CMAKE_FIND_ROOT_PATH_MODE_LIBRARY NEVER )
        set( CMAKE_FIND_ROOT_PATH_MODE_INCLUDE NEVER )
        if( CMAKE_HOST_WIN32 )
            SET( WIN32 1 )
            SET( UNIX )
        elseif( CMAKE_HOST_APPLE )
            SET( APPLE 1 )
            SET( UNIX )
        endif()
        find_program( ${ARGN} )
        SET( WIN32 )
        SET( APPLE )
        SET( UNIX 1 )
        set( CMAKE_FIND_ROOT_PATH_MODE_PROGRAM ONLY )
        set( CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY )
        set( CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY )
    else()
        find_program( ${ARGN} )
    endif()
endmacro()
