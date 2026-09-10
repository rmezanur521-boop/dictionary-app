"""
Converts a CSV word list into the preloaded SQLite database
expected by the Dictionary App at assets/db/dictionary_preloaded.db

Expected input CSV columns (header row required):
english,bangla,pronunciation,part_of_speech,example,category

Usage:
    python build_seed_db.py words.csv dictionary_preloaded.db
"""
import csv
import sqlite3
import sys
from datetime import datetime, timezone

SCHEMA = """
CREATE TABLE words (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    english         TEXT NOT NULL,
    bangla          TEXT NOT NULL,
    pronunciation   TEXT,
    phonetics       TEXT,
    part_of_speech  TEXT,
    example         TEXT,
    synonyms        TEXT,
    antonyms        TEXT,
    word_origin     TEXT,
    category_id     INTEGER,
    is_synced       INTEGER NOT NULL DEFAULT 0,
    last_updated    TEXT,
    search_count    INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL
);
CREATE INDEX idx_words_english ON words(english COLLATE NOCASE);
CREATE INDEX idx_words_bangla ON words(bangla);
CREATE INDEX idx_words_category ON words(category_id);

CREATE TABLE categories (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    name        TEXT NOT NULL UNIQUE,
    icon_code   TEXT,
    word_count  INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE favorites (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    word_id     INTEGER NOT NULL,
    added_at    TEXT NOT NULL,
    FOREIGN KEY (word_id) REFERENCES words(id) ON DELETE CASCADE,
    UNIQUE (word_id)
);
CREATE INDEX idx_favorites_word ON favorites(word_id);

CREATE TABLE search_history (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    query        TEXT NOT NULL,
    word_id      INTEGER,
    searched_at  TEXT NOT NULL,
    language     TEXT NOT NULL,
    FOREIGN KEY (word_id) REFERENCES words(id) ON DELETE SET NULL
);
CREATE INDEX idx_history_searched_at ON search_history(searched_at DESC);

CREATE TABLE cached_api_data (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    word_id      INTEGER NOT NULL,
    raw_json     TEXT NOT NULL,
    source       TEXT NOT NULL DEFAULT 'dictionaryapi.dev',
    fetched_at   TEXT NOT NULL,
    FOREIGN KEY (word_id) REFERENCES words(id) ON DELETE CASCADE,
    UNIQUE (word_id)
);

PRAGMA user_version = 1;
"""

def build(csv_path: str, db_path: str) -> None:
    conn = sqlite3.connect(db_path)
    cur = conn.cursor()
    cur.executescript(SCHEMA)

    categories: dict[str, int] = {}

    def get_category_id(name: str) -> int | None:
        if not name:
            return None
        name = name.strip()
        if name in categories:
            return categories[name]
        cur.execute("INSERT INTO categories (name, icon_code) VALUES (?, ?)", (name, "category"))
        cid = cur.lastrowid
        categories[name] = cid
        return cid

    with open(csv_path, encoding="utf-8") as f:
        reader = csv.DictReader(f)
        count = 0
        for row in reader:
            cat_id = get_category_id(row.get("category", ""))
            cur.execute(
                """INSERT INTO words
                   (english, bangla, pronunciation, part_of_speech, example, category_id, is_synced, last_updated)
                   VALUES (?, ?, ?, ?, ?, ?, 1, ?)""",
                (
                    row["english"].strip(),
                    row["bangla"].strip(),
                    row.get("pronunciation", "").strip() or None,
                    row.get("part_of_speech", "").strip() or None,
                    row.get("example", "").strip() or None,
                    cat_id,
                    datetime.now(timezone.utc).isoformat(),
                ),
            )
            count += 1
            if count % 5000 == 0:
                print(f"Inserted {count} words...")

    # Refresh denormalized word_count per category
    cur.execute("""
        UPDATE categories
        SET word_count = (
            SELECT COUNT(*) FROM words WHERE words.category_id = categories.id
        )
    """)

    conn.commit()
    conn.close()
    print(f"Done. Inserted {count} words into {db_path}")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python build_seed_db.py <input.csv> <output.db>")
        sys.exit(1)
    build(sys.argv[1], sys.argv[2])