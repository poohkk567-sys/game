#!/usr/bin/env python3
"""Package the Red Cap sheets and Godot atlas data without editor caches."""
from hashlib import sha256
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    paths = sorted((root / 'assets/characters/red_cap').rglob('*'))
    paths = [path for path in paths if path.is_file()]
    paths.append(root / 'tools/import_red_cap_sprites.gd')
    prefix = 'RED_CAP_Normal_Spritesheets/'
    output = root / 'docs/downloads/RED_CAP_Normal_Spritesheets.zip'
    output.parent.mkdir(parents=True, exist_ok=True)
    with ZipFile(output, 'w', ZIP_DEFLATED, compresslevel=6) as archive:
        for path in paths:
            archive.write(path, prefix + path.relative_to(root).as_posix())
    with ZipFile(output) as archive:
        assert archive.testzip() is None
        for path in paths:
            assert archive.read(prefix + path.relative_to(root).as_posix()) == path.read_bytes()
    output.with_suffix('.zip.sha256').write_text(
        f'{sha256(output.read_bytes()).hexdigest()}  {output.name}\n', encoding='utf-8'
    )
    print(f'Verified {len(paths)} files, {output.stat().st_size} bytes: {output}')


if __name__ == '__main__':
    main()
