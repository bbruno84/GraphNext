//
//  GraphNextE2ETests.swift
//  GraphNext
//
//  Created by Valerio Buriani on 25/08/25.
//

import XCTest
@testable import GraphNext

final class GraphNextE2ETests: XCTestCase {

    // MARK: - E2E: init → create → attach asset → push (to remote) → reset → pull (from remote) → verify

    func testHappyPath_PushResetPull_WithAssetAttachment() async throws {
        // 0) INIT: due controller GRDB in‑memory (LOCAL e REMOTE)
        let local = try GRDBGraphPersistenceController(path: "E2E_Local_1", inMemory: true)
        let backend = MockRemoteBackend()
    
        // 1) CREATE: 2 Entity + 1 Relationship (owner→customer), poi attach dell'asset all'owner
        let owner = Entity(
            id: UUID(),
            type: "invoice",
            created: .init(by: "tester", at: .now),
            updated: nil,
            version: 1,
            payload: ["number": .string("INV-2025-001")]
        )
        let customer = Entity(
            id: UUID(),
            type: "customer",
            created: .init(by: "tester", at: .now),
            updated: nil,
            version: 1,
            payload: ["name": .string("Mario Rossi")]
        )
        let owns = Relationship(
            id: UUID(),
            type: "owns",
            created: .init(by: "tester", at: .now),
            updated: nil,
            version: 1,
            payload: [:],
            from: owner.id,
            to: customer.id
        )

        try await local.saveEntity(owner)
        try await local.saveEntity(customer)
        try await local.saveRelationship(owns)

        // Asset finto (4 byte "%PDF")
        let data = Data([0x25, 0x50, 0x44, 0x46])
        let asset = try await local.createAssetAndAttach(
            data: data,
            mimeType: "application/pdf",
            fileName: "invoice.pdf",
            attachTo: owner.id
        )

        // Verifica preliminare: l’asset è relazionato all’owner nel LOCAL
        do {
            let relatedLocal = try await local.relatedEntities(from: owner.id)
            XCTAssertTrue(
                relatedLocal.contains(where: { $0.id == asset.id }),
                "Precondition: asset deve risultare collegato all'owner nel LOCAL prima del push"
            )
        }

        // 2) PUSH (simulato): copia le entità/relazioni dal LOCAL al REMOTE
        // Nota: qui simuliamo il backend remoto duplicando i record nel controller REMOTO.
        try await backend.save(entities: [owner, customer, asset])
        let attaches = Relationship(
            id: UUID(),
            type: "attaches",
            created: .init(by: "tester", at: .now),
            updated: nil,
            version: 1,
            payload: [:],
            from: owner.id,
            to: asset.id
        )
        try await backend.save(relationships: [owns, attaches])

        // 3) RESET: “svuota” il LOCAL ricreando un controller nuovo in‑memory
        let localAfterReset = try GRDBGraphPersistenceController(path: "E2E_Local_2_AfterReset", inMemory: true)

        // Verifica che prima del pull non ci sia la relazione (LOCAL appena creato)
        do {
            let relatedPrePull = try await localAfterReset.relatedEntities(from: owner.id)
            XCTAssertFalse(
                relatedPrePull.contains(where: { $0.id == asset.id }),
                "Prima del pull, il LOCAL non deve contenere l'asset relazionato"
            )
        }

        // 4) PULL (simulato): copia dal REMOTE al nuovo LOCAL
        try await backend.prepareDeltaFetch()
        let pulledEntities = try await backend.fetchEntities()
        let pulledRelationships = try await backend.fetchRelationships()

        for e in pulledEntities {
            if e.type == "asset" {
                try await localAfterReset.saveEntity(e, allowAsset: true)
            } else {
                try await localAfterReset.saveEntity(e)
            }
        }
        for r in pulledRelationships {
            try await localAfterReset.saveRelationship(r)
        }

        // 5) VERIFY: l’asset deve risultare di nuovo collegato
        let relatedPostPull = try await localAfterReset.relatedEntities(from: owner.id)
        XCTAssertTrue(
            relatedPostPull.contains(where: { $0.id == asset.id }),
            "Dopo il pull, l'asset deve essere collegato all'owner anche nel LOCAL"
        )
    }
}
