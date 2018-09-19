//
//  ListPickerViewController.swift
//  Piano
//
//  Created by Kevin Kim on 18/09/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import UIKit
import CoreData

class ListPickerViewController: UIViewController, CollectionRegisterable {
    @IBOutlet weak var collectionView: CollectionView!
    private var dataSource: [[CollectionDatable]] = [] {
        didSet {
            collectionView.reloadData()
            if dataSource.count != 0 {
                let firstIndexPath = IndexPath(item: 0, section: 0)
                collectionView.selectItem(at: firstIndexPath, animated: true, scrollPosition: .top)
            }
        }
    }
    
    
    var checklistOff: String!
    var checklistOn: String!

    override func viewDidLoad() {
        super.viewDidLoad()
        registerHeaderView(PianoCollectionReusableView.self)
        registerCell(ListPickerViewModelCell.self)
//        (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.sectionHeadersPinToVisibleBounds = true
        
        let emojiList = "🐶🐱🐭🐹🐰🦊🐻🐼🐨🐯🦁🐮🐷🐽🐸🐵🙈🙉🙊🐒🐔🐧🐦🐤🐣🐥🦆🦅🦉🦇🐺🐗🐴🦄🐝🐛🦋🐌🐚🐞🐜🦗🕷🕸🦂🐢🐍🦎🦖🦕🐙🦑🦐🦀🐡🐠🐟🐬🐳🐋🦈🐊🐅🐆🦓🦍🐘🦏🐪🐫🦒🐃🐂🐄🐎🐖🐏🐑🐐🦌🐕🐩🐈🐓🦃🕊🐇🐁🐀🐿🦔🐾🐉🐲🌵🎄🌲🌳🌴🌱🌿☘️🍀🎍🎋🍃🍂🍁🍄🌾💐🌷🌹🥀🌺🌸🌼🌻🌞🌝🌛🌜🌚🌕🌖🌗🌘🌑🌒🌓🌔🌙🌎🌍🌏💫⭐️🌟✨⚡️☄️💥🔥🌪🌈☀️🌤⛅️🌥☁️🌦🌧⛈🌩🌨❄️☃️⛄️🌬💨💧💦☔️☂️🌊🌫🍏🍎🍐🍊🍋🍌🍉🍇🍓🍈🍒🍑🍍🥥🥝🍅🍆🥑🥦🥒🌶🌽🥕🥔🍠🥐🍞🥖🥨🧀🥚🍳🥞🥓🥩🍗🍖🌭🍔🍟🍕🥪🥙🌮🌯🥗🥘🥫🍝🍜🍲🍛🍣🍱🥟🍤🍙🍚🍘🍥🥠🍢🍡🍧🍨🍦🥧🍰🎂🍮🍭🍬🍫🍿🍩🍪🌰🥜🍯🥛🍼☕️🍵🥤🍶🍺🍻🥂🍷🥃🍸🍹🍾🥄🍴🍽🥣🥡🥢"
        
        dataSource.append(emojiList.map { ListPickerViewModel(emoji: String($0), sectionTitle: "문단 맨 앞에 *와 띄어쓰기를 나란히 적으면 선택한 이모지로 바껴요.") })
        
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let des = segue.destination as? HowToUseViewController {
            des.checklistOff = checklistOff
            des.checklistOn = checklistOn
            
            guard let indexPath = collectionView.indexPathsForSelectedItems?.first,
                let data = dataSource[indexPath.section][indexPath.item] as? ListPickerViewModel else { return }
            des.list = data.emoji
            
        }
    }

}

extension ListPickerViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let data = dataSource[indexPath.section][indexPath.item]
        var cell = collectionView.dequeueReusableCell(withReuseIdentifier: data.identifier, for: indexPath) as! CollectionDataAcceptable & UICollectionViewCell
        cell.data = data
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource[section].count
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return dataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        var reusableView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: dataSource[indexPath.section][indexPath.item].sectionIdentifier ?? "PianoCollectionReusableView", for: indexPath) as! CollectionDataAcceptable & UICollectionReusableView
        reusableView.data = dataSource[indexPath.section][indexPath.item]
        return reusableView
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return dataSource[section].first?.headerSize ?? CGSize.zero
    }
}

extension ListPickerViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        dataSource[indexPath.section][indexPath.item].didSelectItem(fromVC: self)
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        dataSource[indexPath.section][indexPath.item].didDeselectItem(fromVC: self)
    }
}

extension ListPickerViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return dataSource[section].first?.sectionInset ?? UIEdgeInsets.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let maximumWidth = collectionView.bounds.width - (collectionView.marginLeft + collectionView.marginRight)
        return dataSource[indexPath.section][indexPath.item].size(maximumWidth: maximumWidth)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return dataSource[section].first?.minimumLineSpacing ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return dataSource[section].first?.minimumInteritemSpacing ?? 0
    }
}
