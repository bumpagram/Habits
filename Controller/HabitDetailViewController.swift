//  HabitDetailViewController.swift
//  Habits
//  Created by bumpagram on 10/6/24.

import UIKit

class HabitDetailViewController: UIViewController {
    
    @IBOutlet var habitnameLabel: UILabel!
    @IBOutlet var categoryLabel: UILabel!
    @IBOutlet var infoLabel: UILabel!
    @IBOutlet var collectionview: UICollectionView!
    
    typealias DataSourceType = UICollectionViewDiffableDataSource<ViewModel.Section, ViewModel.Item>
    
    enum ViewModel {
        
        enum Section: Hashable {
            case leaders(count: Int)
            case remaining
        }
        
        enum Item: Hashable, Comparable {
            case single(_ stat: UserCount)
            case multi(_ stat: [UserCount])
            
            static func < (lhs: HabitDetailViewController.ViewModel.Item, rhs: HabitDetailViewController.ViewModel.Item) -> Bool {
                switch (lhs, rhs) {
                case (.single(let lCount), .single(let rCount)): return lCount.count < rCount.count
                case(.multi(let lCounts), .multi(let rCounts)): return lCounts.first!.count < rCounts.first!.count
                case (.single, .multi): return false
                case (.multi, .single): return true
                }
            }
            // “The Item view model type can represent a single user count or a collection of users. For now, you'll use it for a single user; later in the project, you'll use it to aggregate users who have the same number of log entries for the habit.”
        }
        
    }
    
    struct Model {
        var habitStatistics: HabitStatistics?
        var userCounts: [UserCount]  { habitStatistics?.userCounts ?? [] }
    }
    
    var datasource: DataSourceType!
    var model = Model()
    var habit: Habit! // “a property for the habit this view controller will handle”

    var currentWorkingTask: Task<Void, Never>? = nil  // контроллируем один текущий запрос, поэтому Task, а не TaskGroup
    var updateInfoTimer: Timer? // раз в некоторое время опрашиваем сервер, чтобы обновлять UI
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        habitnameLabel.text = habit.name
        categoryLabel.text = habit.category.name
        infoLabel.text = habit.info
        
        // и доп конфиги при загрузке экрана на данные и развертку
        datasource = createDatasource()
        collectionview.dataSource = datasource
        collectionview.collectionViewLayout = createLayout()
        updateData()
    }
    
    
    
    init?(coder: NSCoder, habit: Habit) {
        self.habit = habit
        super.init(coder: coder)
    }
    required init?(coder: NSCoder) { // требование компилятора, если пишешь кастомный failable init
        fatalError("init(coder:) has not been implemented")
    }
    deinit {
        currentWorkingTask?.cancel()
    }
    
    
    func updateData() {
        // fetch info from server
        currentWorkingTask?.cancel()
        currentWorkingTask = Task {
            
            if let requestedHabitStatisticsObject = try? await HabitStatisticsRequest(habitNames: [habit.name]).send(), requestedHabitStatisticsObject.count > 0 {
                self.model.habitStatistics = requestedHabitStatisticsObject[0]
                
            } else {
                self.model.habitStatistics = nil // если с сервера ничего не пришло
            }
            
            
            self.updateCollectionView()
            currentWorkingTask = nil
        }
    }
    
    
    func updateCollectionView() {
        // to set up your view model and apply a snapshot.
        // вложенная, вызывается в updateData()
        
        let items = ( self.model.habitStatistics?.userCounts.map{ViewModel.Item.single($0)}  ?? []).sorted(by: >)
        
        datasource.applySnapshotUsing(sectionIDs: [.remaining], itemsBySection: [.remaining: items])
    }
    
    
    func createDatasource() -> DataSourceType {
        // “to configure your cells with user count information.”
        
       let somedata = DataSourceType(collectionView: collectionview) { collectionView, indexPath, itemIdentifier in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "UserCount", for: indexPath) as! UICollectionViewListCell
            var content = UIListContentConfiguration.subtitleCell()
            content.prefersSideBySideTextAndSecondaryText = true
            
            /* хз, в учебнике было “collectionView, indexPath, grouping) ->
            UICollectionViewCell?”   а у меня такого метода нет, что есть grouping и откуда не знаю
             мб просто в свифте метод переделали, тк логика с grouping на itemIdentifier норм перекладывается.
             */
           switch itemIdentifier {
           case .single(let userStat):
               content.text = userStat.user.name
               content.secondaryText = "\(userStat.count)"
               content.textProperties.font = .preferredFont(forTextStyle: .headline)
               content.secondaryTextProperties.font = .preferredFont(forTextStyle: .body)
           default: break
           }
           
            cell.contentConfiguration = content
            return cell
        }
       
        
      return somedata
    }
    
    
    func createLayout() -> UICollectionViewCompositionalLayout {
        
        let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1)))
        
        let groupsize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(44))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupsize, repeatingSubitem: item, count: 1)
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = .init(top: 20, leading: 0, bottom: 20, trailing: 0)
        
        return UICollectionViewCompositionalLayout(section: section)
    }
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateData()
        updateInfoTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in
            // сам таймер нас не интересует, надо просто интерфейс обновлять
            self.updateData()
        })
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // нет смысла продолжать обновлять экран и стучаться через таймер в сервер, если с экрана ушел пользователь
        updateInfoTimer?.invalidate()  //останавливает Timer и запрашивает его вывод из RunLoop
        updateInfoTimer = nil
    }
    
    

}
