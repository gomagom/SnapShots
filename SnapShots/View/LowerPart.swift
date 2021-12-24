//
//  LowerPart.swift
//  SnapShots
//  
//  Created by Gomatamago on 2021/12/15
//  
//

import SwiftUI

struct LowerPart: View {
    
    @StateObject var camera: CameraModel
    
    var body: some View {
        HStack {
            
            // 直近の撮影した写真を表示するパーツ
            Button(action: {
                
                // タッチで写真アプリに遷移
                if let url = URL(string: "photos-redirect:") {
                    
                    UIApplication.shared.open(url)
                }
            }) {
                
                if let image = UIImage(data: camera.picData) {
                    
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    
                    Image(systemName: "photo.on.rectangle")
                        .foregroundColor(.black)
                        .frame(width: 60, height: 60)
                        .background(.white.opacity(0.8))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            
            Spacer()
            
            // シャッターボタン
            Button(action: {
                
                if camera.canUse && camera.isSaved {
                    
                    camera.isSaved = false
                    camera.willTake = true
                }
            }) {
                
                ZStack {
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .stroke(Color.white, lineWidth: 4)
                        .frame(width: 68, height: 68)
                    
                }
            }
            
            Spacer()
            
            // 外カメラと内カメラを切り替えるボタン
            Button(action: {
                
                if camera.canUse {
                    
                    camera.front.toggle()
                    camera.changeCam()
                }
            }) {
                
                Image(systemName: "arrow.triangle.2.circlepath.camera")
                    .foregroundColor(.black)
                    .frame(width: 45, height: 45)
                    .background(.white.opacity(0.8))
                    .clipShape(Circle())
            }
            .frame(width: 60.0, height: 60.0)
            
        }
        .frame(height: 100)
        .padding(.horizontal, 25)
    }
}
