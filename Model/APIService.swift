//  APIService.swift
//  Habits
//  Created by bumpagram on 10/6/24.

import Foundation


struct HabitRequest: APIRequest {
    typealias Response = [String: Habit]  // чаcть декодирования джейсонов. в ендпоинте /habits словарь.
    var habitName: String?
    var path: String {"/habits"}  // вроде как значение по умолчанию
}


