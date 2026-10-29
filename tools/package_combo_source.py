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
    parser.add_argument("--review-prefix", help="Include only matching screenshot filenames")
    parser.add_argument("--video-name", help="Include only this review video from docs")
    parser.add_argument("--no-video", action="store_true", help="Keep the source ZIP small; host the review video separately")
    parser.add_argument("--extra-review-file", action="append", default=[])
    args = parser.parse_args()
    if args.no_video and args.video_name:
        parser.error("--no-video cannot be combined with --video-name")
    output = root / "docs/downloads" / args.output_name
    output.parent.mkdir(parents=True, exist_ok=True)
    paths = set()
    for folder in ("assets", "scenes", "scripts", "tests", "tools", "docs/screenshots"):
        paths.update(
            path for path in (root / folder).rglob("*")
            if path.is_file() and "__pycache__" not in path.parts
            and (folder != "docs/screenshots" or not args.review_prefix
                 or path.name.startswith(args.review_prefix))
        )
    paths.update((root / "docs").glob("*.md"))
    paths.add(root / "docs/.gdignore")
    if args.video_name:
        video = root / "docs" / args.video_name
        assert video.is_file(), video
        paths.add(video)
    elif not args.no_video:
        paths.update((root / "docs").glob("*.mp4"))
    for name in args.extra_review_file:
        path = (root / name).resolve()
        assert path.is_relative_to(root) and path.is_file(), path
        paths.add(path)
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
