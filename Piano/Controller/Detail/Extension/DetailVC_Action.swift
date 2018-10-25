//
//  DetailVC_Action.swift
//  Light
//
//  Created by Kevin Kim on 2018. 9. 2..
//  Copyright © 2018년 Piano. All rights reserved.
//

import Foundation
import CoreGraphics
import UIKit
import ContactsUI
import CoreLocation

protocol ContainerDatasource {
    func reset()
    func startFetch()
    
}

extension DetailViewController {
    
    @objc func changeTag(_ sender: Any) {
        performSegue(withIdentifier: "AttachTagCollectionViewController", sender: nil)
    }

    internal func setNavigationItems(state: VCState){
        guard let note = note else { return }
        var btns: [BarButtonItem] = []
        self.state = state
        switch state {
        case .normal:
            let btn = BarButtonItem(image: note.isShared ? #imageLiteral(resourceName: "addPeople2") : #imageLiteral(resourceName: "addPeople"), style: .plain, target: self, action: #selector(addPeople(_:)))
            btns.append(btn)
            navigationItem.setLeftBarButtonItems(nil, animated: false)
        case .typing:
//            btns.append(BarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done(_:))))
            btns.append(BarButtonItem(image: note.isShared ? #imageLiteral(resourceName: "addPeople2") : #imageLiteral(resourceName: "addPeople"), style: .plain, target: self, action: #selector(addPeople(_:))))

            navigationItem.setLeftBarButtonItems(nil, animated: false)
        case .piano:
            let leftBtns = [BarButtonItem(title: "  ", style: .plain, target: nil, action: nil)]
            navigationController?.navigationItem.setLeftBarButtonItems(leftBtns, animated: false)
            navigationItem.setLeftBarButtonItems(leftBtns, animated: false)

        }
        setTitleView(state: state)
        navigationItem.setRightBarButtonItems(btns, animated: false)
    }
    
    internal func setTitleView(state: VCState) {
        guard let note = note else { return }
        switch state {
        case .piano:
            if let titleView = view.createSubviewIfNeeded(PianoTitleView.self) {
                titleView.set(text: "Swipe over the text you want to copy✨".loc)
                navigationItem.titleView = titleView
            }
            
        default:
            let tagButton = UIButton(type: .system)
            tagButton.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: 200, height: 44))
            tagButton.addTarget(self, action: #selector(changeTag(_:)), for: .touchUpInside)
            navigationItem.titleView = tagButton
            setTagToNavItem()
        }
    }
    
    @IBAction func restore(_ sender: Any) {
        guard let note = note else { return }
        storageService.local.restore(note: note) {}
        // dismiss(animated: true, completion: nil)
    }
    
    @IBAction func addPeople(_ sender: Any) {
        Feedback.success()
        guard let note = note,
            let item = sender as? UIBarButtonItem else {return}
        // TODO: 네트워크 불능이거나, 아직 업로드 안 된 경우 처리
        cloudSharingController(note: note, item: item) {
            [weak self] controller in
            if let self = self, let controller = controller {
                OperationQueue.main.addOperation {
                    self.present(controller, animated: true)
                }
            }
        }
    }
    
    
    @IBAction func tapAttachTag(_ sender: Any) {
        guard let _ = note else { return }
        performSegue(withIdentifier: AttachTagCollectionViewController.identifier, sender: nil)
    }

    
}

extension DetailViewController: CLLocationManagerDelegate {
    
}



