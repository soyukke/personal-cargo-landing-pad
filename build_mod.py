from __future__ import annotations

import json
import shutil
import sys
import zipfile
from pathlib import Path


ROOT = Path(__file__).resolve().parent
MOD_NAME = "personal-cargo-landing-pad"
INCLUDED_PATHS = [
    "changelog.txt",
    "control.lua",
    "info.json",
    "LICENSE",
    "locale/en/locale.cfg",
    "locale/ja/locale.cfg",
    "MOD_PORTAL_DESCRIPTION.md",
    "README.md",
    "routing.lua",
    "thumbnail.png",
]


def main() -> None:
    info = json.loads((ROOT / "info.json").read_text(encoding="utf-8"))
    version = info["version"]
    zip_name = f"{MOD_NAME}_{version}.zip"
    top = f"{MOD_NAME}_{version}"
    target_dir = ROOT / "target"
    target_dir.mkdir(exist_ok=True)
    out_zip = target_dir / zip_name
    if out_zip.exists():
        out_zip.unlink()

    with zipfile.ZipFile(out_zip, "w", compression=zipfile.ZIP_DEFLATED) as archive:
        for rel in INCLUDED_PATHS:
            path = ROOT / rel
            if not path.is_file():
                raise FileNotFoundError(path)
            archive.write(path, f"{top}/{rel}")

    print(f"Built {out_zip}")

    if "--install-local" in sys.argv:
        runtime_mod_dir = Path.home() / ".factorio-server-maintainer" / "Server" / "mods"
        runtime_mod_dir.mkdir(parents=True, exist_ok=True)
        for old_zip in runtime_mod_dir.glob(f"{MOD_NAME}_*.zip"):
            old_zip.unlink()
        shutil.copy2(out_zip, runtime_mod_dir / zip_name)
        print(f"Installed {zip_name} to {runtime_mod_dir}")


if __name__ == "__main__":
    main()
