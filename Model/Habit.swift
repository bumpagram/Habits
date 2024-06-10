//  Habit.swift
//  Habits
//  Created by bumpagram on 10/6/24.

import Foundation

// для декодирования JSON. чтобы распаковать дополнительные вложенные {}, - создаем объекты в объектах

struct Habit: Codable {
    let category: Category
    let info: String
    let name: String
}


struct Category: Codable {
    let color: Color
    let name: String
}


struct Color: Codable {
    let brightness: Double  // "b"
    let hue: Double  // "h"
    let saturation: Double  // "s"
    
    enum CodingKeys: String, CodingKey {
        case hue = "h"
        case saturation = "s"
        case brightness = "b"
    }
}
