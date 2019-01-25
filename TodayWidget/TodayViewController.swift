//
//  TodayViewController.swift
//  TodayWidget
//
//  Created by hoemoon on 15/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

/// 1. context 생성 -> persistant
/// 2. Predicate 만들기
/// 3. 여기서 받아온 노트 그리기

import UIKit
import CoreData
import NotificationCenter

class TodayViewController: UIViewController, NCWidgetProviding {

    @IBOutlet weak var collectionView: UICollectionView!

    var notes: [[String: Any]] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.dataSource = self
        collectionView.delegate = self
    }

    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        let defaults = UserDefaults(suiteName: "group.piano.container")
        if let notes = defaults?.array(forKey: "recentNotes") as? [[String: Any]] {
            self.notes = notes
            self.collectionView.reloadData()
            completionHandler(NCUpdateResult.newData)
        }
        completionHandler(NCUpdateResult.failed)
    }

}

extension TodayViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let baseWidth = (self.collectionView.frame.size.width - 10) / 5.0
        let baseHeight = self.collectionView.frame.size.height
        if indexPath.row == 0 {
            return CGSize(width: baseWidth, height: baseHeight)
        }
        return CGSize(width: 2 * baseWidth, height: baseHeight)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return notes.count + 1
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.row == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NewNoteCell", for: indexPath)
            return cell
        }

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "WidgetNoteCell", for: indexPath) as! WidgetNoteCell
        let index = indexPath.row - 1
        cell.title.text = notes[index]["title"] as? String
        cell.subTitle.text = notes[index]["subTitle"] as? String
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            if let appURL = URL(string: "https://piano.app.link?action=create") {
                extensionContext?.open(appURL, completionHandler: nil)
            }
            return
        }
        let index = indexPath.row - 1
        if let noteId = notes[index]["id"] as? String,
            let appURL = URL(string: "https://piano.app.link?action=view&noteId=\(noteId)") {
            extensionContext?.open(appURL, completionHandler: nil)
        }
    }

    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        let highlightColor = indexPath.row == 0 ? UIColor.init(white: 0.7, alpha: 1) : UIColor.white
        collectionView.cellForItem(at: indexPath)?.contentView.backgroundColor = highlightColor
    }

    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        let normalColor = indexPath.row == 0 ? UIColor.white : UIColor.init(white: 1, alpha: 0.5)
        collectionView.cellForItem(at: indexPath)?.contentView.backgroundColor = normalColor
    }
}

class WidgetNoteCell: UICollectionViewCell {
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var subTitle: UILabel!
}
