# Optional command line arguments:
# see http://stackoverflow.com/a/24264930/43839
#
# For an optimized, stripped build, you might use:
#
#   $ make OPTIMIZE=-O3 SYMBOLS="" DEFINES=""
#
# For a Clang C++11 build, use:
#
#   $ make COMPILER=g++ STDLIB=c++11
#

COMPILER ?= g++
DEFINES ?= -DDEBUG
OPTIMIZE ?= -O0
STDLIB ?= c++17
SYMBOLS ?= -g

#
# Compilation variables.
#
DEPENDENCIES =  -MMD -MP -MF
TEST_DIRECTORY = src/googletest/googletest
TEST_FLAGS = -isystem $(TEST_DIRECTORY)/include -I$(TEST_DIRECTORY)

CXX = $(COMPILER)

MACRO_DEFINITIONS = \
 -DBUILD_TIMESTAMP="\"`date +\"%Y-%m-%d %H:%I:%M\"`\"" \
 -DGIT_COMMIT_ID=\""`git log --format=\"%H\" -n 1`"\" \
 $(DEFINES) \

COMPILATION = $(OPTIMIZE) $(SYMBOLS) -std=$(STDLIB) -pthread
INCLUDE_PATHS = ""
LIBRARIES = -lm -lstdc++
WARNINGS = -Wall -Wextra -Wno-strict-aliasing -Wpedantic -Wno-nested-anon-types

CXXFLAGS_BASE += \
  $(MACRO_DEFINITIONS) \
  $(COMPILATION) \
  $(INCLUDE_PATHS) \
  $(LIBRARIES) \
  $(WARNINGS)

CXXFLAGS = $(CXXFLAGS_BASE) $(DEPENDENCIES)
CXXFLAGS_TEST = $(CXXFLAGS_BASE) $(TEST_FLAGS)

#
# Files and directories
#

TARGETS = bin/binary1 bin/binary2
OBJ = bin/obj

DIRECTORIES = bin $(TEST_OBJ) $(OBJ) .deps

TEST_OBJ = $(OBJ)/googletest

#
# Build rules
#

.PHONY: all targets tests
.SUFFIXES:
.SECONDARY:

all: targets tests

pre-build:
	mkdir -p $(DIRECTORIES)

targets: pre-build
	@$(MAKE) --no-print-directory $(TARGETS)

tests: pre-build
	@$(MAKE) --no-print-directory bin/tests

bin/%: src/project/main/%.cpp $(OBJ)/library.o
	$(CXX) -o $@ $< $(OBJ)/library.o $(CXXFLAGS) .deps/$*.d

$(OBJ)/library.o: src/project/main/library.cpp
	$(CXX) -o $@ -c $< $(CXXFLAGS) .deps/library.d


$(OBJ)/tests.o: src/project/main/tests.cpp
	$(CXX) -o $@ -c $< $(CXXFLAGS_TEST) $(DEPENDENCIES) .deps/tests.d

$(TEST_OBJ)/gtest-all.o:
	$(CXX) -o $@ -c $(TEST_DIRECTORY)/src/gtest-all.cc $(CXXFLAGS_TEST)

$(TEST_OBJ)/gtest_main.o:
	$(CXX) -o $@ -c $(TEST_DIRECTORY)/src/gtest_main.cc $(CXXFLAGS_TEST)

bin/tests: \
  $(OBJ)/tests.o \
  $(TEST_OBJ)/gtest-all.o \
  $(TEST_OBJ)/gtest_main.o \
  $(OBJ)/library.o
	$(CXX) -lpthread $^ -o $@ $(CXXFLAGS_TEST)

clean:
	rm -Rf $(DIRECTORIES)

-include .deps/*.d
