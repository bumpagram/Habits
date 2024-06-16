//  HabitStatistics.swift
//  Habits
//  Created by bumpagram on 16/6/24.

import Foundation

struct HabitStatistics: Codable {
    let habit: Habit
    let userCounts: [UserCount]
}



struct UserCount: Codable, Hashable {  // for embedded type.
    //Hashable- because you'll need to guarantee stable identity of your view model items
    let user: User
    let count: Int
}
