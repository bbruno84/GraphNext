# GraphNext — Asset Storage (File‑backed)

**Obiettivo**  
Tutti gli asset sono file‑backed su disco locale. Nel database (GRDB/Core Data) restano **solo i metadati** (sha256, length, mimeType, fileName) nel `payload` della `Entity` con `type: "asset"`, e i link logici sono espressi via `Relationship` (es. `attaches`).

**Architettura**  
- `AssetStorage` (protocol) definisce l’interfaccia.
- `FileAssetStorage` è l’implementazione di default:
  - Contenuti content‑addressed in `content/<aa>/<bb>/<sha256>`.
  - Indice locale `index/<assetId>.json` → risolve `assetId` → `sha256` e metadati, aggiorna `lastAccess`.
  - Dedup automatico per `sha256`.
  - Pronto per futura **LRU eviction** (usa `lastAccess`).

**Motivazioni**
- Niente BLOB nel DB → schema più pulito, persistenza più rapida, i backup del DB restano leggeri.
- Allineamento immediato a **CloudKit/CKAsset** (usa URL locali) e a Core Data (no binari in Core Data).
- Pull‑from‑zero più veloce: gli asset si scaricano **on‑demand**.

**Roadmap integrazione (PR successive)**
1. GRDB: rimuovere tabella `asset_blobs` e route binari → solo metadati nel `payload`.
2. Core Data: stesso approccio (niente BLOB).
3. CloudKit: `CKAsset` creati da URL locale (push), download on‑demand (pull) → `fetchAssetIfNeeded`.
4. API pubbliche stabili (`createAssetAndAttach`, `loadAssetData`, `openAssetStream`, `assetURLIfPresent`, `delete`, `fetchAssetIfNeeded`).
5. Cache/eviction: configurazione quota (es. 200 MB) e LRU.

**Note**
- La deduplica elimina duplicati per contenuti identici: più `assetId` possono puntare allo stesso file (stesso `sha256`). La rimozione cancella il contenuto solo quando nessun altro indice lo referenzia.

## PR #2 — GRDB refactor (file-backed)

- Rimosso ogni utilizzo della tabella `asset_blobs` nel codice.
- Tutte le operazioni su asset binari usano `AssetStorage` (default `FileAssetStorage`).
- Esposte API pubbliche sul controller GRDB:
  - `saveAssetData(assetId:data:mimeType:fileName:)`
  - `loadAssetData(assetId:)`
  - `openAssetStream(assetId:)`
  - `assetURLIfPresent(assetId:)`
  - `deleteAsset(assetId:)`
  - `fetchAssetIfNeeded(assetId:)` (no-op per GRDB)
- `createAssetAndAttach(...)` ora salva i dati su file storage e scrive solo metadati nel `payload` dell’`Entity(type:"asset")`.

> Nella PR #3 verrà **droppata** la tabella `asset_blobs` tramite migrazione GRDB.

## PR #4 — Core Data integrazione (file‑backed)

- Nessun `Binary Data`/BLOB in Core Data: gli asset sono `Entity(type:"asset")` con metadati nel `payload`.
- Binari salvati su disco tramite `AssetStorage` (default: `FileAssetStorage`).
- API pubbliche allineate a GRDB:
  - `saveAssetData(assetId:data:mimeType:fileName:)`
  - `loadAssetData(assetId:)`
  - `openAssetStream(assetId:)`
  - `assetURLIfPresent(assetId:)`
  - `deleteAsset(assetId:)`
  - `fetchAssetIfNeeded(assetId:)` (no‑op per Core Data)
  - `createAssetAndAttach(data:mimeType:fileName:attachTo:)`
- `deleteEntity(id:)` rimuove anche il file locale quando l’entity è un asset (best‑effort).
- Test in‑memory `CoreDataFileBackedAssetsTests` verdi.
