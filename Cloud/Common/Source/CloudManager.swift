//
//  CloudManager.swift
//  Cloud
//
//  Created by JangDoRi on 2018. 7. 6..
//

import CoreData

/**
 Cloud & CoreData sync기능을 제공하는 CloudManager.
 */
public class CloudManager {
    
    private var container: Container
    
    /// Cloud에서 보내온 notification처리 / 수동 download기능.
    public lazy var download = Download(with: container)
    /// CoreData의 save를 감지하여 auto upload하는 기능
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
        upload.addObserver()
        download.operate()
    }
    
    
}

