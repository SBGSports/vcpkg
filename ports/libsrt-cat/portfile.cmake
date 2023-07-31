include(vcpkg_common_functions)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO Haivision/srt
    REF v1.5.2
    SHA512 1b386e7564c4843cdd8138a2953cb539a37f0990eb4526d872e7839d528551f27112c3d5bb0e6467dac1684668968e787c67600b189120aa68b90c5d5e03b85a
    HEAD_REF master
    PATCHES fix-dependency-install.patch
)

if (VCPKG_LIBRARY_LINKAGE STREQUAL dynamic)
    set(BUILD_DYNAMIC ON)
    set(BUILD_STATIC OFF)
else()
    set(BUILD_DYNAMIC OFF)
    set(BUILD_STATIC ON)
endif()

# tools
set(BUILD_APPS OFF)
if("tool" IN_LIST FEATURES)
    set(BUILD_APPS ON)
endif()

vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}
    OPTIONS
        -DENABLE_SHARED=${BUILD_DYNAMIC}
        -DENABLE_STATIC=${BUILD_STATIC}
        -DENABLE_APPS=${BUILD_APPS}
        -DINSTALL_DOCS=ON
        -DINSTALL_PKG_CONFIG_MODULE=ON
        -DENABLE_SUFLIP=OFF # Since there are some file not found, disable this feature
        -DENABLE_UNITTESTS=OFF
        -DUSE_OPENSSL_PC=OFF
)

vcpkg_install_cmake()
vcpkg_copy_pdbs()

file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/include)
# Handle copyright
file(INSTALL ${SOURCE_PATH}/LICENSE DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT} RENAME copyright)
