#!/bin/bash

SRC_ROOT=`pwd`
KEY="2GSNWPNR77"
SIGNING_KEY_INSTALLER="Developer ID Installer: Andreas Fink (2GSNWPNR77)"
SIGNING_KEY_LIBRARY="Developer ID Application: Andreas Fink (2GSNWPNR77)" 
SIGNING_KEY_KEXT="Developer ID Application: Andreas Fink (2GSNWPNR77)"

VERSION="`cat VERSION`"
BUILDDATE=`date +%Y%m%d%H%M`
echo VERSION=$VERSION

KEXT_ROOT=SCTPSupport_root/
SYMBOLS_FILE="${SRC_ROOT}/SCTPSupport_symbols.txt"

rm -rf "${KEXT_ROOT}"
mkdir -p "${KEXT_ROOT}/Library/Extensions/SCTPSupport.kext/Contents/MacOS"

cat SCTPSupport_Info.plist.in | sed s/@VERSION@/${VERSION}/g > "${KEXT_ROOT}/Library/Extensions/SCTPSupport.kext/Contents/Info.plist"
clang -c dummy.c -o dummy.o
clang -target x86_64-apple-macos10.15 \
      -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.15.sdk \
      -c dummy.c -o dummy.o 
clang -target x86_64-apple-macos10.15 \
      -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.15.sdk \
      -Xlinker -export_dynamic \
      -Xlinker -no_deduplicate \
      -Xlinker -kext \
      -nostdlib  \
      -lkmodc++ \
      -lkmod \
      -lcc_kext \
      -Xlinker -exported_symbols_list \
      -Xlinker ${SYMBOLS_FILE} \
      -W,"-undefined dynamic_lookup" \
      -U dummy  -undefined dynamic_lookup \
      -Xlinker -export_dynamic \
      dummy.o \
      -oX

ld  -syslibroot /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.15.sdk \
    -arch x86_64 \
    -platform_version macos 10.15 10.15\
    -dynamic \
    -kext \
	-lkmodc++ \
	-lkmod \
    -no_deduplicate  \
    -no_function_starts \
    -exported_symbols_list ${SYMBOLS_FILE} \
    -export_dynamic \
    -U _dummy_func \
    -undefined dynamic_lookup \
    -o X



    
    -lkmodc++ \
    -lkmod \
    -lcc_kext \
nm -g X
    
          -Xlinker -dependency_info \

       "${KEXT_ROOT}/Library/Extensions/SCTPSupport.kext/Contents/MacOS/SCTPSupport"

/usr/bin/codesign --force --sign "${SIGNING_KEY_KEXT}" --timestamp --options runtime --requirements sctpsupport.kext.rqset "${KEXT_ROOT}/Library/Extensions/SCTPSupport.kext"

      -dynamiclib \

      -Xlinker -no_function_starts \
      -Xlinker -export_dynamic \
-U dummy  -undefined dynamic_lookup 
	  -lkmodc++ \
      -lkmod \
      -lcc_kext \
