//  CombinedStatistics.swift
//  Habits
//  Created by bumpagram on 20/6/24.

import Foundation


struct CombinedStatistics: Codable {
    let userStatistics: [UserStatistics]
    let habitStatistics: [HabitStatistics]
}
