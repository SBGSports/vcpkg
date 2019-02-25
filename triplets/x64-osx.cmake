set(VCPKG_TARGET_ARCHITECTURE x64)
set(VCPKG_CRT_LINKAGE dynamic)
set(VCPKG_LIBRARY_LINKAGE dynamic)

set(VCPKG_CMAKE_SYSTEM_NAME Darwin)
set(VCPKG_CXX_FLAGS --stdlib=libc++)
# CMake Error at scripts/cmake/vcpkg_configure_cmake.cmake:160 (message):
#  You must set both the VCPKG_CXX_FLAGS and VCPKG_C_FLAGS
set(VCPKG_C_FLAGS "")
set(VCPKG_OSX_DEPLOYMENT_TARGET 10.8)
