//  HomeCollectionViewController.swift
//  Habits
//  Created by bumpagram on 9/6/24.

import UIKit

//private let reuseIdentifier = "Cell"

class HomeCollectionViewController: UICollectionViewController {

    typealias DataSourceType = UICollectionViewDiffableDataSource<ViewModel.Section, ViewModel.Item>
    
    enum ViewModel {
        enum Section: Hashable {
            case leaderboard
            case followedUsers
        }
        
        enum Item: Hashable {
            case leaderboardHabit(name: String, leadingUserRanking: String?, secondaryUserRanking: String?)
            case followedUser(_ user: User, message: String)
            
            func hash(into hasher: inout Hasher) {
                switch self {
                case .leaderboardHabit(name: let somename, leadingUserRanking: _, secondaryUserRanking: _): hasher.combine(somename)
                    
                case .followedUser(let someuser, message: _): hasher.combine(someuser)
                }
            }
            
            static func ==(lh: Item, rh: Item)-> Bool {
                switch (lh, rh) {
                case ( .leaderboardHabit(name: let leftname, leadingUserRanking: _, secondaryUserRanking: _), .leaderboardHabit(name: let rightname, leadingUserRanking: _, secondaryUserRanking: _) ):  return leftname == rightname
                    
                case (.followedUser(let leftuser, message: _), .followedUser(let rightuser, message: _)): return leftuser == rightuser
                    
                default: return false
                }
            }
        }
        
    }
    
    struct Model {
        var usersByID = [String: User]()
        var habitsByName = [String: Habit]()
        var habitStats = [HabitStatistics]()
        var userStats = [UserStatistics]()
        
        var currentuser: User {
            return Settings.shared.currentUser
        }
        var users: [User] {
            return Array(usersByID.values)
        }
        var habits: [Habit] {
            return Array(habitsByName.values)
        }
        var followedUsers: [User] {
            let filteredArray = Array(usersByID.filter({
                Settings.shared.followedUserIDs.contains($0.key)
            }).values)
            return filteredArray
        }
        var favoriteHabits: [Habit] {
            return Settings.shared.favoriteHabits
        }
        var nonFavoriteHabits: [Habit] {
            return habits.filter { !favoriteHabits.contains($0)  }
        }
    }
    
    var model = Model()
    var datasource: DataSourceType!
    var updateTimer: Timer?
    
    var userRequestTask: Task<Void, Never>? = nil
    var habitRequestTask: Task<Void, Never>? = nil
    var combinedStatRequestTask: Task<Void, Never>? = nil
    
    deinit {
        userRequestTask?.cancel()
        habitRequestTask?.cancel()
        combinedStatRequestTask?.cancel()
        // “You don't need to cancel any existing request task, since there will not be any, but you do want to capture references to the tasks so they can be cancelled if the instance is deallocated”.  поэтому проперти и deinit
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("viewdidload")
        datasource = createDataSource()
        collectionView.dataSource = datasource
        collectionView.collectionViewLayout = createLayout()
        
        userRequestTask = Task {
            if let fetchedUsers = try? await UserRequest().send() {
                self.model.usersByID = fetchedUsers
            }
            self.updateCollectionview()
            userRequestTask = nil
        }
        
        habitRequestTask = Task {
            if let fetchedHabits = try? await HabitRequest().send() {
                self.model.habitsByName = fetchedHabits
            }
            self.updateCollectionview()
            habitRequestTask = nil
        }
        print("viewdidload end")

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateData()
        updateTimer = Timer(timeInterval: 3, repeats: true, block: { _ in
            self.updateData()  // опять ставим таймер на обновление каждые 3 сек
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        updateTimer?.invalidate()
        updateTimer = nil  // уничтожаем таймер на постоянные обновления, когда уходим с экрана
    }
    
    
    func updateCollectionview() {
        var arrayOfSectionIDs = [ViewModel.Section]()
        
        // “You're filtering the habit statistics to eliminate habits that aren't in the user's favorites, sorting them by name, then reducing the resulting array into an array of view model items.”
        
        let leaderboardItems = model.habitStats.filter { stat in
            model.favoriteHabits.contains { $0.name == stat.habit.name }
        }
            .sorted { $0.habit.name < $1.habit.name }
            .reduce(into: [ViewModel.Item]()) { partialResult, HabitStatistics in
                // Rank the user counts from highest to lowest
                let rankedUserCounts = HabitStatistics.userCounts.sorted { $0.count > $1.count }
                
                // Find the index of the current user's count, keeping in mind that it won't exist if the user hasn't logged that habit yet
                let myCountIndex = rankedUserCounts.firstIndex {  $0.user.id == self.model.currentuser.id }
                
                func userRankString(from userCount: UserCount) -> String {
                    // “a function that'll create a personalized count string. You can put this inline with the rest of the code in the closure, since it's only going to be used locally.
                    var somename = userCount.user.name
                    var rank = ""
                    
                    if userCount.user.id == self.model.currentuser.id {
                        somename = "You"
                        rank = " \(ordinalString(from: myCountIndex!)) "
                    }
                    return "\(somename) \(userCount.count)" + rank
                }
                
                var leadRank: String?
                var secondRank: String?
                // Examine the number of user counts for the statistic:
                switch rankedUserCounts.count {
                case 0: leadRank = "Nobody Yet!"
                case 1: let onlyCount = rankedUserCounts.first!
                        leadRank = userRankString(from: onlyCount)
                default:
                    leadRank = userRankString(from: rankedUserCounts[0])
                    // Check whether the index of the current user's count exists and is not 0
                    if let myCountIndex = myCountIndex, myCountIndex != rankedUserCounts.startIndex {
                        // If true, the user's count and ranking should be displayed in the secondary label
                        secondRank = userRankString(from: rankedUserCounts[myCountIndex])
                    } else {
                        // If false, the second-place user count should be displayed
                        secondRank = userRankString(from: rankedUserCounts[1])
                    }
                }
                
                // this lines create and set viewmodel item
                let leaderboardItem = ViewModel.Item.leaderboardHabit(name: HabitStatistics.habit.name, leadingUserRanking: leadRank, secondaryUserRanking: secondRank)
                partialResult.append(leaderboardItem)
            }
        
        
        // “add the leaderboard section ID and set up a new variable for your dictionary of sections to items. Populate it with the leaderboard section.
        arrayOfSectionIDs.append(.leaderboard)
        let itemsBySection = [ViewModel.Section.leaderboard: leaderboardItems] // в учебнике var
        // and finally update snapshot
        datasource.applySnapshotUsing(sectionIDs: arrayOfSectionIDs, itemsBySection: itemsBySection)
    }
    
    
    func updateData() {
        combinedStatRequestTask?.cancel()
        
        combinedStatRequestTask = Task {
            if let fetchCombinedStat = try? await CombinedStatRequest().send() {
                self.model.userStats = fetchCombinedStat.userStat
                self.model.habitStats = fetchCombinedStat.habitStat
            } else {
                self.model.userStats = []
                self.model.habitStats = []
            }
            self.updateCollectionview()
            combinedStatRequestTask = nil
        }
    }
    
    
    func createDataSource() -> DataSourceType {
        
        let somedatasource = DataSourceType(collectionView: collectionView) { collectionView, indexPath, itemIdentifier in
            
            switch itemIdentifier {
            case .leaderboardHabit(name: let name, leadingUserRanking: let leadingUserRanking, secondaryUserRanking: let secondaryUserRanking):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "LeaderboardHabit", for: indexPath) as! LeaderboardHabitCollectionViewCell
                print("flag after deque leaderboard cell")  // не выводится 0_о
                cell.habitNameLabel.text = name
                cell.leaderLabel.text = leadingUserRanking
                cell.secondaryLabel.text = secondaryUserRanking
                return cell
                
            default: return nil
            }
        }
        
        
        return somedatasource
    }
    
    
    func createLayout() -> UICollectionViewCompositionalLayout {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, layoutEnvironment in
            print("closure layout")
            switch self.datasource.snapshot().sectionIdentifiers[sectionIndex] {
            case .leaderboard:
                let leaderboardItem = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(0.3)))
                print("case leader - closure")
                let verticalTrioSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.75), heightDimension: .fractionalWidth(0.75))
                let leaderboardVerticalTrio = NSCollectionLayoutGroup.vertical(layoutSize: verticalTrioSize, repeatingSubitem: leaderboardItem, count: 3)
                leaderboardVerticalTrio.interItemSpacing = .fixed(10)
                
                let leaderboardSection = NSCollectionLayoutSection(group: leaderboardVerticalTrio)
                leaderboardSection.interGroupSpacing = 20
                leaderboardSection.orthogonalScrollingBehavior = .continuous
                leaderboardSection.contentInsets = .init(top: 12, leading: 20, bottom: 20, trailing: 20)
                
                return leaderboardSection
                
            default: return nil
            }
        }
        
        
        return layout
    }
    
    
    static let formatter: NumberFormatter = {
        // используется в третьем замыкании updateCollectionview
        var f = NumberFormatter()
        f.numberStyle = .ordinal
        return f
    }()
    
    func ordinalString(from number: Int) -> String {
        // сдвигаем сабскрипты на 1, тк будет выводится  YOur are 1st, 2nd и тд
        // используется в третьем замыкании updateCollectionview
        return Self.formatter.string(from: NSNumber(integerLiteral: number + 1))!
    }
    
    
}
