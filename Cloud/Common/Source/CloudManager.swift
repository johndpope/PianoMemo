//
//  CloudManager.swift
//  Cloud
//
//  Created by JangDoRi on 2018. 7. 6..
//

import CoreData

/// CloudManager 설정.
public struct CloudConfiguration {
    
    /**
     CoreData의 save를 감지하여 자동으로 upload를 진행할 것인지에 대한 여부.
     
     (Default value is false.)
     */
    public var autoUpload = false {
        didSet {
            autoUploadDidChanged?(autoUpload)
        }
    }
    internal var autoUploadDidChanged: ((Bool) -> ())?
    
}

/**
 Cloud & CoreData sync기능을 제공하는 CloudManager.
 */
public class CloudManager {
    
    private var container: Container
    
    /// CloudManager 설정.
    public var configuration = CloudConfiguration()
    
    /// Cloud에서 보내온 notification처리 / 수동 download기능.
    public lazy var download = Download(with: container)
    /**
     CoreData의 save를 감지하여 auto upload하는 기능 / 수동 upload기능.
     
     (It's disabled as default, check 'configuration.autoUpload')
     */
    public lazy var upload = Upload(with: container)
    /// Cloud share invitation에 대한 처리기능.
    public lazy var acceptShared = AcceptShared()
    /// Cloud에 구성원을 invite하여 share하는 작업에 대한 처리기능.
    public lazy var share = Share(with: container)
    
    /// Offline등의 이유로 Cloud에 올바르게 sync하지 못했던 작업들에 대한 처리기능.
    private var longLived: LongLived?
    /// Cloud에서 사용 될 custom Database & Zone 구독정보를 관리하는 기능.
    private var subscription: Subscription?
    /// Cloud account가 바뀌었을때에 대한 처리기능.
    private var accountChanged: AccountChanged?
    
    public init(cloud: CKContainer, coreData: NSPersistentContainer) {
        container = Container(cloud: cloud, coreData: coreData)
        container.cloud.accountStatus { [weak self] (status, error) in
            guard status == .available else {return}
            self?.initialize()
            self?.setup()
        }
    }
    
    private func initialize() {
        accountChanged = AccountChanged(with: container)
        longLived = LongLived(with: container)
        subscription = Subscription(with: container)
    }
    
    private func setup() {
        subscription?.operate { [weak self] in
            self?.longLived?.operate()
        }
        accountChanged?.addObserver { [weak self] in
            self?.accountChanged?.requestUserInfo { [weak self] in
                self?.download.operate()
            }
        }
        configuration.autoUploadDidChanged = { [weak self] value in
            if value {
                self?.upload.addObserver()
            } else {
                self?.upload.removeObserver()
            }
        }
        download.operate()
    }
    
}
