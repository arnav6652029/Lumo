import requests
import mysql.connector

# =====================================
# CHANGE ONLY THIS
# =====================================

RELIGION = "jewish"

# =====================================
# RELIGION MAPPING
# =====================================

osm_religion = RELIGION.lower()

print("Script started")

# =====================================
# MYSQL
# =====================================

db = mysql.connector.connect(
    host="localhost",
    user="root",
    password="Arnav@1234",
    database="Users"
)

cursor = db.cursor()

print("Connected to MySQL")

# =====================================
# OSM QUERY
# =====================================

query = f"""
[out:json][timeout:60];

(
  node["amenity"="place_of_worship"]["religion"="{RELIGION}"](22.50,88.30,22.65,88.45);
  way["amenity"="place_of_worship"]["religion"="{RELIGION}"](22.50,88.30,22.65,88.45);
  relation["amenity"="place_of_worship"]["religion"="{RELIGION}"](22.50,88.30,22.65,88.45);
);

out center;
"""

print(f"Fetching {RELIGION} places...")

response = requests.post(
    "https://lz4.overpass-api.de/api/interpreter",
    data=query,
    headers={
        "User-Agent": "LumoApp/1.0"
    },
    timeout=120
)

print("HTTP Status:", response.status_code)

if response.status_code != 200:
    print(response.text)
    exit()

data = response.json()
print(data)

print("Found", len(data["elements"]), "places")

# =====================================
# INSERT
# =====================================

inserted = 0
skipped = 0

for place in data["elements"]:

    tags = place.get("tags", {})

    name = tags.get("name")

    if not name:
        continue

    lat = place.get("lat")
    lon = place.get("lon")

    if lat is None:

        center = place.get("center", {})

        lat = center.get("lat")
        lon = center.get("lon")

    if lat is None or lon is None:
        continue

    address = (
        tags.get("addr:full")
        or tags.get("addr:street")
        or ""
    )

    description = tags.get(
        "description",
        ""
    )

    try:

        cursor.execute(
            """
            INSERT INTO temples
            (
                name,
                religion,
                latitude,
                longitude,
                address,
                description
            )
            VALUES
            (
                %s,%s,%s,%s,%s,%s
            )
            """,
            (
                name,
                RELIGION,
                lat,
                lon,
                address,
                description
            )
        )

        inserted += 1

    except Exception:
        skipped += 1

db.commit()

print()
print("========== DONE ==========")
print("Religion :", RELIGION)
print("Inserted :", inserted)
print("Skipped  :", skipped)

cursor.close()
db.close()