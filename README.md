# Receptúra — telepítési útmutató

Webes PWA krémreceptekhez, alapanyagokhoz és készlethez, **több eszköz közötti szinkronnal** (Supabase) és **offline működéssel**. Telepítés kb. 15 perc.

A csomag fájljai:
- `index.html` — maga az alkalmazás
- `manifest.webmanifest`, `sw.js`, `icon-192.png`, `icon-512.png`, `apple-touch-icon.png` — a PWA (telepíthető app + offline)
- `supabase-schema.sql` — az adatbázis táblái és jogosultságai
- `vercel.json` — Vercel beállítások

---

## 1. Supabase projekt létrehozása

1. Menj a https://supabase.com oldalra, és hozz létre egy ingyenes fiókot.
2. **New project** → adj nevet és egy erős adatbázis-jelszót (ezt elteheted, de az apphoz nem kell).
3. Várd meg, míg elindul a projekt (1–2 perc).

## 2. Adatbázis séma betöltése

1. A bal oldali menüben: **SQL Editor → New query**.
2. Másold be a `supabase-schema.sql` teljes tartalmát, és kattints **Run**.
3. Sikeres lefutás után a **Table Editor**-ban látnod kell 3 táblát: `ingredients`, `recipes`, `batches`.

## 3. Bejelentkezés beállítása (e-mail + jelszó)

1. **Authentication → Sign In / Providers**: az **Email** legyen bekapcsolva.
2. Egyszerűbb indulás: **Authentication → Providers → Email** alatt kapcsold **ki** a "Confirm email" opciót — így a regisztrált fiók azonnal beléphet megerősítő e-mail nélkül. (Ha bekapcsolva hagyod, a regisztráció után egy megerősítő linkre kell kattintani, mielőtt belépnél.)

> A férj és a feleség **ugyanazt az egy fiókot** (e-mail + jelszó) használja minden eszközön — így látják ugyanazt az adatot. Egyszerűen regisztráljatok egyszer, és mindkét eszközön ezzel lépjetek be.

## 4. Kulcsok bemásolása az appba

1. **Project Settings → API**.
2. Másold ki a **Project URL**-t és az **anon public** kulcsot.
3. Nyisd meg az `index.html`-t egy szövegszerkesztőben, és a fájl elején lévő script részben cseréld ki:
   ```js
   const SUPABASE_URL = "PASTE_YOUR_PROJECT_URL";
   const SUPABASE_ANON_KEY = "PASTE_YOUR_ANON_PUBLIC_KEY";
   ```
   a saját értékeidre. Mentsd el.

> Az **anon public** kulcs nyilvánosnak szánt (a böngészőben fut). A biztonságot a sémában lévő sorszintű jogosultság (RLS) adja: mindenki csak a saját fiókja adatait éri el.

## 5. Telepítés Vercelre

**A) Legegyszerűbb — fogd és vidd:**
1. Menj a https://vercel.com oldalra, jelentkezz be.
2. **Add New… → Project → Deploy** — vagy a Vercel kezdőlapon húzd rá ezt a `bundle` mappát a feltöltőre.
3. Pár másodperc, és kapsz egy `https://...vercel.app` címet.

**B) CLI-vel:**
```bash
npm i -g vercel
cd bundle
vercel        # majd: vercel --prod
```

> Engedélyezett origó: a Supabase alapból minden eredetről fogadja az anon kéréseket, így a Vercel-cím külön beállítás nélkül működik.

## 6. Telepítés a táblagépre (PWA)

1. Nyisd meg a Vercel-címet a táblagép böngészőjében, és **jelentkezz be** (vagy először regisztrálj).
2. **Android/Chrome:** menü (⋮) → **Alkalmazás telepítése** / **Hozzáadás a kezdőképernyőhöz**.
3. **iPad/Safari:** Megosztás → **Hozzáadás a Főképernyőhöz**.
4. Megjelenik a Receptúra ikon; ezután önálló appként, offline is működik.

Ismételd meg a másik eszközön ugyanazzal a bejelentkezéssel — a két eszköz innentől valós időben szinkronban van.

---

## Hogyan működik a szinkron és az offline?

- Indításkor az app **azonnal a helyi gyorsítótárból** tölt (gyors, és net nélkül is megnyílik), majd a háttérben lekéri a friss adatot a Supabase-ből.
- Minden módosítás **rögtön mentődik helyben**, és kis késleltetéssel felmegy a felhőbe.
- **Net nélkül**: a változások a gyorsítótárban maradnak, és újracsatlakozáskor automatikusan felszinkronizálnak. Ilyenkor bal alul megjelenik egy „Nincs kapcsolat" jelzés.
- A másik eszközön végzett változás **valós időben** megjelenik (Supabase Realtime).

## Hibakeresés

- **„Failed to fetch" / nem tölt:** ellenőrizd a `SUPABASE_URL` és `SUPABASE_ANON_KEY` értékeket az `index.html`-ben.
- **Belépés után üres marad / hibát ír:** futott-e le a `supabase-schema.sql` hibátlanul? (RLS és táblák megléte.)
- **Regisztráció után nem enged be:** kapcsold ki a "Confirm email"-t (3. lépés), vagy kattints a kapott megerősítő linkre.
- **Service worker frissítés:** új verzió feltöltése után zárd be teljesen a telepített appot és nyisd újra, vagy frissíts a böngészőben.

---

## Frissítés: Batch szám + SDS feltöltés (alapanyagok)

Az alapanyagokhoz mostantól megadható egy **Batch szám / Lot**, és feltölthető a szállító **biztonsági adatlapja (SDS)** — PDF vagy kép.

**FONTOS sorrend a frissítéskor:**
1. **Előbb a Supabase SQL!** A projektben: SQL Editor → futtasd le a `supabase-schema.sql` végén lévő „UPDATE … batch + SDS” blokkot. Ez:
   - hozzáadja az új oszlopokat (`batch`, `sds_path`, `sds_name`),
   - létrehoz egy `sds` nevű (privát) tárolót (bucket) a fájloknak,
   - beállítja a tárolóhoz a hozzáférési szabályokat.
   (Ha ezt kihagyod, a mentés szinkronja hibára fut, amíg az oszlopok nincsenek meg.)
2. Cseréld le az `index.html`-t az új verzióra, és írd vissza a `SUPABASE_ANON_KEY` sorba a publishable kulcsodat.
3. Töltsd fel Vercelre, a telefonon egy kemény frissítés.

Használat: az alapanyag szerkesztőjében a **Batch** mező és az **SDS** rész (Megnézés / Eltávolítás). A listában az SDS-sel rendelkező alapanyagnál egy **SDS** chip jelenik meg — arra koppintva megnyílik az adatlap.

---

## Frissítés (2026-07) — Tisztítási procedúra (higiéniai kapu)

Új **Tisztítás** fül került az appba. Gyártás (Legyártás) csak akkor indítható, ha a
tisztítási procedúra el van végezve és naplózva. Ha nincs, a Legyártás gomb helyett
figyelmeztetés jelenik meg, és átvisz a Tisztítás fülre.

- A tisztítás egy **ellenőrzőlista** kipipálásával naplózható (ki, mikor).
- A naplózott tisztítás alapból **12 órán át érvényes** (egy műszak). Ez az
  `index.html`-ben a `CLEAN_WINDOW_MS` értékkel állítható (pl. 8 óra = `8*60*60*1000`).
- A tisztítási napló a **Tisztítás** fülön látható, és a Supabase-ben szinkronizálódik
  a többi eszközzel.

**Teendő a Supabase-ben (egyszer):** futtasd le a `supabase-schema.sql` végén lévő
`UPDATE (2026-07)` blokkot az SQL Editorban (létrehozza a `cleanings` táblát + jogosultságokat).
Ha ez nincs meg, az app akkor is működik és lokálisan naplóz, csak a felhő-szinkron marad ki.
