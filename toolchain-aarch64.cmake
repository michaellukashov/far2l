set(CMAKE_CROSSCOMPILING TRUE)
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR AARCH64)
set(CMAKE_HOST_SYSTEM_PROCESSOR x64)

set(CMAKE_AR                    /usr/bin/aarch64-none-elf-ar CACHE PATH "" FORCE)
set(CMAKE_ASM_COMPILER          /usr/bin/aarch64-none-elf-as CACHE PATH "" FORCE)
set(CMAKE_C_COMPILER            /usr/bin/aarch64-none-elf-gcc CACHE PATH "" FORCE)
set(CMAKE_CC_COMPILER            /usr/bin/aarch64-none-elf-gcc CACHE PATH "" FORCE)
set(CMAKE_CXX_COMPILER          /usr/bin/aarch64-none-elf-g++ CACHE PATH "" FORCE)
set(CMAKE_LINKER                /usr/bin/aarch64-none-elf-ld CACHE PATH "" FORCE)
set(CMAKE_OBJCOPY               /usr/bin/aarch64-none-elf-objcopy CACHE PATH "" FORCE)
set(CMAKE_RANLIB                /usr/bin/aarch64-none-elf-ranlib CACHE PATH "" FORCE)
set(CMAKE_SIZE                  /usr/bin/aarch64-none-elf-size CACHE PATH "" FORCE)
set(CMAKE_STRIP                 /usr/bin/aarch64-none-elf-strip CACHE PATH "" FORCE)
set(CMAKE_LD /usr/bin/aarch64-none-elf-ld CACHE PATH "" FORCE)

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

set(CMAKE_C_COMPILER_WORKS TRUE)
set(CMAKE_CC_COMPILER_WORKS TRUE)
set(CMAKE_CXX_COMPILER_WORKS TRUE)