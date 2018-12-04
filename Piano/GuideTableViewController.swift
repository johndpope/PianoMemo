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

        init(title: String, imageName: String? = nil) {
            if let name = imageName {
                self.image = UIImage(named: name)?.withRenderingMode(.alwaysTemplate)

            } else {
                self.image = nil
            }
            self.title = title
        }
    }

    let items = [
        [Item(title: "체크 리스트".loc, imageName: "checklist"),
         Item(title: "이모지 태그".loc, imageName: "addTag")
        ],
        [Item(title: "피아노 효과".loc, imageName: "highlights"),
         Item(title: "헤드라인 변경".loc, imageName: "headline"),
         Item(title: "손쉬운 복사/삭제".loc, imageName: "trash")
        ],
        [Item(title: "캘린더 등록".loc, imageName: "calendar"),
         Item(title: "미리알림 등록".loc, imageName: "reminders"),
         Item(title: "잠금화면 알림".loc, imageName: "remind")
        ],
        [Item(title: "꽉찬 메모 작성".loc, imageName: "newMemo"),
         Item(title: "메모 합치기".loc, imageName: "merge"),
         Item(title: "메모 내보내기".loc, imageName: "copy")
        ]
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
            performSegue(withIdentifier: "checkList", sender: nil)
        case IndexPath(row: 1, section: 0):
            performSegue(withIdentifier: "emojiTag", sender: nil)
        case IndexPath(row: 0, section: 1):
            performSegue(withIdentifier: "pianoEffect", sender: nil)
        case IndexPath(row: 1, section: 1):
            performSegue(withIdentifier: "changeHeadline", sender: nil)
        case IndexPath(row: 2, section: 1):
            performSegue(withIdentifier: "easyCopy", sender: nil)
        case IndexPath(row: 0, section: 2):
            performSegue(withIdentifier: "registerCalendar", sender: nil)
        case IndexPath(row: 1, section: 2):
            performSegue(withIdentifier: "registerReminder", sender: nil)
        case IndexPath(row: 2, section: 2):
            performSegue(withIdentifier: "lockScreen", sender: nil)
        case IndexPath(row: 0, section: 3):
            performSegue(withIdentifier: "fullNote", sender: nil)
        case IndexPath(row: 1, section: 3):
            performSegue(withIdentifier: "mergeNote", sender: nil)
        case IndexPath(row: 2, section: 3):
            performSegue(withIdentifier: "exportNote", sender: nil)
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
