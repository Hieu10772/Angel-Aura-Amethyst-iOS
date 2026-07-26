SHELL := /bin/bash
$(VERBOSE).SILENT:

WORKINGDIR       := "build"
CMAKE_BUILD_TYPE := "release"
DETECTPLAT  	 := $(shell uname -s)
ifeq ($(DETECTPLAT),Linux)
SDKPATH			 := $(THEOS_SDK_PATH)
JOBS := $(shell nproc)
else
SDKPATH 		 := $(shell xcrun --sdk iphoneos --show-sdk-path)
JOBS             := $(shell sysctl -n hw.ncpu)
endif

build:
	mkdir -p $(WORKINGDIR)
	cd $(WORKINGDIR) && cmake . \
		-DCMAKE_BUILD_TYPE=$(CMAKE_BUILD_TYPE) \
		-DCMAKE_CROSSCOMPILING=true \
		-DCMAKE_SYSTEM_NAME=iOS \
		-DCMAKE_SYSTEM_PROCESSOR=aarch64 \
		-DCMAKE_OSX_SYSROOT=$(SDKPATH) \
		-DCMAKE_OSX_DEPLOYMENT_TARGET=14.0 \
		-DCMAKE_OSX_ARCHITECTURES=arm64 \
		-DCMAKE_C_FLAGS="-arch arm64 -isysroot $(SDKPATH) -target arm64-apple-ios14.0" \
		-DCMAKE_CXX_FLAGS="-arch arm64 -isysroot $(SDKPATH) -target arm64-apple-ios14.0 -stdlib=libc++" \
		-DCMAKE_EXE_LINKER_FLAGS="-isysroot $(SDKPATH) -Wl,-syslibroot,$(SDKPATH)" \
		-DCMAKE_SHARED_LINKER_FLAGS="-isysroot $(SDKPATH) -Wl,-syslibroot,$(SDKPATH)" \
		../ltw

	cmake --build $(WORKINGDIR) --config $(CMAKE_BUILD_TYPE) -j$(JOBS)
	ldid -S $(WORKINGDIR)/libLTW.dylib

clean:
	rm -rf build

.PHONY: clean build_external build