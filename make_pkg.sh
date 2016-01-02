#!/bin/bash

PKG_INSTALL_ROOT="MacOSX_installer_root"
PKG_INSTALL_RESOURCES="MacOSX_installer_resources"
PKG_INSTALL_SCRIPTS="MacOSX_installer_scripts"
SIGNING_KEY_INSTALLER="Developer ID Installer: SMSRelay AG"
SIGNING_KEY_LIBRARY="Developer ID Application: SMSRelay AG"
SIGNING_KEY_KEXT="Developer ID Application: SMSRelay AG"

VERSION="`cat VERSION`"
BUILDDATE=`date +%Y%m%d%H%M`
OUTPUT_FILE=SCTP_ElCapitan_${BUILDDATE}.pkg
echo VERSION=$VERSION
echo OUTPUT_FILE="${OUTPUT_FILE}"
rm -rf "${PKG_INSTALL_ROOT}"
mkdir -p "${PKG_INSTALL_ROOT}"/Library/LaunchDaemons
cp com.smsrelay.sctp.plist  "${PKG_INSTALL_ROOT}"/Library/LaunchDaemons

xcodebuild -target SCTP -configuration Debug
cd build/Debug
find SCTP.kext | cpio -pdmuv ../../"${PKG_INSTALL_ROOT}/Library/Extensions/"
cd ../..
MAIN_DIR=`pwd`
mkdir -p "${PKG_INSTALL_ROOT}/Library/Extensions"
pushd "${PKG_INSTALL_ROOT}/Library/Extensions"
tar -xvzf "${MAIN_DIR}/sctp-support.tar.gz"
popd

/usr/bin/codesign --force --sign "${SIGNING_KEY_KEXT}"  "${PKG_INSTALL_ROOT}/Library/Extensions/SCTP.kext"
/usr/bin/codesign --force --sign "${SIGNING_KEY_KEXT}"  "${PKG_INSTALL_ROOT}/Library/Extensions/SCTPSupport.kext"

xcodebuild -target libsctp -configuration Debug

install_name_tool -id @rpath/sctp.framework/Versions/A/sctp build/Debug/libsctp.dylib

mkdir -p "${PKG_INSTALL_ROOT}/Library/Frameworks/sctp.framework/Versions/A/Resources"
mkdir -p "${PKG_INSTALL_ROOT}/Library/Frameworks/sctp.framework/Versions/A/Modules"
mkdir -p "${PKG_INSTALL_ROOT}/Library/Frameworks/sctp.framework/Versions/A/Headers"
mkdir -p "${PKG_INSTALL_ROOT}/Library/LaunchDaemons/"
mkdir -p "${PKG_INSTALL_ROOT}/Library/Application Support/SCTP/"

cp build/Debug/libsctp.dylib 			"${PKG_INSTALL_ROOT}/Library/Frameworks/sctp.framework/Versions/A/sctp"
cp netinet/sctp.h netinet/sctp_uio.h 	"${PKG_INSTALL_ROOT}/Library/Frameworks/sctp.framework/Versions/A/Headers"
cp startup_script.sh					"${PKG_INSTALL_ROOT}/Library/Application Support/SCTP/startup_script.sh"
chmod 755 								"${PKG_INSTALL_ROOT}/Library/Application Support/SCTP/startup_script.sh"
cat >> 									"${PKG_INSTALL_ROOT}/Library/Frameworks/sctp.framework//Versions/A/Modules/module.modulemap" << --eof--
framework module sctp {
  umbrella header "sctp.h"

/usr/bin/codesign --force --sign "${SIGNING_KEY_LIBRARY}"  "${PKG_INSTALL_ROOT}${DYLIB_DIR}/${DYLIB_BIN}"
=======
  export *
  module * { export * }
}
--eof--
cat >> 									"${PKG_INSTALL_ROOT}/Library/Frameworks/sctp.framework/Versions/A/Resources/Info.plist" << --eof--
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>BuildMachineOSBuild</key>
	<string>14D136</string>
	<key>CFBundleDevelopmentRegion</key>
	<string>en</string>
	<key>CFBundleExecutable</key>
	<string>sctp</string>
	<key>CFBundleIdentifier</key>
	<string>com.smsrelay.sctp</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>sctp</string>
	<key>CFBundlePackageType</key>
	<string>FMWK</string>
	<key>CFBundleShortVersionString</key>
	<string>1.0</string>
	<key>CFBundleSignature</key>
	<string>????</string>
	<key>CFBundleVersion</key>
	<string>1</string>
	<key>DTCompiler</key>
	<string>com.apple.compilers.llvm.clang.1_0</string>
	<key>DTPlatformBuild</key>
	<string>6D2105</string>
	<key>DTPlatformVersion</key>
	<string>GM</string>
	<key>DTSDKBuild</key>
	<string>14D125</string>
	<key>DTSDKName</key>
	<string>macosx10.10</string>
	<key>DTXcode</key>
	<string>0632</string>
	<key>DTXcodeBuild</key>
	<string>6D2105</string>
</dict>
</plist>
--eof--
pushd "${PKG_INSTALL_ROOT}"/Library/Frameworks/sctp.framework/Versions/
ln -s A Current
popd
pushd "${PKG_INSTALL_ROOT}"/Library/Frameworks/sctp.framework/
ln -s Versions/Current/Headers Headers
ln -s Versions/Current/Modules Modules
ln -s Versions/Current/Resources Resources
ln -s Versions/Current/sctp sctp
popd
/usr/bin/codesign --force --sign "${SIGNING_KEY_LIBRARY}"  "${PKG_INSTALL_ROOT}"/Library/Frameworks/sctp.framework/Versions/A/sctp
cp com.smsrelay.sctp.plist "${PKG_INSTALL_ROOT}/Library/LaunchDaemons/com.smsrelay.sctp.plist"

#$PKGMAKER --root $PKG_INSTALL_ROOT/  --out "$FILE" --id org.sctp.nke.sctp --version '"$LONGVER"' --title SCTP --install-to /  --verbose --root-volume-only --discard-forks --certificate "$SIGNING_KEY_INSTALLER"
PKG_IDENTIFIER=com.smsrelay.sctp.nke.sctp
pkgbuild --root "${PKG_INSTALL_ROOT}" --install-location /  --sign  "${SIGNING_KEY_INSTALLER}"  --version "${VERSION}" --identifier "${PKG_IDENTIFIER}"    --ownership recommended "${OUTPUT_FILE}"


