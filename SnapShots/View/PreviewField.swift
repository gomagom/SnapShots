//
//  PreviewField.swift
//  SnapShots
//  
//  Created by Gomatamago on 2021/12/15
//  
//

import SwiftUI

struct PreviewField: View {
    
    @StateObject var camera: CameraModel
    
    var body: some View {
        ZStack {
            
            VStack {
                
                // カメラプレビューを設置
                CameraPreview(camera: camera)
                    .ignoresSafeArea(.all, edges: .all)
                    .blur(radius: camera.canUse ? 0 : 20)
            }
            
            // カウントダウン表示用
            if camera.count > 0 {
                    
                Circle()
                    .foregroundColor(.gray.opacity(0.3))
                    .padding(.horizontal, 50)
                
                Text(String(camera.count))
                    .font(.system(size: 250, weight: .black, design: .default))
                    .foregroundColor(.black.opacity(0.3))
            }
            
            // シャッターを切るタイミングで一瞬暗転させる
            if camera.isTaking {
                Color.black
            }
        }
    }
}
