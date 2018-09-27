//
//  NoteCollectionViewCell.swift
//  Piano
//
//  Created by Kevin Kim on 2018. 8. 20..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit

extension Note: CollectionDatable {
    
    internal func size(view: View) -> CGSize {
        let safeWidth = view.bounds.width - (view.safeAreaInsets.left + view.safeAreaInsets.right)
        let headHeight = NSAttributedString(string: "0123456789", attributes: [.font : Font.preferredFont(forTextStyle: .headline)]).size().height
        let subHeadHeight = NSAttributedString(string: "0123456789", attributes: [.font : Font.preferredFont(forTextStyle: .subheadline)]).size().height
        let dateHeight = NSAttributedString(string: "0123456789", attributes: [.font : Font.preferredFont(forTextStyle: .caption2)]).size().height
        let margin: CGFloat = 8
        let spacing: CGFloat = 4
        let totalHeight = headHeight + subHeadHeight + dateHeight + margin * 2 + spacing * 2
        var cellCount: CGFloat = 3
        if safeWidth > 414 {
            let widthOne = (safeWidth - (cellCount + 1) * margin) / cellCount
            if widthOne > 320 {
                return CGSize(width: widthOne, height: totalHeight)
            }
            
            cellCount = 2
            let widthTwo = (safeWidth - (cellCount + 1) * margin) / cellCount
            if widthTwo > 320 {
                return CGSize(width: widthTwo, height: totalHeight)
            }
        }
        cellCount = 1
        return CGSize(width: (safeWidth - (cellCount + 1) * margin), height: totalHeight)
    }
    
    var headerSize: CGSize {
        return sectionTitle != nil ? CGSize(width: 100, height: 40) : CGSize(width: 100, height: 0)
    }
    
    func didSelectItem(collectionView: CollectionView, fromVC viewController: ViewController) {
        guard let mainVC = viewController as? MainViewController else { return }
        
        if collectionView.allowsMultipleSelection {
            mainVC.navigationItem.leftBarButtonItem?.isEnabled = (collectionView.indexPathsForSelectedItems?.count ?? 0 ) != 0
            
        } else {
            mainVC.performSegue(withIdentifier: DetailViewController.identifier, sender: self)
        }
    }
    
    func didDeselectItem(collectionView: CollectionView, fromVC viewController: ViewController) {
        if collectionView.allowsMultipleSelection {
            viewController.navigationItem.leftBarButtonItem?.isEnabled = (collectionView.indexPathsForSelectedItems?.count ?? 0 ) != 0   
        }
    }
    
    
}

class NoteCell: UICollectionViewCell, CollectionDataAcceptable {
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var shareImageView: UIImageView!
    @IBOutlet weak var baseView: UIView!
    
    var data: CollectionDatable? {
        didSet {
            guard let note = self.data as? Note else { return }
            
            if let date = note.modifiedDate {
                dateLabel.text = DateFormatter.sharedInstance.string(from: date)
                if Calendar.current.isDateInToday(date) {
                    dateLabel.textColor = Color.point
                } else {
                    dateLabel.textColor = Color.lightGray
                }
            }
            
            shareImageView.isHidden = note.record()?.share == nil
            
            
            guard let content = note.content else { return }
            var strArray = content.split(separator: "\n").compactMap { return $0.count != 0 ? $0 : nil }
            
            guard strArray.count != 0 else {
                titleLabel.text = "제목 없음".loc
                contentLabel.text = "추가 텍스트 없음".loc
                return
            }
            
            var firstStrSequence = strArray.removeFirst()
            firstStrSequence.removeCharacters(strings: [Preference.idealistKey, Preference.firstlistKey, Preference.secondlistKey, Preference.checklistOnKey, Preference.checklistOffKey])
            let firstStr = String(firstStrSequence)
            
            if firstStr.trimmingCharacters(in: .whitespacesAndNewlines).count != 0 {
                let firstLabelLimit = 50
                titleLabel.text = firstStr.count < firstLabelLimit ? firstStr : (firstStr as NSString).substring(with: NSMakeRange(0, firstLabelLimit))
            } else {
                titleLabel.text = "제목 없음".loc
            }
            
            guard strArray.count != 0 else {
                contentLabel.text = "추가 텍스트 없음".loc
                return
            }
            
            let secondLabelLimit = 50
            var secondStr: Substring = ""
            while strArray.count != 0,  secondStr.count < secondLabelLimit {
                var strSequence = strArray.removeFirst() + Substring(" ")
                strSequence.removeCharacters(strings: [Preference.secondlistKey, Preference.firstlistKey, Preference.idealistKey, Preference.checklistOffKey, Preference.checklistOnKey])
                
                secondStr += strSequence
            }
            
            if secondStr.trimmingCharacters(in: .whitespacesAndNewlines).count != 0 {
                contentLabel.text = String(secondStr)
            } else {
                contentLabel.text = "추가 텍스트 없음".loc
            }
        }
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        selectedBackgroundView = customSelectedBackgroudView
    }
    
    var customSelectedBackgroudView: UIView {
        let view = UIView()
        view.backgroundColor = Color.selected
        view.cornerRadius = 15
        return view
    }

    
}
