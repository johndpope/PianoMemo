//
//  ExpireDateVC_delegate.swift
//  Piano
//
//  Created by Kevin Kim on 23/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import Foundation

extension ExpireDateViewController: CollectionViewDelegate {
    func collectionView(_ collectionView: CollectionView, didSelectItemAt indexPath: IndexPath) {
        let data = dataSource[indexPath.section][indexPath.item]
        datePicker.setDate(data.date, animated: true)
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}
