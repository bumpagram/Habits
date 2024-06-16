//  HabitStatistics.swift
//  Habits
//  Created by bumpagram on 16/6/24.

import Foundation

struct HabitStatistics: Codable {
    let habit: Habit
    let userCounts: [UserCount]
}





struct UserCount: Codable, Hashable {  // for embedded type.
    //Hashable- because you'll need to guarantee stable identity of your view model items
    let user: User
    let count: Int
    
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(user)  // добавление функций hash и == дало корректное отображение анимаций (ячейки двигаются летают вверх вниз как в рангах), но теперь числа не обновляются
    }
    
    static func == (_ left: UserCount, _ right: UserCount) -> Bool {
        left.user == right.user
    }
}
