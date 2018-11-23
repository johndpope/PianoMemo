//
//  GuideTableViewController.swift
//  Piano
//
//  Created by hoemoon on 23/11/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit

class GuideTableViewController: UITableViewController {
    struct Item {
        let image: UIImage?
        let title: String

        init(image: UIImage? = nil, title: String) {
            self.image = image
            self.title = title
        }
    }

    let items = [
        [Item(title: "체크 리스트"), Item(title: "이모지 태그")],
        [Item(title: "피아노 효과"), Item(title: "헤드라인 변경"), Item(title: "손쉬운 복사/삭제")],
        [Item(title: "캘린더 등록"), Item(title: "미리알림 등록"), Item(title: "잠금화면 알림")],
        [Item(title: "꽉찬 메모 작성"), Item(title: "메모 합치기"), Item(title: "메모 내보내기")]
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        clearsSelectionOnViewWillAppear = true
        tableView.tableFooterView = UIView()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return items.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items[section].count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "GuideCell", for: indexPath) as? GuideCell {
            let item = items[indexPath.section][indexPath.row]
            cell.guideIcon.image = item.image
            cell.label.text = item.title
            return cell
        }
        return UITableViewCell()
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath {
        case IndexPath(row: 0, section: 0):
            print()
        case IndexPath(row: 1, section: 0):
            performSegue(withIdentifier: "emojiTag", sender: nil)
        case IndexPath(row: 0, section: 1):
            print()
        case IndexPath(row: 1, section: 1):
            print()
        case IndexPath(row: 2, section: 1):
            print()
        case IndexPath(row: 0, section: 2):
            print()
        case IndexPath(row: 1, section: 2):
            print()
        case IndexPath(row: 2, section: 2):
            print()
        case IndexPath(row: 0, section: 3):
            print()
        case IndexPath(row: 1, section: 3):
            print()
        case IndexPath(row: 2, section: 3):
            print()
        default:
            break
        }
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = UIColor(red:0.94, green:0.94, blue:0.95, alpha:1.00)
        return view
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 0:
            return CGFloat(41)
        default:
            return CGFloat(33)
        }
    }
}
