//
//  AddressPickerViewController.swift
//  Piano
//
//  Created by Kevin Kim on 02/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit

class LocationTagPickerViewController: UIViewController, CollectionRegisterable {

    private var collectionables: [[Collectionable]] = []
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        registerCell(StringCell.self)
        collectionView.allowsMultipleSelection = true
        (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.sectionHeadersPinToVisibleBounds = true
        let emojiList = ["🍽","🥂","🏖","🏥","🏡","🍶","🍺","☕️","🍵","⛱","🏝","🏟","🎡","🎢","🎠","⛲️","🏜","🌋","⛰","🏔","🗻","🗺","🗿","🗽","🗼","🏰","🏯","🛤","🛣","🗾","🎑","🏞","🌅","🌄","🌠","🎇","🎆","🌇","🌆","🏙","🌃","🌌","🌉","🌁","🏕","⛺️","🏛","⛪️","🕌","🕍","🕋","⛩","🏠","🏘","🏚","🏢","🏬","🏣","🏤","🏦","🏨","🏪","🏫","🏩","💒","🚗","🚕","🚙","🚌","🚎","🏎","🚓","🚑","🚒","🚐","🚚","🚛","🚜","🛴","🚲","🛵","🏍","🚨","🚔","🚍","🚘","🚖","🚡","🚠","🚟","🚃","🚋","🚞","🚝","🚄","🚅","🚈","🚂","🚆","🚇","🚊","🚉","✈️","🛫","🛬","🛩","💺","🛰","🚀","🛸","🚁","🛶","⛵️","🚤","🛥","🛳","⛴","🚢","⚓️","⛽️","🚧","🚦","🚥","🚏","🏗","🏭"]
        collectionables.append(emojiList)
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
        
        collectionables.enumerated().forEach { (section, datas) in
            datas.enumerated().forEach({ (item, data) in
                guard let str = data as? String else { return }
                if Preference.locationTags.contains(str) {
                    let indexPath = IndexPath(item: item, section: section)
                    collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .bottom)
                }
            })
        }
    }
    
    @IBAction func done(_ sender: Any) {

        
        var strs: [String] = []
        collectionView.indexPathsForSelectedItems?.forEach {
            guard let str = collectionables[$0.section][$0.item] as? String else { return }
            strs.append(str)
        }
        
        Preference.locationTags = strs
        
        dismiss(animated: true, completion: nil)
    }

}


extension LocationTagPickerViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let collectionable = collectionables[indexPath.section][indexPath.item]
        var cell = collectionView.dequeueReusableCell(withReuseIdentifier: collectionable.reuseIdentifier, for: indexPath) as! ViewModelAcceptable & UICollectionViewCell
        let viewModel = StringViewModel(string: collectionable as! String)
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

extension LocationTagPickerViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionables[indexPath.section][indexPath.item].didSelectItem(collectionView: collectionView, fromVC: self)
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        collectionables[indexPath.section][indexPath.item].didDeselectItem(collectionView: collectionView, fromVC: self)
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        let count = collectionView.indexPathsForSelectedItems?.count ?? 0
        return count < 5
    }
}

extension LocationTagPickerViewController: UICollectionViewDelegateFlowLayout {
    
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
