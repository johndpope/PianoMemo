//
//  Share.swift
//  Cloud
//
//  Created by JangDoRi on 2018. 7. 9..
//

import CloudKit
import CoreData

#if os(iOS)
import UIKit
#elseif os(OSX)
import AppKit
#endif

/// UICloudSharingController.
public class Share: NSObject, ErrorHandleable {
    
    internal var container: Container
    internal var errorBlock: ((Error?) -> ())?
    internal lazy var download = Download(with: container)
    
    #if os(iOS)
    private var itemThumbnail: UIView?
    #elseif os(OSX)
    private var itemThumbnail: NSView?
    #endif
    private var itemTitle: String?
    
    private weak var usingTarget: UIViewController?
    private weak var usingItem: UIBarButtonItem?
    private var usingObject: NSManagedObject?
    
    internal init(with container: Container) {
        self.container = container
    }
    
}

#if os(iOS)
extension Share: UICloudSharingControllerDelegate {
    
    public func isShared(_ note: NSManagedObject, _ completion: @escaping ((Bool) -> ())) {
        guard let record = note.record() else {return}
        let fetch = CKFetchRecordsOperation(recordIDs: [record.recordID])
        container.cloud.privateCloudDatabase.add(fetch)
        fetch.perRecordCompletionBlock = { (record, recordID, error) in
            completion(record?.share != nil)
        }
    }
    
    /**
     특정 CKRecord를 Shared 상태로 수정하고 구성원을 초대할 수 있는 Invitation을 제작하는 작업을 진행한다.
     - Parameter target: Share작업을 진행하고자 하는 ViewController.
     - Parameter item: Pad에서 popover하고자 하는 UIBarButtonItem.
     - Parameter root: Share를 하고자 하는 CKRecord.
     - Parameter thumbnail: Share Invitation이 present될때 표기되는 itemThumbnail.
     - Parameter title: Share Invitation이 present될때 표기되는 itemTitle.
     - Note: thumbnail와 title은 직접 class의 variable에 접근하여 수정을 하던가 Default로 둬도 상관없다.
     */
    public func operate(target: UIViewController, pop item: UIBarButtonItem, note: NSManagedObject, thumbnail: UIView? = nil, title: String? = nil) {
        container.cloud.requestApplicationPermission(.userDiscoverability) { _, _ in}
        usingTarget = target
        usingItem = item
        usingObject = note
        itemThumbnail = thumbnail
        itemTitle = title
        guard let root = note.record() else {return}
        let cloudSharingController = UICloudSharingController { viewCtrl, completion in
            let share = CKShare(rootRecord: root)
            let operation = CKModifyRecordsOperation(recordsToSave: [root, share], recordIDsToDelete: nil)
            operation.modifyRecordsCompletionBlock = {completion(share, self.container.cloud, $2)}
            self.container.cloud.privateCloudDatabase.add(operation)
        }
        cloudSharingController.delegate = self
        cloudSharingController.availablePermissions = [.allowPrivate, .allowReadWrite]
        if let popover = cloudSharingController.popoverPresentationController {
            popover.barButtonItem = item
        }
        target.present(cloudSharingController, animated: true)
    }
    
    public func configure(target: UIViewController, pop item: UIBarButtonItem, note: NSManagedObject) {
        usingTarget = target
        usingItem = item
        usingObject = note
        guard let shareID = note.record()?.share?.recordID else {return}
        let fetch = CKFetchRecordsOperation(recordIDs: [shareID])
        container.cloud.privateCloudDatabase.add(fetch)
        fetch.perRecordCompletionBlock = { (record, recordID, error) in
            guard let share = record as? CKShare else {return}
            let cloudSharingController = UICloudSharingController(share: share, container: self.container.cloud)
            if let popover = cloudSharingController.popoverPresentationController {
                popover.barButtonItem = item
            }
            cloudSharingController.delegate = self
            target.present(cloudSharingController, animated: true)
        }
    }
    
    // Share작업 도중에 발생한 error에 대한 처리.
    public func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
        guard let error = error as? CKError, let partialError = error.partialErrorsByItemID?.values else {return}
        for error in partialError {errorHandle(share: error)}
        alert()
    }
    
    private func alert() {
        let alert = UIAlertController(title: nil, message: "Share operation is pending.", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "취소", style: .cancel)
        let retryAction = UIAlertAction(title: "재시도", style: .default) { _ in
            guard let target = self.usingTarget, let item = self.usingItem, let object = self.usingObject else {return}
            self.operate(target: target, pop: item, note: object, thumbnail: self.itemThumbnail, title: self.itemTitle)
        }
        alert.addAction(cancelAction)
        alert.addAction(retryAction)
        usingTarget?.present(alert, animated: true)
    }
    
    // Share Invitation이 발송되었을때의 처리.
    public func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
        print("cloudSharingControllerDidSaveShare")
        usingItem?.image = UIImage(named: "info")
        download.operate()
    }
    
    // Share Invitation을 그만뒀을때의 처리.
    public func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
        print("cloudSharingControllerDidStopSharing")
        usingItem?.image = UIImage(named: "share")
        download.operate()
    }
    
    // Share Invitation이 present될때 표기되는 itemThumbnail에 대한 재정의.
    public func itemThumbnailData(for csc: UICloudSharingController) -> Data? {
        guard let thumbnail = itemThumbnail else {return nil}
        let renderer = UIGraphicsImageRenderer(bounds: thumbnail.bounds)
        return renderer.image(actions: {thumbnail.layer.render(in: $0.cgContext)}).jpegData(compressionQuality: 1)
    }
    
    // Share Invitation이 present될때 표기되는 itemTitle에 대한 재정의.
    public func itemTitle(for csc: UICloudSharingController) -> String? {
        return itemTitle ?? "shared_title".loc
    }
    
}
#endif

