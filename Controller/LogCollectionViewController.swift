//  LogCollectionViewController.swift
//  Habits
//  Created by bumpagram on 10/6/24.

import UIKit


class LogCollectionViewController: HabitCollectionViewController {
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        // createLayout вызывается в ViewDidLoad, но в HabitCollectionViewController, тк унаследовались от него
        
    }
    
    
    override func configThisCell(_ cell: UICollectionViewListCell, withthis input: HabitCollectionViewController.ViewModel.Item) {
        /* вызывается в CreateDatasource() HabitCollection VC, унаследован. но чуть поправим под этот экран.
         “To make the Log Habit cells feel more like buttons, you can update the state of the cells when they are selected. UICollectionViewListCells can modify their configuration based on the state they are in. One way to do this is by providing a closure to the cell's configureUpdateHandler property. The cell will call this handler every time there is a change in state.”
         */
        
        cell.configurationUpdateHandler = .some({ somecell, state in
            // “You simply generate the complete configuration each time, and the system will take care of optimizing the display of the new state”
            
            var content = UIListContentConfiguration.cell()  // creates default config you use to style a cell in a list
            content.text = input.name
            content.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 11, leading: 8, bottom: 11, trailing: 8)
            content.textProperties.alignment = .center
            somecell.contentConfiguration = content
            
            var backgroundConfig = UIBackgroundConfiguration.clear()
            
            if Settings.shared.favoriteHabits.contains(input) {
                backgroundConfig.backgroundColor = favoriteHabitColor
            } else {
                backgroundConfig.backgroundColor = .systemGray6
            }
            
            if state.isHighlighted {
                // reduce alpha of tint color to 30$ whan highlighted
                backgroundConfig.backgroundColorTransformer = .init({ UIColor in
                    UIColor.withAlphaComponent(0.3)
                })
            }
            
            backgroundConfig.cornerRadius = 0
            somecell.backgroundConfiguration = backgroundConfig
        })
        
        cell.layer.shadowRadius = 3
        cell.layer.shadowColor = UIColor.systemGray3.cgColor
        cell.layer.shadowOffset = CGSize(width: 0, height: 2)
        cell.layer.shadowOpacity = 1
        cell.layer.masksToBounds = false
    }
    
    
    override func createLayout() -> UICollectionViewCompositionalLayout {
        /*
         “The key difference between this screen and the existing habit collection screen is its layout. To make recording favorite habits the smoothest possible process, you'll lay out those cells in a grid rather than in a list, making them larger touch targets. And you won't need a header for the top section, since it'll be clear that the top items are the favorites.
         */
        let layout: UICollectionViewCompositionalLayout = .init { sectionindex, environment in
            
            if sectionindex == 0 && self.model.favoriteHabits.count > 0 {
                // если в избранном что-то есть, тогда вывести это сеткой-квадратами по 2шт вверху экрана. это типо первая(нулевая) секция
                let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.45), heightDimension: .fractionalHeight(1)))
                item.contentInsets = .init(top: 12, leading: 12, bottom: 12, trailing: 12)
                
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(100)), repeatingSubitem: item, count: 2)
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = .init(top: 20, leading: 0, bottom: 20, trailing: 0)
                
                return section
                
            } else {
                // если в избранном ничего нет, то верстаем как обычно. сюда зайдем на всех секциях кроме нулевой.  верстаем группы высотой по 50 и на всю ширину.
                let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1)))
                
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(50)), repeatingSubitem: item, count: 2)
                group.interItemSpacing = .fixed(8)
                group.contentInsets =  NSDirectionalEdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10)
                
                let sectionheader = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(36)), elementKind: SectionHeader.kind.identifier, alignment: .top)
                sectionheader.edgeSpacing = .init(leading: nil, top: nil, trailing: nil, bottom: .fixed(40))
                sectionheader.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
                
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 20, leading: 0, bottom: 20, trailing: 0)
                section.boundarySupplementaryItems = [sectionheader]
                section.interGroupSpacing = 10
                
                return section
            }
            
            
        }
        return layout
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // to send API request, when user taps the cell
        collectionView.deselectItem(at: indexPath, animated: true)
        
        guard let someItem = datasource.itemIdentifier(for: indexPath) else {return}
        
        let someLog = LoggedHabit(userID: Settings.shared.currentUser.id, habitName: someItem.name, timestamp: Date())  // дата - init прямо сейчас когда нажали
        
        Task {
            try? await LogHabitRequest(loggedhabit: someLog).send()
        }
        /*
         “Notice that a reference to the task is not saved in this case, as there is no reason to try to cancel it. All requests to send the data to the server should continue to be tried until it succeeds or times out. (Of course, in a real-world example you would want to handle errors, so the user has the opportunity to submit their request again.) A new Task will be created each time a habit is logged.
         */
    }
    
    
}
