"""Compare archived progress with a migrated database, allowing new browsers."""
import json
import sqlite3
import sys

baseline_path, migrated_path = sys.argv[1:]
baseline = sqlite3.connect(f"file:{baseline_path}?mode=ro", uri=True)
migrated = sqlite3.connect(f"file:{migrated_path}?mode=ro", uri=True)
tables = [row[0] for row in baseline.execute(
    "SELECT name FROM sqlite_master WHERE type = 'table' "
    "AND name NOT IN ('schema_migrations', 'ar_internal_metadata', 'sqlite_sequence') ORDER BY name"
)]
results = {}
for table in tables:
    old_columns = [row[1] for row in baseline.execute(f'PRAGMA table_info("{table}")')]
    new_columns = [row[1] for row in migrated.execute(f'PRAGMA table_info("{table}")')]
    removed = set(old_columns) - set(new_columns)
    assert removed == ({"singleton_key"} if table == "learners" else set()), (table, removed)
    columns = [column for column in old_columns if column not in removed]
    quoted = ", ".join(f'"{column}"' for column in columns)
    before = baseline.execute(f'SELECT {quoted} FROM "{table}" ORDER BY id').fetchall()
    after = dict((row[columns.index("id")], row) for row in
                 migrated.execute(f'SELECT {quoted} FROM "{table}" ORDER BY id'))
    assert all(after.get(row[columns.index("id")]) == row for row in before), table
    results[table] = {"preserved_rows": len(before), "new_rows": len(after) - len(before)}

legacy_ids = [row[0] for row in baseline.execute("SELECT id FROM learners")]
for learner_id in legacy_ids:
    assert migrated.execute("SELECT device_token_digest FROM learners WHERE id = ?", (learner_id,)).fetchone() == (None,)
assert not migrated.execute("PRAGMA foreign_key_check").fetchall()
assert migrated.execute("PRAGMA integrity_check").fetchone() == ("ok",)
print(json.dumps({"preserved": True, "legacy_browser_keys": None, "tables": results}, indent=2))
