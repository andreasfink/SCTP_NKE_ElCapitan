#!/bin/bash

SRC_ROOT=`pwd`
PKG_INSTALL_ROOT="${SRC_ROOT}/MacOSX_installer_root"
PKG_INSTALL_RESOURCES="${SRC_ROOT}/MacOSX_installer_resources"
PKG_INSTALL_SCRIPTS="${SRC_ROOT}/MacOSX_installer_scripts"
KEY="2GSNWPNR77"

#Serial of "Developer ID Installer: Andreas Fink (2GSNWPNR77)"
SIGNING_KEY_INSTALLER="Developer ID Installer: Andreas Fink (2GSNWPNR77)"
#Serial of "Developer ID Application: Andreas Fink (2GSNWPNR77)"
SIGNING_KEY_LIBRARY="Developer ID Application: Andreas Fink (2GSNWPNR77)" 
SIGNING_KEY_KEXT="Developer ID Application: Andreas Fink (2GSNWPNR77)"

VERSION="`cat VERSION`"
BUILDDATE=`date +%Y%m%d%H%M`
OUTPUT_FILE=SCTP_Catalina_${BUILDDATE}.pkg
echo VERSION=$VERSION
echo OUTPUT_FILE="${OUTPUT_FILE}"
rm -rf "${PKG_INSTALL_ROOT}"
mkdir -p "${PKG_INSTALL_ROOT}"/Library/LaunchDaemons
cp me.fink.sctp.plist  "${PKG_INSTALL_ROOT}"/Library/LaunchDaemons

xcodebuild -target SCTP -configuration Release
pushd /tmp/SCTP.dst/Library/Extensions/
find SCTP.kext | cpio -pdmuv "${PKG_INSTALL_ROOT}/Library/Extensions/"
popd

pushd SCTPSupport
make
popd

pushd "${PKG_INSTALL_ROOT}/"
tar -xvzf "${SRC_ROOT}/sctp-support.tar.gz"
popd

cp SCTPSupport/SCTPSupport/ "${PKG_INSTALL_ROOT}/Library/Extensions/SCTPSupport.kext/Contents/MacOS/SCTPSupport"
cat SCTPSupport_Info.plist.in | sed s/@VERSION@/${VERSION}/g > "${PKG_INSTALL_ROOT}/Library/Extensions/SCTPSupport.kext/Contents/Info.plist"
/usr/bin/codesign --force --sign "${SIGNING_KEY_KEXT}" --timestamp --options runtime --requirements sctpsupport.kext.rqset "${PKG_INSTALL_ROOT}/Library/Extensions/SCTPSupport.kext"


xcodebuild -target libsctp -configuration Release
install_name_tool -id @rpath/sctp.framework/Versions/A/sctp /tmp/SCTP.dst/usr/local/lib/libsctp.dylib

mkdir -p "${PKG_INSTALL_ROOT}/Library/Frameworks/sctp.framework/Versions/A/Resources"
mkdir -p "${PKG_INSTALL_ROOT}/Library/Frameworks/sctp.framework/Versions/A/Modules"
mkdir -p "${PKG_INSTALL_ROOT}/Library/Frameworks/sctp.framework/Versions/A/Headers"
mkdir -p "${PKG_INSTALL_ROOT}/Library/LaunchDaemons/"
mkdir -p "${PKG_INSTALL_ROOT}/Library/Application Support/me.fink.sctp/"

cp /tmp/SCTP.dst/usr/local/lib/libsctp.dylib 	"${PKG_INSTALL_ROOT}/Library/Frameworks/sctp.framework/Versions/A/sctp"
cp netinet/sctp.h netinet/sctp_uio.h 	"${PKG_INSTALL_ROOT}/Library/Frameworks/sctp.framework/Versions/A/Headers"
cp startup_script.sh					"${PKG_INSTALL_ROOT}/Library/Application Support/me.fink.sctp/startup_script.sh"
chmod 755 								"${PKG_INSTALL_ROOT}/Library/Application Support/me.fink.sctp/startup_script.sh"
cat >> 									"${PKG_INSTALL_ROOT}/Library/Frameworks/sctp.framework/Versions/A/Modules/module.modulemap" << --eof--
framework module sctp {
  umbrella header "sctp.h"
  export *
  module * { export * }
}
--eof--
cat >> "${PKG_INSTALL_ROOT}/Library/Frameworks/sctp.framework/Versions/A/Resources/Info.plist" << --eof--
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
	<string>me.fink.sctp</string>
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
	<string>macosx10.15</string>
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

install_name_tool "${PKG_INSTALL_ROOT}"/Library/Frameworks/sctp.framework/Versions/A/sctp -change /usr/lib/libsctp.dylib @rpath/sctp.framework/Versions/A/sctp
install_name_tool "${PKG_INSTALL_ROOT}"/Library/Frameworks/sctp.framework/Versions/A/sctp -change /usr/local/lib/libsctp.dylib @rpath/sctp.framework/Versions/A/sctp

/usr/bin/codesign --force --sign "${SIGNING_KEY_KEXT}" --timestamp --options runtime --requirements sctpsupport.kext.rqset "${PKG_INSTALL_ROOT}/Library/Extensions/SCTPSupport.kext"
/usr/bin/codesign --force --sign "${SIGNING_KEY_KEXT}" --timestamp --options runtime --requirements sctp.kext.rqset "${PKG_INSTALL_ROOT}/Library/Extensions/SCTP.kext"


/usr/bin/codesign --force --sign "${SIGNING_KEY_LIBRARY}"  --timestamp --options runtime "${PKG_INSTALL_ROOT}"/Library/Frameworks/sctp.framework/Versions/A/sctp
cp me.fink.sctp.plist "${PKG_INSTALL_ROOT}/Library/LaunchDaemons/me.fink.sctp.plist"

#$PKGMAKER --root $PKG_INSTALL_ROOT/  --out "$FILE" --id org.sctp.nke.sctp --version '"$LONGVER"' --title SCTP --install-to /  --verbose --root-volume-only --discard-forks --certificate "$SIGNING_KEY_INSTALLER"
PKG_IDENTIFIER=me.fink.sctp
pkgbuild --root "${PKG_INSTALL_ROOT}" --install-location /  --sign  "${SIGNING_KEY_INSTALLER}"  --version "${VERSION}" --identifier "${PKG_IDENTIFIER}"    --ownership recommended "${OUTPUT_FILE}"


