# Geo-Suche & City → Nearby-Experten — praxisnaher Leitfaden

**Ziel:** Nutzer tippt eine Stadt (z. B. „Wien“) → wir zeigen nahegelegene Goldexperten, sortiert nach Entfernung, inkl. Facetten/Filter.

Du willst Elasticsearch entfernen — hier sind zwei tragfähige Wege:
- Variante A: Nur DB (MySQL/MariaDB GIS)
- Variante B: Leichte Suchengine (Meilisearch/Typesense)

Beide Optionen funktionieren sauber mit Pimcore.

---

## 1) Datenmodell & Normalisierung

### 1.1 Cities (Referenztabelle)

Lege eine `city`-Tabelle (Pimcore DataObject „City“) an mit folgenden Feldern:

- `id`, `name`, `slug`, `admin_area` (Bundesland), `country_code` (z. B. `AT`)
- `lat` (DECIMAL(9,6)), `lon` (DECIMAL(9,6))
- `location` POINT SRID 4326 (für GIS-Index)
- `alt_names` JSON (Synonyme: „Wien“, „Vienna“)
- `population` (optional, Ranking für Suggest)

Quelle der Geodaten: Geonames, OpenStreetMap-Export oder manuell für AT-Städte.

### 1.2 Experts (Goldexperten)

Pimcore DataObject `Expert` mit mindestens:

- `city_ref` (Relation zu `City`) oder eigene Adress-Felder + Geo
- `lat`, `lon`, `location` POINT SRID 4326
- `address`, `postal_code`, `city_name` (redundant für Anzeige/SEO)

Spatial Index auf `location` ist Pflicht für performante Nearby-Queries.

Beim Speichern: Wenn nur Adresse vorliegt → Geocoding (Nominatim/Google) → `lat`/`lon`/`location` setzen. Fallback: City-Zentrum, falls exaktes Geocoding fehlschlägt.

---

## 2) UX-Flow (City → Nearby)

- Autosuggest im Suchfeld zeigt Cities + bekannte Bezirke/PLZ (z. B. „Wien 1010“).
- Auswahl „Wien“ → Client ruft:

  `GET /api/v1/experts/near?lat=48.2082&lon=16.3738&radius=25km&category=ankauf`

- Backend liefert:
  - Experten sortiert nach Distanz
  - Facetten (Kategorie, „jetzt offen“, etc.)

SEO: Erzeuge Stadt-Landingpages (`/de/experten/wien/`) (SSG/ISR). Diese funktionieren initial ohne User-Geolocation.

---

## 3) Variante A — Nur Datenbank (MySQL/MariaDB GIS)

Pimcore nutzt i. d. R. MySQL/MariaDB. Deren GIS-Funktionen reichen für „Near me“ sehr gut.

### 3.1 Spalten & Indizes (MySQL ≥ 8.0)

Beispiel SQL:

```sql
-- Cities
ALTER TABLE city
  ADD COLUMN location POINT SRID 4326 NOT NULL,
  ADD SPATIAL INDEX idx_city_location (location);

-- Experts
ALTER TABLE expert
  ADD COLUMN location POINT SRID 4326 NOT NULL,
  ADD SPATIAL INDEX idx_expert_location (location);
```

Zusätzlich `lat DECIMAL(9,6)`, `lon DECIMAL(9,6)` für Ausgabe/Debug; Queries laufen primär über `location`.

### 3.2 „Nearby“ Query (Radius + Sort by distance)

Eingaben: `:lat`, `:lon`, `:radius_m` = z. B. `25000` (25 km)

```sql
SET @p = ST_SRID(POINT(:lon, :lat), 4326);

SELECT
  e.id, e.name,
  ST_Distance_Sphere(e.location, @p) AS distance_m
FROM expert e
WHERE ST_Distance_Sphere(e.location, @p) <= :radius_m
ORDER BY distance_m ASC
LIMIT 50;
```

`ST_Distance_Sphere` gibt Distanz in Metern (WGS84-Kugel) — schnell und ausreichend genau.

Optional kann ein Bounding-Box-Vorfilter verwendet werden, ist aber bei Spatial-Index und moderater Datenmenge oft nicht nötig.

### 3.3 City-Autosuggest (ohne extra Engine)

Grundsätzlich möglich mit SQL:

```sql
SELECT id, name, admin_area
FROM city
WHERE name LIKE CONCAT(:q, '%')
   OR JSON_CONTAINS(alt_names, JSON_QUOTE(:q))
ORDER BY population DESC
LIMIT 8;
```

Besser: `FULLTEXT`-Index auf `name`, `alt_names` (ggf. NGRAM-Tokenisierung). Alternativ: App-seitige Levenshtein/closest-match, wenn Ergebnisliste klein ist.

### 3.4 Facetten (DB-seitig)

Kategorie-Facetten-Beispiel:

```sql
SELECT category, COUNT(*)
FROM expert
WHERE ST_Distance_Sphere(location, @p) <= :radius_m
GROUP BY category;
```

### 3.5 Öffnungszeiten „Jetzt offen"

- Öffnungszeiten als strukturiertes JSON speichern.
- Backend berechnet `open_now` (berücksichtige Wochentag + Zeitzone).
- Filter in SQL: Entweder ein vorab berechnetes Flag (z. B. minütlich per Job) oder in App-Logik filtern.

Pro (Variante A):
- Kein zusätzlicher Dienst, einfacher Betrieb, günstig.
- Gut genug für AT-Scope und einige 10k Datensätze.

Contra:
- Fuzzy-Suche/Autosuggest begrenzt.
- Ranking/Boosting ist manueller Aufwand.

---

## 4) Variante B — Meilisearch oder Typesense

Leichte Suchserver mit Geo-Filtern, Typo-Tolerance und Facetten. Eignet sich, wenn du komfortable Suche + Suggest brauchst.

### 4.1 Kurzvergleich

| Feature | Meilisearch | Typesense |
|---|---:|---:|
| Typo-Tolerance | sehr gut (default) | sehr gut (default) |
| Facetten/Filter | ja | ja |
| Geo (Radius, Sort) | ja (Geo-Rang, Filter) | ja (Geo-Filter & Sort) |
| Relevanz-Tuning | einfach | einfach |
| Hosting | self-host / Cloud | self-host / Cloud |
| API/SDK (PHP) | vorhanden | vorhanden |

### 4.2 Index-Modelle

`experts`-Index (Beispielfelder):

- `id`, `name`, `slug`, `city_name`, `admin_area`, `categories[]`, `lat`, `lon`, `badges[]`, `site_visibility`
- Geo: `_geo`: `{ "lat": 48.20, "lng": 16.37 }` (Meilisearch)
- Facetten: `categories`, `city_name`, `badges`

`cities`-Index:
- `id`, `name`, `slug`, `admin_area`, `alt_names[]`, `_geo`, `population`

### 4.3 Beispiel-Query (Meilisearch)

Autosuggest Cities:

```json
POST /indexes/cities/search
{
  "q": "wie",
  "limit": 8,
  "attributesToHighlight": ["name"],
  "filter": "country_code = AT"
}
```

Nearby Experts (25 km um Wien) + Facetten:

```json
POST /indexes/experts/search
{
  "q": "",
  "filter": [
    "_geoRadius(48.2082,16.3738,25000)",
    "site_visibility = gold"
  ],
  "facets": ["categories", "city_name"],
  "sort": ["_geoPoint(48.2082,16.3738):asc"],
  "limit": 50
}
```

### 4.4 Sync mit Pimcore

- Pimcore ist Symfony-basiert → Event-Subscriber auf publish/unpublish/save.
- Bei Änderungen: Upsert ins Such-Index (per PHP-SDK/REST).
- CLI-Command z. B.: `bin/console app:search:reindex --index=experts` (Nightly Rebuild optional).
- Verwende Symfony Messenger / Queue für robuste, asynchrone Index-Updates.

Pro (Variante B):
- Beste UX: Typos, Suggest, Facetten „out of the box".
- Schnell, minimaler Tuning-Aufwand.

Contra:
- Zusätzliche Komponente (Betrieb/Monitoring).
- Index-Sync nötig (Eventual Consistency: ms–s, meist ok).

---

## 5) API-Design (gleich für A & B)

- City-Suggest
  - `GET /api/v1/cities/suggest?q=wie&limit=8`
  - Response: `[{ id, name, slug, admin_area, lat, lon }]`

- Nearby Experts
  - `GET /api/v1/experts/near?lat=48.2082&lon=16.3738&radius=25km&category=ankauf`
  - Response: `[{ id, name, slug, distance_m, city_name, badges, ... }]`

Wichtig: Kapsle die Such-Engine hinter deinen REST-Endpoints. Das Frontend spricht immer dein API — so kannst du die Engine später wechseln, ohne React/Next anzufassen.

---

## 6) Integration in Pimcore (konkret)

- DataObjects: `City`, `Expert` mit oben genannten Feldern.
- Validierung: `lat`/`lon` Pflicht; `location` aus `lat`/`lon` berechnen.
- Geocoding Service: Symfony-Service + Rate-Limit + Cache (z. B. Datei/Redis).
- Event Subscriber:
  - On publish/update:
    - Variante A → DB ist Quelle, keine Index-Aktionen nötig.
    - Variante B → `SearchIndexer->upsertExpert($expert)`.
  - On unpublish/delete → `SearchIndexer->removeExpert(id)`.
- Admin UI: Karte (Leaflet/Mapbox) zur manuellen Korrektur des Pins.

---

## 7) Welche Variante solltest du wählen?

Start lean:
- Wenn schnelle Time-to-market und „gut genug“ genügt → Variante A (MySQL GIS).
- Wenn du starke Autosuggest/Typo-Toleranz + facettierte Suche willst → Variante B (Meilisearch/Typesense).

Empfehlung (AT-Fokus, Local-SEO, planbare Skalierung):
➡️ **Meilisearch**: einfache Ops, großartige Relevanz/Typo-Toleranz, Geo-Filter, Facetten, schnelle Integration mit Pimcore-Events.

Wenn du keine zusätzliche Laufzeitkomponente möchtest, bleib bei MySQL GIS und rüste Meili später nach — deine API bleibt gleich.

---

## 8) Sicherheits- & Qualitätsaspekte

- Input-Härtung: `lat`/`lon`/`radius` validieren (Numerik, Bounds). Setze `radius`-Max (z. B. 100 km).
- Karten-Noise: Bei identischer Adresse mehrere Experten → leichte Jitter/Offset beim Map-Pin (UI).
- Performance:
  - DB-Variante: Spatial Index prüfen (`EXPLAIN`) und optimieren.
  - Meili/Typesense: In-Memory Indizes → achte auf RAM-Sizing.
- Caching: Nearby-Requests mit gleichen Parametern 60–120s CDN-cachen (GET only).
- I18n: City-Namen mit `alt_names` abdecken (Wien/Vienna) → Suggest mehrsprachig.

---

## 9) Mini-Checkliste (To-Do)

- [ ] City DataObject + Import (AT-Städte mit Koordinaten)
- [ ] Expert DataObject: `location` POINT + Spatial Index
- [ ] Geocoding Service + Admin-Kartenfeld
- [ ] `GET /cities/suggest` + `GET /experts/near` Endpoints
- [ ] (Var. B) Meilisearch/Typesense deployen + Indexer (publish/unpublish)
- [ ] Frontend: City-Autosuggest (debounced), Nearby-Liste (Distanzanzeige, Facetten)
- [ ] SEO: Stadt-Landingpages (Hybrid) + interne Verlinkung

---

### Kurz beantwortet: häufige Fragen

- „Wie handle ich die Geo?"
  - Speichere `POINT SRID 4326` für Experten & Städte, Spatial Index.
  - Bei City-Auswahl hole Koordinaten und frage `/experts/near` mit Radius ab, sortiere nach Distanz.

- „Ist Elasticsearch overkill?"
  - Ja, für deinen Scope meist überdimensioniert. Nimm MySQL GIS oder Meilisearch/Typesense.

- „Vorteil Meilisearch/Typesense vs. PostgreSQL/MySQL?"
  - Pro Meili/Typesense: Typo-Tolerance, stabiles Autosuggest, Facetten, Geo-Sort, extrem schnell, wenig Tuning.
  - Pro nur DB: Kein Extradienst, minimaler Betrieb, günstiger.

- „Funktioniert das mit Pimcore?"
  - Ja. Häng dich an Pimcore-Events (publish/unpublish) und pflege den Suchindex (Meili/Typesense) via PHP-SDK/REST. DB-Variante braucht keine Extra-Sync.

---

## Nächste kleine Entscheidung

A) „Ich starte mit MySQL GIS (einfacher Start)"

B) „Ich starte mit Meilisearch (besseres Suggest/Facetten)"

Sag mir A oder B — dann liefere ich konkrete Code-Snippets (SQL/Doctrine Migrations, PHP-Indexer, Beispiel-Controller für `/experts/near` & `/cities/suggest`) passend zu deiner Wahl.