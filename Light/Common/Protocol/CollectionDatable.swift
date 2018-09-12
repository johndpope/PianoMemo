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
    func size(maximumWidth: CGFloat) -> CGSize
    var headerSize: CGSize { get }
    var sectionInset: EdgeInsets { get }
    var minimumInteritemSpacing: CGFloat { get }
    var minimumLineSpacing: CGFloat { get }
}

extension Layoutable {
    
    var minimumInteritemSpacing: CGFloat {
        return 0
    }
    
    var minimumLineSpacing: CGFloat {
        return 0
    }
    
    var minimumCellWidth: CGFloat {
        return 290
    }
    
    var sectionInset: EdgeInsets {
        return EdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    var headerSize: CGSize {
        return CGSize.zero
    }
    
}

protocol Uniquable {
    var identifier: String { get }
    var sectionIdentifier: String? { get set }
}

extension Uniquable {
    //Data 뒤에 Cell을 붙이면 뷰이다. 데이터와 뷰의 관계를 명확히 하고, 스토리보드에서 쉽게 identifier를 세팅하기 위함
    var identifier: String {
        return (String(describing: self).components(separatedBy: "(").first ?? "") + "Cell"
    }
}

protocol CollectionDataAcceptable {
    var data: CollectionDatable? { get set }
}

protocol CollectionDatable: Layoutable, Uniquable {
    var sectionTitle: String? { get set }
    var sectionImage: Image? { get set }
    func didSelectItem(fromVC viewController: ViewController)
    func didDeselectItem(fromVC viewController: ViewController)
}
