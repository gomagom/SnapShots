//
//  DetectionObserver.swift
//  SnapShots
//  
//  Created by Gomatamago on 2021/12/14
//  
//

import Foundation
import SoundAnalysis
import Combine

class DetectionObserver: NSObject, SNResultsObserving {
    private let subject: PassthroughSubject<Bool, Never>
    private var label: String
    
    init(label: String, subject: PassthroughSubject<Bool, Never>) {
        self.subject = subject
        self.label = label
    }
    
    // 検知用の関数
    func request(_ request: SNRequest, didProduce result: SNResult) {
        
        // 指パッチンが検出され、その信頼度が50%以上ならtrueを通知
        if let result = result as? SNClassificationResult,
           let classification = result.classification(forIdentifier: label) {
            
            if classification.confidence > 0.5 {
                
//                print("patching!")
                subject.send(true)
            } else {
                subject.send(false)
            }
        }
    }
}
