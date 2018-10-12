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
    weak var textView: DynamicTextView?
    weak var syncController: Synchronizable!
    private var collectionables: [[Collectionable]] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        registerCell(StringCell.self)
        collectionView.allowsMultipleSelection = true
        (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.sectionHeadersPinToVisibleBounds = true
        collectionables.append(Preference.emojiTags)
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
        
        guard let content = note.content else { return }
        collectionables.enumerated().forEach { (section, datas) in
            datas.enumerated().forEach({ (item, data) in
                guard let str = data as? String else { return }
                
                if content.contains(str) {
                    let indexPath = IndexPath(item: item, section: section)
                    collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .bottom)
                }
            })
        }
    }
    
    @IBAction func done(_ sender: Any) {
        guard let textView = textView else { return }
        var text = note.content ?? ""
        //모든 이모지 태그들을 지우기
        text.removeCharacters(strings: Preference.emojiTags)
        
        
        //선택 된 것들은 앞에다가 붙여주기
        var strs = ""
        collectionView.indexPathsForSelectedItems?.forEach {
            guard let str =  collectionables[$0.section][$0.item] as? String else { return }
            strs.append(str)
        }
        
        //맨 첫 문단이 서식이라면, 앞에 개행을 붙여줘서 서식이 깨지지 않도록 하기
        if let _ = BulletValue(text: textView.text, selectedRange: NSMakeRange(0, 0)) {
            text = "\n" + text
        }
        
        text = strs + text
        //업데이트를 위한 용도
        note.content = text
        textView.hasEdit = true
        dismiss(animated: true, completion: nil)
        
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
