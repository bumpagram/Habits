//  APIService.swift
//  Habits
//  Created by bumpagram on 10/6/24.

import Foundation


struct HabitRequest: APIRequest {
    typealias Response = [String: Habit]  // чаcть декодирования джейсонов. в ендпоинте /habits словарь.
    var habitName: String?
    var path: String {"/habits"}  // вроде как значение по умолчанию
}



struct UserRequest: APIRequest {
    typealias Response = [String: User]
    var path: String {"/users"}
}



struct HabitStatisticsRequest: APIRequest {
    // for fetching habit statistics. Because you can ask for statistics for multiple habit names in one request, you'll provide a comma-separated list of IDs from the queryItems property.
    
    typealias Response = [HabitStatistics]
    var path: String {"/habitStats"}  // API endpoint
    var habitNames: [String]?
    
    var queryItems: [URLQueryItem]? {
        if let existedhabitNames = habitNames {
            return [URLQueryItem(name: "names", value: existedhabitNames.joined(separator: ","))]
        } else {
            return nil
        }
    }
    
}
