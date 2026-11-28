# Which build this is. The Windows build workflow (.github/workflows/windows-build.yml) overwrites this file right before
# exporting, so a downloaded game knows its own commit. "dev" = running from the editor / sandbox (no update checks).
class_name BuildStamp
const COMMIT := "dev"
const BUILT := ""
