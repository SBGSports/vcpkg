
include(vcpkg_common_functions)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO SBGSports/mariadbpp
    REF 07edd6b125b9a28e916eaf7e4d9c6e3498ca5f90
    SHA512 853fc16fb50cad305fb6ad20f716645fbebe5449d404e28ecbc3e27c1dffb8589aee0322774d5c6ae61313d958c5974ecb76ad86488ce9923b05b7edcdf6e1ab
    HEAD_REF master
    PATCHES disable_tests_and_doxygen.patch
            comment_my_bool_typedef.patch
            build_shared_lib.patch
)

file(COPY ${CMAKE_CURRENT_LIST_DIR}/FindMariaDBClient.cmake
    DESTINATION ${SOURCE_PATH}/external/cmake-modules)

vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}
    OPTIONS
        -DBUILD_SHARED_LIBS=ON
)

vcpkg_install_cmake()

if(NOT DEFINED VCPKG_BUILD_TYPE OR VCPKG_BUILD_TYPE STREQUAL "release")
    # remove debug files
    file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug)
endif()

if(VCPKG_BUILD_TYPE STREQUAL "debug")
    # move debug files
    file(RENAME
        ${CURRENT_PACKAGES_DIR}/debug/include
        ${CURRENT_PACKAGES_DIR}/include)
    file(REMOVE_RECURSE
        ${CURRENT_PACKAGES_DIR}/debug/lib
        ${CURRENT_PACKAGES_DIR}/lib)
endif()

file(COPY ${SOURCE_PATH}/LICENSE DESTINATION DESTINATION ${CURRENT_PACKAGES_DIR}/share/mariadbpp)
file(RENAME ${CURRENT_PACKAGES_DIR}/share/mariadbpp/LICENSE ${CURRENT_PACKAGES_DIR}/share/mariadbpp/copyright)
