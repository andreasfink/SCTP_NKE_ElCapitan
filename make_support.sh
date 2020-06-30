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
SYMBOLS_FILE=SCTPSupport_symbols.txt

mkdir -p "${KEXT_ROOT}/Library/Extensions/SCTPSupport.kext/Contents/MacOS"

cat SCTPSupport_Info.plist.in | sed s/@VERSION@/${VERSION}/g > "${KEXT_ROOT}/Library/Extensions/SCTPSupport.kext/Contents/Info.plist"
clang -c dummy.c -o dummy.o
clang -target x86_64-apple-macos10.15 \
      -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.15.sdk \
      -Xlinker -export_dynamic \
      -Xlinker -no_deduplicate \
      -Xlinker -no_function_starts \
      -Xlinker -kext \
      -nostdlib \
	  -lkmodc++ \
      -lkmod \
      -lcc_kext \
      -exported_symbols_order \
      -exported_symbols_list SCTPSupport_symbols.txt \
      -U dummy  -undefined dynamic_lookup dummy.o \
      -o "${KEXT_ROOT}/Library/Extensions/SCTPSupport.kext/Contents/MacOS/SCTPSupport"

/usr/bin/codesign --force --sign "${SIGNING_KEY_KEXT}" --timestamp --options runtime --requirements sctpsupport.kext.rqset "${KEXT_ROOT}/Library/Extensions/SCTPSupport.kext"

