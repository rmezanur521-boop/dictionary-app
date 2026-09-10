import csv

INPUT_FILE = "BengaliDictionary_93.csv"
OUTPUT_FILE = "words_50k.csv"

with open(INPUT_FILE, encoding="utf-8-sig") as infile, \
     open(OUTPUT_FILE, "w", encoding="utf-8", newline="") as outfile:

    reader = csv.reader(infile)
    writer = csv.writer(outfile)
    writer.writerow(["english", "bangla", "pronunciation", "part_of_speech", "example", "category"])

    seen = set()
    count = 0
    for row in reader:
        if len(row) < 2:
            continue
        english = row[0].strip().lower()
        bangla = row[1].strip()
        if not english or not bangla or english in seen:
            continue
        if not english.replace("-", "").replace("'", "").isalpha():
            continue
        seen.add(english)
        writer.writerow([english, bangla, "", "", "", "General"])
        count += 1

print(f"Done — words_50k.csv তৈরি হয়েছে, মোট {count} words")