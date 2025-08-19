# GraphSyncEngine – Plugin CloudKit (CKSyncEngine-based)

## Indice
- [Scopo](#scopo)
- [Requisiti](#requisiti)
- [Configurazione](#configurazione)
- [Inizializzazione](#inizializzazione)
- [Notifiche Remote → Pull debounced](#notifiche-remote--pull-debounced)
- [API principali](#api-principali)
- [Comportamento](#comportamento)
  - [Remote-wins](#remote-wins)
  - [Push incrementale](#push-incrementale)
  - [Debounce & Retry/Backoff](#debounce--retrybackoff)
  - [Reset](#reset)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting)
- [Roadmap (estratto)](#roadmap-estratto)

---

## Scopo
Plugin di sincronizzazione per **GraphNext** basato su **CloudKit/CKSyncEngine**.  

- **remote-wins**: il backend è la fonte di verità.  
- **pull** debounced su notifiche remote.  
- **push** incrementale debounced su modifiche locali del `GraphStore`.  
- **retry/backoff** configurabile.  
- **reset** (clear locale + riallineamento).  

---

## Requisiti
- iOS 16+ (target del progetto).  
- CKSyncEngine disponibile da iOS 17+ (il plugin gestisce fallback/mock nei test).  
- CloudKit container configurato.

---

## Configurazione

```swift
public struct CloudKitSyncConfig: Codable, Equatable {
    public var containerIdentifier: String?      // es: "iCloud.com.company.app"
    public var zoneName: String                  // es: "GraphNextZone"
    public var stateStore: StateStore            // .userDefaults(suiteName:) | .fileSystem(path:)
    public var subscribeOnInit: Bool             // auto-sottoscrizione a modifiche remote
    public var subscriptionID: String            // es: "GraphNextSyncSubscription"
    public var debounceMilliseconds: Int         // default 750 (pull/push/sync)
    public var retryMaxAttempts: Int             // default 3
    public var retryBaseDelaySeconds: Double     // default 0.5
}
```

Esempio:

```swift
let config = CloudKitSyncConfig(
  containerIdentifier: "iCloud.com.company.app",
  zoneName: "GraphNextZone",
  stateStore: .userDefaults(suiteName: "CKSE.GraphNextState"),
  subscribeOnInit: true,
  subscriptionID: "GraphNextSyncSubscription",
  debounceMilliseconds: 500,
  retryMaxAttempts: 3,
  retryBaseDelaySeconds: 0.5
)
```

---

## Inizializzazione

```swift
import CloudKit
import GraphNext
import GraphPersistence
import GraphSyncEngine

let persistence = CoreDataGraphPersistenceController(storeName: "GraphNext", inMemory: false)
let store = GraphStore()
let container = config.containerIdentifier
  .map(CKContainer.init(identifier:)) ?? .default()

let sync = CloudKitSync(
  persistence: persistence,
  store: store,
  configuration: config,
  container: container
)
```

> ✳️ Il plugin **ascolta automaticamente** le modifiche del `GraphStore` e avvia un **push incrementale debounced**.

---

## Notifiche Remote → Pull debounced

Aggancia l’entry point di App/Scene:

```swift
// AppDelegate / SceneDelegate
import CloudKit
import GraphSyncEngine

func application(_ application: UIApplication,
                 didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                 fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    if sync.handleRemoteNotification(userInfo) {
        completionHandler(.newData)
    } else {
        completionHandler(.noData)
    }
}
```

> 🔔 Assicurati che l’App abiliti le **Remote Notifications** (capability) e che la subscription venga creata (se `subscribeOnInit = true`).

---

## API principali

```swift
try await sync.pull()       // scarica dal backend → deletions + upsert
try await sync.push()       // invia solo i delta locali (incrementale)
try await sync.sync()       // pull → push
try await sync.reset()      // clear GraphStore + clear watermarks + pull remoto
```

Helper:
- `sync.triggerPullDebounced()` — usato internamente da `handleRemoteNotification`.
- `sync.triggerSyncDebounced()` — disponibile per trigger manuali/locali.

---

## Comportamento

### Remote-wins
- In caso di conflitto, vince sempre il **remoto**.  
- `pull()` applica prima le **deletion** e poi **upsert** di Entity/Relationship.

### Push incrementale
- Watermark in memoria:
  - `lastPushedEntityTimestamp: [UUID: Date]`
  - `lastPushedRelationshipTimestamp: [UUID: Date]`
- Un nodo viene pushato solo se più recente del suo watermark.
- Watermark aggiornati solo dopo un push riuscito.

### Debounce & Retry/Backoff
- `debounceMilliseconds`: coalescing di trigger ravvicinati.  
- `retryMaxAttempts` + `retryBaseDelaySeconds`: exponential backoff per errori transitori (`networkUnavailable`, `zoneBusy`, ecc.).

### Reset
- `reset()`:
  1. `store.clear()`
  2. azzera watermark
  3. `pull()` remoto (remote-wins)

---

## Testing

- Usa `MockRemoteBackend` / `TransientErrorMockBackend` per test locali.  
- Test implementati:
  - **Debounce** (coalescing pull)
  - **Retry/Backoff** (errori transitori)
  - **Auto push** su modifiche locali
  - **Pull flow** (idempotenza, remote-wins)
  - **Reset flow** (clear + riallineamento)

✅ I test non toccano CloudKit reale.  
Per E2E, usare un target App con **CloudKit capability**.

---

## Troubleshooting

- **`containerIdentifier can not be nil` nei test** → usa mock backend.  
- **Nessun evento su pull dopo notifiche**:
  - verifica subscription creata (`subscribeOnInit = true`)
  - abilita Remote Notifications
  - instrada `didReceiveRemoteNotification` → `handleRemoteNotification(_:)`
- **Push troppo costoso** → già incrementale; batching configurabile è in backlog.

---

## Roadmap (estratto)
- [x] Pull debounced da notifiche  
- [x] Push incrementale debounced da modifiche locali  
- [x] Deletion + remote-wins  
- [x] Retry/backoff + state persistence  
- [x] Reset completo  
- [ ] Batching configurabile (backlog)  
- [ ] Zone custom + condivisione (backlog)  
- [ ] Conflict handler opzionale (backlog)  
