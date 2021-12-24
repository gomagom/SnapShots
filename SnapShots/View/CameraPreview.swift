//
//  CameraPreview.swift
//  SnapShots
//  
//  Created by Gomatamago on 2021/12/15
//  
//

import SwiftUI
import AVFoundation

struct CameraPreview: UIViewRepresentable {
    
    @ObservedObject var camera: CameraModel
    
    // UIKitを使用してUIViewを作成
    func makeUIView(context: Context) -> UIView {
        
        // viewのサイズを指定して生成
        let height = UIScreen.main.bounds.width * 4 / 3
        let y = UIScreen.main.bounds.height / 2 - height / 2 
        let rect = CGRect(x: 0, y: y, width: UIScreen.main.bounds.width, height: height)
        let view = UIView(frame: rect)
        
        camera.preview = AVCaptureVideoPreviewLayer(session: camera.session)
        camera.preview.frame = view.frame
        
        // レイヤーへのプレビューの表示形式（枠に収まるようにアス比を維持してリサイズ）
        camera.preview.videoGravity = .resizeAspect
        view.layer.addSublayer(camera.preview)
        
        // カメラのセッションを開始
        camera.session.startRunning()
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        
    }
}
