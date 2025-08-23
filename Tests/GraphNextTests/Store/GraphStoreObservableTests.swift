//
//  GraphStoreObservableTests.swift
//  GraphNext
//
//  Created by Valerio Buriani on 13/07/25.
//

import XCTest
import Combine
@testable import GraphNext

final class GraphStoreObservableTests: XCTestCase {
    
    var store: GraphStore!
    var cancellables: Set<AnyCancellable> = []
    
    override func setUp() async throws {
        store = await GraphStore(useNSCache: true)
        cancellables = []
    }
    
    override func tearDown() {
        store = nil
        cancellables.removeAll()
    }
    
    func testObjectWillChangeIsCalledOnAdd() async {
        let expectation = XCTestExpectation(description: "objectWillChange published")
        
        await store.objectWillChange
            .sink {
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        let entity = Entity(
            id: UUID(),
            type: "Car",
            created: AuditInfo(by: "test")
        )
        await store.add(node: entity, isRemote: false)
        await fulfillment(of: [expectation], timeout: 1)
    }
    
    func testObjectWillChangeIsCalledOnRemove() async {
        let entity = Entity(
            id: UUID(),
            type: "Car",
            created: AuditInfo(by: "test")
        )
        await store.add(node: entity, isRemote: false)
        
        let expectation = XCTestExpectation(description: "objectWillChange published on remove")
        
        await store.objectWillChange
            .sink {
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        await store.remove(id: entity.id, isRemote: false)
        await fulfillment(of: [expectation], timeout: 1)
    }
}
