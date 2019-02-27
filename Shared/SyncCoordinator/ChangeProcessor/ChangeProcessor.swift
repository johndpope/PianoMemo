//
//  ChangeProcessor.swift
//  Piano
//
//  Created by hoemoon on 24/12/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import CoreData
import CloudKit


/// changeProcessor의 인터페이스를 정의합니다.
/// changeProcessor를 타입으로 다룰 수 있게 합니다.
/// 간편한 구현을 위해 서브 프로토콜인 `ElementChangeProcessor`이 따로 정의되어 있습니다.
protocol ChangeProcessor: class {
    func processChangedLocalObjects(_ objects: [NSManagedObject], in context: ChangeProcessorContext)
    func entityAndPredicateForLocallyTrackedObjects(in context: ChangeProcessorContext) -> EntityAndPredicate<NSManagedObject>?
}
