//  Color.swift
//  Habits
//  Created by bumpagram on 23/6/24.
// для декодирования JSON. чтобы распаковать дополнительные вложенные {}, - создаем объекты в объектах


import UIKit



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



extension Color: Hashable {
    var uiColor: UIColor {
        return UIColor(hue: CGFloat(hue), saturation: CGFloat(saturation), brightness: CGFloat(brightness), alpha: 1)
    }
}
