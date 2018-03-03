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

extra_dist(Makefile.vc)

include_directories(${PROJECT_SOURCE_DIR}/libtiff
                    ${PROJECT_BINARY_DIR}/libtiff
                    ${PROJECT_SOURCE_DIR}/port
                    ${CMAKE_CURRENT_BINARY_DIR})

macro(ADD_TIF_BIN name)
    add_executable(${name} ${name}.c)
    target_link_libraries(${name} tiff port)
    if(OSX_FRAMEWORK)
        set_target_properties(${name} PROPERTIES INSTALL_RPATH "@executable_path/../../Library/Frameworks")
    endif()
endmacro()

set(APP_SOURCES
    fax2ps
    fax2tiff
    pal2rgb
    ppm2tiff
    raw2tiff
    rgb2ycbcr
    thumbnail
    tiff2bw
    tiff2pdf
    tiff2ps
    tiff2rgba
    tiffcmp
    tiffcp
    tiffcrop
    tiffdither
    tiffdump
    tiffinfo
    tiffmedian
    tiffset
    tiffsplit
)

foreach(APP ${APP_SOURCES})
    add_tif_bin(${APP})
endforeach()

install(TARGETS fax2ps
                fax2tiff
                pal2rgb
                ppm2tiff
                raw2tiff
                tiff2bw
                tiff2pdf
                tiff2ps
                tiff2rgba
                tiffcmp
                tiffcp
                tiffcrop
                tiffdither
                tiffdump
                tiffinfo
                tiffmedian
                tiffset
                tiffsplit
        RUNTIME DESTINATION "${INSTALL_BIN_DIR}")

if(HAVE_OPENGL)
  if(OPENGL_INCLUDE_DIR)
    include_directories(${OPENGL_INCLUDE_DIR})
  endif()
  if(GLUT_INCLUDE_DIR)
    include_directories(${GLUT_INCLUDE_DIR})
  endif()

  add_executable(tiffgt tiffgt.c)
  target_link_libraries(tiffgt tiff ${GLUT_LIBRARIES} ${OPENGL_LIBRARIES})
  if(OSX_FRAMEWORK)
      set_target_properties(tiffgt PROPERTIES INSTALL_RPATH "@executable_path/../../Library/Frameworks")
  endif()

  install(TARGETS tiffgt
          RUNTIME DESTINATION "${INSTALL_BIN_DIR}")
endif()

if(WIN32)
    file(GLOB_RECURSE IMPORTED_WIN_DLLS ${CMAKE_BINARY_DIR}/third-party/*.dll)
    set(IMPORTED_WIN_DLLS ${IMPORTED_WIN_DLLS} $<TARGET_FILE:tiff> $<TARGET_FILE:tiffxx>)
    foreach(IMPORTED_WIN_DLL ${IMPORTED_WIN_DLLS})
        add_custom_command(TARGET tiffsplit
                            POST_BUILD
                            COMMAND ${CMAKE_COMMAND} -E copy ${IMPORTED_WIN_DLL} $<TARGET_FILE_DIR:tiffsplit>
                            COMMENT "Copy ${IMPORTED_WIN_DLL} to tiffsplit target directory"
                        )
    endforeach()
endif()
