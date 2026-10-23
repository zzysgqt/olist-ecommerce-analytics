"""Generate the portfolio dashboard from the validated SQLite queries."""

from pathlib import Path
import sqlite3

import matplotlib.pyplot as plt
import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parents[1]
DATABASE_PATH = PROJECT_ROOT / "data" / "processed" / "olist.db"
SQL_DIR = PROJECT_ROOT / "sql"
FIGURE_DIR = PROJECT_ROOT / "outputs" / "figures"
TABLE_DIR = PROJECT_ROOT / "outputs" / "tables"


def read_sql_file(connection: sqlite3.Connection, filename: str) -> pd.DataFrame:
    """Execute one validated SQL file and return its result."""
    query = (SQL_DIR / filename).read_text(encoding="utf-8")
    return pd.read_sql_query(query, connection)


def add_bar_labels(axis, values, *, orientation, suffix="", decimals=0) -> None:
    """Add compact value labels to horizontal or vertical bars."""
    for bar, value in zip(axis.patches, values):
        if orientation == "horizontal":
            axis.text(
                bar.get_width(),
                bar.get_y() + bar.get_height() / 2,
                f" {value:.{decimals}f}{suffix}",
                va="center",
                fontsize=8,
            )
        else:
            axis.text(
                bar.get_x() + bar.get_width() / 2,
                bar.get_height(),
                f"{value:.{decimals}f}{suffix}",
                ha="center",
                va="bottom",
                fontsize=8,
            )


def main() -> None:
    if not DATABASE_PATH.exists():
        raise FileNotFoundError(
            f"Database not found: {DATABASE_PATH}. Run scripts/build_database.py first."
        )

    FIGURE_DIR.mkdir(parents=True, exist_ok=True)
    TABLE_DIR.mkdir(parents=True, exist_ok=True)

    with sqlite3.connect(DATABASE_PATH) as connection:
        monthly = read_sql_file(connection, "12_monthly_kpi.sql")
        rfm = read_sql_file(connection, "21_customer_rfm_segmentation.sql")
        categories = read_sql_file(connection, "22_category_performance.sql")
        delivery = read_sql_file(connection, "24_delivery_review_relationship.sql")

    monthly = monthly.query("'2017-02' <= order_month <= '2018-07'").copy()
    categories = categories.head(10).copy()

    monthly.to_csv(TABLE_DIR / "monthly_kpi.csv", index=False)
    rfm.to_csv(TABLE_DIR / "rfm_segments.csv", index=False)
    categories.to_csv(TABLE_DIR / "top_categories.csv", index=False)
    delivery.to_csv(TABLE_DIR / "delivery_review.csv", index=False)

    plt.style.use("seaborn-v0_8-whitegrid")
    colors = {
        "blue": "#2563EB",
        "teal": "#0F766E",
        "orange": "#EA580C",
        "red": "#DC2626",
        "slate": "#475569",
        "light": "#CBD5E1",
    }

    figure, axes = plt.subplots(2, 2, figsize=(16, 10), constrained_layout=True)
    figure.suptitle(
        "Olist E-commerce Business Dashboard",
        fontsize=20,
        fontweight="bold",
    )

    # Panel 1: comparable monthly delivered-order trend.
    axis = axes[0, 0]
    x_positions = range(len(monthly))
    axis.plot(
        x_positions,
        monthly["delivered_orders"],
        color=colors["blue"],
        marker="o",
        linewidth=2.4,
        markersize=4,
    )
    peak_index = monthly["delivered_orders"].idxmax()
    peak_position = monthly.index.get_loc(peak_index)
    peak_value = monthly.loc[peak_index, "delivered_orders"]
    axis.scatter(peak_position, peak_value, color=colors["red"], s=55, zorder=3)
    axis.annotate(
        f"Peak: {monthly.loc[peak_index, 'order_month']}\n{peak_value:,.0f} orders",
        (peak_position, peak_value),
        xytext=(12, -44),
        textcoords="offset points",
        fontsize=9,
        color=colors["red"],
    )
    axis.set_title("A. Monthly delivered orders")
    axis.set_ylabel("Orders")
    axis.set_xticks(list(x_positions)[::2])
    axis.set_xticklabels(monthly["order_month"].iloc[::2], rotation=45, ha="right")

    # Panel 2: customer segments by total monetary value.
    axis = axes[0, 1]
    rfm_plot = rfm.sort_values("total_monetary_value", ascending=True)
    monetary_millions = rfm_plot["total_monetary_value"] / 1_000_000
    axis.barh(
        rfm_plot["customer_segment"],
        monetary_millions,
        color=colors["teal"],
    )
    axis.set_title("B. RFM segments by total payment value")
    axis.set_xlabel("Payment value (millions)")
    add_bar_labels(
        axis,
        monetary_millions,
        orientation="horizontal",
        suffix="M",
        decimals=2,
    )

    # Panel 3: top product categories by product value.
    axis = axes[1, 0]
    category_plot = categories.sort_values("product_value", ascending=True)
    category_labels = (
        category_plot["category_name"].str.replace("_", " ").str.title()
    )
    category_millions = category_plot["product_value"] / 1_000_000
    axis.barh(category_labels, category_millions, color=colors["orange"])
    axis.set_title("C. Top categories by product value")
    axis.set_xlabel("Product value (millions)")
    add_bar_labels(
        axis,
        category_millions,
        orientation="horizontal",
        suffix="M",
        decimals=2,
    )

    # Panel 4: low-review rate by delivery-delay severity.
    axis = axes[1, 1]
    bar_colors = [
        colors["teal"],
        "#65A30D",
        "#D97706",
        colors["orange"],
        colors["red"],
    ]
    axis.bar(
        delivery["delay_bucket"],
        delivery["low_review_rate_pct"],
        color=bar_colors,
    )
    axis.set_title("D. Low-review rate by delivery delay")
    axis.set_ylabel("Low-review rate (%)")
    axis.set_ylim(0, 90)
    axis.tick_params(axis="x", rotation=25)
    add_bar_labels(
        axis,
        delivery["low_review_rate_pct"],
        orientation="vertical",
        suffix="%",
        decimals=1,
    )

    for axis in axes.flat:
        axis.spines["top"].set_visible(False)
        axis.spines["right"].set_visible(False)

    figure.text(
        0.01,
        0.005,
        "Scope: delivered orders; comparable monthly window 2017-02 to 2018-07. "
        "Product value and payment value are not profit.",
        fontsize=9,
        color=colors["slate"],
    )

    output_path = FIGURE_DIR / "olist_business_dashboard.png"
    figure.savefig(output_path, dpi=180, bbox_inches="tight", facecolor="white")
    plt.close(figure)
    print(f"Dashboard created: {output_path}")


if __name__ == "__main__":
    main()

