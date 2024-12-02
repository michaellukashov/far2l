set(CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake/modules)

cmake_minimum_required (VERSION 3.16.0)

option(OPT_USE_STATIC_EXT_LIBS "Build and use static external libraries: libneon, libsmb etc" OFF)
option(OPT_PVS_ANALYSIS "use PVS static analysis" OFF)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

if(OPT_USE_STATIC_EXT_LIBS)
	# include(cmake/xrepo.cmake)
	# include(cmake/CPM.cmake)
	include(ExternalProject)
	include(FetchContent)

	if(NOT DEFINED VCPKG_ROOT)
		set(VCPKG_ROOT "${CMAKE_BINARY_DIR}/vcpkg")
	endif()
	#message("VCPKG_ROOT: ${VCPKG_ROOT}")
	if(NOT DEFINED VCPKG_PARENT_DIR)
		get_filename_component(PARENT_DIR "${VCPKG_ROOT}" DIRECTORY)
		set(VCPKG_PARENT_DIR "${PARENT_DIR}")
	endif()
	#message("VCPKG_PARENT_DIR: ${VCPKG_PARENT_DIR}")
	#include(cmake/vcpkg.cmake)

	if(DEFINED VCPKG_ROOT AND NOT DEFINED CMAKE_TOOLCHAIN_FILE) #OR DEFINED ${VCPKG_ROOT}
	set(CMAKE_TOOLCHAIN_FILE "${VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake" CACHE STRING "")
	endif()
	#message("CMAKE_TOOLCHAIN_FILE: ${CMAKE_TOOLCHAIN_FILE}")

	if(NOT DEFINED VCPKG_TARGET_TRIPLET)
		set(VCPKG_TARGET_TRIPLET $ENV{VCPKG_DEFAULT_TRIPLET})
	endif()

	if(NOT DEFINED VCPKG_TARGET_TRIPLET)
		set(VCPKG_TARGET_TRIPLET "x64-linux")
	endif()
	# message("VCPKG_TARGET_TRIPLET: ${VCPKG_TARGET_TRIPLET}")
	set(VCPKG_INSTALLED_PATH "${VCPKG_ROOT}/installed/${VCPKG_TARGET_TRIPLET}")
	# message("VCPKG_INSTALLED_PATH: ${VCPKG_INSTALLED_PATH}")

	set(CMAKE_PREFIX_PATH ${VCPKG_INSTALLED_PATH} ${CMAKE_PREFIX_PATH})
	message("CMAKE_PREFIX_PATH: ${CMAKE_PREFIX_PATH}")

	#[[vcpkg_add_package(fmt)
	vcpkg_add_package(spdlog)
	vcpkg_add_package(xerces-c)
	vcpkg_add_package(zlib)
	vcpkg_add_package(bzip2)
	vcpkg_add_package(mbedtls)
	vcpkg_add_package(libssh[core,zlib,mbedtls])
	vcpkg_add_package(pcre)
	vcpkg_add_package(liblzma)
	vcpkg_add_package(libarchive)
	vcpkg_add_package(uchardet)
	vcpkg_add_package(libxml2)]]

endif(OPT_USE_STATIC_EXT_LIBS)

project (far2l LANGUAGES C CXX)

set(APP_NAME "far2l")
set(APP_IDENTIFIER "com.far2l")
set(CPACK_PACKAGE_NAME "far2l")

string(ASCII 27 Esc)
set(ColorNormal "${Esc}[m")
set(ColorRed "${Esc}[1;31m")

include(GNUInstallDirs)

# just to force reconfigure if packaging/version changed
configure_file(${CMAKE_SOURCE_DIR}/packaging/version ${CMAKE_BINARY_DIR}/packaging/version @ONLY)

# reconfigure in case .git directory changed to update version correctly
IF(EXISTS ${CMAKE_SOURCE_DIR}/.git)
    set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS ${CMAKE_SOURCE_DIR}/.git)
endif()

file(READ "${CMAKE_SOURCE_DIR}/packaging/version" VERSION)
string(REGEX REPLACE "[\r\n\t ]$" "" VERSION "${VERSION}")
string(REGEX REPLACE "^([0-9]+)\\..*" "\\1" VERSION_MAJOR "${VERSION}")
string(REGEX REPLACE "^[0-9]+\\.([0-9]+).*" "\\1" VERSION_MINOR "${VERSION}")
string(REGEX REPLACE "^[0-9]+\\.[0-9]+\\.(.*)" "\\1" VERSION_PATCH "${VERSION}")

if("${VERSION_MAJOR}" STREQUAL "" OR "${VERSION_MAJOR}" STREQUAL "${VERSION}"
    OR "${VERSION_MINOR}" STREQUAL "" OR "${VERSION_MINOR}" STREQUAL "${VERSION}"
    OR "${VERSION_PATCH}" STREQUAL "" OR "${VERSION_PATCH}" STREQUAL "${VERSION}")
        message(FATAL_ERROR "${ColorRed}packaging/version is corrupted, please write actual X.Y.Z version into it.${ColorNormal}")
endif()

find_package(Git)

if(GIT_FOUND)
    execute_process(COMMAND "${GIT_EXECUTABLE}" describe --tag
        WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
        OUTPUT_VARIABLE GIT_TAG
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_QUIET)
endif()

if(NOT "${GIT_TAG}" STREQUAL "v_${VERSION}")
    if(GIT_FOUND)
        if(IS_DIRECTORY ${CMAKE_SOURCE_DIR}/.git)
            execute_process(COMMAND "${GIT_EXECUTABLE}" show --no-patch --format=%ci HEAD
                WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
                OUTPUT_VARIABLE GIT_DATE
                OUTPUT_STRIP_TRAILING_WHITESPACE)
            string(SUBSTRING ${GIT_DATE} 0 10 GIT_DATE)
            execute_process(COMMAND "${GIT_EXECUTABLE}" rev-parse --short HEAD
                WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
                OUTPUT_VARIABLE GIT_HASH
                OUTPUT_STRIP_TRAILING_WHITESPACE)
        endif()
    endif()
    if(NOT "${GIT_DATE}" STREQUAL "")
        message(STATUS "git date: ${GIT_DATE}")
        set(VERSION_PATCH "${VERSION_PATCH}-${GIT_DATE}")
    endif()
    if(NOT "${GIT_HASH}" STREQUAL "")
        message(STATUS "git hash: ${GIT_HASH}")
        set(VERSION_PATCH "${VERSION_PATCH}-${GIT_HASH}")
    else()
        message(WARNING "git information unavailable, assuming its a build from v_${VERSION}")
    endif()
endif()

set(VERSION_PATCH "${VERSION_PATCH}-beta")

set(VERSION "${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH}")

set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_EXTENSIONS OFF)

if(NOT CMAKE_BUILD_TYPE)
   set(CMAKE_BUILD_TYPE "Release")
endif()

message(STATUS "Build Type: ${CMAKE_BUILD_TYPE} Version: ${VERSION}")

if(NOT DEFINED CMAKE_INSTALL_PREFIX)
   if (${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
      set(CMAKE_INSTALL_PREFIX "/usr/local")
   elseif (${CMAKE_SYSTEM_NAME} MATCHES "FreeBSD")
      set(CMAKE_INSTALL_PREFIX "/usr/local")
   else()
      set(CMAKE_INSTALL_PREFIX "/usr")
   endif()
endif()

##############################

if (NOT DEFINED TESTING)
    set(TESTING "NO")
endif()

if (NOT DEFINED USEWX)
    set(USEWX "YES")
endif()

if (NOT DEFINED UNRAR)
    set(UNRAR "bundled")
endif()

# EACP disabled by default for now as FAR's GetCodePageInfo rejects all multibyte charsets due to BUGBUG.
# Uncomment EACP-stuff here when that will be fixed. See https://github.com/elfmz/far2l/issues/1179
#if (NOT DEFINED EACP)
#   set(EACP "YES")
#endif()

if (NOT DEFINED LEGACY)
    # TODO: default it to NO  somewhere in 2022, after all obsolete settings
    # registry-upgrade-to-ini stuff will be safe to remove
    set(LEGACY "YES")
elseif(FARFTP)
    set(LEGACY "YES")
    message(STATUS "Force-enable LEGACY due to enabled FARFTP")
endif()

#if (NOT EACP)
#   message(STATUS "${ColorRed}Building without East Asian codepages support due to EACP=${EACP}${ColorNormal}")
#endif()

# set(RM rm) actually not needed: use $(CMAKE_COMMAND) -E remove

if(MUSL)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -D__MUSL__")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -D__MUSL__")
endif()

if(TAR_LIMITED_ARGS)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -D__TAR_LIMITED_ARGS__")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -D__TAR_LIMITED_ARGS__")
endif()

if(${CMAKE_VERSION} VERSION_LESS "3.1.0")
    message("Please consider to switch to newer CMake")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")
endif()

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -fPIC -Wno-unused-function -D_FILE_OFFSET_BITS=64 -D_GLIBCXX_ASSERTIONS") #  -fsanitize=address
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall -std=c99 -fPIC -Wno-unused-function -D_FILE_OFFSET_BITS=64") # -fsanitize=address -fsanitize=bounds
set(CMAKE_CXX_FLAGS_RELEASE "-O2")
set(CMAKE_C_FLAGS_RELEASE "-O2")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-deprecated -D_FILE_OFFSET_BITS=64") #-Wno-c++11-narrowing -fsanitize=address -fsanitize=bounds
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -D_FILE_OFFSET_BITS=64") # -fsanitize=address -fsanitize=bounds
set(CMAKE_SHARED_LIBRARY_LINK_DYNAMIC_FLAGS "${CMAKE_SHARED_LIBRARY_LINK_DYNAMIC_FLAGS} -fpie -Os") # -static-libgcc -static-libstdc++")
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -fpie -Os") # -static-libgcc -static-libstdc++") #-Os -pthread

set(TOOLS_DIR ${CMAKE_BINARY_DIR}/tools)

if(${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
    set(APP_DIR ${CMAKE_BINARY_DIR}/install)
    set(INSTALL_DIR ${APP_DIR}/${APP_NAME}.app/Contents/MacOS)
    set(EXECUTABLE_NAME ${APP_NAME})

else()
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -ffunction-sections -fdata-sections")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -ffunction-sections -fdata-sections")
    set(INSTALL_DIR ${CMAKE_BINARY_DIR}/install)
    set(EXECUTABLE_NAME far2l)

    if (NOT CMAKE_CXX_COMPILER_ID MATCHES "Clang")
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wl,--gc-sections")
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wl,--gc-sections")
    endif()
endif()

if (CMAKE_SYSTEM_NAME MATCHES "CYGWIN")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -D_GNU_SOURCE -D_BSD_SOURCE -D_XOPEN_SOURCE=600")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -D_GNU_SOURCE -D_BSD_SOURCE -D_XOPEN_SOURCE=600")
    message(STATUS "Running under cygwin, wow!")
endif()

if (CMAKE_SYSTEM_NAME MATCHES "Haiku")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -D_GNU_SOURCE -D_DEFAULT_SOURCE -Wno-attributes")
endif()

set(CMAKE_CXX_VISIBILITY_PRESET hidden)
set(CMAKE_C_VISIBILITY_PRESET hidden)

if (LEGACY)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DWINPORT_REGISTRY")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DWINPORT_REGISTRY")
    message(STATUS "Enabling registry support due to enabled LEGACY")
else()
    message(STATUS "LEGACY is not enabled, your old registry settings will be forgotten, if any")
endif()

if(CMAKE_VERSION VERSION_GREATER "3.3")
    cmake_policy(SET CMP0063 NEW)
    cmake_policy(SET CMP0057 NEW)
endif()

include_directories(utils/include)

add_subdirectory (WinPort)
add_subdirectory (utils)
add_subdirectory (far2l)

if (NOT ${USEWX})
    message(STATUS "Building without GUI/wxWidgets backend due to USEWX=${USEWX}")
else()
    message(STATUS "Building with GUI/wxWidgets backend")
    if (${CMAKE_SYSTEM_NAME} MATCHES "FreeBSD")
        if (DEFINED wxWidgets_CONFIG_EXECUTABLE)
            message(STATUS "Using pre-defined wx config: ${wxWidgets_CONFIG_EXECUTABLE}")

        elseif(EXISTS "/usr/local/bin/wxgtk3u-3.2-config")
            set(wxWidgets_CONFIG_EXECUTABLE "/usr/local/bin/wxgtk3u-3.2-config")
            set(wxWidgets_wxrc_EXECUTABLE "/usr/local/bin/wxrc-gtk3u-3.2")
            message(STATUS "Using known location of wx-config 3.2")

        elseif(EXISTS "/usr/local/bin/wxgtk3u-3.1-config")
            set(wxWidgets_CONFIG_EXECUTABLE "/usr/local/bin/wxgtk3u-3.1-config")
            set(wxWidgets_wxrc_EXECUTABLE "/usr/local/bin/wxrc-gtk3u-3.1")
            message(STATUS "Using known location of wx-config 3.1")

        elseif (EXISTS "/usr/local/bin/wxgtk3u-3.0-config")
            set(wxWidgets_CONFIG_EXECUTABLE "/usr/local/bin/wxgtk3u-3.0-config")
            set(wxWidgets_wxrc_EXECUTABLE "/usr/local/bin/wxrc-gtk3u-3.0")
            message(STATUS "Using known location of wx-config 3.0")

        else()
            message(STATUS "No wxgtk3u-3.*-config in expected locations")
        endif()

    elseif (${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
        if (EXISTS "/opt/local/Library/Frameworks/wxWidgets.framework/Versions/wxWidgets/3.2/bin/wx-config")
            # MacPorts
            set(wxWidgets_CONFIG_EXECUTABLE "/opt/local/Library/Frameworks/wxWidgets.framework/Versions/wxWidgets/3.2/bin/wx-config")
            set(wxWidgets_wxrc_EXECUTABLE "/opt/local/Library/Frameworks/wxWidgets.framework/Versions/wxWidgets/3.2/bin/wxrc")
            message(STATUS "Using known location of wx-config 3.2")

        elseif (EXISTS "/opt/local/Library/Frameworks/wxWidgets.framework/Versions/wxWidgets/3.1/bin/wx-config")
            # MacPorts
            set(wxWidgets_CONFIG_EXECUTABLE "/opt/local/Library/Frameworks/wxWidgets.framework/Versions/wxWidgets/3.1/bin/wx-config")
            set(wxWidgets_wxrc_EXECUTABLE "/opt/local/Library/Frameworks/wxWidgets.framework/Versions/wxWidgets/3.1/bin/wxrc")
            message(STATUS "Using known location of wx-config 3.1")

        else()
            message(STATUS "No wx-config in expected locations")
        endif()
    endif()

    add_subdirectory(WinPort/src/Backend/WX)
endif()

if (NOT DEFINED TTYX)
    find_package(X11)
    if(X11_FOUND)
        message(STATUS "Building with TTY X11 extensions due to X11 found")
        add_subdirectory(WinPort/src/Backend/TTY/TTYX)
    else()
        message(STATUS "Building without TTY X11 extensions due to X11 not found")
    endif()
elseif (TTYX)
    message(STATUS "Building with TTY X11 extensions due to TTYX=${TTYX}")
    add_subdirectory(WinPort/src/Backend/TTY/TTYX)
else()
    message(STATUS "Building without TTY X11 extensions due to TTYX=${TTYX}")
endif()


##############################
# plugins directives

if (NOT DEFINED ALIGN OR ALIGN)
    message(STATUS "ALIGN plugin enabled")
    add_subdirectory (align)
else()
    message(STATUS "${ColorRed}ALIGN plugin disabled due to ALIGN=${ALIGN}${ColorNormal}")
    install(CODE "
        execute_process(COMMAND ${CMAKE_COMMAND} -E rm -f ${CMAKE_INSTALL_PREFIX}/lib/far2l/Plugins/align/plug/align.far-plug-wide)
        " COMPONENT system)
endif()

if (NOT DEFINED AUTOWRAP OR AUTOWRAP)
    message(STATUS "AUTOWRAP plugin enabled")
    add_subdirectory (autowrap)
else()
    message(STATUS "${ColorRed}AUTOWRAP plugin disabled due to AUTOWRAP=${AUTOWRAP}${ColorNormal}")
    install(CODE "
        execute_process(COMMAND ${CMAKE_COMMAND} -E rm -f ${CMAKE_INSTALL_PREFIX}/lib/far2l/Plugins/autowrap/plug/autowrap.far-plug-wide)
        " COMPONENT system)
endif()

if (NOT DEFINED CALC OR CALC)
    message(STATUS "CALC plugin enabled")
    add_subdirectory (calc)
else()
    message(STATUS "${ColorRed}CALC plugin disabled due to CALC=${CALC}${ColorNormal}")
    install(CODE "
        execute_process(COMMAND ${CMAKE_COMMAND} -E rm -f ${CMAKE_INSTALL_PREFIX}/lib/far2l/Plugins/calc/plug/calc.far-plug-wide)
        " COMPONENT system)
endif()

if (NOT DEFINED COLORER OR COLORER)
    message(STATUS "COLORER plugin enabled")
    add_subdirectory (colorer)
else()
    message(STATUS "${ColorRed}COLORER plugin disabled due to COLORER=${COLORER}${ColorNormal}")
    install(CODE "
        execute_process(COMMAND ${CMAKE_COMMAND} -E rm -f ${CMAKE_INSTALL_PREFIX}/lib/far2l/Plugins/colorer/plug/colorer.far-plug-wide)
        " COMPONENT system)
endif()

if (NOT DEFINED COMPARE OR COMPARE)
    message(STATUS "COMPARE plugin enabled")
    add_subdirectory (compare)
else()
    message(STATUS "${ColorRed}COMPARE plugin disabled due to COMPARE=${COMPARE}${ColorNormal}")
    install(CODE "
        execute_process(COMMAND ${CMAKE_COMMAND} -E rm -f ${CMAKE_INSTALL_PREFIX}/lib/far2l/Plugins/compare/plug/compare.far-plug-wide)
        " COMPONENT system)
endif()

if (NOT DEFINED DRAWLINE OR DRAWLINE)
    message(STATUS "DRAWLINE plugin enabled")
    add_subdirectory (drawline)
else()
    message(STATUS "${ColorRed}DRAWLINE plugin disabled due to DRAWLINE=${DRAWLINE}${ColorNormal}")
    install(CODE "
        execute_process(COMMAND ${CMAKE_COMMAND} -E rm -f ${CMAKE_INSTALL_PREFIX}/lib/far2l/Plugins/drawline/plug/drawline.far-plug-wide)
        " COMPONENT system)
endif()

if (NOT DEFINED EDITCASE OR EDITCASE)
    message(STATUS "EDITCASE plugin enabled")
    add_subdirectory (editcase)
else()
    message(STATUS "${ColorRed}EDITCASE plugin disabled due to EDITCASE=${EDITCASE}${ColorNormal}")
    install(CODE "
        execute_process(COMMAND ${CMAKE_COMMAND} -E rm -f ${CMAKE_INSTALL_PREFIX}/lib/far2l/Plugins/editcase/plug/editcase.far-plug-wide)
        " COMPONENT system)
endif()

if (NOT DEFINED EDITORCOMP OR EDITORCOMP)
    message(STATUS "EDITORCOMP plugin enabled")
    add_subdirectory (editorcomp)
else()
    message(STATUS "${ColorRed}EDITORCOMP plugin disabled due to EDITORCOMP=${EDITORCOMP}${ColorNormal}")
    install(CODE "
        execute_process(COMMAND ${CMAKE_COMMAND} -E rm -f ${CMAKE_INSTALL_PREFIX}/lib/far2l/Plugins/editorcomp/plug/editorcomp.far-plug-wide)
        " COMPONENT system)
endif()

if (DEFINED FARFTP AND FARFTP)
    message(STATUS "FARFTP plugin enabled (obsolete)")
    add_subdirectory (FARStdlib)
    add_subdirectory (farftp)
else()
    install(CODE "
        execute_process(COMMAND ${CMAKE_COMMAND} -E rm -f ${CMAKE_INSTALL_PREFIX}/lib/far2l/Plugins/farftp/plug/farftp.far-plug-mb)
        " COMPONENT system)
endif()

if (NOT DEFINED FILECASE OR FILECASE)
    message(STATUS "FILECASE plugin enabled")
    add_subdirectory (filecase)
else()
    message(STATUS "${ColorRed}FILECASE plugin disabled due to FILECASE=${FILECASE}${ColorNormal}")
    install(CODE "
        execute_process(COMMAND ${CMAKE_COMMAND} -E rm -f ${CMAKE_INSTALL_PREFIX}/lib/far2l/Plugins/filecase/plug/filecase.far-plug-wide)
        " COMPONENT system)
endif()

if (NOT DEFINED INCSRCH OR INCSRCH)
    message(STATUS "INCSRCH plugin enabled")
    add_subdirectory (incsrch)
else()
    message(STATUS "${ColorRed}Building without <INCSRCH> plugin due to INCSRCH=${INCSRCH}${ColorNormal}")
    install(CODE "
        execute_process(COMMAND ${CMAKE_COMMAND} -E rm -f ${CMAKE_INSTALL_PREFIX}/lib/far2l/Plugins/incsrch/plug/incsrch.far-plug-wide)
        " COMPONENT system)
endif()

if (NOT DEFINED INSIDE OR INSIDE)
    message(STATUS "INSIDE plugin enabled")
    add_subdirectory (inside)
else()
    message(STATUS "${ColorRed}INSIDE plugin disabled due to INSIDE=${INSIDE}${ColorNormal}")
    install(CODE "
        execute_process(COMMAND ${CMAKE_COMMAND} -E rm -f ${CMAKE_INSTALL_PREFIX}/lib/far2l/Plugins/inside/plug/inside.far-plug-mb)
        " COMPONENT system)
endif()

#set(OPENSSL_USE_STATIC_LIBS TRUE)
if(OPT_USE_STATIC_EXT_LIBS)
  find_library(OPENSSL_LIBRARY
    NAMES
      libcrypto.a
    HINTS ${OPENSSL_ROOT_DIR} ENV OPENSSL_ROOT_DIR
    NAMES_PER_DIR
    PATHS
      ${OPENSSL_ROOT_DIR}/lib
    NO_CMAKE_SYSTEM_PATH
    NO_DEFAULT_PATH
  )
  #message("OPENSSL_LIBRARY: ${OPENSSL_LIBRARY}")
  #message("OPENSSL_FOUND: ${OPENSSL_FOUND}")
  if(EXISTS ${OPENSSL_LIBRARY})
    set(OPENSSL_FOUND TRUE)
    set(OPENSSL_LIBRARIES ${OPENSSL_LIBRARY})
    set(OPENSSL_INCLUDE_DIR ${OPENSSL_ROOT_DIR}/include)
    set(OPENSSL_INCLUDE_DIRS ${OPENSSL_INCLUDE_DIR})
    add_library(OPENSSL STATIC IMPORTED)
    set_target_properties(OPENSSL PROPERTIES IMPORTED_LOCATION ${OPENSSL_LIBRARY})
  endif()
else()
  include(${CMAKE_ROOT}/Modules/FindOpenSSL.cmake)
  find_package(OpenSSL REQUIRED)
endif(OPT_USE_STATIC_EXT_LIBS)
#message("OPENSSL_LIBRARIES: ${OPENSSL_LIBRARIES}")
if (NOT DEFINED MULTIARC OR MULTIARC)
    message(STATUS "MULTIARC plugin enabled")

    find_package(PkgConfig REQUIRED)
    pkg_search_module(LibArchive QUIET libarchive)
    if(NOT LibArchive_FOUND)
        # workaround for MacOS brew's/macports' libarchive
        if(IS_DIRECTORY "/usr/local/opt/libarchive/include")
            set(LibArchive_INCLUDE_DIR "/usr/local/opt/libarchive/include")
            set(LibArchive_LIBRARY "/usr/local/opt/libarchive/lib/libarchive.dylib")
        elseif(EXISTS "/opt/local/lib/libarchive.dylib")
            set(LibArchive_LIBRARY "/opt/local/lib/libarchive.dylib")
        endif()
        find_package(LibArchive)
        if(NOT LibArchive_FOUND)
            message(WARNING "${ColorRed}libarchive not found, multiarc will have weaker archives support. Its recommended to install libarchive-dev and reconfigure far2l.${ColorNormal}")
        endif()
    endif()

    add_subdirectory (multiarc)
else()
    message(STATUS "${ColorRed}MULTIARC plugin disabled due to MULTIARC=${MULTIARC}${ColorNormal}")
    install(CODE "
        execute_process(COMMAND ${CMAKE_COMMAND} -E rm -f ${CMAKE_INSTALL_PREFIX}/lib/far2l/Plugins/multiarc/plug/multiarc.far-plug-mb)
        " COMPONENT system)
endif()

if (NOT DEFINED NETROCKS OR NETROCKS)
    message(STATUS "NETROCKS plugin enabled")
    find_package(OpenSSL)
    if(OPENSSL_FOUND)
        message(STATUS "OpenSSL found -> enjoy FTPS support in NetRocks")
    else()
        message(WARNING "${ColorRed}OpenSSL not found, NetRocks will not have FTPS protocol support. Install libssl-dev if you want FTPS protocol available in NetRocks.${ColorNormal}")
    endif(OPENSSL_FOUND)

    find_package(LibSSH 0.5.0)
    if(LIBSSH_FOUND)
        message(STATUS "libssh found -> enjoy SFTP support in NetRocks")
    else()
        message(WARNING "${ColorRed}libssh not found, NetRocks will not have SFTP protocol support. Install libssh-dev if you want SFTP protocol available in NetRocks.${ColorNormal}")
    endif(LIBSSH_FOUND)

	if(FALSE)
	if(OPT_USE_STATIC_EXT_LIBS)
	#TODO: get and build https://github.com/samba-team/samba.git
 	set(LIBSMBCLIENT_ROOT "${CMAKE_CURRENT_BINARY_DIR}/samba_${VCPKG_TARGET_TRIPLET}")
  #message("VCPKG_INSTALLED_PATH: ${VCPKG_INSTALLED_PATH}")
  #TODO: install libtool gettext xmlto
 	ExternalProject_Add(smbclient-static
 		GIT_REPOSITORY https://github.com/samba-team/samba.git
 		GIT_TAG samba-4.16.4 #samba-4.15.4
 		BUILD_IN_SOURCE TRUE
 		CONFIGURE_COMMAND ./autogen.sh
 		COMMAND ./configure --prefix=${LIBSMBCLIENT_FOUND} --enable-static --with-ssl=openssl --with-libxml2 --with-libs=${VCPKG_INSTALLED_PATH}:${VCPKG_ROOT}/packages/zlib_${VCPKG_TARGET_TRIPLET}:${VCPKG_ROOT}/packages/libxml2_${VCPKG_TARGET_TRIPLET}
 		BUILD_COMMAND make
    COMMAND make docs
    COMMAND make update-po
    COMMAND make compile-gmo
 		INSTALL_COMMAND make install
 		UPDATE_COMMAND ""
 	)
	endif(OPT_USE_STATIC_EXT_LIBS)
	endif(FALSE)

    find_package(Libsmbclient)
    if(LIBSMBCLIENT_FOUND)
        message(STATUS "libsmbclient found -> enjoy SMB support in NetRocks")
    else()
        message(WARNING "${ColorRed}libsmbclient not found, NetRocks will not have SMB protocol support. Install libsmbclient-dev if you want SMB protocol available in NetRocks.${ColorNormal}")
    endif(LIBSMBCLIENT_FOUND)

    if (FALSE)
    if (OPT_USE_STATIC_EXT_LIBS)
    #TODO: get and build https://github.com/samba-team/samba.git
    set(LIBSMBCLIENT_ROOT "${CMAKE_CURRENT_BINARY_DIR}/samba_${VCPKG_TARGET_TRIPLET}")
    #message("VCPKG_INSTALLED_PATH: ${VCPKG_INSTALLED_PATH}")
    #TODO: install libtool gettext xmlto
    ExternalProject_Add(smbclient-static
        GIT_REPOSITORY https://github.com/samba-team/samba.git
        GIT_TAG samba-4.16.4 #samba-4.15.4
        BUILD_IN_SOURCE TRUE
        CONFIGURE_COMMAND ./autogen.sh
        COMMAND ./configure --prefix=${LIBSMBCLIENT_FOUND} --enable-static --with-ssl=openssl --with-libxml2 --with-libs=${VCPKG_INSTALLED_PATH}:${VCPKG_ROOT}/packages/zlib_${VCPKG_TARGET_TRIPLET}:${VCPKG_ROOT}/packages/libxml2_${VCPKG_TARGET_TRIPLET}
        BUILD_COMMAND make
    COMMAND make docs
    COMMAND make update-po
    COMMAND make compile-gmo
        INSTALL_COMMAND make install
        UPDATE_COMMAND ""
    )
    endif (OPT_USE_STATIC_EXT_LIBS)
    endif (FALSE)

    if (FALSE)
    if (OPT_USE_STATIC_EXT_LIBS)
        set(LibNfs_DIR "${CMAKE_BINARY_DIR}/nfs_${VCPKG_TARGET_TRIPLET}")
        ExternalProject_Add(nfs-static
            GIT_REPOSITORY https://github.com/sahlberg/libnfs.git
            SOURCE_SUBDIR "src"
            GIT_TAG libnfs-5.0.1

            # BUILD_IN_SOURCE TRUE
            PREFIX ${CMAKE_BINARY_DIR}/nfs
            INSTALL_DIR ${LibNfs_DIR}
            CONFIGURE_COMMAND cd ${CMAKE_BINARY_DIR}/nfs/src/nfs-static && ./bootstrap
            COMMAND cd ${CMAKE_BINARY_DIR}/nfs/src/nfs-static && ./configure --prefix=${LibNfs_DIR} --enable-static --enable-shared=no
            BUILD_COMMAND cd ${CMAKE_BINARY_DIR}/nfs/src/nfs-static && make || exit 0
            INSTALL_COMMAND cd ${CMAKE_BINARY_DIR}/nfs/src/nfs-static && make install || exit 0
            UPDATE_COMMAND ""
        )
        # ExternalProject_Get_Property(nfs-static install_dir)
        # message("install_dir: ${install_dir}")
        set(LIBNFS_FOUND TRUE)
        set(LIBNFS_INCLUDE_DIR ${LibNfs_DIR}/include)
        set(LIBNFS_LIBRARY ${LibNfs_DIR}/lib/libnfs.a)
        set(LIBNFS_LIBRARIES ${LIBNFS_LIBRARY})
        set(LIBNFS_INCLUDE_DIRS ${LIBNFS_INCLUDE_DIR})
        set(LIBNFS_LIBRARIES ${LIBNFS_LIBRARY})
        set(CMAKE_PREFIX_PATH ${LibNfs_DIR} ${CMAKE_PREFIX_PATH})
        add_library(LibNfs STATIC IMPORTED)
        set_target_properties(LibNfs PROPERTIES IMPORTED_LOCATION ${LIBNFS_LIBRARY})
        add_dependencies(LibNfs nfs-static)
        set_source_files_properties(
            ${LIBNFS_LIBRARY}
            PROPERTIES GENERATED TRUE
        )
    endif (OPT_USE_STATIC_EXT_LIBS)
    endif (FALSE)

    if(OPT_USE_STATIC_EXT_LIBS AND EXISTS LIBNEON_ROOT_DIR)
      find_library(LIBNEON_LIBRARY
        NAMES
          neon
        HINTS ENV LIBNEON_ROOT_DIR
        PATHS
          ${LIBNEON_ROOT_DIR}/lib
        NO_CMAKE_SYSTEM_PATH
      )
      message(STATUS "LIBNEON_LIBRARY: ${LIBNEON_LIBRARY}")
      message(STATUS "LIBNEON_ROOT_DIR: ${LIBNEON_ROOT_DIR}")
      message(STATUS "LIBNEON_FOUND: '${LIBNEON_FOUND}'")
      if(LIBNEON_FOUND STREQUAL TRUE AND EXISTS ${LIBNEON_LIBRARY})
        # set(LIBNEON_FOUND TRUE)
        set(LIBNEON_LIBRARIES ${LIBNEON_LIBRARY})
        set(LIBNEON_INCLUDE_DIR ${LIBNEON_ROOT_DIR}/include)
        set(LIBNEON_INCLUDE_DIRS ${LIBNEON_INCLUDE_DIR})
        add_library(LibNEON STATIC IMPORTED)
          set_target_properties(LibNEON PROPERTIES IMPORTED_LOCATION ${LIBNEON_LIBRARY})
      endif()
    else()
      include(cmake/modules/FindLibNEON.cmake)
      find_package(LibNEON CONFIG)
    endif()

    find_package(LibNfs)
    if(LIBNFS_FOUND)
        message(STATUS "libnfs found -> enjoy NFS support in NetRocks")
    else()
        message(WARNING "${ColorRed}libnfs not found, NetRocks will not have NFS protocol support. Install libnfs-dev if you want NFS protocol available in NetRocks.${ColorNormal}")
    endif(LIBNFS_FOUND)

	if(OPT_USE_STATIC_EXT_LIBS)
		find_package(LibXml2 CONFIG)
		find_package(liblzma CONFIG)
		set(LibNEON_DIR /build/neon)
  	set(LIBNEON_LIBRARY ${LibNEON_DIR}/lib/libneon.a)
		if(EXISTS ${LIBNEON_LIBRARY})
      set(LIBNEON_FOUND TRUE)
      set(LIBNEON_LIBRARIES ${LIBNEON_LIBRARY})
      set(LIBNEON_INCLUDE_DIR ${LibNEON_DIR}/include)
      set(LIBNEON_INCLUDE_DIRS ${LIBNEON_INCLUDE_DIR})
      add_library(LibNEON STATIC IMPORTED)
  		set_target_properties(LibNEON PROPERTIES IMPORTED_LOCATION ${LIBNEON_LIBRARY})
    endif()
  else()
    find_package(LibNEON)
  endif(OPT_USE_STATIC_EXT_LIBS)

  # message("LibNEON_FOUND: ${LibNEON_FOUND}")
	# message("LIBNEON_LIBRARY: ${LIBNEON_LIBRARY}")
	# message("LIBNEON_LIBRARIES: ${LIBNEON_LIBRARIES}")
        message(STATUS "libneon found -> enjoy WebDav support in NetRocks")
    else()
        message(WARNING "${ColorRed}libneon not found, NetRocks will not have WebDav protocol support. Install libneon*-dev if you want WebDav protocol available in NetRocks.${ColorNormal}")
    endif()

    add_subdirectory (NetRocks)

    #message("OPENSSL_LIBRARIES: ${OPENSSL_LIBRARIES}")
    if(OPT_USE_STATIC_EXT_LIBS)
        #add_dependencies(NetRocks-NFS LibNfs)
        if(LIBNEON_FOUND STREQUAL TRUE AND EXISTS ${LIBNEON_LIBRARY})
        # add_dependencies(NetRocks-WebDAV LibNEON)
        target_link_libraries(NetRocks-WebDAV ${LIBNEON_LIBRARY})
        target_link_libraries(NetRocks-WebDAV ${OPENSSL_LIBRARIES} #${OPENSSL_SSL_LIBRARY} #LibXml2::LibXml2 LibLZMA::LibLZMA
            ${VCPKG_INSTALLED_PATH}/lib/libz.a
            ${VCPKG_INSTALLED_PATH}/lib/libxml2.a
            ${VCPKG_INSTALLED_PATH}/lib/liblzma.a
            #${VCPKG_INSTALLED_PATH}/lib/liproxy.a
            dl)
        endif()
    endif(OPT_USE_STATIC_EXT_LIBS)

else()
    message(STATUS "${ColorRed}NETROCKS plugin disabled due to NETROCKS=${NETROCKS}${ColorNormal}")
    install(CODE "
        execute_process(COMMAND ${CMAKE_COMMAND} -E rm -f ${CMAKE_INSTALL_PREFIX}/lib/far2l/Plugins/NetRocks/plug/NetRocks.far-plug-wide)
        " COMPONENT system)
endif()

if (DEFINED PYTHON AND PYTHON)
    message(STATUS "PYTHON plugin with interpreter from virtualenv enabled")
    add_subdirectory (python)
    # Copy this explicitly cuz generic copier command excludes 'far2l'
    install(DIRECTORY "${INSTALL_DIR}/Plugins/python/plug/far2l"
        DESTINATION "lib/far2l/Plugins/python/plug/" USE_SOURCE_PERMISSIONS
        COMPONENT base FILES_MATCHING
        PATTERN "*")
    install(DIRECTORY "${INSTALL_DIR}/Plugins/python/plug/plugins"
        DESTINATION "lib/far2l/Plugins/python/plug/" USE_SOURCE_PERMISSIONS
        COMPONENT base FILES_MATCHING
        PATTERN "*")
else()
    message(STATUS "${ColorRed}PYTHON plugin disabled, use -DPYTHON=yes if you need it${ColorNormal}")
    install(CODE "
        execute_process(COMMAND rm -f ${CMAKE_INSTALL_PREFIX}/lib/far2l/Plugins/python/plug/python.far-plug-wide)
        " COMPONENT system)
endif()

if (NOT DEFINED SIMPLEINDENT OR SIMPLEINDENT)
    message(STATUS "SIMPLEINDENT plugin enabled")
    add_subdirectory (SimpleIndent)
else()
    message(STATUS "${ColorRed}SIMPLEINDENT plugin disabled due to SIMPLEINDENT=${SIMPLEINDENT}${ColorNormal}")
    install(CODE "
        execute_process(COMMAND rm -f ${CMAKE_INSTALL_PREFIX}/lib/far2l/Plugins/SimpleIndent/plug/SimpleIndent.far-plug-wide)
        " COMPONENT system)
endif()

if (NOT DEFINED TMPPANEL OR TMPPANEL)
    message(STATUS "TMPPANEL plugin enabled")
    add_subdirectory (tmppanel)
else()
    message(STATUS "${ColorRed}TMPPANEL plugin disabled due to TMPPANEL=${TMPPANEL}${ColorNormal}")
    install(CODE "
        execute_process(COMMAND rm -f ${CMAKE_INSTALL_PREFIX}/lib/far2l/Plugins/tmppanel/plug/tmppanel.far-plug-wide)
        " COMPONENT system)
endif()

##############################
# common install directives

add_subdirectory (packaging)

add_subdirectory(man)
add_subdirectory(bash-completion)

if (${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
    set(FIXUP_SCRIPT packaging/osx/FixupBundle.cmake)
    configure_file(${FIXUP_SCRIPT}.in ${PROJECT_BINARY_DIR}/${FIXUP_SCRIPT} @ONLY)
    install(DIRECTORY ${APP_DIR}/${APP_NAME}.app DESTINATION . USE_SOURCE_PERMISSIONS COMPONENT app EXCLUDE_FROM_ALL)
    install(SCRIPT ${PROJECT_BINARY_DIR}/${FIXUP_SCRIPT} COMPONENT app EXCLUDE_FROM_ALL)
endif()

install(PROGRAMS "${INSTALL_DIR}/${EXECUTABLE_NAME}" DESTINATION "bin" RENAME far2l COMPONENT base)

install(DIRECTORY "${INSTALL_DIR}/" DESTINATION "lib/far2l" USE_SOURCE_PERMISSIONS COMPONENT base FILES_MATCHING
    PATTERN "colorer/base" EXCLUDE
    PATTERN "far2l_gui.so"
    PATTERN "far2l_ttyx.broker"
    PATTERN "plug/*.far-plug-*"
    PATTERN "plug/*.broker"
)

install(DIRECTORY "${INSTALL_DIR}/" DESTINATION "share/far2l" USE_SOURCE_PERMISSIONS COMPONENT base FILES_MATCHING
    PATTERN "${EXECUTABLE_NAME}" EXCLUDE
    PATTERN "far2ledit" EXCLUDE
    PATTERN "far2l_*" EXCLUDE
    PATTERN "*.far-plug-*" EXCLUDE
    PATTERN "*.broker" EXCLUDE
    PATTERN "python/plug/python" EXCLUDE
    PATTERN "*"
)

#[[get_cmake_property(_variableNames VARIABLES)
list (SORT _variableNames)
foreach (_variableName ${_variableNames})
    message(STATUS "${_variableName}=${${_variableName}}")
endforeach()]]

if(OPT_PVS_ANALYSIS)

include(FetchContent)
FetchContent_Declare(
    PVS_CMakeModule
    GIT_REPOSITORY "https://github.com/viva64/pvs-studio-cmake-module.git"
    GIT_TAG "master"
)

FetchContent_MakeAvailable(PVS_CMakeModule)
include("${pvs_cmakemodule_SOURCE_DIR}/PVS-Studio.cmake")

pvs_studio_add_target(TARGET far2l.analyze ALL
    OUTPUT FORMAT json
    ANALYZE far2l
    COMPILE_COMMANDS
    MODE GA:1,2
    LOG target.err
    # ARGS -e CMakeFiles/far2l.dir/far2l_autogen)
)

endif(OPT_PVS_ANALYSIS)

# setup some symlinks and remove deprecated stuff from previous installation
execute_process(COMMAND ${CMAKE_COMMAND} -E create_symlink ../../bin/far2l ${PROJECT_BINARY_DIR}/far2l/far2l_askpass)
execute_process(COMMAND ${CMAKE_COMMAND} -E create_symlink ../../bin/far2l ${PROJECT_BINARY_DIR}/far2l/far2l_sudoapp)
execute_process(COMMAND ${CMAKE_COMMAND} -E create_symlink far2l ${PROJECT_BINARY_DIR}/far2l/far2ledit)
install(FILES "${PROJECT_BINARY_DIR}/far2l/far2l_askpass" DESTINATION "lib/far2l" COMPONENT system)
install(FILES "${PROJECT_BINARY_DIR}/far2l/far2l_sudoapp" DESTINATION "lib/far2l" COMPONENT system)
install(FILES "${PROJECT_BINARY_DIR}/far2l/far2ledit" DESTINATION "bin" COMPONENT base)
install(CODE "
    execute_process(COMMAND ${CMAKE_COMMAND} -E remove -f \"\${CMAKE_INSTALL_PREFIX}/lib/far2l/Plugins/objinfo/plug/objinfo.far-plug-mb\")
    " COMPONENT system)

#[[get_cmake_property(_variableNames VARIABLES)
list (SORT _variableNames)
foreach (_variableName ${_variableNames})
	message(STATUS "${_variableName}=${${_variableName}}")
endforeach()]]

if(OPT_PVS_ANALYSIS)

include(FetchContent)
FetchContent_Declare(
	PVS_CMakeModule
	GIT_REPOSITORY "https://github.com/viva64/pvs-studio-cmake-module.git"
	GIT_TAG "master"
)
FetchContent_MakeAvailable(PVS_CMakeModule)
include("${pvs_cmakemodule_SOURCE_DIR}/PVS-Studio.cmake")

pvs_studio_add_target(TARGET far2l.analyze ALL
	OUTPUT FORMAT json
	ANALYZE far2l
	COMPILE_COMMANDS
	MODE GA:1,2
	LOG target.err
	# ARGS -e CMakeFiles/far2l.dir/far2l_autogen)
)

endif(OPT_PVS_ANALYSIS)

