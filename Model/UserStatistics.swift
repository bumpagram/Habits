//  UserStatistics.swift
//  Habits
//  Created by bumpagram on 16/6/24.

import Foundation

struct UserStatistics: Codable {
    let user: User
    let habitCounts: [HabitCount]
}





struct HabitCount: Codable, Hashable { // for embedded type
    
    let habit: Habit  // to display
    let count: Int
    
    
    func hash(into hasher: inout Hasher) {
            hasher.combine(habit)
        }
    static func ==(_ lhs: HabitCount, _ rhs: HabitCount) -> Bool {
            return lhs.habit == rhs.habit
        }
    
}
