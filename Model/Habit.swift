//  Habit.swift
//  Habits
//  Created by bumpagram on 10/6/24.
// для декодирования JSON. чтобы распаковать дополнительные вложенные {}, - создаем объекты в объектах

import Foundation



struct Habit: Codable, Comparable {
    let category: Category
    let info: String
    let name: String
    
    static func < (lhs: Habit, rhs: Habit) -> Bool {
        //“if you switch away from the Habits screen and come back, the order of the habits shuffles. You need to sort them in each section so that there's a consistent display”
        return lhs.name < rhs.name
    }
}



struct Category: Codable {
    let color: Color
    let name: String
}



extension Habit: Hashable {
    static func == (lhs: Habit, rhs: Habit) -> Bool {
        return lhs.name == rhs.name
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)  // хз что это и зачем, просто переписал
    }
}



extension Category: Hashable {
    static func == (lhs: Category, rhs: Category) -> Bool {
        return lhs.name == rhs.name
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)  // хз что это и зачем, просто переписал
    }
}
