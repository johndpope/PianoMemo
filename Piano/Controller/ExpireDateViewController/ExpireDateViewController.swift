//
//  ExpiredDateViewController.swift
//  Piano
//
//  Created by Kevin Kim on 23/01/2019.
//  Copyright © 2019 Piano. All rights reserved.
//

import UIKit

/*
 필요한 것: 노트, 노트 핸들러,
 동작: 셀을 선택하면 피커 값이 세팅된다.
 취소누르면 dismiss
 완료 누르면 피커 값이 세팅된다.
 */

class ExpireDateViewController: UIViewController {

    struct ExpireTime {
        let name: String
        let date: Date
    }

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var datePicker: UIDatePicker!
    var dataSource: [[ExpireTime]] = []
    weak var noteHandler: NoteHandlable!
    var note: Note!

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        setupDataSource()
    }
}
