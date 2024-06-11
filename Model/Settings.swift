//
//  Settings.swift
//  Habits
//  Created by bumpagram on 11/6/24.

import Foundation


struct Settings {
    
    static var shared = Settings() // синглтон. точка входа
    
    private let defaults = UserDefaults.standard  // “You're only running a simulated social network, so there'll only be one real user—the other users don't need to flag favorite habits or follow users. So you'll store favorite and followed status locally using UserDefaults.
    
    private func archiveJSON<T: Encodable>(value: T, key: String) {
        /* “generic methods to archive and unarchive JSON from UserDefaults”
         “You can assume that JSON encoding and decoding will work, so you can disable error propagation by using try!. Using that variant of the try keyword will cause a runtime error if the call to encode(_:) or decode(_:from:) throws an error, so there's no need to wrap your code in a do/catch block.
         */
        let data = try! JSONEncoder().encode(value)
        let somestring = String(data: data, encoding: .utf8)
        defaults.set(somestring, forKey: key)
    }
    
    private func unarchiveJSON<T: Decodable>(key: String) -> T? {
        guard let somestring = defaults.string(forKey: key),
              let data = somestring.data(using: .utf8) else {
                return nil
        }
        // generic метод, работаем с любым типом соответствующим Decodable и его же и пытаемся синтезировать + вернуть
        return try! JSONDecoder().decode(T.self, from: data)
    }
   
    var favoriteHabits: [Habit] {
        get {
            return unarchiveJSON(key: Setting.favoriteHabits) ?? []
        }
        set {
            archiveJSON(value: newValue, key: Setting.favoriteHabits)
        }
    }
    
    
}


enum Setting {
    // “You'll notice the string "favoriteHabits" is used twice. It's generally a good practice to use constants whenever a value is used more than once. Once again, you'll use an enum namespace to store the key string. This way, when additional keys are added later, they'll be nicely grouped and contained. As a bonus, it also makes the code more readable.”
   
    static let favoriteHabits = "favoriteHabits"
    // будет дополнен позже
    
}
