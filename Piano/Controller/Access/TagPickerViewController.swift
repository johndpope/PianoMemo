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
    private var categorized = [ArraySection<String, Emoji>]()
    @IBOutlet weak var collectionView: UICollectionView!
    weak var storageService: StorageService!

    var titles = [String]()

    override func viewDidLoad() {
        super.viewDidLoad()
        registerCell(StringCell.self)
        (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.sectionHeadersPinToVisibleBounds = true
        refresh()
    }

    private func refresh() {
        if let parser = EmojiParser(filename: "emoji.csv"),
            let _ = parser.setup() {
            var newCategorized = [ArraySection<String, Emoji>]()

            let using = storageService.local.emojiTags
                .map { Emoji(string: $0) }
            if using.count > 0 {
                newCategorized.append(ArraySection(model: "사용 중", elements: using))
            }
            let recommended = parser.emojis.filter { $0.isRecommended == true }
                .filter { !using.contains($0) }

            if recommended.count > 0 {
                newCategorized.append(ArraySection(model: "추천", elements: recommended))
            }

            parser.categories.forEach { category in
                let filtered = parser.emojis.filter { $0.category == category }
                    .filter { !using.contains($0) }
                newCategorized.append(ArraySection(model: category, elements: filtered))
            }

            let changeSet = StagedChangeset(source: categorized, target: newCategorized)
            collectionView.visibleCells.forEach {
                $0.layer.zPosition = 10
            }

            collectionView.reload(using: changeSet, setData: { data in
                self.categorized = data
            }) { _ in
                self.collectionView.visibleCells.forEach {
                    $0.layer.zPosition = 0
                }
            }
        }
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

    @IBAction func done(_ sender: Any) {
    }
}

extension TagPickerViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let emoji = categorized[indexPath.section].elements[indexPath.item]
        var cell = collectionView.dequeueReusableCell(withReuseIdentifier: "StringCell", for: indexPath) as! ViewModelAcceptable & UICollectionViewCell
        let viewModel = StringViewModel(string: emoji.string)
        cell.viewModel = viewModel
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return categorized[section].elements.count
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return categorized.count
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "EmojiSectionHeader", for: indexPath) as? EmojiSectionHeader {
            header.label.text = categorized[indexPath.section].model
            header.backgroundColor = UIColor.white.withAlphaComponent(0.85)
            return header
        }
        return UICollectionReusableView()
    }
}

extension TagPickerViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if storageService.local.emojiTags.count > 0 {
            if indexPath.section == 0 {
                var now = categorized[0].elements
                now.remove(at: indexPath.item)
                storageService.local.emojiTags = now.map { $0.string }

            } else {
                let selected = categorized[indexPath.section].elements[indexPath.item]
                var now = categorized[0].elements
                now.append(selected)
                storageService.local.emojiTags = now.map { $0.string }
            }
        } else {
            let selected = categorized[indexPath.section].elements[indexPath.item]
            storageService.local.emojiTags = [selected.string]
        }
        refresh()
    }

}

extension TagPickerViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return categorized.first?.elements.first?.sectionInset(view: collectionView) ?? UIEdgeInsets.zero
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return categorized[indexPath.section].elements[indexPath.item].size(view: collectionView)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return categorized.first?.elements.first?.minimumLineSpacing ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return categorized.first?.elements.first?.minimumInteritemSpacing ?? 0
    }
}

extension String: Differentiable {}
