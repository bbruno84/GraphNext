
# GRDBGraphPersistenceController

## Overview

`GRDBGraphPersistenceController` è il controller di persistenza locale basato su GRDB/SQLite per la libreria GraphNext. Fornisce supporto completo per CRUD, query avanzate, asset leggeri e relazioni, mantenendo una struttura coerente con il grafo in memoria (`GraphStore`). È un'alternativa a `CoreDataGraphPersistenceController`, con maggiore controllo sullo storage e migliori performance.

### Caratteristiche principali
- Basato su SQLite via [GRDB](https://github.com/groue/GRDB.swift)
- Query su `payload` tramite `json_extract`
- Gestione asset leggeri inline fino a 5–10 MB
- Cascade delete su entità e asset
- Supporto per `relatedEntities(from:)`
- Tutto asincrono via `async/await`

---

## Funzionalità Disponibili

### CRUD
- `saveEntity(_:)`
- `entity(id:)`
- `deleteEntity(id:)`
- `saveRelationship(_:)`
- `relationship(id:)`
- `deleteRelationship(id:)`

### Query su Entity
- `queryEntities(matching:)`
- `queryEntities(wherePayloadKey:equals:)`
- `queryEntities(wherePayloadKey:greaterThan:)`
- `queryEntities(wherePayloadKey:lessThan:)`
- `queryEntities(wherePayloadKey:greaterThanOrEqualTo:)`
- `queryEntities(wherePayloadKey:lessThanOrEqualTo:)`
- `queryEntities(wherePayloadKey:between:and:)`

### Query su Relationship
- `queryRelationships(matching:)`
- `queryRelationships(wherePayloadKey:equals:)`
- `queryRelationships(wherePayloadKey:greaterThan:)`
- `queryRelationships(wherePayloadKey:lessThan:)`
- `queryRelationships(wherePayloadKey:greaterThanOrEqualTo:)`
- `queryRelationships(wherePayloadKey:lessThanOrEqualTo:)`
- `queryRelationships(wherePayloadKey:between:and:)`

### Asset leggeri
- `saveAssetBlob(for:data:mimeType:fileName:)`
- `loadAssetBlob(for:)`
- `deleteAssetBlob(for:)`
- `createAssetAndAttach(data:mimeType:fileName:attachTo:)`

### Altre utility
- `relatedEntities(from:)`

---

## API Details

### Entity CRUD

```swift
func saveEntity(_ entity: Entity) async throws
```
Salva o aggiorna un'entità.

```swift
func entity(id: UUID) async throws -> Entity?
```
Restituisce un'entità per ID.

```swift
func deleteEntity(id: UUID) async throws
```
Rimuove l'entità per ID.

---

### Relationship CRUD

```swift
func saveRelationship(_ relationship: Relationship) async throws
```
Salva o aggiorna una relazione.

```swift
func relationship(id: UUID) async throws -> Relationship?
```
Recupera una relazione per ID.

```swift
func deleteRelationship(id: UUID) async throws
```
Elimina una relazione per ID.

---

### Query con filtro su payload (esempi)

```swift
func queryEntities(wherePayloadKey key: String, equals value: GraphPayloadValue) async throws -> [Entity]
```

```swift
func queryRelationships(wherePayloadKey key: String, greaterThan value: GraphPayloadValue) async throws -> [Relationship]
```

Supporta confronti: `=`, `<`, `>`, `<=`, `>=`, `BETWEEN`.

---

### Gestione Asset

```swift
func saveAssetBlob(for assetId: UUID, data: Data,
                   mimeType: String?, fileName: String?) async throws -> AssetMetadata
```

```swift
func loadAssetBlob(for assetId: UUID) async throws -> (data: Data, meta: AssetMetadata)
```

```swift
func deleteAssetBlob(for assetId: UUID) async throws
```

```swift
func createAssetAndAttach(data: Data, mimeType: String?, fileName: String?, attachTo: UUID) async throws -> UUID
```

---

### Altre funzioni

```swift
func relatedEntities(from entityId: UUID) async throws -> [Entity]
```
Recupera tutte le entità collegate in uscita da una data entità (`from → to`).

---

## Limitazioni Note

- La query su JSON è disponibile solo per tipi payload di tipo semplice (string, int, double, bool, date).
- Gli asset oltre 10MB non sono supportati in GRDB 1.0.
- Nessun supporto a FTS5 o indicizzazione avanzata (prevista in futuro).

---

© GraphNext 2025
