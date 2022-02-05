set(CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake/modules)

cmake_minimum_required (VERSION 3.0.2)

option(OPT_USE_STATIC_EXT_LIBS "Build and use static external libraries: libneon, libsmb etc" OFF)

if(OPT_USE_STATIC_EXT_LIBS)
	# include(cmake/xrepo.cmake)
	# include(cmake/CPM.cmake)
	include(cmake/vcpkg.cmake)
	include(ExternalProject)

	if(NOT DEFINED VCPKG_ROOT)
		set(VCPKG_ROOT $ENV{VCPKG_ROOT})
	endif()

	# message("VCPKG_ROOT: ${VCPKG_ROOT}")
	# message("CMAKE_TOOLCHAIN_FILE: ${CMAKE_TOOLCHAIN_FILE}")
	if(DEFINED VCPKG_ROOT AND NOT DEFINED CMAKE_TOOLCHAIN_FILE) #OR DEFINED ${VCPKG_ROOT}
		set(CMAKE_TOOLCHAIN_FILE "${VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake" CACHE STRING "")
	endif()

	# message("CMAKE_TOOLCHAIN_FILE: ${CMAKE_TOOLCHAIN_FILE}")

	if(NOT DEFINED VCPKG_TARGET_TRIPLET)
		set(VCPKG_TARGET_TRIPLET $ENV{VCPKG_TARGET_TRIPLET})
	endif()

	if(NOT DEFINED VCPKG_TARGET_TRIPLET)
		set(VCPKG_TARGET_TRIPLET "x64-linux")
	endif()
	# message("VCPKG_TARGET_TRIPLET: ${VCPKG_TARGET_TRIPLET}")
	set(VCPKG_LIBS_PATH "${VCPKG_ROOT}/installed/${VCPKG_TARGET_TRIPLET}")

	message("VCPKG_LIBS_PATH: ${VCPKG_LIBS_PATH}")

	if(NOT DEFINED CMAKE_PREFIX_PATH)
		set(CMAKE_PREFIX_PATH "${VCPKG_LIBS_PATH}")
	endif()
	message("CMAKE_PREFIX_PATH: ${CMAKE_PREFIX_PATH}")

	vcpkg_add_package(uchardet)
	# set(UCHARDET_DIR "${VCPKG_LIBS_PATH}")
	# set(UCHARDET_FOUND TRUE)
	# set(UCHARDET_INCLUDE_DIR ${UCHARDET_DIR}/include/uchardet)
	# set(UCHARDET_LIBRARY ${UCHARDET_DIR}/lib/libuchardet.a)

endif(OPT_USE_STATIC_EXT_LIBS)

project (far2l)

set(APP_NAME "far2l")
set(APP_IDENTIFIER "com.far2l")
set(CPACK_PACKAGE_NAME "far2l")

string(ASCII 27 Esc)
set(ColorNormal "${Esc}[m")
set(ColorRed "${Esc}[1;31m")

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

execute_process(COMMAND sh -c
        "cd ${CMAKE_SOURCE_DIR} && git describe --tag"
        OUTPUT_VARIABLE GIT_TAG)
string(REGEX REPLACE "[\r\n\t ]$" "" GIT_TAG "${GIT_TAG}")

if(NOT "${GIT_TAG}" STREQUAL "v_${VERSION}")
	execute_process(COMMAND sh -c
		"cd ${CMAKE_SOURCE_DIR} && git rev-parse --short HEAD"
		OUTPUT_VARIABLE GIT_HASH)
	string(REGEX REPLACE "[\r\n\t ]$" "" GIT_HASH "${GIT_HASH}")
	if(NOT "${GIT_HASH}" STREQUAL "")
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

if (NOT DEFINED USEWX)
	set(USEWX "YES")
endif()

# EACP disabled by default for now as FAR's GetCodePageInfo rejects all multibyte charsets due to BUGBUG.
# Uncomment EACP-stuff here when that will be fixed. See https://github.com/elfmz/far2l/issues/1179
#if (NOT DEFINED EACP)
#	set(EACP "YES")
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
#	message(STATUS "${ColorRed}Building without East Asian codepages support due to EACP=${EACP}${ColorNormal}")
#endif()

if (${CMAKE_SYSTEM_NAME} MATCHES "FreeBSD")
    set(M4_NAME gm4)
else()
    set(M4_NAME m4)
endif()

find_program(M4_PROG NAMES ${M4_NAME})

if(NOT M4_PROG)
    message(FATAL_ERROR "${ColorRed}${M4_NAME} not found - please install it${ColorNormal}")
endif ()
set(M4 ${M4_PROG} -P "-DARCH=${CMAKE_SYSTEM_NAME} ${CMAKE_SYSTEM_PROCESSOR}" "-DMAJOR=${VERSION_MAJOR}" "-DMINOR=${VERSION_MINOR}" "-DPATCH=${VERSION_PATCH}")

# set(RM rm) actually not needed: use $(CMAKE_COMMAND) -E remove
find_program (GAWK NAMES gawk)
if(NOT GAWK)
  message(FATAL_ERROR "${ColorRed}gawk not found - please install it${ColorNormal}")
endif ()

if(${CMAKE_VERSION} VERSION_LESS "3.1.0")
    message("Please consider to switch to newer CMake")
	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")
endif()

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -fPIC -Wno-unused-function -Wno-deprecated -D_FILE_OFFSET_BITS=64") #-Wno-c++11-narrowing -fsanitize=address -fsanitize=bounds
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall -std=c99 -fPIC -Wno-unused-function -D_FILE_OFFSET_BITS=64") # -fsanitize=address -fsanitize=bounds
set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS} -O2")
set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS} -O2")
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

add_subdirectory (farlng)
add_subdirectory (WinPort)
add_subdirectory (utils)
add_subdirectory (far2l)
add_dependencies (far2l farlng)

set_target_properties(farlng
  PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "${TOOLS_DIR}"
)

if (NOT ${USEWX})
	message(STATUS "Building without GUI/wxWidgets backend due to USEWX=${USEWX}")
else()
	message(STATUS "Building with GUI/wxWidgets backend")
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
		execute_process(COMMAND rm -f ${CMAKE_INSTALL_PREFIX}/lib/far2l/Plugins/align/plug/align.far-plug-wide)
		" COMPONENT system)
endif()

if (NOT DEFINED AUTOWRAP OR AUTOWRAP)
	message(STATUS "AUTOWRAP plugin enabled")
	add_subdirectory (autowrap)
else()
	message(STATUS "${ColorRed}AUTOWRAP plugin disabled due to AUTOWRAP=${AUTOWRAP}${ColorNormal}")
	install(CODE "
		execute_process(COMMAND rm -f ${CMAKE_INSTALL_PREFIX}/lib/far2l/Plugins/autowrap/plug/autowrap.far-plug-wide)
		" COMPONENT system)
endif()

if (NOT DEFINED CALC OR CALC)
	message(STATUS "CALC plugin enabled")
	add_subdirectory (calc)
else()
	message(STATUS "${ColorRed}CALC plugin disabled due to CALC=${CALC}${ColorNormal}")
	install(CODE "
		execute_process(COMMAND rm -f ${CMAKE_INSTALL_PREFIX}/lib/far2l/Plugins/calc/plug/calc.far-plug-wide)
		" COMPONENT system)
endif()

if (NOT DEFINED COLORER OR COLORER)
	message(STATUS "COLORER plugin enabled")
	add_subdirectory (colorer)
else()
	message(STATUS "${ColorRed}COLORER plugin disabled due to COLORER=${COLORER}${ColorNormal}")
	install(CODE "
		execute_process(COMMAND rm -f ${CMAKE_INSTALL_PREFIX}/lib/far2l/Plugins/colorer/plug/colorer.far-plug-wide)
		" COMPONENT system)
endif()

if (NOT DEFINED COMPARE OR COMPARE)
	message(STATUS "COMPARE plugin enabled")
	add_subdirectory (compare)
else()
	message(STATUS "${ColorRed}COMPARE plugin disabled due to COMPARE=${COMPARE}${ColorNormal}")
	install(CODE "
		execute_process(COMMAND rm -f ${CMAKE_INSTALL_PREFIX}/lib/far2l/Plugins/compare/plug/compare.far-plug-wide)
		" COMPONENT system)
endif()

if (NOT DEFINED DRAWLINE OR DRAWLINE)
	message(STATUS "DRAWLINE plugin enabled")
	add_subdirectory (drawline)
else()
	message(STATUS "${ColorRed}DRAWLINE plugin disabled due to DRAWLINE=${DRAWLINE}${ColorNormal}")
	install(CODE "
		execute_process(COMMAND rm -f ${CMAKE_INSTALL_PREFIX}/lib/far2l/Plugins/drawline/plug/drawline.far-plug-wide)
		" COMPONENT system)
endif()

if (NOT DEFINED EDITCASE OR EDITCASE)
	message(STATUS "EDITCASE plugin enabled")
	add_subdirectory (editcase)
else()
	message(STATUS "${ColorRed}EDITCASE plugin disabled due to EDITCASE=${EDITCASE}${ColorNormal}")
	install(CODE "
		execute_process(COMMAND rm -f ${CMAKE_INSTALL_PREFIX}/lib/far2l/Plugins/editcase/plug/editcase.far-plug-wide)
		" COMPONENT system)
endif()

if (NOT DEFINED EDITORCOMP OR EDITORCOMP)
	message(STATUS "EDITORCOMP plugin enabled")
	add_subdirectory (editorcomp)
else()
	message(STATUS "${ColorRed}EDITORCOMP plugin disabled due to EDITORCOMP=${EDITORCOMP}${ColorNormal}")
	install(CODE "
		execute_process(COMMAND rm -f ${CMAKE_INSTALL_PREFIX}/lib/far2l/Plugins/editorcomp/plug/editorcomp.far-plug-wide)
		" COMPONENT system)
endif()

if (DEFINED FARFTP AND FARFTP)
	message(STATUS "FARFTP plugin enabled (obsolete)")
	add_subdirectory (FARStdlib)
	add_subdirectory (farftp)
else()
	install(CODE "
		execute_process(COMMAND rm -f ${CMAKE_INSTALL_PREFIX}/lib/far2l/Plugins/farftp/plug/farftp.far-plug-mb)
		" COMPONENT system)
endif()

if (NOT DEFINED FILECASE OR FILECASE)
	message(STATUS "FILECASE plugin enabled")
	add_subdirectory (filecase)
else()
	message(STATUS "${ColorRed}FILECASE plugin disabled due to FILECASE=${FILECASE}${ColorNormal}")
	install(CODE "
		execute_process(COMMAND rm -f ${CMAKE_INSTALL_PREFIX}/lib/far2l/Plugins/filecase/plug/filecase.far-plug-wide)
		" COMPONENT system)
endif()

if (NOT DEFINED INCSRCH OR INCSRCH)
	message(STATUS "INCSRCH plugin enabled")
	add_subdirectory (incsrch)
else()
	message(STATUS "${ColorRed}Building without <INCSRCH> plugin due to INCSRCH=${INCSRCH}${ColorNormal}")
	install(CODE "
		execute_process(COMMAND rm -f ${CMAKE_INSTALL_PREFIX}/lib/far2l/Plugins/incsrch/plug/incsrch.far-plug-wide)
		" COMPONENT system)
endif()

if (NOT DEFINED INSIDE OR INSIDE)
	message(STATUS "INSIDE plugin enabled")
	add_subdirectory (inside)
else()
	message(STATUS "${ColorRed}INSIDE plugin disabled due to INSIDE=${INSIDE}${ColorNormal}")
	install(CODE "
		execute_process(COMMAND rm -f ${CMAKE_INSTALL_PREFIX}/lib/far2l/Plugins/inside/plug/inside.far-plug-mb)
		" COMPONENT system)
endif()

if (NOT DEFINED MULTIARC OR MULTIARC)
	message(STATUS "MULTIARC plugin enabled")
	# workaround for brew's/macports' libarchive
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

	find_package(PCRE)
	if(NOT PCRE_FOUND)
		message(WARNING "${ColorRed}libpcre not found, multiarc will have no custom archives support. Install libpcre and reconfigure far2l if you need that functionality.${ColorNormal}")
	endif()

	add_subdirectory (multiarc)
else()
	message(STATUS "${ColorRed}MULTIARC plugin disabled due to MULTIARC=${MULTIARC}${ColorNormal}")
	install(CODE "
		execute_process(COMMAND rm -f ${CMAKE_INSTALL_PREFIX}/lib/far2l/Plugins/multiarc/plug/multiarc.far-plug-mb)
		" COMPONENT system)
endif()

if (NOT DEFINED NETROCKS OR NETROCKS)
	message(STATUS "NETROCKS plugin enabled")
	if(${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
		# workaround for brew/macports vs system openssl conflicts
		if(IS_DIRECTORY "/usr/local/opt/openssl@1.1/include" AND IS_DIRECTORY "/usr/local/opt/openssl@1.1/lib")
			set(OPENSSL_LIBRARIES "/usr/local/opt/openssl@1.1/lib/libcrypto.dylib;/usr/local/opt/openssl@1.1/lib/libssl.dylib")
			set(OPENSSL_INCLUDE_DIRS "/usr/local/opt/openssl@1.1/include")
		elseif(EXISTS "/opt/local/lib/libssl.dylib" AND IS_DIRECTORY "/opt/local/include/openssl")
			set(OPENSSL_LIBRARIES "/opt/local//lib/libcrypto.dylib;/opt/local/lib/libssl.dylib")
			set(OPENSSL_INCLUDE_DIRS "/opt/local/include")
		endif()
	endif()

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
  set(LIBNEON_ROOT "${CMAKE_CURRENT_BINARY_DIR}/neon-static")
  #message("VCPKG_LIBS_PATH: ${VCPKG_LIBS_PATH}")
  #TODO: install libtool gettext xmlto
 	ExternalProject_Add(smbclient-static
 		GIT_REPOSITORY https://github.com/samba-team/samba.git
 		GIT_TAG samba-4.15.4
 		BUILD_IN_SOURCE TRUE
 		# PREFIX ${CMAKE_CURRENT_BINARY_DIR}/neon
 		CONFIGURE_COMMAND ./autogen.sh
 		COMMAND ./configure --prefix=${LIBNEON_ROOT} --enable-static --with-ssl=openssl --with-libxml2 --with-libs=${VCPKG_LIBS_PATH}:${VCPKG_ROOT}/packages/zlib_${VCPKG_TARGET_TRIPLET}:${VCPKG_ROOT}/packages/libxml2_${VCPKG_TARGET_TRIPLET}
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

	find_package(LibNfs)
	if(LIBNFS_FOUND)
		message(STATUS "libnfs found -> enjoy NFS support in NetRocks")
	else()
		message(WARNING "${ColorRed}libnfs not found, NetRocks will not have NFS protocol support. Install libnfs-dev if you want NFS protocol available in NetRocks.${ColorNormal}")
	endif(LIBNFS_FOUND)
	if(OPT_USE_STATIC_EXT_LIBS)
		# xrepo_package("neon 0.32.2" CONFIGS "shared=false,mt=true")

		# TODO: install libtool gettext xmlto
		set(LibNEON_DIR "${CMAKE_CURRENT_BINARY_DIR}/neon_${VCPKG_TARGET_TRIPLET}")
		ExternalProject_Add(neon-static
			GIT_REPOSITORY https://github.com/notroj/neon.git
			GIT_TAG 0.32.2
			BUILD_IN_SOURCE TRUE
			# PREFIX ${CMAKE_CURRENT_BINARY_DIR}/neon
			CONFIGURE_COMMAND ./autogen.sh
			COMMAND ./configure --prefix=${LibNEON_DIR} --enable-static --with-ssl=openssl --with-libxml2 --with-libs=${VCPKG_LIBS_PATH}:${VCPKG_ROOT}/packages/zlib_${VCPKG_TARGET_TRIPLET}:${VCPKG_ROOT}/packages/libxml2_${VCPKG_TARGET_TRIPLET}
			BUILD_COMMAND make
			COMMAND make docs
			COMMAND make update-po
			COMMAND make compile-gmo
			INSTALL_COMMAND make install
			UPDATE_COMMAND ""
		)
		# set(LIBNEON_FOUND TRUE)
		# CPMAddPackage("gh:notroj/neon#0.32.2")
		# message("neon_ADDED: ${neon_ADDED}")
		# message("neon_BINARY_DIR: ${neon_BINARY_DIR}")
		# set(LibNEON_DIR "${neon_BINARY_DIR}")
		# message("LibNEON_DIR: ${LibNEON_DIR} ")
		set(LIBNEON_FOUND TRUE)
		set(LIBNEON_INCLUDE_DIRS "${LibNEON_DIR}/include")
		set(LIBNEON_LIBRARIES
			${LibNEON_DIR}/lib/libneon.a
			${VCPKG_LIBS_PATH}/lib/libssl.a
			${VCPKG_LIBS_PATH}/lib/libcrypto.a #-ldl -pthread  -L/home/user/vcpkg/installed/x64-linux/lib/pkgconfig/../../lib
			${VCPKG_LIBS_PATH}/lib/libxml2.a #-lm -lz
			${VCPKG_LIBS_PATH}/lib/liblzma.a #-pthread
			${VCPKG_LIBS_PATH}/lib/libz.a #-lm -lz
			-ldl
		)
		#find_package(LibNEON MODULE) # NAMES " libneon.a ") # HINTS " ${LibNEON_DIR}" PATHS "${LibNEON_DIR} " NO_DEFAULT_PATH NO_SYSTEM_ENVIRONMENT_PATH) #PATH_SUFFIXES " ${LibNEON_DIR} ") #CONFIG ) #${LibNEON_DIR}/lib/pkgconfig/neon.pc NAMES libneon.a")
		#find_library(LIBNEON NAMES "libneon.a" PATHS "${LibNEON_DIR}" HINTS "${LibNEON_DIR}/lib" NO_DEFAULT_PATH)
		#set(LibNEON_INCLUDE_DIR "${LibNEON_DIR}/include")
		#set(LibNEON_LIBRARY "${LibNEON_DIR}/lib/libneon.a")
		#find_library(LIBNEON NAMES "libneon.a" PATHS "${LibNEON_DIR}" HINTS "${LibNEON_DIR}/lib" NO_DEFAULT_PATH)
	else()
		find_package(LibNEON) # NAMES "libneon.a") # HINTS "${LibNEON_DIR}" PATHS "${LibNEON_DIR}" NO_DEFAULT_PATH NO_SYSTEM_ENVIRONMENT_PATH) #PATH_SUFFIXES "${LibNEON_DIR}") #CONFIG ) #${LibNEON_DIR}/lib/pkgconfig/neon.pc NAMES libneon.a")
	endif(OPT_USE_STATIC_EXT_LIBS)
	message("LIBNEON_LIBRARY: ${LIBNEON_LIBRARY}")
	message("LIBNEON_FOUND: ${LIBNEON_FOUND}")
	message("LIBNEON_LIBRARIES: ${LIBNEON_LIBRARIES}")
	if(LIBNEON_FOUND)
		message(STATUS "libneon found -> enjoy WebDav support in NetRocks")
	else()
		message(WARNING "${ColorRed}libneon not found, NetRocks will not have WebDav protocol support. Install libneon*-dev if you want WebDav protocol available in NetRocks.${ColorNormal}")
	endif(LIBNEON_FOUND)

	add_subdirectory (NetRocks)
else()
	message(STATUS "${ColorRed}NETROCKS plugin disabled due to NETROCKS=${NETROCKS}${ColorNormal}")
	install(CODE "
		execute_process(COMMAND rm -f ${CMAKE_INSTALL_PREFIX}/lib/far2l/Plugins/NetRocks/plug/NetRocks.far-plug-wide)
		" COMPONENT system)
endif()

if (DEFINED PYTHON AND PYTHON)
	find_package(PythonLibs 3.0)

	if(PYTHONLIBS_FOUND)
		find_program (PYTHON3 NAMES python3)
		if(PYTHON3)
			message(STATUS "PYTHON plugin enabled")
			add_subdirectory (python)
		else()
			message(WARNING "${ColorRed}PYTHON plugin disabled due to missing python3 ${ColorNormal}")
		endif ()
	else()
		message(WARNING "${ColorRed}PYTHON plugin disabled due to Python libraries not found${ColorNormal}")
	endif()

	install(CODE "
		execute_process(COMMAND echo Python: preparing virtual environment)
		" COMPONENT system)
	install(CODE "
		execute_process(COMMAND ${PYTHON3} -m venv --system-site-packages ${CMAKE_INSTALL_PREFIX}/lib/far2l/Plugins/python/plug/python)
		" COMPONENT system)
	install(CODE "
		execute_process(COMMAND echo Python: installing packages)
		" COMPONENT system)
	install(CODE "
		execute_process(COMMAND ${CMAKE_INSTALL_PREFIX}/lib/far2l/Plugins/python/plug/python/bin/python -m pip install cffi debugpy)
		" COMPONENT system)

	# Copy this explicitly cuz generic copier command excludes 'far2l'
	install(DIRECTORY "${INSTALL_DIR}/Plugins/python/plug/far2l"
		DESTINATION "share/far2l/Plugins/python/plug/" USE_SOURCE_PERMISSIONS
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

if (${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
	set(FIXUP_SCRIPT packaging/osx/FixupBundle.cmake)
	configure_file(${FIXUP_SCRIPT} ${PROJECT_BINARY_DIR}/${FIXUP_SCRIPT} @ONLY)
	install(DIRECTORY ${APP_DIR}/${APP_NAME}.app DESTINATION . USE_SOURCE_PERMISSIONS COMPONENT app EXCLUDE_FROM_ALL)
	install(SCRIPT ${PROJECT_BINARY_DIR}/${FIXUP_SCRIPT} COMPONENT app EXCLUDE_FROM_ALL)
endif()

install(PROGRAMS "${INSTALL_DIR}/${EXECUTABLE_NAME}" DESTINATION "bin" RENAME far2l COMPONENT base)

install(DIRECTORY "${INSTALL_DIR}/" DESTINATION "lib/far2l" USE_SOURCE_PERMISSIONS COMPONENT base FILES_MATCHING
	PATTERN "colorer/base" EXCLUDE
	PATTERN "far2l_gui.so"
	PATTERN "far2l_ttyx.broker"
	PATTERN "plug/*.far-plug-*"
	PATTERN "plug/*.broker")

install(DIRECTORY "${INSTALL_DIR}/" DESTINATION "share/far2l" USE_SOURCE_PERMISSIONS COMPONENT base FILES_MATCHING
	PATTERN "${EXECUTABLE_NAME}" EXCLUDE
	PATTERN "far2l_*" EXCLUDE
	PATTERN "*.far-plug-*" EXCLUDE
	PATTERN "*.broker" EXCLUDE
	PATTERN "python/plug/python" EXCLUDE
	PATTERN "*")# setup some symlinks and remove deprecated stuff from previous installation
install(CODE "
	execute_process(COMMAND ln -sf ../../bin/far2l ${CMAKE_INSTALL_PREFIX}/lib/far2l/far2l_askpass)
	execute_process(COMMAND ln -sf ../../bin/far2l ${CMAKE_INSTALL_PREFIX}/lib/far2l/far2l_sudoapp)
	execute_process(COMMAND rm -f ${CMAKE_INSTALL_PREFIX}/lib/far2l/Plugins/objinfo/plug/objinfo.far-plug-mb)
	" COMPONENT system)
