//
//  HabitCollectionViewController.swift
//  Habits
//  Created by bumpagram on 9/6/24.
//

import UIKit

private let reuseIdentifier = "Cell"

class HabitCollectionViewController: UICollectionViewController {
    
    typealias DataSourceType = UICollectionViewDiffableDataSource<ViewModel.Section, ViewModel.Item>
    var habitsRequestTask: Task <Void, Never>? = nil  // keep track of async tasks so they can be cancelled when appropriate (колесо текущих активных). “This property is used to cancel the task if it has not completed before a new request is made.”
    
    deinit {  habitsRequestTask?.cancel()  } // “You'll want to make sure the task is cancelled if the instance of the class is no longer in use but the task has not completed. You'll use the deinit method for this purpose. deinit is called just before the instance is deallocated. The superclass's deinit method will also be called automatically. ”
    
    enum ViewModel {
        enum Section: Hashable {
            case favorites
            case category(_ category: Category)
        }
        typealias Item = Habit
    }

    struct Model {
        var habitsByName = [String: Habit]()
    }
    
    var datasource: DataSourceType!
    var model = Model()  // “to store the data model after it's fetched from the network. Notice that you don't have a viewModel property. You'll construct a new view model each time you receive an update from the API and use it to create a snapshot, so there's no need for you to maintain your own copy.
   
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    func update() { // to get Habit objects from server
        habitsRequestTask?.cancel()
        habitsRequestTask = Task {
            if let requestedHabits = try? await HabitRequest().send() {
                self.model.habitsByName = requestedHabits // назначить в словарь модели то, что я запросил с сервера
            } else {
                self.model.habitsByName = [:]
            }
            self.updateCollectionView()
            habitsRequestTask = nil // в конце все таски обнуляем
        }
    }
    
    
    func updateCollectionView() {
        // “to update the collection view once the API has returned data”
        
    }

    
    
    
}
