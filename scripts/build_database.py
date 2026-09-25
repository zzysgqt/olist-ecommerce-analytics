"""Build a reproducible SQLite database from the nine Olist CSV files."""

from __future__ import annotations

import os
import sqlite3
from contextlib import closing
from pathlib import Path

import pandas as pd


ROOT = Path(__file__).resolve().parents[1]
RAW_DIR = ROOT / "data" / "raw"
PROCESSED_DIR = ROOT / "data" / "processed"
DATABASE_PATH = PROCESSED_DIR / "olist.db"
TEMP_DATABASE_PATH = PROCESSED_DIR / "olist.tmp.db"

TABLES = {
    "olist_customers_dataset.csv": "customers",
    "olist_geolocation_dataset.csv": "geolocation",
    "olist_order_items_dataset.csv": "order_items",
    "olist_order_payments_dataset.csv": "order_payments",
    "olist_order_reviews_dataset.csv": "order_reviews",
    "olist_orders_dataset.csv": "orders",
    "olist_products_dataset.csv": "products",
    "olist_sellers_dataset.csv": "sellers",
    "product_category_name_translation.csv": "category_translation",
}

INDEXES = [
    "CREATE UNIQUE INDEX idx_orders_order_id ON orders(order_id)",
    "CREATE INDEX idx_orders_customer_id ON orders(customer_id)",
    "CREATE INDEX idx_orders_purchase_timestamp ON orders(order_purchase_timestamp)",
    "CREATE UNIQUE INDEX idx_customers_customer_id ON customers(customer_id)",
    "CREATE INDEX idx_customers_unique_id ON customers(customer_unique_id)",
    "CREATE INDEX idx_items_order_id ON order_items(order_id)",
    "CREATE INDEX idx_items_product_id ON order_items(product_id)",
    "CREATE INDEX idx_items_seller_id ON order_items(seller_id)",
    "CREATE INDEX idx_payments_order_id ON order_payments(order_id)",
    "CREATE INDEX idx_reviews_order_id ON order_reviews(order_id)",
    "CREATE UNIQUE INDEX idx_products_product_id ON products(product_id)",
    "CREATE UNIQUE INDEX idx_sellers_seller_id ON sellers(seller_id)",
    "CREATE INDEX idx_geo_zip ON geolocation(geolocation_zip_code_prefix)",
]


def import_csv(connection: sqlite3.Connection, csv_path: Path, table: str) -> int:
    """Import one CSV in chunks and return its row count."""
    row_count = 0
    for chunk_number, chunk in enumerate(
        pd.read_csv(csv_path, chunksize=100_000, low_memory=False)
    ):
        mode = "replace" if chunk_number == 0 else "append"
        chunk.to_sql(table, connection, if_exists=mode, index=False)
        row_count += len(chunk)
    return row_count


def main() -> None:
    missing = [name for name in TABLES if not (RAW_DIR / name).exists()]
    if missing:
        raise FileNotFoundError(f"Missing source files: {missing}")

    PROCESSED_DIR.mkdir(parents=True, exist_ok=True)
    TEMP_DATABASE_PATH.unlink(missing_ok=True)

    # sqlite3.Connection.__exit__ commits or rolls back, but does not close the
    # file handle. ``closing`` matters on Windows because the open temporary
    # database cannot be atomically renamed.
    with closing(sqlite3.connect(TEMP_DATABASE_PATH)) as connection:
        connection.execute("PRAGMA journal_mode = OFF")
        connection.execute("PRAGMA synchronous = OFF")
        connection.execute("PRAGMA temp_store = MEMORY")

        print("Importing source tables...")
        for filename, table in TABLES.items():
            rows = import_csv(connection, RAW_DIR / filename, table)
            print(f"  {table:22s} {rows:>10,} rows")

        print("Creating indexes...")
        for statement in INDEXES:
            connection.execute(statement)
        connection.commit()

    os.replace(TEMP_DATABASE_PATH, DATABASE_PATH)
    print(f"Database ready: {DATABASE_PATH}")


if __name__ == "__main__":
    main()
