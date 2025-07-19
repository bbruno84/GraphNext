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
    
    override func setUp() {
        store = GraphStore(useNSCache: true)
        cancellables = []
    }
    
    override func tearDown() {
        store = nil
        cancellables.removeAll()
    }
    
    func testObjectWillChangeIsCalledOnAdd() {
        let expectation = XCTestExpectation(description: "objectWillChange published")
        
        store.objectWillChange
            .sink {
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        let entity = Entity(
            id: UUID(),
            type: "Car",
            created: AuditInfo(by: "test")
        )
        store.add(entity)
        wait(for: [expectation], timeout: 1)
    }
    
    func testObjectWillChangeIsCalledOnRemove() {
        let entity = Entity(
            id: UUID(),
            type: "Car",
            created: AuditInfo(by: "test")
        )
        store.add(entity)
        
        let expectation = XCTestExpectation(description: "objectWillChange published on remove")
        
        store.objectWillChange
            .sink {
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        store.removeNode(id: entity.id)
        wait(for: [expectation], timeout: 1)
    }
}

