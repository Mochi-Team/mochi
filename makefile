all: ios-build macos-build

ios-build:
	set -o pipefail && xcodebuild archive \
		-project App/mochi.xcodeproj \
    	-destination "generic/platform=iOS" \
        -scheme "mochi" \
        -archivePath "./App/mochi (iOS).xcarchive" \
        -xcconfig "./App/MainConfig.xcconfig" \
        CODE_SIGNING_REQUIRED=NO \
        CODE_SIGNING_ALLOWED=NO \
        CODE_SIGN_IDENTITY= \
        CODE_SIGN_ENTITLEMENTS= \
        GCC_OPTIMIZATION_LEVEL=s \
        SWIFT_OPTIMIZATION_LEVEL=-O \
        GCC_GENERATE_DEBUGGING_SYMBOLS=YES \
        DEBUG_INFORMATION_FORMAT=dwarf-with-dsym | xcbeautify
	mkdir -p "./App/Payload"
	cd App && mv "./mochi (iOS).xcarchive/Products/Applications/mochi.app" "./Payload/mochi.app"
	cd App && zip -r "./mochi (iOS).ipa" './Payload'
	cd App && tar -czf 'mochi (iOS) Symbols.tar.gz' -C './mochi (iOS).xcarchive' 'dSYMs'

macos-build:
	set -o pipefail && xcodebuild archive \
		-project App/mochi.xcodeproj \
		-destination "generic/platform=macOS" \
		-scheme "mochi" \
		-archivePath "./App/mochi (macOS).xcarchive" \
		-xcconfig "./App/MainConfig.xcconfig" \
		CODE_SIGNING_REQUIRED=NO \
		CODE_SIGNING_ALLOWED=NO \
		CODE_SIGN_IDENTITY= \
		CODE_SIGN_ENTITLEMENTS= \
		GCC_OPTIMIZATION_LEVEL=s \
		SWIFT_OPTIMIZATION_LEVEL=-O \
		GCC_GENERATE_DEBUGGING_SYMBOLS=YES \
		DEBUG_INFORMATION_FORMAT=dwarf-with-dsym | xcbeautify
	create-dmg \
		--volname "mochi" \
		--background "./Misc/Media/dmg_background.png" \
		--window-pos 200 120 \
		--window-size 660 400 \
		--icon-size 160 \
		--icon "mochi.app" 180 170 \
		--hide-extension "mochi.app" \
		--app-drop-link 480 170 \
		--no-internet-enable \
		"./App/mochi (macOS).dmg" \
		"./App/mochi (macOS).xcarchive/Products/Applications/"
	cd App && tar -czf 'mochi (macOS) Symbols.tar.gz' -C './mochi (macOS).xcarchive' 'dSYMs'
