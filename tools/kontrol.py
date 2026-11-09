#!/usr/bin/env python3
"""Depo kontrolu. Kullanim: python3 tools/kontrol.py  (cikis 1 = sorun var)
1. README dosyalarindaki `olcum/...`, `betikler/...`, `gorsel/...` yollari var mi
2. betikler/senaryolar ve senaryolar-en ayni dosya adlarina sahip mi
3. Dosya adlari kucuk harf ASCII mi (senaryo klasorleri)
4. Gizli bilgi kaliplari yok mu (parola degeri, IP, token)
5. SQL dosyalari bos degil ve satir sonu ile bitiyor mu
6. CITATION.cff, LICENSE, LICENSE-PDF.md mevcut mu
"""
import os, re, subprocess, sys

KOK = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.chdir(KOK)
sorun = []

def dosyalar():
    cikti = subprocess.run(["git", "ls-files"], capture_output=True, text=True, check=True).stdout.split("\n")
    return [f for f in cikti if f and os.path.isfile(f)]

tum = dosyalar()

for rd in ("README.md", "README.en.md"):
    t = open(rd, encoding="utf-8").read()
    for p in sorted(set(re.findall(r"`((?:olcum|betikler|gorsel)/[^`\s,]*)`", t))):
        if not os.path.exists(p.rstrip("/")):
            sorun.append("%s icindeki yol yok: %s" % (rd, p))

def agac(kok):
    return sorted(os.path.relpath(f, kok) for f in tum if f.startswith(kok + "/"))
if agac("betikler/senaryolar") != agac("betikler/senaryolar-en"):
    sorun.append("betikler/senaryolar ile senaryolar-en ayni dosya adlarina sahip degil")

for f in tum:
    if f.startswith("betikler/senaryolar") and not re.fullmatch(r"[a-z0-9._/-]+", f):
        sorun.append("senaryo dosya adi kucuk harf ASCII degil: " + f)

YASAK = [(r"PASSWORD\s*=\s*N?'(?!<)[^']{3,}'", "parola degeri"), (r"\b(?:10|172\.(?:1[6-9]|2\d|3[01])|192\.168)\.\d{1,3}\.\d{1,3}(?:\.\d{1,3})?\b(?<!\d\.\d\.\d\.\d)", "ozel ag IP"),
         (r"gh[opsu]_[A-Za-z0-9]{20,}", "GitHub token"), (r"AKIA[0-9A-Z]{16}", "AWS anahtari")]
for f in tum:
    if f.lower().endswith((".jpg", ".png", ".pdf")): continue
    try: t = open(f, encoding="utf-8", errors="ignore").read()
    except OSError: continue
    for desen, ad in YASAK:
        for m in re.finditer(desen, t):
            s = m.group(0)
            if re.fullmatch(r"\d+\.\d+\.\d+\.\d+", s) and s.split(".")[0] in ("15", "16", "17"): continue
            sorun.append("%s: %s bulundu (%s...)" % (f, ad, s[:25]))

for f in tum:
    if f.endswith(".sql"):
        b = open(f, "rb").read()
        if not b.strip(): sorun.append("bos SQL dosyasi: " + f)
        elif not b.endswith(b"\n"): sorun.append("SQL dosyasi satir sonu ile bitmiyor: " + f)

for f in ("CITATION.cff", "LICENSE", "LICENSE-PDF.md", "CONTRIBUTING.md", "CODE_OF_CONDUCT.md"):
    if not os.path.exists(f): sorun.append("eksik dosya: " + f)

if sorun:
    print("%d SORUN" % len(sorun))
    for s in sorun[:60]: print(" -", s)
    sys.exit(1)
print("TAMAM,", len(tum), "dosya kontrol edildi")
