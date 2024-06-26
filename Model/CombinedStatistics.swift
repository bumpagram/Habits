//  CombinedStatistics.swift
//  Habits
//  Created by bumpagram on 20/6/24.

import Foundation


struct CombinedStatistics: Codable {
    let userStatistics: [UserStatistics]   // учавствует в декодировании JSON, поэтому имена длинные
    let habitStatistics: [HabitStatistics]
}
