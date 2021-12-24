//
//  CameraModel.swift
//  SnapShots
//  
//  Created by Gomatamago on 2021/12/15
//  
//

import SwiftUI
import AVFoundation

class CameraModel: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    
    // カメラのステータス
    @Published var willTake = false
    @Published var isTaking = false
    @Published var isSaved = true
    @Published var canUse = false
    
    @Published var session = AVCaptureSession()
    
    var inputDevice: AVCaptureDeviceInput!
    
    // 写真データを取得するためのアウトプット
    @Published var output = AVCapturePhotoOutput()
    
    // プレビュー
    @Published var preview: AVCaptureVideoPreviewLayer!
    
    // 撮影データ
    @AppStorage("last_pic") var picData = Data(count: 0)
    
    // オプション
    @Published var alert = false
    @Published var front = false
    @Published var flash: AVCaptureDevice.FlashMode = .off

    @Published var delay = 0
    @Published var count = 0
    @Published var timerHandler: Timer?
    
    // 指パッチン検出器
    var detector: SystemAudioClassifier?
    
    override init() {
        
        super.init()
        self.detector = SystemAudioClassifier(self)
    }
    
    func check() {
        
        // カメラへのアクセス権を確認
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setUp()
        case .notDetermined:
            // アクセス許可をリクエスト
            AVCaptureDevice.requestAccess(for: .video) { (status) in
                
                if status{
                    self.setUp()
                }
            }
        case .denied:
            self.alert.toggle()
            
        default:
            return
        }
    }
    
    // 起動時の設定
    func setUp() {
        
        // カメラの初期設定を行う
        
        do{
            // 設定変更を開始
            self.session.beginConfiguration()
            
            // プリセットに写真用のものを選択
            self.session.sessionPreset = .photo
            
            // インプット元のデバイスなどを設定（機種によって変更する必要有るかも）
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
            
            inputDevice = try AVCaptureDeviceInput(device: device!)
            
            // セッションに追加できるかを確認し、インプット元を追加
            if self.session.canAddInput(inputDevice) {
                self.session.addInput(inputDevice)
            }
            
            // 同様にアウトプット先を追加
            if self.session.canAddOutput(self.output) {
                self.session.addOutput(self.output)
            }
            
            // キャプチャを高解像度に設定
            self.output.isHighResolutionCaptureEnabled = true
            // 写真は品質を優先するように設定
            self.output.maxPhotoQualityPrioritization = .quality

            
            // 設定変更をコミット
            self.session.commitConfiguration()
            
            DispatchQueue.main.async {
                self.canUse = true
            }
        } catch{
            print(error.localizedDescription)
        }
    }
    
    // カメラセッションの設定を変更
    func changeCam() {
        
        // 切り替え中に撮影処理が実行されないようにフラグを変更
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.2)){self.canUse = false}
        }
        
        DispatchQueue.global(qos: .userInteractive).async {
            do {
                // 設定変更を開始
                self.session.beginConfiguration()
                
                var device: AVCaptureDevice?
                
                // フラグをもとにフロントカメラかバックカメラをデバイスとして設定
                if self.front {
                    device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
                } else {
                    device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
                }
                
                self.inputDevice = try AVCaptureDeviceInput(device: device!)
                
                // すでにセッションに登録されているインプットを削除
                for input in self.session.inputs {
                    self.session.removeInput(input as AVCaptureInput)
                }
                
                // セッションにデバイスを追加
                if self.session.canAddInput(self.inputDevice) {
                    self.session.addInput(self.inputDevice)
                }
                
                // 設定変更をコミット
                self.session.commitConfiguration()
                
                // 撮影可能状態に戻す
                DispatchQueue.main.async {
                    withAnimation(.easeInOut(duration: 0.2)){self.canUse = true}
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    // 撮影を行うための処理を開始する
    func camSequence() {
        
        if delay == 0 {
            takePic()
        } else {
            startTimer()
        }
        
        print("sequence started (Timer: \(delay))")
    }
    
    // タイマーで呼ばれるメソッド
    func countDown() {
        
        count -= 1
        
        // カウントが終了した時の処理
        if count <= 0 {
            timerHandler?.invalidate()
            takePic()
        }
    }
    
    // カウントダウンを開始する
    func startTimer() {
        
        // タイマーが実行中の場合
        if let unwrapedTimerHandler = timerHandler {
            if unwrapedTimerHandler.isValid {
                return
            }
        }
        
        // カウンドダウン用の変数に設定された遅延を代入
        if count <= 0 {
            count = delay
        }
        
        // 1秒毎にカウントダウンを行う
        timerHandler = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            self.countDown()
        }
    }
    
    // 写真撮影を行う
    func takePic() {
        
        DispatchQueue.global(qos: .userInteractive).async {
            
            // 撮影時の設定を行う
            let photoSettings = AVCapturePhotoSettings()
            // フラッシュを焚くかどうか
            if self.inputDevice.device.isFlashAvailable {
                photoSettings.flashMode = self.flash
            }
            
            // 撮影を高解像度で行う
            photoSettings.isHighResolutionPhotoEnabled = true
            // 撮影を品質優先で行う
            photoSettings.photoQualityPrioritization = .quality
            
            // 撮影を実行
            self.output.capturePhoto(with: photoSettings, delegate: self)
            
            DispatchQueue.main.async {
                print("pic taken")
                self.willTake = false
            }
        }
    }
    
    // 撮影の瞬間に呼ばれるメソッド
    func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        
        // 画面を一瞬暗転させる
        DispatchQueue.main.async {
            withAnimation(.linear(duration: 0.025)) {self.isTaking = true}
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.125) {
            withAnimation(.linear(duration: 0.025)) {self.isTaking = false}
        }
    }
    
    // 撮影結果の受信
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        if error != nil{
            return
        }
        
        // 撮影データを生成
        guard let imageData = photo.fileDataRepresentation() else {return}
        self.picData = imageData
        
        // UIImageに変換
        let image = UIImage(data: self.picData)!
        
        // イメージをアルバムに保存
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        
        // セーブ完了
        DispatchQueue.main.async {
            self.isSaved = true
        }
        
        print("saved Successfully")
    }
}
