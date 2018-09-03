//
//  DetailVC_Action.swift
//  Light
//
//  Created by Kevin Kim on 2018. 9. 2..
//  Copyright © 2018년 Piano. All rights reserved.
//

import Foundation
import CoreGraphics

protocol ContainerDatasource {
    func reset()
    func startFetch()
    
}

extension DetailViewController {
    
    @IBAction func highlight(_ sender: Any) {
        
    }
    
    @IBAction func addPeople(_ sender: Any) {
        
    }
    
    @IBAction func done(_ sender: Any) {
        textView.resignFirstResponder()
    }
    
//    private var bottomCollectionVC: BottomCollectionViewController? {
//        return (childViewControllers.first as? NavigationController)?.topViewController as? BottomCollectionViewController
//    }
    
    @IBAction func switchBottomView(_ sender: Button) {
        
        //이미 선택이 되었었는데 다시 누르는 경우
        if sender.isSelected {
            containerViews.forEach { $0.removeFromSuperview() }
            
            setBottomContainerHeight(to: 0, completions: nil)
            
            sender.isSelected = false
            //TODO: 데이터 소스 초기화하기
            resetContainerViews()
            return
        }
        
        keyboardToken?.invalidate()
        keyboardToken = nil
        //버튼 상태 바꿔주고
        bottomButtons.forEach{ $0.isSelected = $0 == sender }
        
        //텍스트뷰 내려주고
        textView.resignFirstResponder()
       
        setBottomContainerHeight(to: kbHeight) { (_) in

            
            self.containerViews.forEach {
                if $0.tag != sender.tag {
                    $0.removeFromSuperview()
                } else {
                    //컨스트레인트를 포함해 붙여준다.
                    self.view.addSubview($0)
                    $0.translatesAutoresizingMaskIntoConstraints = false
                    $0.topAnchor.constraint(equalTo: self.bottomView.bottomAnchor).isActive = true
                    $0.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
                    $0.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
                    $0.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
                }
                
            }
        }
        
        //컨테이너뷰에게 데이터 소스 갱신하라 전달
        guard let dataType = DataType(rawValue: sender.tag) else { return }
        setContainerView(type: dataType)
    }
    
    
    internal func setBottomContainerHeight(to height: CGFloat, completions: ((Bool) -> Void)?) {
        
        //텍스트뷰 델리게이트에서 시작될 때 컨테이너뷰는 사라짐.
        
        View.animate(withDuration: 0.3, animations: { [weak self] in
            self?.bottomViewBottomAnchor.constant = height
            self?.view.layoutIfNeeded()
        }, completion: completions)
    }
    
    internal func resetContainerViews() {
        childViewControllers.forEach {
            (($0 as? NavigationController)?.topViewController as? ContainerDatasource)?.reset()
        }
    }
    
    internal func setContainerView(type: DataType) {
        childViewControllers.enumerated().forEach { (offset, vc) in
            guard let containerDS = (vc as? NavigationController)?.topViewController as? ContainerDatasource else { return }
            
            if offset != type.rawValue {
                containerDS.reset()
            } else {
                containerDS.startFetch()
            }
        }
    }
    
}