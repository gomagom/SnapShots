//
//  SystemAudioClassifier.swift
//  SnapShots
//  
//  Created by Gomatamago on 2021/12/14
//  
//

import Foundation
import AVFoundation
import SoundAnalysis
import Combine

class SystemAudioClassifier: NSObject {
    
    // 指パッチン検知を通知するサブジェクト
    let subject = PassthroughSubject<Bool, Never>()
    var detectionCancellable: AnyCancellable?
    
    // アナライザー関連
    let audioEngine = AVAudioEngine()
    var inputFormat: AVAudioFormat!
    var analyzer: SNAudioStreamAnalyzer!
    
    // オブザーバー
    var detectionObserver: DetectionObserver!
    
    var camera: CameraModel!
    
    init(_ camera: CameraModel) {
        detectionObserver = DetectionObserver(label: "finger_snapping", subject: subject)
        self.camera = camera
        super.init()
    }
    
    func check() {
        
        // マイクの使用権限を確認
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            setUpAudioSession()
            startAudioEngine()
            setUpAnalyzer()
            startAnalyze()
        case .notDetermined:
            // 権限がなければ要求
            AVCaptureDevice.requestAccess(for: .audio) { (status) in
                
                if status{
                    self.setUpAudioSession()
                    self.startAudioEngine()
                    self.setUpAnalyzer()
                    self.startAnalyze()
                }
            }
        case .denied:
            return
        default:
            return
        }
    }
    
    func setUpAudioSession() {
        // セッションの設定
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement)
            try session.setActive(true)
        } catch {
            fatalError("Failed to configure and activate session.")
        }
    }
    
    func startAudioEngine() {
        
        // 入力形式を取得
        inputFormat = audioEngine.inputNode.inputFormat(forBus: 0)
        
        // オーディオエンジンを開始
        do{
            try audioEngine.start()
        }catch( _){
            print("error in starting the Audio Engin")
        }
    }
    
    func setUpAnalyzer() {
        
        // マイクストリームから音を入力
        analyzer = SNAudioStreamAnalyzer(format: inputFormat)

        do {
            // ビルトインの音声分類器を使用
            let request = try SNClassifySoundRequest(classifierIdentifier: .version1)
            
            // ウインドウの時間的な長さ
            request.windowDuration = CMTimeMakeWithSeconds(0.5, preferredTimescale: 48_000)
            
            // ウインドウの重なり度合い
            request.overlapFactor = 0.9

            // アナライザーに検出リクエストを追加
            try analyzer.add(request, withObserver: detectionObserver)
        } catch {
            print("Unable to prepare request: \(error.localizedDescription)")
            return
        }
    }

    func startAnalyze() {

        // 監視用のオーディオタップをインストール
        audioEngine.inputNode.installTap(onBus: 0, bufferSize: 8000, format: inputFormat) { buffer, time in
            DispatchQueue.global().async {
                self.analyzer.analyze(buffer, atAudioFramePosition: time.sampleTime)
            }
        }
        
        // detectionObserverから送られる通知を処理
        detectionCancellable = subject
            .receive(on: DispatchQueue.main)
            .sink{
                
                // 指パッチンが検出されたらカメラの撮影トリガーを切り替える
                if $0 && self.camera.isSaved && self.camera.canUse {
                    
                    self.camera.isSaved = false
                    self.camera.willTake = true
                }
        }
    }
}
