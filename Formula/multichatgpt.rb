class Multichatgpt < Formula
  desc "Create named, independent ChatGPT desktop profile launchers"
  homepage "https://github.com/flavioaiello/multichatgpt"
  url "https://github.com/flavioaiello/multichatgpt.git",
      tag: "v0.2.0"
  version "0.2.0"
  license "MIT"
  head "https://github.com/flavioaiello/multichatgpt.git", branch: "main"

  depends_on :macos
  depends_on "python@3.13"

  def install
    system ENV.cc, "-Wall", "-Wextra", "-Werror", "src/launcher.c", "-o", "profile-launcher"
    libexec.install "profile-launcher"
    (libexec/"bin").install "bin/multichatgpt"
    (bin/"multichatgpt").write <<~SH
      #!/bin/sh
      exec "#{Formula["python@3.13"].opt_bin}/python3.13" "#{libexec}/bin/multichatgpt" "$@"
    SH
  end

  test do
    assert_match "multichatgpt 0.2.0", shell_output("#{bin}/multichatgpt --version")
    assert_equal "[]", shell_output("#{bin}/multichatgpt list --json --data-dir '#{testpath}/profiles'").strip
    app = testpath/"Fake ChatGPT.app"
    (app/"Contents/MacOS").mkpath
    (app/"Contents/Info.plist").write <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <plist version="1.0"><dict>
      <key>CFBundleIdentifier</key><string>com.openai.codex</string>
      <key>CFBundleExecutable</key><string>fake-chatgpt</string>
      </dict></plist>
    XML
    (app/"Contents/MacOS/fake-chatgpt").write "#!/bin/sh\nprintf '%s\\n' \"$CODEX_HOME\" \"$@\"\n"
    chmod 0755, app/"Contents/MacOS/fake-chatgpt"
    2.times do
      system bin/"multichatgpt", "clone", "chatgpt", "--app", app,
             "--applications-dir", testpath/"apps", "--data-dir", testpath/"profiles"
    end
    entries = JSON.parse(shell_output("#{bin}/multichatgpt list --json --data-dir '#{testpath}/profiles'"))
    assert_equal 2, entries.length
    assert_equal 2, entries.map { |entry| entry.fetch("id") }.uniq.length
    entries.each do |entry|
      assert_path_exists "#{entry.fetch("app")}/Contents/MacOS/fake-chatgpt"
      system "/usr/bin/env", "#{entry.fetch("app")}/Contents/MacOS/profile-launcher"
      profile = Pathname(entry.fetch("profile"))
      assert_equal ["#{profile}/codex", "--user-data-dir=#{profile}/browser"],
                   (profile/"launcher.log").read.lines.map(&:strip)
    end
    entry = entries.first
    marker = Pathname(entry.fetch("profile"))/"codex/keep.txt"
    marker.write "existing profile data"
    system bin/"multichatgpt", "refresh", entry.fetch("name"),
           "--app", app, "--data-dir", testpath/"profiles"
    assert_equal "existing profile data", marker.read
  end
end
