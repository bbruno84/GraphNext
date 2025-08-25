# Assets (File‑Backed)

**Stato:** attivo  
**Target:** iOS 16+  
**Moduli:** GraphNext (Store, Persistence GRDB/Core Data), GraphSyncEngine (CloudKit)

## Perché file‑backed
- **Niente BLOB in DB**: schema più pulito, meno I/O sul database.
- **Coerenza con CloudKit**: usa `CKAsset(fileURL:)`.
- **API pubbliche stabili**: nessuna rottura per i consumatori.
- **Pull‑from‑zero veloce**: gli asset si scaricano **on‑demand**.

---

## Concetti chiave

- Un asset è una `Entity` con `type == "asset"` che contiene **solo metadati** nel `payload`:
  - `mimeType: String`
  - `fileName: String`
  - `length: Int`
  - `sha256: String` (hex)
- I byte reali sono salvati su disco da `AssetStorage` (default: `FileAssetStorage`).
- La relazione con il “proprietario” è `Relationship(type:"attaches")`: `owner --attaches--> asset`.

---

## API pubbliche (superficie invariata)

```swift
// Crea asset + relation "attaches" al proprietario; salva i byte via storage
func createAssetAndAttach(
    data: Data,
    mimeType: String?,
    fileName: String?,
    attachTo ownerId: UUID
) async throws -> Entity

// Salva/aggiorna solo i bytes di un asset esistente; ritorna metadati
@discardableResult
func saveAssetData(
    assetId: UUID,
    data: Data,
    mimeType: String,
    fileName: String?
) async throws -> AssetMetadata

// Carica tutti i bytes (streaming interno)
func loadAssetData(assetId: UUID) async throws -> Data

// Stream di sola lettura
func openAssetStream(assetId: UUID) async throws -> InputStream?

// URL locale se presente (non forza download)
func assetURLIfPresent(assetId: UUID) async throws -> URL?

// Rimuove solo il file locale (non l’entity)
func deleteAsset(assetId: UUID) async throws

// CloudKit: scarica file on‑demand se necessario
func fetchAssetIfNeeded(assetId: UUID) async throws
```

> Nota: in CloudKit abbiamo anche la **convenience** sul sync:  
> `CloudKitSync.fetchAssetIfNeededAndNotify(assetId:)` che, dopo il download, invia un `.update` sullo `Store` (Combine) tramite `store.notifyAssetReady(_:)`.

---

## AssetStorage

```swift
protocol AssetStorage {
    @discardableResult
    func save(data: Data, for assetId: UUID, meta: AssetMetadata) throws -> URL
    func openRead(assetId: UUID) throws -> InputStream?
    func urlIfPresent(assetId: UUID) throws -> URL?
    func exists(assetId: UUID) throws -> Bool
    func remove(assetId: UUID) throws
    func verifyChecksum(assetId: UUID) throws -> Bool
}

struct AssetMetadata: Equatable {
    let length: Int
    let sha256: String
    let mimeType: String?
    let fileName: String?
}
```

**Default:** `FileAssetStorage`
- Directory dedicata (es. `.../GN_Assets_<UUID>/content/`).
- Sharding su SHA256 (per evitare troppe entry per cartella).
- `verifyChecksum` via SHA256 del file.

---

## Integrazioni

### GRDB
- **Nessun BLOB** in tabelle — solo metadati in `Entity.payload`.
- I metodi `deleteEntity(id:)` rimuovono **best‑effort** anche il file locale quando `type == "asset"`.

### Core Data
- Nessun campo `Binary Data`; stessi metadati nel `payload`.
- Stessa logica **best‑effort** in `delete...` per rimuovere i file locali.

### CloudKit
- **Push**: `Entity.asCKRecord()` allega `record["file"] = CKAsset(fileURL:)` se il file locale esiste; metadati **sempre** nel `payload`.
- **Pull**: solo metadati; **niente** copia automatica dei byte.
- **On‑demand**:  
  - `CloudKitSync.fetchAssetIfNeeded(assetId:)` effettua `CKFetchRecordsOperation` con `desiredKeys: ["file"]` e salva il file nello storage.
  - `CloudKitSync.fetchAssetIfNeededAndNotify(assetId:)` → in più chiama `store.notifyAssetReady(_:)` (Combine `.update`).

**Config CloudKit:**
```swift
struct CloudKitSyncConfig {
    var containerIdentifier: String?
    var zoneName: String
    var stateStore: StateStore
    var subscribeOnInit: Bool
    var pushBatchSize: Int      // default: 100
    var pushMaxIntervalSeconds: Double // default: 3.0
    var debounceMilliseconds: Int
    var retryMaxAttempts: Int
    var retryBaseDelaySeconds: Double
    var assetThresholdBytes: Int // default: 15 MB (reserved for policy, wiring next)
}
```

---

## Esempi d’uso

### Creare e collegare un asset a un documento
```swift
let owner = try await storeController.createDocument(...) // o saveEntity(...)
let data: Data = ... // bytes
let asset = try await controller.createAssetAndAttach(
    data: data,
    mimeType: "application/pdf",
    fileName: "report.pdf",
    attachTo: owner.id
)
```

### Caricare l’asset (se già locale)
```swift
if let url = try await controller.assetURLIfPresent(assetId: asset.id) {
    // uso diretto dell’URL (read-only)
} else {
    // CloudKit: scarico on-demand e notifico la UI
    try await cloudKitSync.fetchAssetIfNeededAndNotify(assetId: asset.id)
}
```

### Ascoltare aggiornamenti (Combine)
```swift
store.changeFeed
    .sink { change in
        if case let .update(node, isRemote) = change,
           let e = node as? Entity, e.type == "asset", isRemote {
            // asset diventato disponibile offline: aggiornare UI
        }
    }
    .store(in: &cancellables)
```

---

## Migrazione (PR3)
- Rimosse strutture legacy: `asset_blobs` + indici (`DROP ... IF EXISTS`).
- Nessuna migrazione dati (libreria non rilasciata).

---

## Test (principali)

- **Round-trip** (GRDB/Core Data): create → save → load → checksum → delete → file sparito.
- **CloudKit Mapper**: `asCKRecord` allega `CKAsset` se URL locale presente.
- **CloudKit On‑Demand**: fetch con test‑hook → file in storage → `notifyAssetReady`.
- **Schema GRDB**: niente `asset_blobs` in `sqlite_master`.

---

## Best‑practice & guardrail

- **NON** creare manualmente `Entity(type:"asset")`. Usare **sempre** `createAssetAndAttach(...)`.
- Usare `assetURLIfPresent` per evitare I/O non necessario; se `nil`, usare **on‑demand**.
- Non salvare segreti nel `payload` degli asset (solo metadati tecnici).
- Considerare `mimeType`/`fileName` opzionali (fallback `application/octet-stream`).

---

## Roadmap (next)

- **Eviction/Cache (PR6b)**: quota (es. 200 MB) con LRU (aggiorna `lastAccess` su `openRead`).
- **Soglia “light/heavy”**: usare `assetThresholdBytes` in push per non allegare file troppo grandi.
- **Miglioramenti diagnostica**: logging coerente su asset mancanti.

---

### Changelog
- **PR1–2**: AssetStorage + GRDB file‑backed, API pubbliche.
- **PR3**: drop `asset_blobs`.
- **PR4**: Core Data integrazione (file‑backed).
- **PR5**: CloudKit: CKAsset + on‑demand + notify Store.
- **PR6a**: Documentazione aggiornata (questo file).

---

### Link correlati
- `Sources/GraphNext/Persistence/Assets/*`
- `Sources/GraphNext/Persistence/GRDB/*`
- `Sources/GraphNext/Persistence/CoreData/*`
- `Sources/GraphSyncEngine/CloudKit/*`
- Test: `Tests/GraphNextTests/Assets/*`, `Tests/GraphNextTests/CloudKit/*`
