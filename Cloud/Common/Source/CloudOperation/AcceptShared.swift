//
//  AcceptShared.swift
//  Cloud
//
//  Created by JangDoRi on 2018. 7. 4..
//

/// CKAcceptSharesOperation.
public class AcceptShared {
    
    /// CKAcceptSharesOperation이 종료되었을때 호출되는 Block.
    public var acceptSharesCompletionBlock: ((Error?) -> ())?
    /// 서버에서 CKShare에 대한 처리가 완료될때 마다 호출되는 Block.
    public var perShareCompletionBlock: ((CKShare.Metadata, CKShare?, Error?) -> ())?
    
    /**
     Shared record의 invite에 대한 accept처리를 진행한다.
     - Parameter data: CKShareMetadata.
     */
    public func operate(with data: CKShare.Metadata) {
        let acceptSharesOperation = CKAcceptSharesOperation(shareMetadatas: [data])
        acceptSharesOperation.acceptSharesCompletionBlock = {self.acceptSharesCompletionBlock?($0)}
        acceptSharesOperation.perShareCompletionBlock = {self.perShareCompletionBlock?($0, $1, $2)}
        CKContainer(identifier: data.containerIdentifier).add(acceptSharesOperation)
    }
    
}

