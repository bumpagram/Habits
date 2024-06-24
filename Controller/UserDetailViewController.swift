//  UserDetailViewController.swift
//  Habits
//  Created by bumpagram on 10/6/24.

import UIKit

class UserDetailViewController: UIViewController, UICollectionViewDelegate {
    
    @IBOutlet var profileImageView: UIImageView!
    @IBOutlet var usernameLabel: UILabel!
    @IBOutlet var bioLabel: UILabel!
    @IBOutlet var collectionview: UICollectionView!
    
    typealias DataSourceType = UICollectionViewDiffableDataSource<ViewModel.Section, ViewModel.Item>
    
    enum SectionHeader: String {
        // собрал просто в одном месте, чтобы руками не прописывать каждый раз
        case kind = "SectionHeader"
        case reuse = "HeaderView"
        var identifier: String {
            return rawValue // исчесляемое свойство, работает для всех case
        }
    }
    
    enum ViewModel {
        typealias Item = HabitCount
        enum Section: Hashable, Comparable {
            case leading
            case category(_ some: Category)
            
            var sectionColor: UIColor {
                switch self{
                case .leading: return .systemGray4
                case .category(let somecategory): return somecategory.color.uiColor
                }
            }
            
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
        var userStatistics: UserStatistics?
        var leadingStats: UserStatistics?
    }
    
    var user: User! // main property to handle and display
    var datasource: DataSourceType!
    var model = Model()
    //Keep track of async tasks so they can be cancelled when appropriate
    var imageRequestTask: Task<Void, Never>? = nil  // will be used later
    var userStatRequestTask: Task<Void, Never>? = nil
    var habitLeadStatRequestTask: Task<Void, Never>? = nil
    // set up timed api polling for this detail screen as well
    var updateTimer: Timer?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        usernameLabel.text = user.name
        bioLabel.text = user.bio
        collectionview.register(NamedSectionHeaderView.self, forSupplementaryViewOfKind: SectionHeader.kind.identifier, withReuseIdentifier: SectionHeader.reuse.identifier)
        
        // to populate data source
        datasource = createDatasource()  // создали источник данных DiffableDataSource
        collectionview.dataSource = datasource // назначили его из проперти в аутлет-> верстка
        collectionview.collectionViewLayout = createLayout()
        updateData()
        
        imageRequestTask = Task {
            // “it's enough to send image request once, since you can assume user profile images will change rarely.”
            if let fetchedImage = try? await ImageRequest(imageID: user.id).send() {
                self.profileImageView.image = fetchedImage
            }
            imageRequestTask = nil
        }
        
        collectionview.delegate = self
        // корневая view,если не сделать доп настройки то закрасит вообще всё что надо и не надо, втч navigationBar, tabBar, system top
        view.backgroundColor = user.color?.uiColor ?? .white
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.backgroundColor = .quaternarySystemFill
        tabBarController?.tabBar.scrollEdgeAppearance = tabBarAppearance
        let navBarApperance = UINavigationBarAppearance()
        navBarApperance.backgroundColor = .quaternarySystemFill
        navigationItem.scrollEdgeAppearance = navBarApperance
    }
    
    
    init?(coder: NSCoder, user: User) { // to enable segue action from HabitCollection VC
        super.init(coder: coder)
        self.user = user
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    deinit {
        imageRequestTask?.cancel()
        userStatRequestTask?.cancel()
        habitLeadStatRequestTask?.cancel()
    }
    
        
    func updateData() {
        // “data-fetching code. This time, you'll be issuing two requests independently. Each time you get a result back, you'll update your collection view.
        
        userStatRequestTask?.cancel()
        userStatRequestTask = Task {
            if let askServerUserStats = try? await UserStatisticsRequest(userIDs: [user.id]).send(),
               askServerUserStats.count > 0 {
                self.model.userStatistics = askServerUserStats[0]
            } else {
                self.model.userStatistics = nil
            }
            
            self.updateCollectionView()
            userStatRequestTask = nil
        }
       
        
        habitLeadStatRequestTask?.cancel()
        habitLeadStatRequestTask = Task {
            if let askServerUserStats = try? await HabitLeadStatRequest(userID: user.id).send() {
                self.model.leadingStats = askServerUserStats
            } else {
                self.model.leadingStats = nil
            }
            
            self.updateCollectionView()
            habitLeadStatRequestTask = nil
        }
        
    }
        
    
    func updateCollectionView() {
        // to setup your viewmodel and apply snapshot.  Ведомый метод для updateData().
        guard let someUserStats = model.userStatistics, let someLeadStats = model.leadingStats  else {return}
        
        var itemsBySection = someUserStats.habitCounts.reduce(into: [ViewModel.Section: [ViewModel.Item]]())  { partialResult, someHabitCount in
            let someSection: ViewModel.Section
            
            if someLeadStats.habitCounts.contains(someHabitCount) {
                someSection = .leading
            } else {
                someSection = .category(someHabitCount.habit.category)
            }
            partialResult[someSection, default: []].append(someHabitCount)
        }
        
        itemsBySection = itemsBySection.mapValues({    $0.sorted()   })
        
        let sortedIDs = itemsBySection.keys.sorted()
        datasource.applySnapshotUsing(sectionIDs: sortedIDs, itemsBySection: itemsBySection)
    }
        
    
    func createDatasource() -> DataSourceType {
        let someDatasource = DataSourceType(collectionView: collectionview) { collectionView, indexPath, itemIdentifier in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "HabitCount", for: indexPath) as! UICollectionViewListCell
            
            var content = UIListContentConfiguration.subtitleCell()
            content.text = itemIdentifier.habit.name
            content.secondaryText = "\(itemIdentifier.count)"
            content.prefersSideBySideTextAndSecondaryText = true
            content.textProperties.font = .preferredFont(forTextStyle: .headline)
            content.secondaryTextProperties.font = .preferredFont(forTextStyle: .body)
            cell.contentConfiguration = content
            return cell
        }
        
        someDatasource.supplementaryViewProvider = .some({ collectionView, elementKind, indexPath in
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: SectionHeader.kind.identifier, withReuseIdentifier: SectionHeader.reuse.identifier, for: indexPath) as! NamedSectionHeaderView
            let section = someDatasource.snapshot().sectionIdentifiers[indexPath.section]
            
            switch section {
            case .leading: header.nameLabel.text = "Leading"
            case .category(let somecategory): header.nameLabel.text = somecategory.name
            }
            
            header.backgroundColor = section.sectionColor
            return header
        })
        
        
        return someDatasource
    }
    
    
    func createLayout()-> UICollectionViewCompositionalLayout {
        // верстка с section header'ами
        let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1)))
        item.contentInsets = .init(top: 0, leading: 0, bottom: 0, trailing: 12)
        
        let groupsize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(44))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupsize, repeatingSubitem: item, count: 1)
        
        let sectionheader = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(36)), elementKind: SectionHeader.kind.identifier, alignment: .top)
        sectionheader.pinToVisibleBounds = true
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = .init(top: 20, leading: 0, bottom: 20, trailing: 0)
        section.boundarySupplementaryItems = [sectionheader]
        
        return UICollectionViewCompositionalLayout(section: section)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateData() // обновить данные экрана перед показом в первый раз
        updateTimer = .scheduledTimer(withTimeInterval: 3, repeats: true, block: { _ in
            self.updateData()  // вызываем функцию на обновление данных с сервака каждый TimeInterval (3 сек)
        })
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        updateTimer?.invalidate()  // ушли с экрана= сбросили и обнулили регулярные запросы к серверу на обновление данных
        updateTimer = nil
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // метод делегейта из протокола UICollectionViewDelegate, чтобы сбрасывать выделение ячейки при нажатии пользователя
        collectionView.deselectItem(at: indexPath, animated: true)
    }
    
}
