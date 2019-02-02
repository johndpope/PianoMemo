//
//  NoteCollectionVC+UISearchResultsUpdating.swift
//  Piano
//
//  Created by hoemoon on 02/02/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import UIKit

extension NoteCollectionViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let input = searchController.searchBar.text else { return }
        filter(input)
    }

    private func filter(_ searchText: String) {
        let filter = FilterNoteOperation(controller: resultsController, noteCollectionState: noteCollectionState) { [weak self] in
            guard let self = self else { return }
            self.collectionView.reloadData()
        }
        filter.setKeyword(searchText)
        privateQueue.cancelAllOperations()
        privateQueue.addOperation(filter)
    }

    var isFiltering: Bool {
        return (searchController.searchBar.text?.count ?? 0) > 0
    }
}
