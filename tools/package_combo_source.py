#!/usr/bin/env python3
"""Package the playable combo source and review media, without editor caches/EXEs."""
from hashlib import sha256
import argparse
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-name", default="PHUZASHI_Air_Combos_Godot.zip")
    parser.add_argument("--folder-name", default="PHUZASHI_Air_Combos")
    args = parser.parse_args()
    output = root / "docs/downloads" / args.output_name
    output.parent.mkdir(parents=True, exist_ok=True)
    paths = set()
    for folder in ("assets", "scenes", "scripts", "tests", "tools", "docs/screenshots"):
        paths.update(
            path for path in (root / folder).rglob("*")
            if path.is_file() and "__pycache__" not in path.parts
        )
    paths.update((root / "docs").glob("*.md"))
    paths.update((root / "docs").glob("*.mp4"))
    paths.update(root / name for name in (
        "project.godot", "README.md", "README_TH.md", "START_HERE_TH.txt"
    ))
    prefix = args.folder_name.rstrip("/") + "/"
    with ZipFile(output, "w", ZIP_DEFLATED, compresslevel=6) as archive:
        for path in sorted(paths):
            archive.write(path, prefix + path.relative_to(root).as_posix())
    with ZipFile(output) as archive:
        assert archive.testzip() is None, "ZIP CRC check failed"
        for path in paths:
            assert archive.read(prefix + path.relative_to(root).as_posix()) == path.read_bytes(), path
        assert not any(
            name.lower().endswith((".exe", ".pck")) or "/.godot/" in name
            for name in archive.namelist()
        ), "Unexpected executable/cache in source ZIP"
    digest = sha256(output.read_bytes()).hexdigest()
    output.with_suffix(".zip.sha256").write_text(
        f"{digest}  {output.name}\n", encoding="utf-8"
    )
    print(f"Verified {len(paths)} files, {output.stat().st_size} bytes: {output}")
    print(f"SHA-256: {digest}")


if __name__ == "__main__":
    main()
