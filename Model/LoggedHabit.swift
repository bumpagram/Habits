//  LoggedHabit.swift
//  Habits
//  Created by bumpagram on 19/6/24.

import Foundation


struct LoggedHabit: Codable {
    let userID: String
    let habitName: String
    let timestamp: Date
}
