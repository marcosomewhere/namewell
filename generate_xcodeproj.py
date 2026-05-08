#!/usr/bin/env python3
"""
Generates a complete Namewell.xcodeproj for Xcode 15+ / macOS 14+.
Run from the Namewell/ root directory:
    python3 generate_xcodeproj.py
"""

import os
import uuid
import json
from pathlib import Path

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def new_id():
    """Generate a 24-character uppercase hex Xcode PBX object ID."""
    return uuid.uuid4().hex[:24].upper()

class PBX:
    """Accumulates PBX objects for the project.pbxproj file."""
    def __init__(self):
        self.objects = {}

    def add(self, oid, obj):
        self.objects[oid] = obj
        return oid

    def render(self, root_id, archive_version=1, object_version=56):
        lines = ["// !$*UTF8*$!", "{"]
        lines.append(f"\tarchiveVersion = {archive_version};")
        lines.append(f"\tclasses = {{")
        lines.append(f"\t}};")
        lines.append(f"\tobjectVersion = {object_version};")
        lines.append(f"\tobjects = {{")
        lines.append("")

        # Group by isa
        by_isa = {}
        for oid, obj in self.objects.items():
            isa = obj.get("isa", "Unknown")
            by_isa.setdefault(isa, []).append((oid, obj))

        section_order = [
            "PBXBuildFile",
            "PBXFileReference",
            "PBXFrameworksBuildPhase",
            "PBXGroup",
            "PBXNativeTarget",
            "PBXProject",
            "PBXResourcesBuildPhase",
            "PBXShellScriptBuildPhase",
            "PBXSourcesBuildPhase",
            "XCBuildConfiguration",
            "XCConfigurationList",
        ]

        for section in section_order:
            items = by_isa.get(section, [])
            if not items:
                continue
            lines.append(f"/* Begin {section} section */")
            for oid, obj in sorted(items, key=lambda x: x[0]):
                comment = obj.get("_comment", "")
                comment_str = f" /* {comment} */" if comment else ""
                lines.append(f"\t\t{oid}{comment_str} = {{")
                for k, v in obj.items():
                    if k.startswith("_"):
                        continue
                    lines.append(f"\t\t\t{k} = {format_value(v)};")
                lines.append(f"\t\t}};")
            lines.append(f"/* End {section} section */")
            lines.append("")

        lines.append(f"\t}};")
        lines.append(f"\trootObject = {root_id} /* Project object */;")
        lines.append("}")
        return "\n".join(lines)


def format_value(v):
    if isinstance(v, dict):
        if not v:
            return "{}"
        inner = "; ".join(f"{k} = {format_value(val)}" for k, val in v.items())
        return "{" + inner + "; }"
    elif isinstance(v, list):
        if not v:
            return "()"
        inner = ",\n\t\t\t\t".join(format_value(i) for i in v)
        return f"(\n\t\t\t\t{inner},\n\t\t\t)"
    elif isinstance(v, str):
        if v == "":
            return '""'
        # Quote if contains spaces or special chars
        needs_quote = any(c in v for c in ' \t\n/.-()[]{}@#$%^&*+=|\\<>?,;:\'"!')
        if needs_quote:
            return f'"{v}"'
        return v
    return str(v)

# ---------------------------------------------------------------------------
# File tree definition
# ---------------------------------------------------------------------------

APP_NAME = "Namewell"
BUNDLE_ID = "com.namewell.app"
TEAM_ID   = ""          # Fill in your Apple Team ID
MACOS_TARGET = "14.0"

SOURCE_FILES = [
    # (group_path, filename)
    ("Namewell/App",        "NamewellApp.swift"),
    ("Namewell/App",        "AppNotifications.swift"),
    ("Namewell/Models",     "RenameItem.swift"),
    ("Namewell/Models",     "CommandSuggestion.swift"),
    ("Namewell/Models",     "RenameRule.swift"),
    ("Namewell/Models",     "RenameOperation.swift"),
    ("Namewell/Models",     "RenameValidationError.swift"),
    ("Namewell/Services",   "CommandParser.swift"),
    ("Namewell/Services",   "RenameEngine.swift"),
    ("Namewell/Services",   "RenameValidator.swift"),
    ("Namewell/Services",   "FileLoadingService.swift"),
    ("Namewell/Services",   "FolderSelectionService.swift"),
    ("Namewell/Services",   "FileRenameService.swift"),
    ("Namewell/Services",   "UndoManagerService.swift"),
    ("Namewell/ViewModels", "RenameViewModel.swift"),
    ("Namewell/Views",      "ContentView.swift"),
    ("Namewell/Views",      "HeaderView.swift"),
    ("Namewell/Views",      "CommandInputView.swift"),
    ("Namewell/Views",      "PreviewListView.swift"),
    ("Namewell/Views",      "StatusBarView.swift"),
    ("Namewell/Views",      "EmptyStateView.swift"),
    ("Namewell/Utilities",  "FileDropHandler.swift"),
    ("Namewell/Utilities",  "L10n.swift"),
]

RESOURCE_FILES = [
    ("Namewell/Resources",  "en.lproj/Localizable.strings"),
    ("Namewell/Resources",  "de.lproj/Localizable.strings"),
    ("Namewell/Resources",  "fr.lproj/Localizable.strings"),
    ("Namewell/Resources",  "pl.lproj/Localizable.strings"),
    ("Namewell",            "Assets.xcassets"),
]

TEST_FILES = [
    ("NamewellTests",       "NamewellTests.swift"),
]

# ---------------------------------------------------------------------------
# Build the PBX graph
# ---------------------------------------------------------------------------

def build_project():
    pbx = PBX()

    # ---- File references ----
    source_refs   = {}  # filename → ref_id
    resource_refs = {}
    test_refs     = {}

    for (group, fname) in SOURCE_FILES:
        ref = new_id()
        last = fname.split("/")[-1]
        pbx.add(ref, {
            "isa": "PBXFileReference",
            "_comment": last,
            "fileEncoding": "4",
            "lastKnownFileType": "sourcecode.swift",
            "path": last,
            "sourceTree": "<group>",
        })
        source_refs[(group, fname)] = ref

    for (group, fname) in RESOURCE_FILES:
        ref = new_id()
        last = fname.split("/")[-1]
        if fname.endswith(".strings"):
            ftype = "text.plist.strings"
        elif fname.endswith(".xcassets"):
            ftype = "folder.assetcatalog"
        elif fname.endswith(".entitlements"):
            ftype = "text.plist.entitlements"
        else:
            ftype = "file"
        pbx.add(ref, {
            "isa": "PBXFileReference",
            "_comment": last,
            "lastKnownFileType": ftype,
            "path": last if "/" not in fname else fname,
            "sourceTree": "<group>",
        })
        resource_refs[(group, fname)] = ref

    for (group, fname) in TEST_FILES:
        ref = new_id()
        last = fname.split("/")[-1]
        pbx.add(ref, {
            "isa": "PBXFileReference",
            "_comment": last,
            "fileEncoding": "4",
            "lastKnownFileType": "sourcecode.swift",
            "path": last,
            "sourceTree": "<group>",
        })
        test_refs[(group, fname)] = ref

    # App product reference
    app_product_ref = new_id()
    pbx.add(app_product_ref, {
        "isa": "PBXFileReference",
        "_comment": f"{APP_NAME}.app",
        "explicitFileType": "wrapper.application",
        "includeInIndex": "0",
        "path": f"{APP_NAME}.app",
        "sourceTree": "BUILT_PRODUCTS_DIR",
    })

    # Test product reference
    test_product_ref = new_id()
    pbx.add(test_product_ref, {
        "isa": "PBXFileReference",
        "_comment": "NamewellTests.xctest",
        "explicitFileType": "wrapper.cfbundle",
        "includeInIndex": "0",
        "path": "NamewellTests.xctest",
        "sourceTree": "BUILT_PRODUCTS_DIR",
    })

    # ---- Build files ----
    source_build_files = []
    for (group, fname) in SOURCE_FILES:
        bf = new_id()
        ref = source_refs[(group, fname)]
        last = fname.split("/")[-1]
        pbx.add(bf, {
            "isa": "PBXBuildFile",
            "_comment": f"{last} in Sources",
            "fileRef": ref,
        })
        source_build_files.append(bf)

    resource_build_files = []
    for (group, fname) in RESOURCE_FILES:
        bf = new_id()
        ref = resource_refs[(group, fname)]
        last = fname.split("/")[-1]
        pbx.add(bf, {
            "isa": "PBXBuildFile",
            "_comment": f"{last} in Resources",
            "fileRef": ref,
        })
        resource_build_files.append(bf)

    test_build_files = []
    for (group, fname) in TEST_FILES:
        bf = new_id()
        ref = test_refs[(group, fname)]
        last = fname.split("/")[-1]
        pbx.add(bf, {
            "isa": "PBXBuildFile",
            "_comment": f"{last} in Sources",
            "fileRef": ref,
        })
        test_build_files.append(bf)

    # ---- Groups ----
    # Sub-groups
    def make_group(name, children, path=None):
        gid = new_id()
        obj = {
            "isa": "PBXGroup",
            "_comment": name,
            "children": children,
            "name": name,
            "sourceTree": "<group>",
        }
        if path:
            obj["path"] = path
            del obj["name"]
        pbx.add(gid, obj)
        return gid

    app_children = [source_refs[k] for k in source_refs if k[0] == "Namewell/App"]
    models_children = [source_refs[k] for k in source_refs if k[0] == "Namewell/Models"]
    services_children = [source_refs[k] for k in source_refs if k[0] == "Namewell/Services"]
    viewmodels_children = [source_refs[k] for k in source_refs if k[0] == "Namewell/ViewModels"]
    views_children = [source_refs[k] for k in source_refs if k[0] == "Namewell/Views"]
    utilities_children = [source_refs[k] for k in source_refs if k[0] == "Namewell/Utilities"]
    resources_children = [resource_refs[k] for k in resource_refs if k[0] == "Namewell/Resources"]

    app_sources_group = make_group("App", app_children, path="App")
    models_group = make_group("Models", models_children, path="Models")
    services_group = make_group("Services", services_children, path="Services")
    viewmodels_group = make_group("ViewModels", viewmodels_children, path="ViewModels")
    views_group = make_group("Views", views_children, path="Views")
    utilities_group = make_group("Utilities", utilities_children, path="Utilities")
    resources_group = make_group("Resources", resources_children, path="Resources")

    app_root_children = (
        [app_sources_group, models_group, services_group, viewmodels_group, views_group, utilities_group, resources_group]
        + [resource_refs[k] for k in resource_refs if k[0] == "Namewell"]
    )
    app_group = new_id()
    pbx.add(app_group, {
        "isa": "PBXGroup",
        "_comment": APP_NAME,
        "children": app_root_children,
        "path": APP_NAME,
        "sourceTree": "<group>",
    })

    test_group_children = [test_refs[k] for k in test_refs]
    test_group = make_group("NamewellTests", test_group_children, path="NamewellTests")

    products_group = new_id()
    pbx.add(products_group, {
        "isa": "PBXGroup",
        "_comment": "Products",
        "children": [app_product_ref, test_product_ref],
        "name": "Products",
        "sourceTree": "<group>",
    })

    main_group = new_id()
    pbx.add(main_group, {
        "isa": "PBXGroup",
        "_comment": APP_NAME,
        "children": [app_group, test_group, products_group],
        "sourceTree": "<group>",
    })

    # ---- Build phases ----
    app_sources_phase = new_id()
    pbx.add(app_sources_phase, {
        "isa": "PBXSourcesBuildPhase",
        "_comment": "Sources",
        "buildActionMask": "2147483647",
        "files": source_build_files,
        "runOnlyForDeploymentPostprocessing": "0",
    })

    app_resources_phase = new_id()
    pbx.add(app_resources_phase, {
        "isa": "PBXResourcesBuildPhase",
        "_comment": "Resources",
        "buildActionMask": "2147483647",
        "files": resource_build_files,
        "runOnlyForDeploymentPostprocessing": "0",
    })

    app_frameworks_phase = new_id()
    pbx.add(app_frameworks_phase, {
        "isa": "PBXFrameworksBuildPhase",
        "_comment": "Frameworks",
        "buildActionMask": "2147483647",
        "files": [],
        "runOnlyForDeploymentPostprocessing": "0",
    })

    test_sources_phase = new_id()
    pbx.add(test_sources_phase, {
        "isa": "PBXSourcesBuildPhase",
        "_comment": "Sources",
        "buildActionMask": "2147483647",
        "files": test_build_files,
        "runOnlyForDeploymentPostprocessing": "0",
    })

    test_frameworks_phase = new_id()
    pbx.add(test_frameworks_phase, {
        "isa": "PBXFrameworksBuildPhase",
        "_comment": "Frameworks",
        "buildActionMask": "2147483647",
        "files": [],
        "runOnlyForDeploymentPostprocessing": "0",
    })

    # ---- Build configurations ----
    def app_debug_settings():
        return {
            "ALWAYS_SEARCH_USER_PATHS": "NO",
            "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
            "CLANG_ANALYZER_NONNULL": "YES",
            "CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION": "YES_AGGRESSIVE",
            "CODE_SIGN_ENTITLEMENTS": f"{APP_NAME}/{APP_NAME}.entitlements",
            "CODE_SIGN_STYLE": "Automatic",
            "COMBINE_HIDPI_IMAGES": "YES",
            "CURRENT_PROJECT_VERSION": "1",
            "DEAD_CODE_STRIPPING": "YES",
            "DEBUG_INFORMATION_FORMAT": "dwarf",
            "ENABLE_STRICT_OBJC_MSGSEND": "YES",
            "ENABLE_TESTABILITY": "YES",
            "GCC_C_LANGUAGE_STANDARD": "gnu17",
            "GCC_DYNAMIC_NO_PIC": "NO",
            "GCC_NO_COMMON_BLOCKS": "YES",
            "GCC_OPTIMIZATION_LEVEL": "0",
            "GCC_PREPROCESSOR_DEFINITIONS": ["DEBUG=1", "$(inherited)"],
            "INFOPLIST_FILE": f"{APP_NAME}/Info.plist",
            "INFOPLIST_KEY_NSHumanReadableCopyright": "Copyright © 2024 Namewell",
            "LD_RUNPATH_SEARCH_PATHS": ["$(inherited)", "@executable_path/../Frameworks"],
            "MACOSX_DEPLOYMENT_TARGET": MACOS_TARGET,
            "MARKETING_VERSION": "1.0",
            "MTL_ENABLE_DEBUG_INFO": "INCLUDE_SOURCE",
            "MTL_FAST_MATH": "YES",
            "ONLY_ACTIVE_ARCH": "YES",
            "PRODUCT_BUNDLE_IDENTIFIER": BUNDLE_ID,
            "PRODUCT_NAME": "$(TARGET_NAME)",
            "SDKROOT": "macosx",
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "DEBUG",
            "SWIFT_OPTIMIZATION_LEVEL": "-Onone",
            "SWIFT_VERSION": "5.9",
        }

    def app_release_settings():
        s = app_debug_settings()
        s["DEBUG_INFORMATION_FORMAT"] = "dwarf-with-dsym"
        s["GCC_OPTIMIZATION_LEVEL"] = "s"
        s["MTL_ENABLE_DEBUG_INFO"] = "NO"
        s["ONLY_ACTIVE_ARCH"] = "NO"
        s["SWIFT_ACTIVE_COMPILATION_CONDITIONS"] = ""
        s["SWIFT_OPTIMIZATION_LEVEL"] = "-Owholemodule"
        del s["GCC_DYNAMIC_NO_PIC"]
        del s["GCC_PREPROCESSOR_DEFINITIONS"]
        del s["ENABLE_TESTABILITY"]
        return s

    def project_debug_settings():
        return {
            "ALWAYS_SEARCH_USER_PATHS": "NO",
            "CLANG_ANALYZER_NONNULL": "YES",
            "CLANG_ENABLE_MODULES": "YES",
            "CLANG_ENABLE_OBJC_ARC": "YES",
            "CLANG_ENABLE_OBJC_WEAK": "YES",
            "COPY_PHASE_STRIP": "NO",
            "DEBUG_INFORMATION_FORMAT": "dwarf",
            "ENABLE_STRICT_OBJC_MSGSEND": "YES",
            "GCC_C_LANGUAGE_STANDARD": "gnu17",
            "GCC_NO_COMMON_BLOCKS": "YES",
            "GCC_WARN_ABOUT_RETURN_TYPE": "YES_ERROR",
            "GCC_WARN_UNINITIALIZED_AUTOS": "YES_AGGRESSIVE",
            "GCC_WARN_UNUSED_FUNCTION": "YES",
            "GCC_WARN_UNUSED_VARIABLE": "YES",
            "MACOSX_DEPLOYMENT_TARGET": MACOS_TARGET,
            "MTL_ENABLE_DEBUG_INFO": "INCLUDE_SOURCE",
            "MTL_FAST_MATH": "YES",
            "ONLY_ACTIVE_ARCH": "YES",
            "SDKROOT": "macosx",
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "DEBUG",
        }

    def project_release_settings():
        s = project_debug_settings()
        s["COPY_PHASE_STRIP"] = "NO"
        s["DEBUG_INFORMATION_FORMAT"] = "dwarf-with-dsym"
        s["ENABLE_NS_ASSERTIONS"] = "NO"
        s["MTL_ENABLE_DEBUG_INFO"] = "NO"
        s["ONLY_ACTIVE_ARCH"] = "NO"
        s["SWIFT_ACTIVE_COMPILATION_CONDITIONS"] = ""
        s["SWIFT_OPTIMIZATION_LEVEL"] = "-Owholemodule"
        s["VALIDATE_PRODUCT"] = "YES"
        return s

    proj_debug_cfg = new_id()
    pbx.add(proj_debug_cfg, {"isa": "XCBuildConfiguration", "_comment": "Debug", "buildSettings": project_debug_settings(), "name": "Debug"})

    proj_release_cfg = new_id()
    pbx.add(proj_release_cfg, {"isa": "XCBuildConfiguration", "_comment": "Release", "buildSettings": project_release_settings(), "name": "Release"})

    app_debug_cfg = new_id()
    pbx.add(app_debug_cfg, {"isa": "XCBuildConfiguration", "_comment": "Debug", "buildSettings": app_debug_settings(), "name": "Debug"})

    app_release_cfg = new_id()
    pbx.add(app_release_cfg, {"isa": "XCBuildConfiguration", "_comment": "Release", "buildSettings": app_release_settings(), "name": "Release"})

    test_debug_settings = {
        "BUNDLE_LOADER": "$(TEST_HOST)",
        "CODE_SIGN_STYLE": "Automatic",
        "CURRENT_PROJECT_VERSION": "1",
        "MACOSX_DEPLOYMENT_TARGET": MACOS_TARGET,
        "MARKETING_VERSION": "1.0",
        "PRODUCT_BUNDLE_IDENTIFIER": f"{BUNDLE_ID}.tests",
        "PRODUCT_NAME": "$(TARGET_NAME)",
        "SDKROOT": "macosx",
        "SWIFT_VERSION": "5.9",
        "TEST_HOST": "$(BUILT_PRODUCTS_DIR)/Namewell.app/Contents/MacOS/Namewell",
    }
    test_release_settings = dict(test_debug_settings)

    test_debug_cfg = new_id()
    pbx.add(test_debug_cfg, {"isa": "XCBuildConfiguration", "_comment": "Debug", "buildSettings": test_debug_settings, "name": "Debug"})

    test_release_cfg = new_id()
    pbx.add(test_release_cfg, {"isa": "XCBuildConfiguration", "_comment": "Release", "buildSettings": test_release_settings, "name": "Release"})

    # ---- Configuration lists ----
    proj_cfg_list = new_id()
    pbx.add(proj_cfg_list, {
        "isa": "XCConfigurationList",
        "_comment": f"Build configuration list for PBXProject \"{APP_NAME}\"",
        "buildConfigurations": [proj_debug_cfg, proj_release_cfg],
        "defaultConfigurationIsVisible": "0",
        "defaultConfigurationName": "Release",
    })

    app_cfg_list = new_id()
    pbx.add(app_cfg_list, {
        "isa": "XCConfigurationList",
        "_comment": f"Build configuration list for PBXNativeTarget \"{APP_NAME}\"",
        "buildConfigurations": [app_debug_cfg, app_release_cfg],
        "defaultConfigurationIsVisible": "0",
        "defaultConfigurationName": "Release",
    })

    test_cfg_list = new_id()
    pbx.add(test_cfg_list, {
        "isa": "XCConfigurationList",
        "_comment": "Build configuration list for PBXNativeTarget \"NamewellTests\"",
        "buildConfigurations": [test_debug_cfg, test_release_cfg],
        "defaultConfigurationIsVisible": "0",
        "defaultConfigurationName": "Release",
    })

    # ---- Targets ----
    app_target = new_id()
    pbx.add(app_target, {
        "isa": "PBXNativeTarget",
        "_comment": APP_NAME,
        "buildConfigurationList": app_cfg_list,
        "buildPhases": [app_sources_phase, app_resources_phase, app_frameworks_phase],
        "buildRules": [],
        "dependencies": [],
        "name": APP_NAME,
        "productName": APP_NAME,
        "productReference": app_product_ref,
        "productType": "com.apple.product-type.application",
    })

    test_target = new_id()
    pbx.add(test_target, {
        "isa": "PBXNativeTarget",
        "_comment": "NamewellTests",
        "buildConfigurationList": test_cfg_list,
        "buildPhases": [test_sources_phase, test_frameworks_phase],
        "buildRules": [],
        "dependencies": [],
        "name": "NamewellTests",
        "productName": "NamewellTests",
        "productReference": test_product_ref,
        "productType": "com.apple.product-type.bundle.unit-test",
    })

    # ---- Project ----
    project_id = new_id()
    pbx.add(project_id, {
        "isa": "PBXProject",
        "_comment": "Project object",
        "attributes": {
            "BuildIndependentTargetsInParallel": "1",
            "LastSwiftUpdateCheck": "1500",
            "LastUpgradeCheck": "1500",
            "TargetAttributes": {
                app_target:  {"CreatedOnToolsVersion": "15.0"},
                test_target: {"CreatedOnToolsVersion": "15.0", "TestTargetID": app_target},
            },
        },
        "buildConfigurationList": proj_cfg_list,
        "compatibilityVersion": "Xcode 14.0",
        "developmentRegion": "en",
        "hasScannedForEncodings": "0",
        "knownRegions": ["en", "de", "fr", "pl", "Base"],
        "mainGroup": main_group,
        "productRefGroup": products_group,
        "projectDirPath": "",
        "projectRoot": "",
        "targets": [app_target, test_target],
    })

    return pbx.render(project_id)


# ---------------------------------------------------------------------------
# Write project
# ---------------------------------------------------------------------------

def main():
    base = Path(".")
    xcodeproj = base / f"{APP_NAME}.xcodeproj"
    xcodeproj.mkdir(exist_ok=True)

    # project.pbxproj
    pbxproj = xcodeproj / "project.pbxproj"
    content = build_project()
    pbxproj.write_text(content, encoding="utf-8")
    print(f"✓ {pbxproj}  ({len(content):,} chars)")

    # xcshareddata/xcschemes
    schemes_dir = xcodeproj / "xcshareddata" / "xcschemes"
    schemes_dir.mkdir(parents=True, exist_ok=True)

    scheme_xml = f"""<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1500"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "PLACEHOLDER"
               BuildableName = "{APP_NAME}.app"
               BlueprintName = "{APP_NAME}"
               ReferencedContainer = "container:{APP_NAME}.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES">
      <Testables>
         <TestableReference
            skipped = "NO">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "PLACEHOLDER2"
               BuildableName = "NamewellTests.xctest"
               BlueprintName = "NamewellTests"
               ReferencedContainer = "container:{APP_NAME}.xcodeproj">
            </BuildableReference>
         </TestableReference>
      </Testables>
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "PLACEHOLDER"
            BuildableName = "{APP_NAME}.app"
            BlueprintName = "{APP_NAME}"
            ReferencedContainer = "container:{APP_NAME}.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "PLACEHOLDER"
            BuildableName = "{APP_NAME}.app"
            BlueprintName = "{APP_NAME}"
            ReferencedContainer = "container:{APP_NAME}.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
"""
    scheme_path = schemes_dir / f"{APP_NAME}.xcscheme"
    scheme_path.write_text(scheme_xml, encoding="utf-8")
    print(f"✓ {scheme_path}")

    print(f"\n✅ {APP_NAME}.xcodeproj generated successfully.")
    print("   Open in Xcode: open Namewell.xcodeproj")

if __name__ == "__main__":
    main()
