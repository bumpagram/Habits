//  HomeCollectionViewController.swift
//  Habits
//  Created by bumpagram on 9/6/24.

import UIKit


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
        var habitStatistics = [HabitStatistics]()
        var userStatistics = [UserStatistics]()
        
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
        
        SupplementaryView.allCases.forEach { $0.nowRegister(this: collectionView)  }  // supplementary view can register themselves.  collectionView = internal property of current Class
        
        
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
        
        let leaderboardItems = model.habitStatistics.filter { stat in
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
        var itemsBySection = [ViewModel.Section.leaderboard: leaderboardItems]
        //--------------------------------------------//
        
        var followedUserItems = [ViewModel.Item]()
        
        // Get the current user's logged habits and extract the favorites
        let currentuserLoggedHabits = loggedHabitNames(for: model.currentuser)
        let favoriteLoggedHabits = Set(model.favoriteHabits.map { $0.name }).intersection(currentuserLoggedHabits) // ищет совпадения элементов 2х множеств и возвращает их
        
        for somefollowedUser in model.followedUsers.sorted(by: { $0.name < $1.name }) {
            let message: String
            let followedUserLoggedhabits = loggedHabitNames(for: somefollowedUser)
            // If the users have a habit in common:
            let existedCommon = followedUserLoggedhabits.intersection(currentuserLoggedHabits)
            if existedCommon.count > 0 {
                // Pick the habit to focus on
                let habitName: String
                let commonFavLogHabits = favoriteLoggedHabits.intersection(existedCommon)
                if commonFavLogHabits.count > 0 {
                    habitName = commonFavLogHabits.sorted().first!
                } else {
                    habitName = existedCommon.sorted().first!
                }
                // Get the full statistics (all the user counts) for that habit
                let habitStats = model.habitStatistics.first { $0.habit.name == habitName }!
                // Get the ranking for each user
                let rankedUserCounts = habitStats.userCounts.sorted { $0.count > $1.count }
                let currentUserRank = rankedUserCounts.firstIndex { $0.user == model.currentuser}!
                let followedUserRank = rankedUserCounts.firstIndex { $0.user == somefollowedUser }!
                // Construct the message depending on who's leading
                if currentUserRank < followedUserRank {
                    message = "Currently \(ordinalString(from: followedUserRank)), behind you \(ordinalString(from: currentUserRank)) in \(habitName).\n Send them a friendly reminder!"
                } else if currentUserRank > followedUserRank {
                    message = "Currently \(ordinalString(from: followedUserRank)), ahead of you \(ordinalString(from: currentUserRank)) in \(habitName).\n You might catch up with a little extra effort!"
                } else {
                    message = "You're tied at \(ordinalString(from: followedUserRank)) in \(habitName)! Now's your chance to pull ahead"
                }
                
            } else if followedUserLoggedhabits.count > 0 {
                // Otherwise, if the followed user has logged at least one habit:
                let habitName = followedUserLoggedhabits.sorted().first!
                // Get the full statistics (all the user counts) for that habit
                let habitStats = model.habitStatistics.first { $0.habit.name == habitName }!
                // Get the user's ranking for that habit
                let rankedUserCounts = habitStats.userCounts.sorted { $0.count > $1.count }
                let followedUserRank = rankedUserCounts.firstIndex { $0.user == somefollowedUser }!
                // Construct the message
                message = "Currently \(ordinalString(from: followedUserRank)), in \(habitName).\n Mabye you should give this habit a look"
            } else {
                // Otherwise, this user hasn't done anything
                message = "This user dousent seem to have done much yet. Check in to see if they need any help getting started"
            }
            
            followedUserItems.append(.followedUser(somefollowedUser, message: message))
            
        } // end for
        
        
        arrayOfSectionIDs.append(.followedUsers)
        itemsBySection[.followedUsers] = followedUserItems
        
        // and finally update snapshot
        datasource.applySnapshotUsing(sectionIDs: arrayOfSectionIDs, itemsBySection: itemsBySection)
    }
    
    
    func updateData() {
        combinedStatRequestTask?.cancel()
        
        combinedStatRequestTask = Task {
            if let fetchCombinedStat = try? await CombinedStatRequest().send() {
                self.model.userStatistics = fetchCombinedStat.userStatistics
                self.model.habitStatistics = fetchCombinedStat.habitStatistics
            } else {
                self.model.userStatistics = []
                self.model.habitStatistics = []
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
                cell.habitNameLabel.text = name
                cell.leaderLabel.text = leadingUserRanking
                cell.secondaryLabel.text = secondaryUserRanking
                return cell
                
            case .followedUser(let user, message: let message):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FollowedUser", for: indexPath) as! FollowedUserCollectionViewCell
                cell.primaryTextLabel.text = user.name
                cell.secondaryTextLabel.text = message
                return cell
                
            }
        }
        
        
        somedatasource.supplementaryViewProvider = .some({ collectionView, elementKind, indexPath in
            /* для конфига и создания supplementaryViews (header или footer)
             “Note that you don't handle the .leaderboardBackground case; that's because decoration views provide visual adornments to a section or to the entire collection view but are not otherwise tied to the data provided by the collection view’s data source.
            */
            guard let thisKind = SupplementaryView(rawValue: elementKind) else {return nil}
            let someview = collectionView.dequeueReusableSupplementaryView(ofKind: thisKind.viewKind, withReuseIdentifier: thisKind.reuseIdentifier, for: indexPath)
            
            switch thisKind {
            case .leaderboardSectionHeader:
                let header = someview as! NamedSectionHeaderView
                header.nameLabel.text = "Leaderboard"
                header.nameLabel.font = UIFont.preferredFont(forTextStyle: .largeTitle)
                header.alignLabelToTop()
                return header
                
            case .followedUsersSectionHeader:
                let header = someview as! NamedSectionHeaderView
                header.nameLabel.text = "Following"
                header.nameLabel.font = UIFont.preferredFont(forTextStyle: .title2)
                header.alignLabelToYCenter()
                return header
                
            default: return nil
            }
            
        })
        
        
        return somedatasource
    }
    
    
    func createLayout() -> UICollectionViewCompositionalLayout {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, layoutEnvironment in

            switch self.datasource.snapshot().sectionIdentifiers[sectionIndex] {
            case .leaderboard:
                let leaderboardItem = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(0.3)))
                
                let verticalTrioSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.75), heightDimension: .fractionalWidth(0.75))
                let leaderboardVerticalTrio = NSCollectionLayoutGroup.vertical(layoutSize: verticalTrioSize, repeatingSubitem: leaderboardItem, count: 3)
                leaderboardVerticalTrio.interItemSpacing = .fixed(10)
                
                let leaderboardSection = NSCollectionLayoutSection(group: leaderboardVerticalTrio)
                leaderboardSection.interGroupSpacing = 20
                leaderboardSection.orthogonalScrollingBehavior = .continuous
                leaderboardSection.contentInsets = .init(top: 12, leading: 20, bottom: 20, trailing: 20)
                
                let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(80)), elementKind: SupplementaryView.leaderboardSectionHeader.viewKind, alignment: .top)
                let background = NSCollectionLayoutDecorationItem.background(elementKind: SupplementaryView.leaderboardBackground.viewKind)
                leaderboardSection.boundarySupplementaryItems = [sectionHeader]
                leaderboardSection.decorationItems = [background]
                leaderboardSection.supplementariesFollowContentInsets = false
                
                return leaderboardSection
                
            case .followedUsers:
                let followItem = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(100)))
                
                let followGroup = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(100)), repeatingSubitem: followItem, count: 1)
                
                let followSection = NSCollectionLayoutSection(group: followGroup)
                
                let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(60)), elementKind: SupplementaryView.followedUsersSectionHeader.viewKind, alignment: .top)
                followSection.boundarySupplementaryItems = [header]
                
                return followSection
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
    
    func loggedHabitNames(for this: User) -> Set<String> {
        // “a helper function that returns a set of the habit names that a user has logged. ” used in updateCollectionview()
        var names = [String]()
        if let stats = model.userStatistics.first(where: {
            $0.user == this
        }) {
            names = stats.habitCounts.map({
                $0.habit.name
            })
        }
        
        
        return Set(names)
    }
    
    
}



enum SupplementaryItemType {
    /*
     “to distinguish between the two different methods for registering supplementary views. The most common way is registering supplementary views with the collection view, which you're already familiar with. However, you must register decoration views that you create in compositional layouts with the layout itself.
     */
    case collectionSuppView
    case layoutDecorationView
}


protocol SupplementaryItem {
    /* “provides everything you need to write generic code to register supplementary items”
     “You'll notice that the ViewClass associated type enables you to register a class whose type you don't know, because you've restricted it to be a subclass of UICollectionReusableView, which is the requirement of register(_:forDecorationViewOfKind:) and register(_:forSupplementaryViewOfKind:).
     */
    
    associatedtype ViewClass: UICollectionReusableView
    var itemType: SupplementaryItemType {get}
    var reuseIdentifier: String {get}
    var viewKind: String {get}
    var viewClass: ViewClass.Type {get}
}


extension SupplementaryItem {
    // func for registering supplementary items
    func nowRegister(this: UICollectionView) {
        switch itemType {
        case .collectionSuppView:
            this.register(viewClass.self, forSupplementaryViewOfKind: viewKind, withReuseIdentifier: reuseIdentifier)
            
        case .layoutDecorationView:
            this.collectionViewLayout.register(viewClass.self, forDecorationViewOfKind: viewKind)
        }
    }
}


enum SupplementaryView: String, CaseIterable, SupplementaryItem {
    
    /*
     “The home screen will include section headers for the leaderboard and followed users as well as a background decoration view for the leaderboard and a background for each group of three leaderboard items. Declare a new enum for all these new views that adopts the new protocol you just created.”
     CaseIterable - чтобы можно было собрать все case в .allCases массив
     String = rawValue для исчисляемых свойств
     SupplementaryItem = соответствие этому протоколу чтобы в замыкании методы и проперти юзать
     */
    case leaderboardSectionHeader
    case leaderboardBackground
    case followedUsersSectionHeader
    
    var reuseIdentifier: String { rawValue }
    var viewKind: String { rawValue }
    
    var viewClass: UICollectionReusableView.Type {
        switch self {
        case .leaderboardBackground: return SectionBackgroundView.self
        default: return NamedSectionHeaderView.self
        }
    }
    
    var itemType: SupplementaryItemType {
        switch self {
        case .leaderboardBackground: return .layoutDecorationView
        default: return .collectionSuppView
        }
    }
    
}



class SectionBackgroundView: UICollectionReusableView {
    override func didMoveToSuperview() {
        backgroundColor = .systemGray6
    }
}
