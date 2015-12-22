#Don't execute script if CREATE_UNIVERSAL_FRAMEWORK is 0 in order to avoid infinite loops.
if [ "${CREATE_UNIVERSAL_FRAMEWORK}" = 0 ]; then
exit $?
fi

#For some reason xcodebuild fails to produce simulator build (i386,x86_64) when one chooses 'Generic iOS device' from Xcode 7.1
#Xcode error:
#CodeSign error: entitlements are required for product type 'Framework' in SDK 'Simulator - iOS 9.1'. Your Xcode installation may be damaged.

if [[ "${SDK_NAME}" == iphoneos* ]]; then
echo "Build for simulator in order to produce universal static framework."
kill $PPID # exit 1 doesn't mark the build as failure.
fi

if [[ "${CONFIGURATION}" != Release ]]; then
echo "Change build configuration to 'Release'."
echo "Go to Edit Scheme...->Run->Build Configuration"
kill $PPID # exit 1 doesn't mark the build as failure.
fi


#Constants.
FRAMEWORK_NAME="${PROJECT_NAME}.framework"
SIMULATOR_FRAMEWORK_PATH="${BUILD_DIR}/${CONFIGURATION}-iphonesimulator"
DEVICE_FRAMEWORK_PATH="${BUILD_DIR}/${CONFIGURATION}-iphoneos"
UNIVERSAL_FRAMEWORK_PATH="$(dirname "${SRCROOT}")"

#Produce builds for all simulator and arm architectures.
xcodebuild -project ${PROJECT_NAME}.xcodeproj -sdk iphonesimulator -arch i386 -arch x86_64 -target ${PROJECT_NAME} -configuration ${CONFIGURATION}  CONFIGURATION_BUILD_DIR=${SIMULATOR_FRAMEWORK_PATH} CREATE_UNIVERSAL_FRAMEWORK=0 clean build

xcodebuild -project ${PROJECT_NAME}.xcodeproj -sdk iphoneos -arch arm64 -arch armv7 -arch armv7s -target ${PROJECT_NAME} -configuration ${CONFIGURATION} CONFIGURATION_BUILD_DIR=${DEVICE_FRAMEWORK_PATH} CREATE_UNIVERSAL_FRAMEWORK=0 clean build

#Clean destination directory.
rm -rf "${UNIVERSAL_FRAMEWORK_PATH}/${FRAMEWORK_NAME}" && mkdir -p "${UNIVERSAL_FRAMEWORK_PATH}/${FRAMEWORK_NAME}"
cp -r "${DEVICE_FRAMEWORK_PATH}/${FRAMEWORK_NAME}/." "${UNIVERSAL_FRAMEWORK_PATH}/${FRAMEWORK_NAME}"

#Produce universal binary.
lipo "${SIMULATOR_FRAMEWORK_PATH}/${FRAMEWORK_NAME}/${PROJECT_NAME}" "${DEVICE_FRAMEWORK_PATH}/${FRAMEWORK_NAME}/${PROJECT_NAME}" -create -output "${UNIVERSAL_FRAMEWORK_PATH}/${FRAMEWORK_NAME}/${PROJECT_NAME}"