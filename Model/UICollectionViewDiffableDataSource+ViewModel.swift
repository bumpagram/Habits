//  UICollectionViewDiffableDataSource+ViewModel.swift
//  Habits
//  Created by bumpagram on 11/6/24.

import UIKit

extension UICollectionViewDiffableDataSource {
    
    func applySnapshotUsing(sectionIDs: [SectionIdentifierType], itemsBySection: [SectionIdentifierType: [ItemIdentifierType]], sectionsRetainedIfEmpty: Set<SectionIdentifierType> = Set<SectionIdentifierType>() ) {
        /* вызываем в этой функции другую функцию почти такую же, передавая насквозь аргументы
         “You'll be able to call the methods in this extension from all your view controllers, provided you construct an array of section identifiers and a dictionary mapping them to arrays of items. The additional parameters control whether to animate the updates and whether sections that have no items appear in the snapshot or are skipped (the default is to skip them).
         */
        applySnapshotUsing(sectionIDs: sectionIDs, itemsBySection: itemsBySection, animatingDiff: true, sectionsRetainedIfEmpty: sectionsRetainedIfEmpty)
    }
    
    
    func applySnapshotUsing(sectionIDs: [SectionIdentifierType], itemsBySection: [SectionIdentifierType: [ItemIdentifierType]], animatingDiff: Bool, sectionsRetainedIfEmpty: Set<SectionIdentifierType> = Set<SectionIdentifierType>() ) {
        
        var snapshot = NSDiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>()
        
        for someID in sectionIDs {
            guard let sectionItems = itemsBySection[someID], sectionItems.count > 0
                    || sectionsRetainedIfEmpty.contains(someID) else { continue }
            snapshot.appendSections([someID])
            snapshot.appendItems(sectionItems, toSection: someID)
        }
        
        self.apply(snapshot, animatingDifferences: animatingDiff)
    }
    
}
