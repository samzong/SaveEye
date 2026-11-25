# SaveEye releases

SaveEye is an L1 desktop tool. Published versions and tags are immutable.
Use `X.Y.Z` for release cores and `vX.Y.Z` for stable tags.
Use `vX.Y.Z-alpha.N`, `vX.Y.Z-beta.N`, or `vX.Y.Z-rc.N` for prerelease tags.
Start new prerelease sequences at 1. Use no leading zeros.
The release gate also accepts sequence 0 under the repository's tag syntax contract.

`SaveEye/Info.plist` contains the release core in `CFBundleShortVersionString`.
The application target must use the same `MARKETING_VERSION` in every Xcode build configuration.
`CFBundleVersion` expands the tracked `CURRENT_PROJECT_VERSION` from the Xcode project.
Prerelease suffixes appear in tags and DMG filenames. Application version fields contain the release core.

## Prepare a release

1. Set the release core from the repository root:

   ```sh
   make version VERSION=1.2.0
   ```

   This command updates `Info.plist` and the Xcode marketing versions together.
2. Increase `CURRENT_PROJECT_VERSION` in both application build configurations before each publication, including prereleases.
3. Update `CHANGELOG.md` before tagging. Install `git-cliff` with Homebrew, then generate the new section:

   ```sh
   git cliff --unreleased --tag v1.2.0 --prepend CHANGELOG.md
   ```

4. Review the generated section. Use the full prerelease version in its heading when preparing a prerelease.
5. Run the version gate, build, tests, and package checks on a Mac with Xcode:

   ```sh
   python3 .github/scripts/check-release-tag.py v1.2.0
   xcodebuild test -scheme SaveEye -destination 'platform=macOS' -derivedDataPath build/DerivedData CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
   make dmg-unsigned VERSION=1.2.0
   bash .github/scripts/verify-package.sh 1.2.0 1.2.0 2
   python3 .github/scripts/release-notes.py 1.2.0 build/release-notes.txt
   ```

   Replace `2` with the tracked build number. All commands must succeed, and release notes must contain text.
6. Submit the changes through a PR and wait for the macOS CI checks before merging.

## Publish after owner authorization

After the owner authorizes publication, create a new tag at the reviewed release commit and push that tag.
Never move, rename, delete, or reuse a published tag, including the historical `v1` tag.
A tag push starts the release workflow. The first check after checkout rejects invalid tags and version drift before Xcode runs.

The workflow tests the app, builds an unsigned arm64 DMG, and verifies its integrity, architecture, and application versions.
It extracts the exact version section from `CHANGELOG.md`.
If that section is missing or blank, it writes the release version and a DMG installation instruction.
The workflow uploads `SaveEye-{version}-arm64.dmg` to GitHub Releases.
Prerelease tags set `prerelease: true` and `make_latest: false`.

After publication, inspect the release version, notes, prerelease flag, and downloadable DMG.
Live publication is separate from PR validation. PR validation does not publish a GitHub Release.
Homebrew updates belong to the centralized `samzong/homebrew-tap` scan.
This repository does not push changes or dispatch updates to the tap.

## Validation limits

CI runs the existing Xcode test targets. Their current coverage includes launch checks and an empty unit test example.
A green run proves build, test execution, and package checks. It does not prove all eye-care behavior.
Local release checks require Xcode. A Command Line Tools installation alone cannot build or test the application.
