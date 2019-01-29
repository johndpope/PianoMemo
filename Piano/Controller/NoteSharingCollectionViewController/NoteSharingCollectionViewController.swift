//
//  NoteSharingCollectionViewController.swift
//  Piano
//
//  Created by Kevin Kim on 24/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import UIKit
/**
 전체 복사
 이미지로 복사
 PDF로 복사
 */
class NoteSharingCollectionViewController: UICollectionViewController {
    enum NoteSharingType {
        case clipboard
        case image
        case pdf
    }

    weak var blockTableVC: BlockTableViewController?
    var note: Note!
    var dataSource: [[NoteSharingType]] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
        setupDataSource()

    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let des = segue.destination as? ImagePreviewViewController {
            des.note = note
            return
        }

        if let des = segue.destination as? PDFPreviewViewController {
            des.note = note
            return
        }
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return dataSource.count
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource[section].count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: NoteSharingCollectionViewCell.reuseIdentifier,
            for: indexPath) as? NoteSharingCollectionViewCell
            else { return UICollectionViewCell() }

        cell.data = dataSource[indexPath.section][indexPath.item]
        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let type = dataSource[indexPath.section][indexPath.item]
        switch type {
        case .clipboard:
            UIPasteboard.general.string = note.content
            dismiss(animated: true, completion: nil)
            blockTableVC?.transparentNavigationController?.show(message: "✨Copied Successfully✨".loc, color: Color(red: 52/255, green: 120/255, blue: 246/255, alpha: 0.85))
        case .image:
            performSegue(withIdentifier: ImagePreviewViewController.identifier, sender: nil)
        case .pdf:
            performSegue(withIdentifier: PDFPreviewViewController.identifier, sender: nil)
        }
    }
}
