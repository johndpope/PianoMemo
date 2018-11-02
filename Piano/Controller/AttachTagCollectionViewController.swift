//
//  AttachTagCollectionViewController.swift
//  Piano
//
//  Created by Kevin Kim on 12/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit

class AttachTagCollectionViewController: UICollectionViewController, CollectionRegisterable {

    var note: Note!
    weak var detailVC: Detail2ViewController?
    weak var storageService: StorageService!
    private var collectionables: [[Collectionable]] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        registerCell(StringCell.self)
        collectionView.allowsMultipleSelection = true
        (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.sectionHeadersPinToVisibleBounds = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(invalidLayout), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
        
        collectionables = []
        collectionables.append(storageService.local.emojiTags)
        collectionView.reloadData()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let des = segue.destination as? TagPickerViewController {
            des.storageService = storageService
            return
        }
        
        if let des = segue.destination as? UINavigationController,
            let vc = des.topViewController as? TagPickerViewController {
            vc.storageService = storageService
            return
        }
    }

    
    @objc private func invalidLayout() {
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard let tags = note.tags else { return }
        collectionables.enumerated().forEach { (section, datas) in
            datas.enumerated().forEach({ (item, data) in
                guard let str = data as? String else { return }
                if tags.contains(str) {
                    let indexPath = IndexPath(item: item, section: section)
                    collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .bottom)
                }
            })
        }
    }
    
    @IBAction func done(_ sender: Any) {
        if let indexPaths = collectionView.indexPathsForSelectedItems {
            let strs = indexPaths.reduce("") { (result, indexPath) -> String in
                guard let str = collectionables[indexPath.section][indexPath.item] as? String  else { return result }
                return result + str
            }
            
            storageService.local.update(note: note, tags: strs) { [weak self] in
                guard let self = self,
                    let detailVC = self.detailVC else { return }
                DispatchQueue.main.async {
                    detailVC.setupTagToNavItem()
                    self.dismiss(animated: true, completion: nil)
                }
            }
        } else {
            dismiss(animated: true, completion: nil)
        }
        
    }
    
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
        
    }

   
}

extension AttachTagCollectionViewController {
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let collectionable = collectionables[indexPath.section][indexPath.item]
        var cell = collectionView.dequeueReusableCell(withReuseIdentifier: collectionable.reuseIdentifier, for: indexPath) as! ViewModelAcceptable & UICollectionViewCell
        let viewModel = StringViewModel(string: collectionable as! String)
        cell.viewModel = viewModel
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collectionables[section].count
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return collectionables.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let reusableView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "ReusableView", for: indexPath)
        return reusableView
    }
}

extension AttachTagCollectionViewController {
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionables[indexPath.section][indexPath.item].didSelectItem(collectionView: collectionView, fromVC: self)
    }
    
    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        collectionables[indexPath.section][indexPath.item].didDeselectItem(collectionView: collectionView, fromVC: self)
    }
    
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        let count = collectionView.indexPathsForSelectedItems?.count ?? 0
        return count < 10
    }
}

extension AttachTagCollectionViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return collectionables.first?.first?.sectionInset(view: collectionView) ?? UIEdgeInsets.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionables[indexPath.section][indexPath.item].size(view: collectionView)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return collectionables.first?.first?.minimumLineSpacing ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return collectionables.first?.first?.minimumInteritemSpacing ?? 0
    }
}
