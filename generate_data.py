"""
generate_data.py
----------------
Builds a realistic synthetic e-commerce dataset and loads it into
ecommerce.db using the schema in 01_schema.sql.

This script is NOT part of the "deliverable" SQL — it just creates
a believable dataset so the analysis queries have something real
to run against. Feel free to change SEED / NUM_CUSTOMERS / etc.
"""

import sqlite3
import random
import datetime

random.seed(42)

DB_PATH = "ecommerce.db"
SCHEMA_PATH = "01_schema.sql"

NUM_CUSTOMERS = 400
NUM_ORDERS = 6000
START_DATE = datetime.date(2024, 1, 1)
END_DATE = datetime.date(2025, 12, 31)

CITIES = [
    ("New York", "NY"), ("Los Angeles", "CA"), ("Chicago", "IL"),
    ("Houston", "TX"), ("Phoenix", "AZ"), ("Philadelphia", "PA"),
    ("San Antonio", "TX"), ("San Diego", "CA"), ("Dallas", "TX"),
    ("Austin", "TX"), ("Seattle", "WA"), ("Denver", "CO"),
    ("Boston", "MA"), ("Miami", "FL"), ("Atlanta", "GA"),
]

SEGMENTS = ["Consumer", "Corporate", "Home Office"]
SEGMENT_WEIGHTS = [0.55, 0.30, 0.15]

SHIP_MODES = ["Same Day", "First Class", "Second Class", "Standard Class"]
SHIP_WEIGHTS = [0.05, 0.15, 0.25, 0.55]

# category -> subcategories -> (min_price, max_price, cost_ratio)
CATALOG = {
    "Furniture": {
        "Chairs": (60, 400, 0.6), "Tables": (100, 600, 0.55),
        "Bookcases": (80, 350, 0.6), "Furnishings": (20, 150, 0.5),
    },
    "Technology": {
        "Phones": (150, 1200, 0.65), "Accessories": (10, 120, 0.4),
        "Machines": (300, 2500, 0.7), "Copiers": (200, 1800, 0.65),
    },
    "Office Supplies": {
        "Binders": (2, 40, 0.35), "Paper": (3, 25, 0.3),
        "Storage": (15, 120, 0.45), "Art": (2, 60, 0.35),
        "Labels": (1, 15, 0.3), "Envelopes": (2, 20, 0.3),
    },
}

FIRST_NAMES = ["James","Mary","Robert","Patricia","John","Jennifer","Michael","Linda",
    "David","Elizabeth","William","Barbara","Richard","Susan","Joseph","Jessica",
    "Thomas","Sarah","Charles","Karen","Priya","Amit","Wei","Fatima","Carlos",
    "Sofia","Ivan","Mei","Aisha","Diego"]
LAST_NAMES = ["Smith","Johnson","Williams","Brown","Jones","Garcia","Miller","Davis",
    "Rodriguez","Martinez","Hernandez","Lopez","Gonzalez","Wilson","Anderson","Thomas",
    "Taylor","Moore","Jackson","Martin","Lee","Perez","Thompson","White","Harris","Sanchez"]

PRODUCT_ADJECTIVES = ["Deluxe","Standard","Premium","Basic","Pro","Compact","Executive","Classic"]


def random_date(start, end):
    delta = (end - start).days
    return start + datetime.timedelta(days=random.randint(0, delta))


def build_customers(conn):
    cur = conn.cursor()
    rows = []
    for cid in range(1, NUM_CUSTOMERS + 1):
        fname = random.choice(FIRST_NAMES)
        lname = random.choice(LAST_NAMES)
        name = f"{fname} {lname}"
        email = f"{fname.lower()}.{lname.lower()}{cid}@example.com"
        city, state = random.choice(CITIES)
        signup = random_date(START_DATE, END_DATE - datetime.timedelta(days=30))
        segment = random.choices(SEGMENTS, weights=SEGMENT_WEIGHTS)[0]
        rows.append((cid, name, email, city, state, "United States", signup.isoformat(), segment))
    cur.executemany(
        "INSERT INTO customers VALUES (?,?,?,?,?,?,?,?)", rows
    )
    conn.commit()


def build_products(conn):
    cur = conn.cursor()
    rows = []
    pid = 1
    product_lookup = []  # (product_id, unit_price, category)
    for category, subcats in CATALOG.items():
        for subcat, (lo, hi, cost_ratio) in subcats.items():
            # 6-10 products per subcategory
            for i in range(random.randint(6, 10)):
                adj = random.choice(PRODUCT_ADJECTIVES)
                name = f"{adj} {subcat[:-1] if subcat.endswith('s') else subcat} {i+1}"
                price = round(random.uniform(lo, hi), 2)
                cost = round(price * cost_ratio * random.uniform(0.85, 1.05), 2)
                rows.append((pid, name, category, subcat, price, cost))
                product_lookup.append((pid, price, category))
                pid += 1
    cur.executemany(
        "INSERT INTO products VALUES (?,?,?,?,?,?)", rows
    )
    conn.commit()
    return product_lookup


def build_orders_and_items(conn, product_lookup):
    cur = conn.cursor()
    order_rows = []
    item_rows = []
    item_id = 1

    # Give customers different "activity levels" so repeat-purchase analysis is meaningful
    customer_weights = {}
    for cid in range(1, NUM_CUSTOMERS + 1):
        # 70% low activity, 25% medium, 5% power users (VIP)
        r = random.random()
        if r < 0.70:
            customer_weights[cid] = 1
        elif r < 0.95:
            customer_weights[cid] = 3
        else:
            customer_weights[cid] = 8

    weighted_customers = []
    for cid, w in customer_weights.items():
        weighted_customers.extend([cid] * w)

    for oid in range(1, NUM_ORDERS + 1):
        cid = random.choice(weighted_customers)

        # seasonality: more orders in Nov/Dec (holiday) and July (summer sale)
        month = random.choices(
            range(1, 13),
            weights=[7, 6, 7, 7, 7, 8, 10, 8, 8, 9, 13, 15]
        )[0]
        year = random.choice([2024, 2025])
        day = random.randint(1, 28)
        order_date = datetime.date(year, month, day)
        if order_date > END_DATE:
            order_date = END_DATE - datetime.timedelta(days=random.randint(0, 60))

        ship_mode = random.choices(SHIP_MODES, weights=SHIP_WEIGHTS)[0]
        ship_delay = {"Same Day": 0, "First Class": 2, "Second Class": 4, "Standard Class": 6}[ship_mode]
        ship_date = order_date + datetime.timedelta(days=ship_delay + random.randint(0, 2))

        status = random.choices(
            ["Completed", "Returned", "Cancelled"], weights=[0.90, 0.07, 0.03]
        )[0]

        order_rows.append((oid, cid, order_date.isoformat(), ship_date.isoformat(), ship_mode, status))

        # 1-4 line items per order
        num_items = random.choices([1, 2, 3, 4], weights=[0.45, 0.30, 0.17, 0.08])[0]
        chosen_products = random.sample(product_lookup, k=min(num_items, len(product_lookup)))
        for pid, price, category in chosen_products:
            qty = random.choices([1, 2, 3, 4, 5], weights=[0.5, 0.25, 0.13, 0.07, 0.05])[0]
            discount = random.choices([0, 0.1, 0.15, 0.2, 0.3], weights=[0.55, 0.2, 0.12, 0.08, 0.05])[0]
            item_rows.append((item_id, oid, pid, qty, price, discount))
            item_id += 1

    cur.executemany(
        "INSERT INTO orders VALUES (?,?,?,?,?,?)", order_rows
    )
    cur.executemany(
        "INSERT INTO order_items VALUES (?,?,?,?,?,?)", item_rows
    )
    conn.commit()


def main():
    with open(SCHEMA_PATH, "r") as f:
        schema_sql = f.read()

    conn = sqlite3.connect(DB_PATH)
    conn.executescript(schema_sql)

    build_customers(conn)
    product_lookup = build_products(conn)
    build_orders_and_items(conn, product_lookup)

    # sanity check counts
    cur = conn.cursor()
    for table in ["customers", "products", "orders", "order_items"]:
        cur.execute(f"SELECT COUNT(*) FROM {table}")
        print(f"{table}: {cur.fetchone()[0]} rows")

    conn.close()


if __name__ == "__main__":
    main()
