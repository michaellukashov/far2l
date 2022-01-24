include(ExternalProject)
function(get_vcpkg)
    ExternalProject_Add(vcpkg
        GIT_REPOSITORY https://github.com/microsoft/vcpkg.git
        CONFIGURE_COMMAND ""
        INSTALL_COMMAND ""
        UPDATE_COMMAND ""
        BUILD_COMMAND "<SOURCE_DIR>/bootstrap-vcpkg.sh"
    )
    ExternalProject_Get_Property(vcpkg SOURCE_DIR)
    set(VCPKG_DIR ${SOURCE_DIR} PARENT_SCOPE)
    set(VCPKG_DEPENDENCIES "vcpkg" PARENT_SCOPE)
endfunction()

function(vcpkg_install PACKAGE_NAME)
    add_custom_command(
        OUTPUT ${VCPKG_DIR}/packages/${PACKAGE_NAME}_x64-linux/BUILD_INFO
        COMMAND ${VCPKG_DIR}/vcpkg install ${PACKAGE_NAME}:x64-linux
        WORKING_DIRECTORY ${VCPKG_DIR}
        DEPENDS vcpkg
    )
    add_custom_target(get${PACKAGE_NAME}
        ALL
        DEPENDS ${VCPKG_DIR}/packages/${PACKAGE_NAME}_x64-linux/BUILD_INFO
    )
    list(APPEND VCPKG_DEPENDENCIES "get${PACKAGE_NAME}")
    set(VCPKG_DEPENDENCIES ${VCPKG_DEPENDENCIES} PARENT_SCOPE)
endfunction()
