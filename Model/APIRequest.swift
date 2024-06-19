//  APIRequest.swift
//  Habits
//  Created by bumpagram on 10/6/24.
/* “In the Generics lesson, you built a simple APIRequest protocol that streamlined network processing by providing a default implementation for handling URLSessionDataTasks. For the Habits app, you'll do away with a separate network controller in favor of a handful of lightweight structs that conform to a modified version of the APIRequest protocol that reduces the need for boilerplate code even more than the one you used in previous Unit 3 projects. ”
 “To start, declare the protocol itself. It has one associated type—Response—that represents the type of object returned by a request. That should sound familiar; it's the same approach you used in the Swift Generics lab. This time, though, instead of requiring two methods for creating a request and decoding a response, the protocol will simply define four computed properties that will be used to build a URL request.  */

import UIKit

protocol APIRequest {
    associatedtype Response
    
    var path: String {get}
    var queryItems: [URLQueryItem]? {get}
    var request: URLRequest {get}
    var postData: Data? {get}
}


enum APIRequestError: Error {
    case itemsNotFound
    case requestFailed
}


// new error type to handle cases of bad image data and missing image data
enum ImageRequestError: Error {
    case couldNotInitializeFromData
    case imageDataMissing
}


extension APIRequest {
    var host: String {"localhost"}
    var port: Int {8080}
    var queryItems: [URLQueryItem]? {nil}    // “two default implementations returning nil for the queryItems and postData properties in a separate extension, since they'll be unused in most of your request types.
    var postData: Data? {nil}
}


extension APIRequest {
    var request: URLRequest {
        var components = URLComponents()
        components.scheme = "http"
        components.host = host // конструируем будущий URL запрос. В проперти url назначаем содержимое проперти протокола
        components.port = port
        components.path = path
        components.queryItems = queryItems
        var request = URLRequest(url: components.url!)
        
        if let data = postData {
            request.httpBody = data
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")  // не понял что это и откуда, просто с учебника переписал
            request.httpMethod = "POST"
        }
        
        return request
    }
}


// ниже расширение с методом для отправки запросов и обработки полученного результата
extension APIRequest where Response: Decodable {
    func send() async throws -> Response {
        let (somedata, someresponse) = try await URLSession.shared.data(for: request)
        guard let httpResponse = someresponse as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIRequestError.itemsNotFound
        }
        let decodedData = try JSONDecoder().decode(Response.self, from: somedata)
        return decodedData
    }
}


// доп расширение для fetching images
extension APIRequest where Response == UIImage {
    func send() async throws -> UIImage {
        
        let (somedata, someresponse) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = someresponse as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw ImageRequestError.imageDataMissing
        }
        
        guard let image = UIImage(data: somedata) else {
            throw ImageRequestError.couldNotInitializeFromData
        }
        
        return image
    }
}


// для POST запроса, где нет Response, а есть Void. будем использовать при отправке на сервер LoggedHabits.
extension APIRequest {
    func send() async throws -> Void {
        let (_ , response) = try await URLSession.shared.data(for: request)  // проперти протокола
        
        guard let httpresponse = response as? HTTPURLResponse, httpresponse.statusCode == 200 else {
            throw APIRequestError.requestFailed
        }
    }
}
