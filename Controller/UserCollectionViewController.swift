//
//  UserCollectionViewController.swift
//  Habits
//  Created by bumpagram on 9/6/24.
//

import UIKit

private let reuseIdentifier = "Cell"

class UserCollectionViewController: UICollectionViewController {

    typealias DataSourceType = UICollectionViewDiffableDataSource<ViewModel.Section, ViewModel.Item>
    
    var usersRequestTask: Task<Void, Never>? = nil  // Keep track of async tasks so they can be cancelled when appropriate
    deinit { usersRequestTask?.cancel() }
    
    enum ViewModel {
        typealias Section = Int
        
        struct Item: Hashable {
            let user: User
            let isFollowed: Bool
            
            func hash(into hasher: inout Hasher) {
                hasher.combine(user)
            }
            static func == (lhs: UserCollectionViewController.ViewModel.Item, rhs: UserCollectionViewController.ViewModel.Item) -> Bool {
                lhs.user == rhs.user
            }
        }
    }
    
    struct Model {
        var usersByID = [String: User]()  // сюда положим ответ от сервера
        
        var followedUsers: [User]  {
            let filtered = usersByID.filter {
                Settings.shared.followedUserIDs.contains($0.key)
            }
            return Array(filtered.values)
        }
    }
    
    var datasource: DataSourceType!
    var model = Model()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        datasource = createDataSource()
        collectionView.dataSource = datasource
        collectionView.collectionViewLayout = createLayout()
        
        update()
    }
    
    
    func update() {
        usersRequestTask?.cancel()
        usersRequestTask = Task {
            if let requestedUsers = try? await UserRequest().send() {  // стучимся в сеть
                self.model.usersByID = requestedUsers  // назначаем в проперти полученную инфу
            } else {
                self.model.usersByID = [:]  // если ничего не пришло, тогда пустой словарь
            }
            self.updateCollectionView()
            usersRequestTask = nil // обнуляем колесо асинхронных задач
        }
    }  // to get users from API service
    
    
    func updateCollectionView() {
        // “The implementation simply reduces the model's user dictionary into an array of view model instances, sets up a single section, and applies the snapshot.
        let reducedUsers = model.usersByID.values.sorted().reduce(into: [ViewModel.Item]()) { partialResult, someUser in
            
            partialResult.append(  ViewModel.Item(user: someUser, isFollowed: model.followedUsers.contains(someUser))  )
        }
        let itemsBysection = [0: reducedUsers]  // нихера уже не понимаю что происходит и почему нули
        datasource.applySnapshotUsing(sectionIDs: [0], itemsBySection: itemsBysection)
    }
    
    
    func createDataSource() -> DataSourceType {
        
        let somedataSource = DataSourceType(collectionView: collectionView) { collectionView, indexPath, itemIdentifier in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "User", for: indexPath) as! UICollectionViewListCell
            var content = cell.defaultContentConfiguration()
            content.text = itemIdentifier.user.name
            content.directionalLayoutMargins = .init(top: 11, leading: 8, bottom: 11, trailing: 8)
            content.textProperties.alignment = .center
            cell.contentConfiguration = content
            return cell
        }
        
        return somedataSource
    }
    
    
    func createLayout() -> UICollectionViewCompositionalLayout {
        
        let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalHeight(1), heightDimension: .fractionalHeight(1)), supplementaryItems: [] )
        
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalWidth(0.45)), repeatingSubitem: item, count: 2)
        group.interItemSpacing = .fixed(20)
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 20
        section.contentInsets = .init(top: 20, leading: 20, bottom: 20, trailing: 20)
        
        return UICollectionViewCompositionalLayout(section: section)
    }
    
    
}
