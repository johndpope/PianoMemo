//
//  Share.swift
//  Cloud
//
//  Created by JangDoRi on 2018. 7. 9..
//

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
    
    internal init(with container: Container) {
        self.container = container
    }
    
}

#if os(iOS)
extension Share: UICloudSharingControllerDelegate {
    
    /**
     특정 CKRecord를 Shared 상태로 수정하고 구성원을 초대할 수 있는 Invitation을 제작하는 작업을 진행한다.
     - Parameter target: Share작업을 진행하고자 하는 ViewController.
     - Parameter item: Pad에서 popover하고자 하는 UIBarButtonItem.
     - Parameter root: Share를 하고자 하는 CKRecord.
     - Parameter thumbnail: Share Invitation이 present될때 표기되는 itemThumbnail.
     - Parameter title: Share Invitation이 present될때 표기되는 itemTitle.
     - Note: thumbnail와 title은 직접 class의 variable에 접근하여 수정을 하던가 Default로 둬도 상관없다.
     */
    public func operate(target: UIViewController, pop item: UIBarButtonItem, root: CKRecord, thumbnail: UIView? = nil, title: String? = nil) {
        container.cloud.requestApplicationPermission(.userDiscoverability) { _, _ in}
        itemThumbnail = thumbnail
        itemTitle = title
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
    
    // Share작업 도중에 발생한 error에 대한 처리.
    public func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
        guard let error = error as? CKError, let partialError = error.partialErrorsByItemID?.values else {return}
        for error in partialError {errorHandle(share: error)}
    }
    
    // Share Invitation을 중도에 그만뒀을때의 처리.
    public func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
        download.operate()
    }
    
    // Share Invitation이 present될때 표기되는 itemThumbnail에 대한 재정의.
    public func itemThumbnailData(for csc: UICloudSharingController) -> Data? {
        guard let thumbnail = itemThumbnail else {return nil}
        let renderer = UIGraphicsImageRenderer(bounds: thumbnail.bounds)
        return nil
        //TODO: DORI
//        return UIImageJPEGRepresentation(renderer.image {thumbnail.layer.render(in: $0.cgContext)}, 1)
    }
    
    // Share Invitation이 present될때 표기되는 itemTitle에 대한 재정의.
    public func itemTitle(for csc: UICloudSharingController) -> String? {
        return itemTitle ?? "shared_title".loc
    }
    
}
#endif
