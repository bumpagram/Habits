//  APIService.swift
//  Habits
//  Created by bumpagram on 10/6/24.

import UIKit


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



struct UserStatisticsRequest: APIRequest {
    typealias Response = [UserStatistics]
    var userIDs: [String]?
    var path: String {"/userStats"}
    
    var queryItems: [URLQueryItem]? {
        if let userIDs = userIDs {
            return [URLQueryItem(name: "ids", value: userIDs.joined(separator: ","))]
        } else {
            return nil
        }
    }
    // as you may have guessed, based on the model, you'll query the API for all the user's habit counts as well as those the user leads”
}



struct HabitLeadStatRequest: APIRequest {
    typealias Response = UserStatistics
    var userID: String
    var path: String { "/userLeadingStats/\(userID)" }
}



struct ImageRequest: APIRequest {
    typealias Response = UIImage
    var imageID: String
    var path: String { "/images/" + imageID}
}



struct LogHabitRequest: APIRequest { // это будет не GET запрос, а POST
    typealias Response = Void  // “because the API doesn't return anything from this POST call, you can declare Void as the response type”
    
    var loggedhabit: LoggedHabit
    var path: String { "/loggedHabit" }
    
    var postData: Data? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try! encoder.encode(loggedhabit)
    }
}



struct CombinedStatRequest: APIRequest {
    typealias Response = CombinedStatistics
    
    var path: String {"/combinedStats"}
}
