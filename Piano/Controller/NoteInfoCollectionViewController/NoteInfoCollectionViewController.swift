//
//  NoteInfoCollectionViewController.swift
//  Piano
//
//  Created by Kevin Kim on 24/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import UIKit

/**
 read: 생성일, 수정일, 글자 수, 문단 수, 체크리스트 수, 체크리스트 달성율, 폴더 정보, 폭파 시간
 write: 폴더 정보, 폭파 시간
*/
class NoteInfoCollectionViewController: UICollectionViewController {
    enum NoteInfoType {
        case creationDate
        case modifiedDate
        case characterCount
        case paragraphCount
        case checklistCount
        case checklistAchievementRate
        case folder
        case expireDate
    }

    struct NoteInfo {
        let type: NoteInfoType
        let note: Note
    }

    internal var note: Note!
    internal var noteHandler: NoteHandlable!
    var dataSource: [[NoteInfo]] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
        setupDataSource()
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return dataSource.count
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource[section].count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NoteInfoCollectionViewCell.reuseIdentifier, for: indexPath) as? NoteInfoCollectionViewCell else { return UICollectionViewCell() }
        cell.data = dataSource[indexPath.section][indexPath.item]
        return cell
    }

}
