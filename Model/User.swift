//  User.swift
//  Habits
//  Created by bumpagram on 12/6/24.

import Foundation

struct User: Codable, Hashable, Comparable {
    
    let id: String
    let name: String
    let color: Color?
    let bio: String?
    
    static func == (lhs: User, rhs: User) -> Bool {
        lhs.id == rhs.id
    }
    static func < (lhs: User, rhs: User) -> Bool {
        lhs.name < rhs.name  // Because you'll want to be able to display the users sorted by name, extend User to adopt Comparable
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
}


