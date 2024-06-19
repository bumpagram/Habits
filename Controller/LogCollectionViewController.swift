//  LogCollectionViewController.swift
//  Habits
//  Created by bumpagram on 10/6/24.

import UIKit

private let reuseIdentifier = "Cell"

class LogCollectionViewController: HabitCollectionViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        //self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        // createLayout вызывается в ViewDidLoad, но в HabitCollectionViewController, тк унаследовались от него
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
