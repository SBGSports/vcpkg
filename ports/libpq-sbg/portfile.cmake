include(vcpkg_common_functions)
set(SOURCE_PATH ${CURRENT_BUILDTREES_DIR}/src/postgresql-11.3)
vcpkg_download_distfile(ARCHIVE
    URLS "https://ftp.postgresql.org/pub/source/v11.3/postgresql-11.3.tar.bz2"
    FILENAME "postgresql-11.3.tar.bz2"
    SHA512 03269bb88f44f3a81d5e3a8ca2fe59f63f784436840f08870b2e539755629cbde8ac288e0bb4472ee93294a88b37b814ddff48444254c1a3f7a10b4bb64f7133
)
vcpkg_extract_source_archive(${ARCHIVE})

#Patch for openssl 1.1.1 obtained from here, might make it uptream eventually
#https://www.postgresql.org/message-id/CAC%2BAXB3_YNqAr%3Du9ccuXOoKQF%3DkZRQFjnLgRaSFQEjNz%2BPo%2B1w%40mail.gmail.com
vcpkg_apply_patches(
    SOURCE_PATH ${SOURCE_PATH}
    PATCHES ${CMAKE_CURRENT_LIST_DIR}/0001_windows_openssl_1.1.0_build_PG11_&_HEAD_v1.patch
)

file(COPY ${CMAKE_CURRENT_LIST_DIR}/CMakeLists.txt DESTINATION ${SOURCE_PATH})

vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}
    PREFER_NINJA
    OPTIONS
        "-DPORT_DIR=${CMAKE_CURRENT_LIST_DIR}"
    OPTIONS_DEBUG
        -DINSTALL_INCLUDES=OFF
)

vcpkg_install_cmake()
vcpkg_copy_pdbs()

file(INSTALL ${SOURCE_PATH}/COPYRIGHT DESTINATION ${CURRENT_PACKAGES_DIR}/share/libpq-sbg RENAME copyright)
