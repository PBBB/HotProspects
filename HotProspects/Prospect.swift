//
//  Prospect.swift
//  HotProspects
//
//  Created by Issac Penn on 2019/12/15.
//  Copyright © 2019 Issac Penn. All rights reserved.
//

import SwiftUI

class Prospect: Identifiable, Codable {
    let id = UUID()
    var name = "Anonymous"
    var emailAddress = ""
    fileprivate(set) var isContacted = false
}

class Prospects: ObservableObject {
    static let saveKey = "SavedData"
    @Published private(set) var people: [Prospect]
    
    init() {
        let url = FileManager.getDocumentDirectory().appendingPathComponent(Self.saveKey)
        if let data = try? Data(contentsOf: url) {
            if let decoded = try? JSONDecoder().decode([Prospect].self, from: data) {
                self.people = decoded
                return
            }
        }
        self.people = []
    }
    
    func toggle(_ prospect: Prospect) {
        objectWillChange.send()
        prospect.isContacted.toggle()
        save()
    }
    
    func add(_ prospect: Prospect) {
        people.append(prospect)
        save()
    }
    
    private func save() {
        if let encoded = try? JSONEncoder().encode(self.people) {
            let url = FileManager.getDocumentDirectory().appendingPathComponent(Self.saveKey)
            try? encoded.write(to: url)
        }
    }
}

extension FileManager {
    static func getDocumentDirectory() -> URL {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[0]
    }
}
