# GraphNext – Init & Config Quick-Start

Questo documento spiega come avviare **GraphNext** con la nuova API `GraphNextConfig` e il costruttore `GraphNext.init(config:)`.

---

## Configurazione base

```swift
import GraphNext

var config = GraphNextConfig(
    useNSCache: true,            // Abilita cache volatile nello store
    inMemoryStore: false,        // true = persistence solo in RAM (es. test/preview)
    storeName: "GraphNext",      // Nome dello store (multi-istanza → personalizza)
    preloadFromPersistence: true,
    autoSyncOnLaunch: true,
    makePersistence: { name, mem in
        // CoreDataGraphPersistenceController usa internamente Bundle.module
        CoreDataGraphPersistenceController(storeName: name, inMemory: mem)
    },
    makeBackends: { store, persistence, instanceID in
        // Factory dei backend: CloudKit, Mock, ecc.
        try GraphSyncEngineFactory.makeEngines(
            store: store,
            persistence: persistence,
            instanceID: instanceID
        )
    }
)

let graph = try GraphNext(config: config)
```

---

## Multi-istanza

Puoi distinguere più istanze dello store con `storeNameForAccount` e `instanceID`:

```swift
let account: AccountDescriptor = .custom(id: "teamA")

config.storeName = config.storeNameForAccount(account)
config.instanceID = "teamA-instance-1"

let graphA = try GraphNext(config: config)
```

---

## Auto-Sync

Se `autoSyncOnLaunch = true` e ci sono backend registrati:
- all’avvio viene eseguito **`pull()`** e poi **`push()`** per ogni engine;
- la sequenza gira in un `Task` a priorità `.utility`, senza bloccare l’init.

---

## Test minimi

Sono presenti in `Tests/GraphNextTests/Init/GraphNextInitTests.swift`:

- **Init senza backend** → nessun crash, store/persistence creati.
- **Init con backend** → ordine `pull() → push()` garantito.
- **Preload flag** → init valido sia con che senza preload.
- **Multi-istanza** → due init separati hanno persistence ed engine distinti.

---

## Note

- Import unico: `import GraphNext`.
- Nessun coupling con auth: l’app decide lo switch di account e passa il nome store con `storeNameForAccount`.
- `CoreDataGraphPersistenceController` carica il modello Core Data da `Bundle.module`.
- I backend sono modulabili e iniettati da `makeBackends`.
