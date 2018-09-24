//
//  MainVC_CollectionViewDataSource.swift
//  Light
//
//  Created by Kevin Kim on 2018. 8. 28..
//  Copyright © 2018년 Piano. All rights reserved.
//

import Foundation
import CoreGraphics
import CloudKit


extension MainViewController: CollectionViewDataSource {
    func collectionView(_ collectionView: CollectionView, cellForItemAt indexPath: IndexPath) -> CollectionViewCell {
        
        let data = resultsController.object(at: indexPath)
        var cell = collectionView.dequeueReusableCell(withReuseIdentifier: data.reuseIdentifier, for: indexPath) as! CollectionDataAcceptable & CollectionViewCell
        cell.data = data
        return cell
    }
    
    func collectionView(_ collectionView: CollectionView, numberOfItemsInSection section: Int) -> Int {
        return resultsController.sections?[section].numberOfObjects ?? 0
    }
    
    func numberOfSections(in collectionView: CollectionView) -> Int {
        return resultsController.sections?.count ?? 0
    }
}
