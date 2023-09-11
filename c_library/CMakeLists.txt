cmake_minimum_required(VERSION 3.26)
project(aidnpu_c C)

set(CMAKE_C_STANDARD 11)

add_executable(aidnpu_c registers.h
        main.c
        bfloat16.h
        bfloat16_test.h
        float16.h
        float16_test.h)
