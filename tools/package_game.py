#!/usr/bin/env python3
"""Build a portable Windows ZIP and a separate editable Godot source ZIP.

Uses an isolated staging project so local export template overrides cannot leak
into the tracked presets or the source download. Requires matching Godot 4.6.3
release templates and the engine's LICENSE.txt/COPYRIGHT.txt in the license dir.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[1]


def run(command, log, env=None):
    with log.open("w", encoding="utf-8") as output:
        result = subprocess.run(command, stdout=output, stderr=subprocess.STDOUT, env=env)
    text = log.read_text(encoding="utf-8", errors="replace")
    if result.returncode or "SCRIPT ERROR:" in text or "ERROR:" in text:
        raise RuntimeError(f"Build/validation failed; inspect {log}")


def archive(path, files):
    with zipfile.ZipFile(path, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as out:
        for source, target in files:
            out.write(source, target)
    with zipfile.ZipFile(path) as check:
        if check.testzip() is not None:
            raise RuntimeError(f"ZIP integrity failure: {path}")
    digest = hashlib.sha256(path.read_bytes()).hexdigest()
    path.with_suffix(path.suffix + ".sha256").write_text(f"{digest}  {path.name}\n")
    return {"file": path.name, "bytes": path.stat().st_size, "sha256": digest}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--godot", default="godot")
    parser.add_argument("--templates", type=Path, required=True)
    parser.add_argument("--licenses", type=Path, required=True)
    parser.add_argument("--work", type=Path, default=ROOT / "work" / "package")
    parser.add_argument("--output", type=Path, default=ROOT / "docs" / "downloads")
    args = parser.parse_args()
    args.work = args.work.resolve()
    args.output = args.output.resolve()
    args.templates = args.templates.resolve()
    args.licenses = args.licenses.resolve()
    args.work.mkdir(parents=True, exist_ok=True)
    args.output.mkdir(parents=True, exist_ok=True)
    stage = args.work / "project"
    stage.mkdir(exist_ok=True)
    for folder in ("assets", "scenes", "scripts"):
        shutil.copytree(ROOT / folder, stage / folder, dirs_exist_ok=True)
    shutil.copy2(ROOT / "project.godot", stage / "project.godot")
    presets = (ROOT / "export_presets.cfg").read_text()
    for template in ("windows_release_x86_64.exe", "linux_release.x86_64"):
        if not (args.templates / template).is_file():
            raise FileNotFoundError(args.templates / template)
    windows_template = (args.templates / "windows_release_x86_64.exe").as_posix()
    linux_template = (args.templates / "linux_release.x86_64").as_posix()
    presets = presets.replace('custom_template/release=""',
                              f'custom_template/release="{windows_template}"', 1)
    # The native validation preset belongs only to the temporary staging project.
    presets += f'''
[preset.1]
name="Linux (validation)"
platform="Linux"
runnable=false
export_filter="all_resources"
include_filter=""
exclude_filter="docs/*,tests/*,tools/*,browser/*,.github/*,work/*"
export_path="PHUZASHI.x86_64"
script_export_mode=2
[preset.1.options]
custom_template/release="{linux_template}"
binary_format/embed_pck=true
binary_format/architecture="x86_64"
'''
    (stage / "export_presets.cfg").write_text(presets)
    task_env = os.environ.copy()
    task_env["XDG_DATA_HOME"] = str(args.work / "userdata")
    task_env["XDG_CACHE_HOME"] = str(args.work / "cache")
    run([args.godot, "--headless", "--path", str(stage), "--editor", "--import", "--quit"],
        args.work / "import.log", task_env)
    windows = args.work / "Windows"
    native = args.work / "native"
    windows.mkdir(exist_ok=True)
    native.mkdir(exist_ok=True)
    executable = windows / "PHUZASHI.exe"
    linux = native / "PHUZASHI.x86_64"
    for preset, destination, log in (("Windows", executable, "windows-export.log"),
                                     ("Linux (validation)", linux, "linux-export.log")):
        run([args.godot, "--headless", "--path", str(stage), "--export-release", preset, str(destination)],
            args.work / log, task_env)
    linux.chmod(0o755)
    run([str(linux), "--headless", "--quit-after", "180"],
        args.work / "native-smoke.log", task_env)
    (windows / "เริ่มเล่น.txt").write_text(
        "PHUZASHI — DARK PULSE\n\n"
        "1. แตกไฟล์ ZIP ทั้งหมดลงในโฟลเดอร์\n"
        "2. ดับเบิลคลิก PHUZASHI.exe เพื่อเล่น (Windows 64-bit)\n"
        "3. คลิกหน้าต่างเกมเพื่อรับปุ่มควบคุม\n\n"
        "F2 สาธิตครบ 12 ท่า / F1 รายการท่า / Esc หยุด-เล่นต่อ\n"
        "A,D เดิน / Shift วิ่ง / Space กระโดด / S หมอบ / L ป้องกัน\n"
        "J ต่อย / K เตะ / U สกิล / I อัลติเมต / H รับแรงโจมตี / N ล้ม / R รีเซ็ต\n\n"
        "ชุดนี้มี spritesheet 96 เฟรม รวมข้อมูลเกมไว้ใน EXE แล้ว\n"
        "ไฟล์โปรเจกต์สำหรับแก้ไขอยู่ใน PHUZASHI_Godot_Source.zip แยกต่างหาก\n",
        encoding="utf-8-sig", newline="\r\n")
    for filename in ("GODOT_LICENSE.txt", "GODOT_COPYRIGHT.txt"):
        shutil.copy2(args.licenses / filename, windows / filename)
    standalone = archive(args.output / "PHUZASHI_Windows_x64.zip",
                         [(p, "PHUZASHI/" + p.name) for p in sorted(windows.iterdir()) if p.is_file() and not p.name.endswith(".console.exe")])
    if standalone["bytes"] >= 95_000_000:
        raise RuntimeError("Windows ZIP exceeds the repository delivery size limit")
    source_files = []
    for folder in ("assets", "scenes", "scripts", "tests", "tools"):
        for path in sorted((ROOT / folder).rglob("*")):
            if path.is_file() and "__pycache__" not in path.parts:
                source_files.append((path, "PHUZASHI_Godot/" + path.relative_to(ROOT).as_posix()))
    for filename in ("project.godot", "export_presets.cfg"):
        source_files.append((ROOT / filename, "PHUZASHI_Godot/" + filename))
    instructions = args.work / "เปิดใน_Godot.txt"
    instructions.write_text(
        "แตก ZIP แล้วเปิด Godot 4.2.2 ขึ้นไป\n"
        "Import > เลือก project.godot > Import & Edit > กด F5\n"
        "F2 สาธิตครบทุกท่า / F1 รายการท่า\n\n"
        "คู่มือ: https://github.com/poohkk567-sys/game\n", encoding="utf-8-sig")
    source_files.append((instructions, "PHUZASHI_Godot/เปิดใน_Godot.txt"))
    source = archive(args.output / "PHUZASHI_Godot_Source.zip", source_files)
    try:
        game_commit = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT,
                                              text=True, stderr=subprocess.DEVNULL).strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        game_commit = "source archive (no Git metadata)"
    manifest = {"game_commit": game_commit,
                "engine": subprocess.check_output([args.godot, "--version"], text=True).strip(),
                "packages": [standalone, source], "windows_native_runtime_tested": False,
                "linux_exported_runtime_smoke_test": "passed"}
    (args.output / "build_manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print(json.dumps(manifest, indent=2))


if __name__ == "__main__":
    main()
