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
        performSegue(withIdentifier: DetailViewController.identifier, sender: note)
        
        DispatchQueue.main.async { [weak self] in
            self?.bottomView.textView.resignFirstResponder()
        }

    }
}
