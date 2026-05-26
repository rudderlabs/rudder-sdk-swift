# Sample App Templates

The sample app is a SwiftUI app in the `Example/` directory that demonstrates the integration's functionality. It uses a local SPM package reference to the parent integration repo.

## Directory Structure

```
Example/
  <Name>ExampleApp.swift          -- @main App entry + AnalyticsManager
  ContentView.swift               -- UI with sectioned event buttons
  Example.xcodeproj/
    project.pbxproj               -- Xcode project (from template below)
  Assets.xcassets/
    Contents.json
    AccentColor.colorset/
      Contents.json
    AppIcon.appiconset/
      Contents.json
```

## Generating Unique PBX IDs

The pbxproj file requires unique 24-character uppercase hex IDs. Generate them deterministically from a seed:

```bash
# Generate 17 unique IDs using openssl
for i in $(seq 1 23); do
  openssl rand -hex 12 | tr 'a-f' 'A-F'
done
```

Assign each generated ID to a named slot (see the template's `{{ID_XX}}` placeholders).

## ID Slot Assignments

| Slot | PBX Object |
|---|---|
| `{{ID_01}}` | PBXBuildFile: framework in Frameworks |
| `{{ID_02}}` | PBXBuildFile: ExampleApp.swift in Sources |
| `{{ID_03}}` | PBXBuildFile: ContentView.swift in Sources |
| `{{ID_04}}` | PBXBuildFile: Assets.xcassets in Resources |
| `{{ID_05}}` | PBXFileReference: Example.app (product) |
| `{{ID_06}}` | PBXFileReference: ExampleApp.swift |
| `{{ID_07}}` | PBXFileReference: ContentView.swift |
| `{{ID_08}}` | PBXFileReference: Assets.xcassets |
| `{{ID_09}}` | PBXFrameworksBuildPhase |
| `{{ID_10}}` | PBXGroup: main group (root) |
| `{{ID_11}}` | PBXGroup: Products |
| `{{ID_12}}` | PBXNativeTarget: Example |
| `{{ID_13}}` | PBXProject: Project object |
| `{{ID_14}}` | PBXResourcesBuildPhase |
| `{{ID_15}}` | PBXSourcesBuildPhase |
| `{{ID_16}}` | XCBuildConfiguration: project Debug |
| `{{ID_17}}` | XCBuildConfiguration: project Release |
| `{{ID_18}}` | XCBuildConfiguration: target Debug |
| `{{ID_19}}` | XCBuildConfiguration: target Release |
| `{{ID_20}}` | XCConfigurationList: project |
| `{{ID_21}}` | XCConfigurationList: target |
| `{{ID_22}}` | XCLocalSwiftPackageReference |
| `{{ID_23}}` | XCSwiftPackageProductDependency |

Generate 23 unique IDs total.

## project.pbxproj Template

Replace all `{{PLACEHOLDER}}` values:
- `{{ID_XX}}` — unique 24-char hex IDs (see table above)
- `{{Name}}` — PascalCase integration name (e.g., `Firebase`)
- `{{name}}` — lowercase integration name (e.g., `firebase`)
- `{{MODULE_NAME}}` — `RudderIntegration<Name>` (e.g., `RudderIntegrationFirebase`)
- `{{IOS_DEPLOYMENT_TARGET}}` — iOS deployment target matching Package.swift (e.g., `15.0`, `16.0`). Use the major.minor form Xcode expects.
- `{{MACOS_DEPLOYMENT_TARGET}}` — macOS deployment target. Use `15.0` as a reasonable default for the Example app even if the library doesn't support macOS.
- `{{XROS_DEPLOYMENT_TARGET}}` — visionOS deployment target. Use `2.0` as default.

```
// !$*UTF8*$!
{
	archiveVersion = 1;
	classes = {
	};
	objectVersion = 77;
	objects = {

/* Begin PBXBuildFile section */
		{{ID_01}} /* {{MODULE_NAME}} in Frameworks */ = {isa = PBXBuildFile; productRef = {{ID_23}} /* {{MODULE_NAME}} */; };
		{{ID_02}} /* {{Name}}ExampleApp.swift in Sources */ = {isa = PBXBuildFile; fileRef = {{ID_06}} /* {{Name}}ExampleApp.swift */; };
		{{ID_03}} /* ContentView.swift in Sources */ = {isa = PBXBuildFile; fileRef = {{ID_07}} /* ContentView.swift */; };
		{{ID_04}} /* Assets.xcassets in Resources */ = {isa = PBXBuildFile; fileRef = {{ID_08}} /* Assets.xcassets */; };
/* End PBXBuildFile section */

/* Begin PBXFileReference section */
		{{ID_05}} /* Example.app */ = {isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = Example.app; sourceTree = BUILT_PRODUCTS_DIR; };
		{{ID_06}} /* {{Name}}ExampleApp.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {{Name}}ExampleApp.swift; sourceTree = "<group>"; };
		{{ID_07}} /* ContentView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = ContentView.swift; sourceTree = "<group>"; };
		{{ID_08}} /* Assets.xcassets */ = {isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = "<group>"; };
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
		{{ID_09}} /* Frameworks */ = {
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
				{{ID_01}} /* {{MODULE_NAME}} in Frameworks */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
		{{ID_10}} = {
			isa = PBXGroup;
			children = (
				{{ID_11}} /* Products */,
				{{ID_08}} /* Assets.xcassets */,
				{{ID_06}} /* {{Name}}ExampleApp.swift */,
				{{ID_07}} /* ContentView.swift */,
			);
			sourceTree = "<group>";
		};
		{{ID_11}} /* Products */ = {
			isa = PBXGroup;
			children = (
				{{ID_05}} /* Example.app */,
			);
			name = Products;
			sourceTree = "<group>";
		};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
		{{ID_12}} /* Example */ = {
			isa = PBXNativeTarget;
			buildConfigurationList = {{ID_21}} /* Build configuration list for PBXNativeTarget "Example" */;
			buildPhases = (
				{{ID_15}} /* Sources */,
				{{ID_09}} /* Frameworks */,
				{{ID_14}} /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
			);
			name = Example;
			packageProductDependencies = (
				{{ID_23}} /* {{MODULE_NAME}} */,
			);
			productName = {{Name}}Example;
			productReference = {{ID_05}} /* Example.app */;
			productType = "com.apple.product-type.application";
		};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
		{{ID_13}} /* Project object */ = {
			isa = PBXProject;
			attributes = {
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 2610;
				LastUpgradeCheck = 2610;
				TargetAttributes = {
					{{ID_12}} = {
						CreatedOnToolsVersion = 26.1;
					};
				};
			};
			buildConfigurationList = {{ID_20}} /* Build configuration list for PBXProject "Example" */;
			developmentRegion = en;
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
				Base,
			);
			mainGroup = {{ID_10}};
			minimizedProjectReferenceProxies = 1;
			packageReferences = (
				{{ID_22}} /* XCLocalSwiftPackageReference "../../integration-swift-{{name}}" */,
			);
			preferredProjectObjectVersion = 77;
			productRefGroup = {{ID_11}} /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				{{ID_12}} /* Example */,
			);
		};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
		{{ID_14}} /* Resources */ = {
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				{{ID_04}} /* Assets.xcassets in Resources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
		{{ID_15}} /* Sources */ = {
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				{{ID_03}} /* ContentView.swift in Sources */,
				{{ID_02}} /* {{Name}}ExampleApp.swift in Sources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
		{{ID_16}} /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_ENABLE_OBJC_WEAK = YES;
				CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_COMMA = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
				CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
				CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INFINITE_RECURSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
				CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
				CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
				CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
				CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
				CLANG_WARN_STRICT_PROTOTYPES = YES;
				CLANG_WARN_SUSPICIOUS_MOVE = YES;
				CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = dwarf;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_TESTABILITY = YES;
				ENABLE_USER_SCRIPT_SANDBOXING = YES;
				GCC_C_LANGUAGE_STANDARD = gnu17;
				GCC_DYNAMIC_NO_PIC = NO;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_OPTIMIZATION_LEVEL = 0;
				GCC_PREPROCESSOR_DEFINITIONS = (
					"DEBUG=1",
					"$(inherited)",
				);
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				LOCALIZATION_PREFERS_STRING_CATALOGS = YES;
				MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
				MTL_FAST_MATH = YES;
				ONLY_ACTIVE_ARCH = YES;
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG $(inherited)";
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
			};
			name = Debug;
		};
		{{ID_17}} /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_ENABLE_OBJC_WEAK = YES;
				CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_COMMA = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
				CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
				CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INFINITE_RECURSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
				CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
				CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
				CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
				CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
				CLANG_WARN_STRICT_PROTOTYPES = YES;
				CLANG_WARN_SUSPICIOUS_MOVE = YES;
				CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
				ENABLE_NS_ASSERTIONS = NO;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_USER_SCRIPT_SANDBOXING = YES;
				GCC_C_LANGUAGE_STANDARD = gnu17;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				LOCALIZATION_PREFERS_STRING_CATALOGS = YES;
				MTL_ENABLE_DEBUG_INFO = NO;
				MTL_FAST_MATH = YES;
				SWIFT_COMPILATION_MODE = wholemodule;
			};
			name = Release;
		};
		{{ID_18}} /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				ENABLE_APP_SANDBOX = YES;
				ENABLE_HARDENED_RUNTIME = YES;
				ENABLE_PREVIEWS = YES;
				ENABLE_USER_SELECTED_FILES = readonly;
				GENERATE_INFOPLIST_FILE = YES;
				"INFOPLIST_KEY_UIApplicationSceneManifest_Generation[sdk=iphoneos*]" = YES;
				"INFOPLIST_KEY_UIApplicationSceneManifest_Generation[sdk=iphonesimulator*]" = YES;
				"INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents[sdk=iphoneos*]" = YES;
				"INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents[sdk=iphonesimulator*]" = YES;
				"INFOPLIST_KEY_UILaunchScreen_Generation[sdk=iphoneos*]" = YES;
				"INFOPLIST_KEY_UILaunchScreen_Generation[sdk=iphonesimulator*]" = YES;
				"INFOPLIST_KEY_UIStatusBarStyle[sdk=iphoneos*]" = UIStatusBarStyleDefault;
				"INFOPLIST_KEY_UIStatusBarStyle[sdk=iphonesimulator*]" = UIStatusBarStyleDefault;
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
				IPHONEOS_DEPLOYMENT_TARGET = {{IOS_DEPLOYMENT_TARGET}};
				LD_RUNPATH_SEARCH_PATHS = "@executable_path/Frameworks";
				"LD_RUNPATH_SEARCH_PATHS[sdk=macosx*]" = "@executable_path/../Frameworks";
				MACOSX_DEPLOYMENT_TARGET = {{MACOS_DEPLOYMENT_TARGET}};
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = "com.rudderstack.{{Name}}Example";
				PRODUCT_NAME = "$(TARGET_NAME)";
				REGISTER_APP_GROUPS = YES;
				SDKROOT = auto;
				STRING_CATALOG_GENERATE_SYMBOLS = YES;
				SUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
				SWIFT_APPROACHABLE_CONCURRENCY = YES;
				SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor;
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
				XROS_DEPLOYMENT_TARGET = {{XROS_DEPLOYMENT_TARGET}};
			};
			name = Debug;
		};
		{{ID_19}} /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				ENABLE_APP_SANDBOX = YES;
				ENABLE_HARDENED_RUNTIME = YES;
				ENABLE_PREVIEWS = YES;
				ENABLE_USER_SELECTED_FILES = readonly;
				GENERATE_INFOPLIST_FILE = YES;
				"INFOPLIST_KEY_UIApplicationSceneManifest_Generation[sdk=iphoneos*]" = YES;
				"INFOPLIST_KEY_UIApplicationSceneManifest_Generation[sdk=iphonesimulator*]" = YES;
				"INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents[sdk=iphoneos*]" = YES;
				"INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents[sdk=iphonesimulator*]" = YES;
				"INFOPLIST_KEY_UILaunchScreen_Generation[sdk=iphoneos*]" = YES;
				"INFOPLIST_KEY_UILaunchScreen_Generation[sdk=iphonesimulator*]" = YES;
				"INFOPLIST_KEY_UIStatusBarStyle[sdk=iphoneos*]" = UIStatusBarStyleDefault;
				"INFOPLIST_KEY_UIStatusBarStyle[sdk=iphonesimulator*]" = UIStatusBarStyleDefault;
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = "UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
				INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";
				IPHONEOS_DEPLOYMENT_TARGET = {{IOS_DEPLOYMENT_TARGET}};
				LD_RUNPATH_SEARCH_PATHS = "@executable_path/Frameworks";
				"LD_RUNPATH_SEARCH_PATHS[sdk=macosx*]" = "@executable_path/../Frameworks";
				MACOSX_DEPLOYMENT_TARGET = {{MACOS_DEPLOYMENT_TARGET}};
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = "com.rudderstack.{{Name}}Example";
				PRODUCT_NAME = "$(TARGET_NAME)";
				REGISTER_APP_GROUPS = YES;
				SDKROOT = auto;
				STRING_CATALOG_GENERATE_SYMBOLS = YES;
				SUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
				SWIFT_APPROACHABLE_CONCURRENCY = YES;
				SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor;
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
				XROS_DEPLOYMENT_TARGET = {{XROS_DEPLOYMENT_TARGET}};
			};
			name = Release;
		};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
		{{ID_20}} /* Build configuration list for PBXProject "Example" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				{{ID_16}} /* Debug */,
				{{ID_17}} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
		{{ID_21}} /* Build configuration list for PBXNativeTarget "Example" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				{{ID_18}} /* Debug */,
				{{ID_19}} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
/* End XCConfigurationList section */

/* Begin XCLocalSwiftPackageReference section */
		{{ID_22}} /* XCLocalSwiftPackageReference "../../integration-swift-{{name}}" */ = {
			isa = XCLocalSwiftPackageReference;
			relativePath = "../../integration-swift-{{name}}";
		};
/* End XCLocalSwiftPackageReference section */

/* Begin XCSwiftPackageProductDependency section */
		{{ID_23}} /* {{MODULE_NAME}} */ = {
			isa = XCSwiftPackageProductDependency;
			productName = {{MODULE_NAME}};
		};
/* End XCSwiftPackageProductDependency section */
	};
	rootObject = {{ID_13}} /* Project object */;
}
```

### Platform Customization

The default template targets iOS only. If the third-party SDK supports additional platforms, adjust the target-level build settings (both Debug and Release):

**iOS + tvOS:**
```
SUPPORTED_PLATFORMS = "appletvos appletvsimulator iphoneos iphonesimulator";
SUPPORTS_MACCATALYST = NO;
TARGETED_DEVICE_FAMILY = "1,2,3";
```

**iOS + macOS + tvOS + watchOS (like Firebase):**
```
SUPPORTED_PLATFORMS = "iphoneos iphonesimulator macosx xros xrsimulator";
TARGETED_DEVICE_FAMILY = "1,2,7";
```

## App Entry Point: `<Name>ExampleApp.swift`

```swift
import SwiftUI
import Combine
import RudderStackAnalytics
import RudderIntegration{{Name}}

@main
struct {{Name}}ExampleApp: App {

    init() {
        setupAnalytics()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }

    private func setupAnalytics() {
        LoggerAnalytics.logLevel = .verbose

        let configuration = Configuration(
            writeKey: "<WRITE_KEY>",
            dataPlaneUrl: "<DATA_PLANE_URL>"
        )

        let analytics = Analytics(configuration: configuration)

        let integration = {{Name}}Integration()
        analytics.add(plugin: integration)

        AnalyticsManager.shared.analytics = analytics
    }
}

class AnalyticsManager {
    static let shared = AnalyticsManager()
    var analytics: Analytics?

    private init() {}
}

extension AnalyticsManager {

    // MARK: - User Identity

    func identifyUser() {
        let traits: [String: Any] = [
            "email": "test.swift@integration-test.com",
            "firstName": "Test",
            "lastName": "User",
            "phone": "0123456789"
        ]

        analytics?.identify(userId: "test_user_ios_1", traits: traits)
        LoggerAnalytics.debug("Identified user with traits")
    }

    // MARK: - Track Events

    func trackEventWithProperties() {
        let properties: [String: Any] = [
            "key_1": "value_1",
            "key_2": "value_2"
        ]

        analytics?.track(name: "Custom Event", properties: properties)
        LoggerAnalytics.debug("Tracked custom event with properties")
    }

    func trackEventWithoutProperties() {
        analytics?.track(name: "Simple Event")
        LoggerAnalytics.debug("Tracked simple event")
    }

    // MARK: - Screen Events

    func screenEvent() {
        let properties: [String: Any] = [
            "key_1": "value_1"
        ]

        analytics?.screen(screenName: "Home Screen", properties: properties)
        LoggerAnalytics.debug("Screen event sent")
    }

    // MARK: - Reset

    func resetUser() {
        analytics?.reset()
        LoggerAnalytics.debug("Reset user state")
    }

    // MARK: - Flush

    func flush() {
        analytics?.flush()
        LoggerAnalytics.debug("Flushed analytics queue")
    }
}
```

Customize the `AnalyticsManager` extension based on the integration's supported event types. Add integration-specific methods (e.g., ecommerce events for Firebase, install attribution for Braze, etc.).

## ContentView: `ContentView.swift`

```swift
import SwiftUI
import RudderStackAnalytics

struct ContentView: View {
    private var analyticsManager = AnalyticsManager.shared

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // User Identity Section
                    VStack(spacing: 12) {
                        Text("User Identity")
                            .font(.headline)

                        Button("Identify User") {
                            analyticsManager.identifyUser()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)

                    // Track Events Section
                    VStack(spacing: 12) {
                        Text("Track Events")
                            .font(.headline)

                        Button("Track (With Properties)") {
                            analyticsManager.trackEventWithProperties()
                        }
                        .buttonStyle(SecondaryButtonStyle())

                        Button("Track (No Properties)") {
                            analyticsManager.trackEventWithoutProperties()
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)

                    // Screen Events Section
                    VStack(spacing: 12) {
                        Text("Screen Events")
                            .font(.headline)

                        Button("Screen Event") {
                            analyticsManager.screenEvent()
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(10)

                    // Queue Management Section
                    VStack(spacing: 12) {
                        Text("Queue Management")
                            .font(.headline)

                        Button("Reset") {
                            analyticsManager.resetUser()
                        }
                        .buttonStyle(SecondaryButtonStyle())

                        Button("Flush") {
                            analyticsManager.flush()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                    .padding()
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(10)
                }
                .padding()
            }
            .navigationTitle("{{Name}} Example")
        }
    }
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .background(Color.gray.opacity(0.2))
            .foregroundColor(.primary)
            .cornerRadius(6)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

#Preview {
    ContentView()
}
```

Customize sections based on the integration's supported events. Add integration-specific sections (ecommerce, install attribution, etc.) as needed.

## Asset Catalogs

### `Assets.xcassets/Contents.json`
```json
{
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

### `Assets.xcassets/AccentColor.colorset/Contents.json`
```json
{
  "colors" : [
    {
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

### `Assets.xcassets/AppIcon.appiconset/Contents.json`
```json
{
  "images" : [
    {
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    },
    {
      "appearances" : [
        {
          "appearance" : "luminosity",
          "value" : "dark"
        }
      ],
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    },
    {
      "appearances" : [
        {
          "appearance" : "luminosity",
          "value" : "tinted"
        }
      ],
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    },
    {
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "16x16"
    },
    {
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "16x16"
    },
    {
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "32x32"
    },
    {
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "32x32"
    },
    {
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "128x128"
    },
    {
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "128x128"
    },
    {
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "256x256"
    },
    {
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "256x256"
    },
    {
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "512x512"
    },
    {
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "512x512"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```
