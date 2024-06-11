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
    
    deinit {
        habitsRequestTask?.cancel()
        // “You'll want to make sure the task is cancelled if the instance of the class is no longer in use but the task has not completed. You'll use the deinit method for this purpose. deinit is called just before the instance is deallocated. The superclass's deinit method will also be called automatically. ”
        }
    
    enum ViewModel {
        enum Section: Hashable, Comparable {
            case favorites
            case category(_ category: Category)
            
            static func < (lhs: Section, rhs: Section) -> Bool {
                switch (lhs, rhs) {
                case (.category(let l), .category(let r)): return l.name < r.name
                case (.favorites, _): return true
                case (_, .favorites): return false
                    // “This switch statement uses a new form of pattern matching over a tuple: a comma-separated list of values. In each case, you address permutations of your left-hand and right-hand values. If they're both categories, you sort by name. If one or the other is .favorites, you ensure that it's sorted to the beginning.
                }
            }
        }
        typealias Item = Habit
    }

    struct Model {
        var habitsByName = [String: Habit]()
        var favoriteHabits: [Habit] {  return Settings.shared.favoriteHabits }
    }
    
    enum SectionHeader: String {
        case kind = "SectionHeader"
        case reuse = "HeaderView"
        var identifier: String { return rawValue }  // это доп unwrapper, чтобы case переводить в String в нужных функциях вызова
    }
    
    var datasource: DataSourceType!
    var model = Model()  
    /* “to store the data model after it's fetched from the network. Notice that you don't have a viewModel property. You'll construct a new view model each time you receive an update from the API and use it to create a snapshot, so there's no need for you to maintain your own copy.
     */
   
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // code to set up sollcection view and fetch your data
        datasource = createDataSource()
        collectionView.dataSource = datasource
        collectionView.collectionViewLayout = createLayout()
        // register your new header class
        collectionView.register(NamedSectionHeaderView.self, forSupplementaryViewOfKind: SectionHeader.kind.identifier, withReuseIdentifier: SectionHeader.reuse.identifier)
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        // “that this screen refreshes every time you visit it. (This won't be necessary now, but in the future users will toggle the favorite status of habits on different screens.)
       
        update()
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        /* “To allow the user to easily toggle a habit's favorite status, you'll use a context menu that's activated with a long press. To provide a context menu from a collection view cell, declare the following delegate method.
         “The menu system in iOS is built on the UIMenu type. A menu can contain menu items that trigger actions along with submenus to create arbitrary hierarchies. UICollectionViewController handles a default long press behavior on its cells and will automatically display a context menu if you provide an implementation for the delegate method above.”
         */
        
        let config = UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            
            let item = self.datasource.itemIdentifier(for: indexPath)!
            let willBeTitle = self.model.favoriteHabits.contains(item) ? "Unfavorite" : "Favorite" // тернарный оператор Bool для вывода title будущей кнопки
            let favToggle = UIAction(title: willBeTitle ) { UIAction in
                Settings.shared.toggleFavorite(item)
                self.updateCollectionView()
            }
            
            return UIMenu(title: "", image: nil, identifier: nil, options: [], children: [favToggle])
        }
     
        return config
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
        // “to update the collection view once the API has returned data”. this method will be responsible for building a view model, using it to create a snapshot, and applying that snapshot to the diffable data source.
        var itemsBySection = model.habitsByName.values.reduce(into: [ViewModel.Section: [ViewModel.Item]]() ) { partialResult, habit in
            let item = habit
            let section: ViewModel.Section
            if model.favoriteHabits.contains(habit) {
                section = .favorites
            } else {
                section = .category(habit.category)
            }
            partialResult[section, default: []].append(item)  // хз что тут происходит - просто переписал
        }
        
        itemsBySection = itemsBySection.mapValues({  $0.sorted()  })  // “handy method for dictionaries that applies the provided closure to each of the values in the dictionary. ”
        
        let sectionIDs = itemsBySection.keys.sorted()
        datasource.applySnapshotUsing(sectionIDs: sectionIDs, itemsBySection: itemsBySection)
    }

        
    func createDataSource() -> DataSourceType {
        let somedataSource = DataSourceType(collectionView: collectionView) { collectionView, indexPath, itemIdentifier in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Habit", for: indexPath) as! UICollectionViewListCell
            var content = cell.defaultContentConfiguration()
            content.text = itemIdentifier.name
            cell.contentConfiguration = content
            return cell
        }
        
        somedataSource.supplementaryViewProvider = .some({ collectionView, elementKind, indexPath in
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: SectionHeader.kind.identifier, withReuseIdentifier: SectionHeader.reuse.identifier, for: indexPath) as! NamedSectionHeaderView
            let section = somedataSource.snapshot().sectionIdentifiers[indexPath.section]
            
            switch section {
            case .favorites: header.nameLabel.text = "Favorites"
            case .category(let existCategory): header.nameLabel.text = existCategory.name
            }
            
            return header
        })
        
        
        return somedataSource
    }
    
    
    func createLayout() -> UICollectionViewCompositionalLayout {
        let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1)))
        
        let groupsize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(44))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupsize, repeatingSubitem: item, count: 1)
        
        let sectionheader = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(36)), elementKind: SectionHeader.kind.identifier, alignment: .top)
        sectionheader.pinToVisibleBounds = true
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = .init(top: 0, leading: 10, bottom: 0, trailing: 10)
        section.boundarySupplementaryItems = [sectionheader]
        
        return UICollectionViewCompositionalLayout(section: section)
    }
    
}
