# CMake build for libtiff
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

# Generate headers
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/tif_config.h.cmake.in
               ${CMAKE_CURRENT_BINARY_DIR}/tif_config.h
               @ONLY)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/tiffconf.h.cmake.in
               ${CMAKE_CURRENT_BINARY_DIR}/tiffconf.h
               @ONLY)

extra_dist(
  SConstruct
  tif_config.h-vms
  tif_config.vc.h
  tif_config.wince.h
  tiffconf.vc.h
  tiffconf.wince.h
  libtiff.def
  libtiff.map
  libtiffxx.map)

set(tiff_HEADERS
  tiff.h
  tiffio.h
  tiffvers.h)

set(tiff_noinst_HEADERS
  t4.h
  tif_dir.h
  tif_predict.h
  tiffiop.h
  uvcode.h)

set(nodist_tiff_HEADERS
  ${CMAKE_CURRENT_BINARY_DIR}/tiffconf.h)

set(tiff_SOURCES
  tif_aux.c
  tif_close.c
  tif_codec.c
  tif_color.c
  tif_compress.c
  tif_dir.c
  tif_dirinfo.c
  tif_dirread.c
  tif_dirwrite.c
  tif_dumpmode.c
  tif_error.c
  tif_extension.c
  tif_fax3.c
  tif_fax3sm.c
  tif_flush.c
  tif_getimage.c
  tif_jbig.c
  tif_jpeg.c
  tif_jpeg_12.c
  tif_luv.c
  tif_lzma.c
  tif_lzw.c
  tif_next.c
  tif_ojpeg.c
  tif_open.c
  tif_packbits.c
  tif_pixarlog.c
  tif_predict.c
  tif_print.c
  tif_read.c
  tif_strip.c
  tif_swab.c
  tif_thunder.c
  tif_tile.c
  tif_version.c
  tif_warning.c
  tif_write.c
  tif_zip.c)

set(tiffxx_HEADERS
  tiffio.hxx)

set(tiffxx_SOURCES
  tif_stream.cxx)
if(MSVC)
    set(tiffxx_SOURCES ${tiffxx_SOURCES} libtiffxx.def)
endif()

if(WIN32_IO)
  extra_dist(tif_unix.c)
  list(APPEND tiff_SOURCES tif_win32.c)
else()
  extra_dist(tif_win32.c)
  list(APPEND tiff_SOURCES tif_unix.c)
endif()

set(_DEPENDENCY_LIB ${DEPENDENCY_LIB})
set(_EXPORTS_PATHS ${EXPORTS_PATHS})

if(TIFF_LIBRARY_DEPS)
    set(TARGET_LINK_LIB ${TIFF_LIBRARY_DEPS})
endif()

set(DEPENDENCY_LIB ${_DEPENDENCY_LIB})
set(EXPORTS_PATHS ${_EXPORTS_PATHS})

include_directories(${CMAKE_CURRENT_SOURCE_DIR}
                    ${CMAKE_CURRENT_BINARY_DIR}
                    ${TIFF_INCLUDES})

set(LIB_NAME ${PROJECT_NAME})

add_library(${LIB_NAME} ${tiff_SOURCES} ${tiff_HEADERS} ${nodist_tiff_HEADERS}
            ${tiff_port_SOURCES} libtiff.def)
# target_link_libraries(${LIB_NAME} ${TIFF_LIBRARY_DEPS})
set_target_properties(${LIB_NAME} PROPERTIES SOVERSION ${SO_COMPATVERSION})
if(NOT CYGWIN)
    # This property causes shared libraries on Linux to have the full version
    # encoded into their final filename.  We disable this on Cygwin because
    # it causes cygz-${TIFF_FULL_VERSION}.dll to be created when cygz.dll
    # seems to be the default.
    set_target_properties(${LIB_NAME} PROPERTIES VERSION ${SO_VERSION})
endif()
if(HAVE_LD_VERSION_SCRIPT)
  set_target_properties(${LIB_NAME} PROPERTIES LINK_FLAGS
                        "-Wl,--version-script=${CMAKE_CURRENT_SOURCE_DIR}/libtiff.map")
endif()

target_link_extlibraries(${LIB_NAME})
set(EXPORT_TARGETS ${LIB_NAME})

install(TARGETS ${LIB_NAME}
    EXPORT ${PACKAGE_UPPER_NAME}Targets
    RUNTIME DESTINATION ${INSTALL_BIN_DIR}
    LIBRARY DESTINATION ${INSTALL_LIB_DIR}
    ARCHIVE DESTINATION ${INSTALL_LIB_DIR}
    INCLUDES DESTINATION ${INSTALL_INC_DIR}
    FRAMEWORK DESTINATION ${INSTALL_LIB_DIR})

if(OSX_FRAMEWORK)
    set(OSX_HEADERS ${tiff_HEADERS} ${nodist_tiff_HEADERS})
  set_target_properties(${LIB_NAME} PROPERTIES
    FRAMEWORK TRUE
    FRAMEWORK_VERSION ${FRAMEWORK_VERSION}
    MACOSX_FRAMEWORK_SHORT_VERSION_STRING ${SO_MAJOR}.${SO_MINOR}
    MACOSX_FRAMEWORK_BUNDLE_VERSION ${SO_VERSION}
    MACOSX_FRAMEWORK_IDENTIFIER org.libtiff.libtiff
    XCODE_ATTRIBUTE_INSTALL_PATH "@rpath"
    PUBLIC_HEADER "${OSX_HEADERS}"
    OUTPUT_NAME tiff)
else()
  install(FILES ${tiff_HEADERS} ${nodist_tiff_HEADERS}
        DESTINATION "${INSTALL_INC_DIR}")
endif()

if(cxx)
  add_library(${LIB_NAME}xx ${tiffxx_SOURCES} ${tiffxx_HEADERS})
  if(BUILD_SHARED_LIBS)
    set_target_properties(${LIB_NAME}xx PROPERTIES DEFINE_SYMBOL TIFF_DLL_EXPORTS)
  endif()
  target_link_libraries(${LIB_NAME}xx ${LIB_NAME})
  set_target_properties(${LIB_NAME}xx PROPERTIES SOVERSION ${SO_COMPATVERSION})
  if(NOT CYGWIN)
    # This property causes shared libraries on Linux to have the full version
    # encoded into their final filename.  We disable this on Cygwin because
    # it causes cygz-${TIFF_FULL_VERSION}.dll to be created when cygz.dll
    # seems to be the default.
    set_target_properties(${LIB_NAME}xx PROPERTIES VERSION ${SO_VERSION})
  endif()
  if(HAVE_LD_VERSION_SCRIPT)
    set_target_properties(${LIB_NAME}xx PROPERTIES LINK_FLAGS
                          "-Wl,--version-script=${CMAKE_CURRENT_SOURCE_DIR}/libtiffxx.map")
  endif()

  install(TARGETS ${LIB_NAME}xx
      EXPORT ${PACKAGE_UPPER_NAME}Targets
      RUNTIME DESTINATION ${INSTALL_BIN_DIR}
      LIBRARY DESTINATION ${INSTALL_LIB_DIR}
      ARCHIVE DESTINATION ${INSTALL_LIB_DIR}
      INCLUDES DESTINATION "${INSTALL_LIB_DIR}/${PROJECT_NAME}xx.framework/Headers"
      FRAMEWORK DESTINATION ${INSTALL_LIB_DIR})

  if(OSX_FRAMEWORK)
    set_target_properties(${LIB_NAME}xx PROPERTIES
      FRAMEWORK TRUE
      FRAMEWORK_VERSION ${FRAMEWORK_VERSION}
      MACOSX_FRAMEWORK_SHORT_VERSION_STRING ${SO_MAJOR}.${SO_MINOR}
      MACOSX_FRAMEWORK_BUNDLE_VERSION ${SO_VERSION}
      MACOSX_FRAMEWORK_IDENTIFIER org.libtiff.libtiffxx
      XCODE_ATTRIBUTE_INSTALL_PATH "@rpath"
      PUBLIC_HEADER "${tiffxx_HEADERS}"
      OUTPUT_NAME tiffxx)
  else()
    install(FILES ${tiffxx_HEADERS}
          DESTINATION "${INSTALL_INC_DIR}")
  endif()

  if(NOT BUILD_SHARED_LIBS)
    set(EXPORT_TARGETS ${EXPORT_TARGETS} ${LIB_NAME}xx)
  endif()
endif()

if(NOT SKIP_INSTALL_FILES AND NOT SKIP_INSTALL_ALL AND NOT WIN32)
  install(FILES ${CMAKE_BINARY_DIR}/libtiff-4.pc
        DESTINATION "${INSTALL_LIB_DIR}/pkgconfig")
endif()


# Add path to includes to build-tree export
target_include_directories(${LIB_NAME} PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}>
)

target_include_directories(${LIB_NAME}xx PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}>
)

# Add all targets to the build-tree export set
export(TARGETS ${LIB_NAME}
    FILE ${PROJECT_BINARY_DIR}/${PACKAGE_UPPER_NAME}Targets.cmake)

# Create the <Package>Config.cmake file
configure_file(${PROJECT_SOURCE_DIR}/cmake/PackageConfig.cmake.in
    ${PROJECT_BINARY_DIR}/${PACKAGE_UPPER_NAME}Config.cmake @ONLY)

if(NOT SKIP_INSTALL_LIBRARIES AND NOT SKIP_INSTALL_ALL)
    # Install the <Package>Config.cmake
    install(FILES
      ${PROJECT_BINARY_DIR}/${PACKAGE_UPPER_NAME}Config.cmake
      DESTINATION ${INSTALL_CMAKECONF_DIR} COMPONENT dev)

    # Install the export set for use with the install-tree
    install(EXPORT ${PACKAGE_UPPER_NAME}Targets DESTINATION ${INSTALL_CMAKECONF_DIR} COMPONENT dev)
endif()
