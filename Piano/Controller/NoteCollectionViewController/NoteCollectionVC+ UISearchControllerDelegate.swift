//
//  NoteCollectionVC+ UISearchControllerDelegate.swift
//  Piano
//
//  Created by hoemoon on 02/02/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import UIKit
import CoreData

extension NoteCollectionViewController: UISearchControllerDelegate {
    func willDismissSearchController(_ searchController: UISearchController) {
        NSFetchedResultsController<Note>.deleteCache(withName: noteCollectionState.cache)
        setResultsController(state: noteCollectionState)
    }
}
