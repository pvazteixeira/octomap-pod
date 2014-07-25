
default_target: all

# Default to a less-verbose build.  If you want all the gory compiler output,
# run "make VERBOSE=1"
$(VERBOSE).SILENT:

# Figure out where to build the software.
#   Use BUILD_PREFIX if it was passed in.
#   If not, search up to four parent directories for a 'build' directory.
#   Otherwise, use ./build.
ifeq "$(BUILD_PREFIX)" ""
BUILD_PREFIX:=$(shell for pfx in ./ .. ../.. ../../.. ../../../..; do d=`pwd`/$$pfx/build;\
               if [ -d $$d ]; then echo $$d; exit 0; fi; done; echo `pwd`/build)
endif
# create the build directory if needed, and normalize its path name
BUILD_PREFIX:=$(shell mkdir -p $(BUILD_PREFIX) && cd $(BUILD_PREFIX) && echo `pwd`)

# Default to a release build.  If you want to enable debugging flags, run
# "make BUILD_TYPE=Debug"
ifeq "$(BUILD_TYPE)" ""
BUILD_TYPE="Release"
endif

OCTOMAP_INSTALL_LIBS = liboctomath.1.6.6.dylib \
	liboctomap.1.6.6.dylib

all: pod-build/Makefile
	$(MAKE) -C pod-build all install
ifeq ($(shell uname), Darwin)
	@for lib in $(OCTOMAP_INSTALL_LIBS); do \
		install_name_tool -id $(BUILD_PREFIX)/lib/$$lib $(BUILD_PREFIX)/lib/$$lib; \
		for deplib in $(OCTOMAP_INSTALL_LIBS); do \
			install_name_tool -change $$deplib $(BUILD_PREFIX)/lib/$$deplib $(BUILD_PREFIX)/lib/$$lib; \
		done; \
	done
endif

pod-build/Makefile:
	$(MAKE) configure

.PHONY: configure
configure: octomap/CMakeLists.txt
	@echo "\nBUILD_PREFIX: $(BUILD_PREFIX)\n\n"

	# create the temporary build directory if needed
	@mkdir -p pod-build

	# run CMake to generate and configure the build scripts
	@cd pod-build && cmake -DCMAKE_INSTALL_PREFIX=$(BUILD_PREFIX) \
		   -DCMAKE_BUILD_TYPE=$(BUILD_TYPE) ../octomap/octomap


clean:
	-if [ -e pod-build/install_manifest.txt ]; then rm -f `cat pod-build/install_manifest.txt`; fi
	-if [ -d pod-build ]; then $(MAKE) -C pod-build clean; rm -rf pod-build; fi

# other (custom) targets are passed through to the cmake-generated Makefile
%::
	$(MAKE) -C pod-build $@
