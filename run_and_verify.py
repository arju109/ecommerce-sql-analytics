"""
Splits 02_analysis_queries.sql into individual statements (by the
'-- Q<number>.' markers) and executes each one against ecommerce.db,
printing pass/fail and a preview of results. This verifies every
query in the deliverable actually runs before handing off the project.
"""
import sqlite3
import re

DB_PATH = "ecommerce.db"
SQL_PATH = "02_analysis_queries.sql"

with open(SQL_PATH) as f:
    content = f.read()

# Split into blocks starting at each "-- Q<n>." comment
blocks = re.split(r"(?=-- Q\d+\.)", content)
blocks = [b for b in blocks if b.strip().startswith("-- Q")]

conn = sqlite3.connect(DB_PATH)
cur = conn.cursor()

all_ok = True
for block in blocks:
    header_match = re.match(r"-- (Q\d+)\.\s*(.*)", block)
    qid, desc = header_match.group(1), header_match.group(2)
    try:
        cur.execute(block)
        rows = cur.fetchmany(3)
        colnames = [d[0] for d in cur.description]
        print(f"[OK] {qid}: {desc}")
        print(f"     columns: {colnames}")
        for r in rows:
            print(f"     {r}")
        print()
    except Exception as e:
        all_ok = False
        print(f"[FAIL] {qid}: {desc}")
        print(f"       ERROR: {e}\n")

conn.close()
print("ALL QUERIES PASSED" if all_ok else "SOME QUERIES FAILED — see above")
