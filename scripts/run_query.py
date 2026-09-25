"""Run the final query in a SQL file against the local Olist database."""

from __future__ import annotations

import argparse
import sqlite3
from pathlib import Path

import pandas as pd


ROOT = Path(__file__).resolve().parents[1]
DATABASE_PATH = ROOT / "data" / "processed" / "olist.db"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("sql_file", type=Path)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()

    if not DATABASE_PATH.exists():
        raise FileNotFoundError(
            "Database not found. Run: python scripts/build_database.py"
        )

    query = args.sql_file.read_text(encoding="utf-8")
    with sqlite3.connect(DATABASE_PATH) as connection:
        result = pd.read_sql_query(query, connection)

    print(result.to_string(index=False))
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        result.to_csv(args.output, index=False, encoding="utf-8-sig")
        print(f"\nSaved: {args.output}")


if __name__ == "__main__":
    main()
