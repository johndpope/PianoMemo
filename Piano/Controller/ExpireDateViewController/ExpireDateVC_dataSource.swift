//
//  ExpireDateVC_dataSource.swift
//  Piano
//
//  Created by Kevin Kim on 23/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import Foundation

extension ExpireDateViewController : CollectionViewDataSource {
    func collectionView(_ collectionView: CollectionView, cellForItemAt indexPath: IndexPath) -> CollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ExpireDateCell.reuseIdentifier, for: indexPath) as? ExpireDateCell
            else { return CollectionViewCell() }
        cell.data = dataSource[indexPath.section][indexPath.item]
        return cell
    }
    
    func collectionView(_ collectionView: CollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource[section].count
    }
    
    func numberOfSections(in collectionView: CollectionView) -> Int {
        return dataSource.count
    }
}
