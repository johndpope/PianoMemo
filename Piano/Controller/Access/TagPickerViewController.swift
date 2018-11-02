//
//  TagPickerCollectionViewController.swift
//  Piano
//
//  Created by Kevin Kim on 30/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit
import DifferenceKit

class TagPickerViewController: UIViewController, CollectionRegisterable {
    private var categorized: [[Collectionable]] = []
    @IBOutlet weak var collectionView: UICollectionView!
    weak var syncController: StorageService!

    var titles = [String]()

    override func viewDidLoad() {
        super.viewDidLoad()
        registerCell(StringCell.self)
        collectionView.allowsMultipleSelection = true
        (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.sectionHeadersPinToVisibleBounds = true
        setup()
    }

    private func setup() {
        if let parser = EmojiParser(filename: "emoji.csv"),
            let _ = parser.setup() {
            if syncController.local.emojiTags.count > 0 {
                titles.append("사용 중")
                let using = syncController.local.emojiTags
                    .map { Emoji(string: $0) }
                categorized.append(using)
            }
            let recommended = parser.emojis.filter { $0.isRecommended == true }

            if recommended.count > 0 {
                titles.append("추천")
                categorized.append(recommended)
            }

            parser.categories.forEach { category in
                titles.append(category)
                let filtered = parser.emojis.filter { $0.category == category }
                categorized.append(filtered)
            }
        }
    }

    private func refresh() {
        //        let selected = syncController.local.emojiTags
        //        let filteredAll = emojiList.filter { !syncController.local.emojiTags.contains($0) }
        //        let filteredRecommend = recommendDict.filter { !syncController.local.emojiTags.contains($0.key) }.map { $0.key }
        //
        //        if selected.count == 0 {
        //            titles = ["추천", "카테고리"]
        //            collectionables.append(selected)
        //        } else {
        //            titles = ["사용 중", "추천", "카테고리"]
        //        }
        //        collectionables.append(filteredRecommend)
        //        collectionables.append(filteredAll)
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
        //                if syncController.local.emojiTags.contains(str) {
        //                    let indexPath = IndexPath(item: item, section: section)
        //                    collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .bottom)
        //                }
        //            })
        //        }
//        let itemCount = collectionView.numberOfItems(inSection: 0)
//        for item in 0...itemCount {
//            let path = IndexPath(item: item, section: 0)
//            collectionView.selectItem(at: path, animated: true, scrollPosition: .bottom)
//        }
    }

    @IBAction func done(_ sender: Any) {
        var strs: [String] = []
        collectionView.indexPathsForSelectedItems?.forEach {
            guard let str =  categorized[$0.section][$0.item] as? String else { return }
            strs.append(str)
        }

        syncController.local.emojiTags = strs
        dismiss(animated: true, completion: nil)
    }
}

extension TagPickerViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let emoji = categorized[indexPath.section][indexPath.item]
        var cell = collectionView.dequeueReusableCell(withReuseIdentifier: "StringCell", for: indexPath) as! ViewModelAcceptable & UICollectionViewCell
        let viewModel = StringViewModel(string: (emoji as! Emoji).string)
        cell.viewModel = viewModel
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return categorized[section].count
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return categorized.count
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {

        if let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "EmojiSectionHeader", for: indexPath) as? EmojiSectionHeader {
            header.label.text = titles[indexPath.section]
            header.backgroundColor = UIColor.white.withAlphaComponent(0.85)
            return header
        }
        return UICollectionReusableView()
    }
}

extension TagPickerViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        categorized[indexPath.section][indexPath.item].didSelectItem(collectionView: collectionView, fromVC: self)
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        categorized[indexPath.section][indexPath.item].didDeselectItem(collectionView: collectionView, fromVC: self)
    }

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        let count = collectionView.indexPathsForSelectedItems?.count ?? 0
        return count < 10
    }
}

extension TagPickerViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return categorized.first?.first?.sectionInset(view: collectionView) ?? UIEdgeInsets.zero
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return categorized[indexPath.section][indexPath.item].size(view: collectionView)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return categorized.first?.first?.minimumLineSpacing ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return categorized.first?.first?.minimumInteritemSpacing ?? 0
    }
}

extension String: Differentiable {}
