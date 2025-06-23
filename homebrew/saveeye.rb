cask "saveeye" do
  version "1.0.0"
  sha256 arm:   "ARM_SHA256_PLACEHOLDER",
         intel: "INTEL_SHA256_PLACEHOLDER"

  url "https://github.com/samzong/SaveEye/releases/download/v#{version}/SaveEye-#{version}-#{Hardware::CPU.arch}.dmg"
  name "SaveEye"
  desc "macOS eye care reminder app, monitor user activity and remind to rest to protect eyesight"
  homepage "https://github.com/samzong/SaveEye"

  livecheck do
    url :url
    strategy :github_latest
  end

  auto_updates true

  depends_on macos: ">= :big_sur"

  app "SaveEye.app"

  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-cr", "#{appdir}/SaveEye.app"],
                   sudo: false
  end

  uninstall quit: "com.seimo.SaveEye"

  zap trash: [
    "~/Library/Application Support/SaveEye",
    "~/Library/Caches/com.seimo.SaveEye",
    "~/Library/HTTPStorages/com.seimo.SaveEye",
    "~/Library/Logs/SaveEye",
    "~/Library/Preferences/com.seimo.SaveEye.plist",
    "~/Library/Saved Application State/com.seimo.SaveEye.savedState",
    "~/Library/WebKit/com.seimo.SaveEye",
  ]
end