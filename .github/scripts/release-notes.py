import re
import sys
from pathlib import Path


version, destination = sys.argv[1:]
changelog = Path("CHANGELOG.md")
lines = changelog.read_text().splitlines() if changelog.is_file() else []
notes = []
collecting = False
for line in lines:
    if line.startswith("## "):
        if collecting:
            break
        collecting = re.fullmatch(
            r"## (?:\[" + re.escape(version) + r"\]|" + re.escape(version) + r")(?:\s+.*)?",
            line,
        ) is not None
    elif collecting:
        notes.append(line)
body = "\n".join(notes).strip()
if not body:
    body = f"SaveEye {version}.\n\nDownload the DMG and move SaveEye to Applications."
Path(destination).write_text(body + "\n")
if not Path(destination).read_text().strip():
    sys.exit("Release notes must not be empty")
