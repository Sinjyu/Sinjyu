#!/usr/bin/env python3
"""Build a Simplified-Chinese Yuri's Revenge string table for the RA2 web/Mac port.

Inputs
  --en        English YR table produced by the port's setup.sh from YOUR retail
              copy:  redalert2/public/generalmd.csf  (extracted from langmd.mix)
  --zh        Chinese RA2 table shipped by huangkaoya/redalert2: public/general.csf
              (RA2 only — Yuri's Revenge-only labels are not in it)
  --glossary  TSV you own: label <TAB> english <TAB> chinese. Filled rows win over
              --zh. Rows with an empty chinese column are rewritten each run with the
              labels that are still untranslated, so this one file is both the
              to-do list and the record of your own translations.

Output
  --out       redalert2/public/generalmd.zh.csf  (language id = Chinese, so the
              engine also picks res/locale/zh-CN.json)
  --config    redalert2/public/config.ini is pointed at --out (csfFile=...,
              defaultLanguage=zh-CN). Re-running setup.sh never touches --out.

Python 3 standard library only.
"""
import argparse
import csv
import os
import re
import struct
import sys

LANG_CHINESE_CN = 100


def read_csf(path):
    """Return (language, [(label, value)]) in file order. Label case is kept."""
    data = open(path, "rb").read()
    if data[:4] != b" FSC":
        sys.exit(f"{path}: not a CSF file")
    _version, num_labels, _num_strings, _reserved, language = struct.unpack_from("<5I", data, 4)
    pos, out = 24, []
    for _ in range(num_labels):
        if data[pos:pos + 4] != b" LBL":
            sys.exit(f"{path}: bad label header at byte {pos}")
        pairs, name_len = struct.unpack_from("<II", data, pos + 4)
        name = data[pos + 12:pos + 12 + name_len].decode("latin-1")
        pos += 12 + name_len
        value = ""
        for i in range(pairs):
            tag = data[pos:pos + 4]
            (chars,) = struct.unpack_from("<I", data, pos + 4)
            raw = data[pos + 8:pos + 8 + 2 * chars]
            pos += 8 + 2 * chars
            if i == 0:
                value = bytes(b ^ 0xFF for b in raw).decode("utf-16-le", "replace")
            if tag == b"WRTS":  # value carries an extra 8-bit string
                (extra,) = struct.unpack_from("<I", data, pos)
                pos += 4 + extra
        out.append((name, value))
    return language, out


def write_csf(path, entries, language):
    parts = [b" FSC", struct.pack("<5I", 3, len(entries), len(entries), 0, language)]
    for name, value in entries:
        name_b = name.encode("latin-1")
        val_b = bytes(b ^ 0xFF for b in value.encode("utf-16-le"))
        parts += [b" LBL", struct.pack("<II", 1, len(name_b)), name_b,
                  b" RTS", struct.pack("<I", len(val_b) // 2), val_b]
    with open(path, "wb") as f:
        f.write(b"".join(parts))


def read_glossary(path):
    filled = {}
    if os.path.exists(path):
        with open(path, newline="", encoding="utf-8") as f:
            for row in csv.reader(f, delimiter="\t"):
                if len(row) >= 3 and row[0] and not row[0].startswith("#") and row[2].strip():
                    filled[row[0].upper()] = (row[0], row[1], row[2])
    return filled


def write_glossary(path, filled, missing):
    with open(path, "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f, delimiter="\t", lineterminator="\n")
        w.writerow(["# label", "english", "chinese (fill this column, then re-run)"])
        for key in sorted(filled):
            w.writerow(filled[key])
        for label, english in missing:
            w.writerow([label, english.replace("\n", "\\n"), ""])


def point_config(config_path, csf_name):
    text = open(config_path, encoding="utf-8").read()
    for key, value in (("csfFile", csf_name), ("defaultLanguage", "zh-CN")):
        pattern = re.compile(rf"^\s*{key}\s*=.*$", re.M)
        if not pattern.search(text):
            sys.exit(f"{config_path}: no '{key}=' line found; edit it by hand")
        text = pattern.sub(f"{key} = {value}" if key == "csfFile" else f"{key}={value}", text, count=1)
    open(config_path, "w", encoding="utf-8").write(text)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--en", required=True)
    ap.add_argument("--zh", required=True)
    ap.add_argument("--glossary", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--config")
    args = ap.parse_args()

    _, en = read_csf(args.en)
    _, zh_entries = read_csf(args.zh)
    zh = {k.upper(): v for k, v in zh_entries}
    filled = read_glossary(args.glossary)

    merged, missing, n_glossary, n_zh = [], [], 0, 0
    for label, english in en:
        key = label.upper()
        if key in filled:
            merged.append((label, filled[key][2].replace("\\n", "\n")))
            n_glossary += 1
        elif key in zh:
            merged.append((label, zh[key]))
            n_zh += 1
        else:
            merged.append((label, english))
            if english.strip():
                missing.append((label, english))

    write_csf(args.out, merged, LANG_CHINESE_CN)
    write_glossary(args.glossary, filled, missing)
    if args.config:
        point_config(args.config, os.path.basename(args.out))

    print(f"labels in your English YR table : {len(en)}")
    print(f"  from huangkaoya Chinese table : {n_zh}")
    print(f"  from your glossary            : {n_glossary}")
    print(f"  still English (to translate)  : {len(missing)}  -> {args.glossary}")
    print(f"wrote {args.out}" + (f"; {args.config} now points at it" if args.config else ""))


if __name__ == "__main__":
    main()
