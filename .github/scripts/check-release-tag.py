import json
import os
import plistlib
import re
import subprocess
import sys
from pathlib import Path


tag = sys.argv[1]
if not re.fullmatch(
    r"v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-(alpha|beta|rc)\.(0|[1-9][0-9]*))?",
    tag,
):
    sys.exit(f"Invalid SemVer release tag: {tag}")

version = tag[1:]
core = version.split("-", 1)[0]
with Path("SaveEye/Info.plist").open("rb") as source:
    plist = plistlib.load(source)
if plist.get("CFBundleShortVersionString") != core:
    sys.exit(f"Info.plist CFBundleShortVersionString must equal {core}")

project = json.loads(subprocess.check_output([
    "plutil", "-convert", "json", "-o", "-", "SaveEye.xcodeproj/project.pbxproj",
]))["objects"]
targets = [item for item in project.values()
           if item.get("productType") == "com.apple.product-type.application"]
if len(targets) != 1:
    sys.exit("Expected one application target in the Xcode project")
configurations = project[targets[0]["buildConfigurationList"]]["buildConfigurations"]
if not configurations:
    sys.exit("The application target has no build configurations")
builds = set()
for identifier in configurations:
    configuration = project[identifier]
    settings = configuration["buildSettings"]
    if settings.get("MARKETING_VERSION") != core:
        sys.exit(f"{configuration['name']} MARKETING_VERSION must equal {core}")
    build = str(settings.get("CURRENT_PROJECT_VERSION", ""))
    if not re.fullmatch(r"[1-9][0-9]*", build):
        sys.exit("CURRENT_PROJECT_VERSION must be a positive integer")
    builds.add(build)
if len(builds) != 1:
    sys.exit("Application build configurations must use the same CURRENT_PROJECT_VERSION")
build = builds.pop()
if str(plist.get("CFBundleVersion")) not in (build, "$(CURRENT_PROJECT_VERSION)"):
    sys.exit("Info.plist CFBundleVersion must match CURRENT_PROJECT_VERSION")

prerelease = "-" in version
output = (
    f"version={version}\ncore={core}\nbuild={build}\n"
    f"is_prerelease={str(prerelease).lower()}\n"
    f"make_latest={str(not prerelease).lower()}\n"
)
if os.environ.get("GITHUB_OUTPUT"):
    with Path(os.environ["GITHUB_OUTPUT"]).open("a") as destination:
        destination.write(output)
print(output, end="")
