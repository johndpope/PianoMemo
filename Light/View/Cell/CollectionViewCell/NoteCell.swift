//
//  NoteCollectionViewCell.swift
//  Piano
//
//  Created by Kevin Kim on 2018. 8. 20..
//  Copyright © 2018년 Piano. All rights reserved.
//

import UIKit
import BiometricAuthentication

extension Note: Collectionable {
    
    var minimumLineSpacing: CGFloat { return 0 }
    
    func sectionInset(view: View) -> EdgeInsets {
        return EdgeInsets(top: 0, left: 8, bottom: 8, right: 8)
    }
    
    internal func size(view: View) -> CGSize {
        let width = view.bounds.width
        let headlineHeight = NSAttributedString(string: "0123456789", attributes: [.font : Font.preferredFont(forTextStyle: .headline)]).size().height
        let subheadlineHeight = NSAttributedString(string: "0123456789", attributes: [.font : Font.preferredFont(forTextStyle: .subheadline)]).size().height
        let dateHeight = NSAttributedString(string: "0123456789", attributes: [.font : Font.preferredFont(forTextStyle: .caption2)]).size().height
        let margin: CGFloat = minimumInteritemSpacing
        let spacing: CGFloat = 4
        let totalHeight = headlineHeight + subheadlineHeight + dateHeight + margin * 2 + spacing * 2
        var cellCount: CGFloat = 3
        if width > 414 {
            let widthOne = (width - (cellCount + 1) * margin) / cellCount
            if widthOne > 320 {
                return CGSize(width: widthOne, height: totalHeight)
            }
            
            cellCount = 2
            let widthTwo = (width - (cellCount + 1) * margin) / cellCount
            if widthTwo > 320 {
                return CGSize(width: widthTwo, height: totalHeight)
            }
        }
        cellCount = 1
        return CGSize(width: (width - (cellCount + 1) * margin), height: totalHeight)
    }
    
    func didSelectItem(collectionView: CollectionView, fromVC viewController: ViewController) {
        if let content = self.content, content.contains("🔒") {
            BioMetricAuthenticator.authenticateWithBioMetrics(reason: "", success: {
                // authentication success
                viewController.performSegue(withIdentifier: DetailViewController.identifier, sender: self)
                return
            }) { (error) in
                
                collectionView.indexPathsForSelectedItems?.forEach {
                    collectionView.deselectItem(at: $0, animated: true)
                }
                
                Alert.warning(from: viewController, title: "Authentication failure😭".loc, message: "Set up passcode from the ‘settings’ to unlock this note.".loc)
                
                // error
                print(error.message())
            }
        } else {
            viewController.performSegue(withIdentifier: DetailViewController.identifier, sender: self)
        }
    }
    
    func didDeselectItem(collectionView: CollectionView, fromVC viewController: ViewController) {
        if collectionView.allowsMultipleSelection {
            viewController.navigationItem.leftBarButtonItem?.isEnabled = (collectionView.indexPathsForSelectedItems?.count ?? 0 ) != 0
        }
    }
}

struct NoteViewModel: ViewModel {
    let note: Note
    let viewController: ViewController?
    
    init(note: Note, viewController: ViewController? = nil) {
        self.note = note
        self.viewController = viewController
    }
}

class NoteCell: UICollectionViewCell, ViewModelAcceptable {
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var shareLabel: UILabel!

    weak var refreshDelegate: UIRefreshDelegate!
    weak var syncController: Synchronizable!
    
    var viewModel: ViewModel? {
        didSet {
            backgroundColor = Color.white
            guard let noteViewModel = self.viewModel as? NoteViewModel else { return }
            let note = noteViewModel.note

            if let date = note.modifiedAt {
                dateLabel.text = DateFormatter.sharedInstance.string(from: date)
                if Calendar.current.isDateInToday(date) {
                    dateLabel.textColor = Color.point
                } else {
                    dateLabel.textColor = Color.lightGray
                }
            }
            
            titleLabel.text = note.title
            subTitleLabel.text = note.subTitle
            shareLabel.isHidden = !note.isShared
            
        }
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        selectedBackgroundView = customSelectedBackgroudView
    }
    
    
    var customSelectedBackgroudView: UIView {
        let view = UIView()
        view.backgroundColor = Color.selected
        //        view.cornerRadius = 15
        return view
    }
    
}

extension NoteCell: Refreshable, SyncControllable {
    
}
