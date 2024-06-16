//  UserDetailViewController.swift
//  Habits
//  Created by bumpagram on 10/6/24.

import UIKit

class UserDetailViewController: UIViewController {
    
    @IBOutlet var profileImageView: UIImageView!
    @IBOutlet var usernameLabel: UILabel!
    @IBOutlet var bioLabel: UILabel!
    @IBOutlet var collectionview: UICollectionView!
    
    typealias DataSourceType = UICollectionViewDiffableDataSource<ViewModel.Section, ViewModel.Item>
    
    enum ViewModel {
        typealias Item = HabitCount
        enum Section: Hashable, Comparable {
            case leading
            case category(_ some: Category)
            
            static func < (lhs: UserDetailViewController.ViewModel.Section, rhs: UserDetailViewController.ViewModel.Section) -> Bool {
                switch (lhs, rhs) {
                case (.leading, .category), (.leading, .leading): return true
                case (.category, .leading): return false
                case (category(let one), category(let two)): return one.name > two.name
                }
            }
        }
    }
    
    struct Model {
        var userStats: UserStatistics?
        var leadingStats: UserStatistics?
    }
    
    
    var user: User! // main property to handle and display
    var datasource: DataSourceType!
    var model = Model()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        usernameLabel.text = user.name
        bioLabel.text = user.bio
        //
        
    }
    
    
    init?(coder: NSCoder, user: User) { // to enable segue action from HabitCollection VC
        super.init(coder: coder)
        self.user = user
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
        
        
        
        
    
}
