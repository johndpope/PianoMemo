//
//  Protocol.swift
//  Light
//
//  Created by Kevin Kim on 2018. 9. 10..
//  Copyright © 2018년 Piano. All rights reserved.
//

import Foundation
import CoreGraphics

//iphone8 plus width: 414, iphone se width: 320

//Tip: 익스텐션에만 선언해두면 오버라이딩이 정상작동하질 않음. -> 이유 찾기
protocol Layoutable {
    func size(view: View) -> CGSize
    func sectionInset(view: View) -> EdgeInsets
    var headerSize: CGSize { get }
    var minimumInteritemSpacing: CGFloat { get }
    var minimumLineSpacing: CGFloat { get }
}

extension Layoutable {
    
    var minimumInteritemSpacing: CGFloat {
        return 8
    }
    
    var minimumLineSpacing: CGFloat {
        return 8
    }
    
    var headerSize: CGSize {
        return CGSize.zero
    }
    
    func sectionInset(view: View) -> EdgeInsets {
        return EdgeInsets(top: 0, left:  8, bottom: 50, right: 8)
    }
    
    func size(view: View) -> CGSize {
        return CGSize.zero
    }
    
}

protocol Uniquable {
    var reuseIdentifier: String { get }
    var reusableViewReuseIdentifier: String { get }
}

extension Uniquable {
    var reuseIdentifier: String { return String(describing: type(of: self)) + "Cell" }
    var reusableViewReuseIdentifier: String { return "PianoReusableView" }
}

protocol Sectionable {
    var sectionTitle: String? { get }
    var sectionImage: Image? { get }
}

extension Sectionable {
    var sectionTitle: String? { return "" }
    var sectionImage: Image? { return nil }
}

protocol CollectionItemSelectable {
    func didSelectItem(collectionView: CollectionView, fromVC viewController: ViewController)
    func didDeselectItem(collectionView: CollectionView, fromVC viewController: ViewController)
}

extension CollectionItemSelectable {
    func didSelectItem(collectionView: CollectionView, fromVC viewController: ViewController) {}
    func didDeselectItem(collectionView: CollectionView, fromVC viewController: ViewController) {}
}

protocol ViewModelAcceptable {
    var viewModel: ViewModel? { get set }
}

protocol ViewModel: Uniquable { }

protocol Collectionable: Layoutable, Uniquable, Sectionable, CollectionItemSelectable { }
