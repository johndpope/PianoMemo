//
//  SecondListPickerViewController.swift
//  Piano
//
//  Created by Kevin Kim on 20/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit

class SecondListPickerViewController: UIViewController, CollectionRegisterable {
    internal var collectionables: [[Collectionable]] = []

    @IBOutlet weak var collectionView: CollectionView!
    
    
    var checklistOff: String!
    var checklistOn: String!
    var firstlist: String!
    var gender: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        registerCell(StringCell.self)
        (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.sectionHeadersPinToVisibleBounds = true
//        let emojiList = Preference.secondList
//        collectionables.append(emojiList)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(invalidLayout), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
    }
    
    @objc private func invalidLayout() {
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
//        collectionables.enumerated().forEach { (section, datas) in
//            datas.enumerated().forEach({ (item, data) in
//                guard let str = data as? String else { return }
//                if str == Preference.secondlistValue {
//                    let indexPath = IndexPath(item: item, section: section)
//                    collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .bottom)
//                }
//            })
//        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let des = segue.destination as? HowToUseViewController {
            des.checklistOff = checklistOff
            des.checklistOn = checklistOn
            des.firstlist = firstlist
            des.gender = gender
            
            guard let indexPath = collectionView.indexPathsForSelectedItems?.first,
                let str = collectionables[indexPath.section][indexPath.item] as? String else { return }
            des.secondlist = str
            
        }
    }
}

extension SecondListPickerViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let collectionable = collectionables[indexPath.section][indexPath.item]
        let str = collectionable as! String
        let viewModel = StringViewModel(string: str)
        var cell = collectionView.dequeueReusableCell(withReuseIdentifier: collectionable.reuseIdentifier, for: indexPath) as! ViewModelAcceptable & UICollectionViewCell
        cell.viewModel = viewModel
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collectionables[section].count
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return collectionables.count
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let reusableView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "ReusableView", for: indexPath)
        return reusableView
    }
}

extension SecondListPickerViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionables[indexPath.section][indexPath.item].didSelectItem(collectionView: collectionView, fromVC: self)
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        collectionables[indexPath.section][indexPath.item].didDeselectItem(collectionView: collectionView, fromVC: self)
    }
}

extension SecondListPickerViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return collectionables[section].first?.sectionInset(view: collectionView) ?? UIEdgeInsets.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionables[indexPath.section][indexPath.item].size(view: collectionView)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return collectionables[section].first?.minimumLineSpacing ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return collectionables[section].first?.minimumInteritemSpacing ?? 0
    }
}
