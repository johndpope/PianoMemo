//
//  MainVC_CollectionViewDelegate.swift
//  Light
//
//  Created by Kevin Kim on 2018. 8. 28..
//  Copyright © 2018년 Piano. All rights reserved.
//

import Foundation

extension MainViewController: CollectionViewDelegate {
    func collectionView(_ collectionView: CollectionView, didSelectItemAt indexPath: IndexPath) {
        let note = resultsController.object(at: indexPath)
        performSegue(withIdentifier: DetailTabBarViewController.identifier, sender: note)
        
        DispatchQueue.main.async { [weak self] in
            collectionView.deselectItem(at: indexPath, animated: true)
            self?.bottomView.textView.resignFirstResponder()
        }

    }
}
