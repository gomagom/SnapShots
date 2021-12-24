//
//  UpperPart.swift
//  SnapShots
//  
//  Created by Gomatamago on 2021/12/15
//  
//

import SwiftUI

struct UpperPart: View {
    
    @StateObject var camera: CameraModel
    
    @State var flashImage = "bolt.slash"
    let timerOptions = ["OFF", "1秒", "3秒", "5秒"]
    let delay = [0, 1, 3, 5]

    var body: some View {
        HStack {
            
            Spacer()
            
            // フラッシュ切り替えボタン
            Button(action: {
                
                // タップする度ON、OFF、AUTOを循環
                switch camera.flash {
                case .off:
                    flashImage = "bolt"
                    camera.flash = .on
                case .on:
                    flashImage = "bolt.badge.a"
                    camera.flash = .auto
                case .auto:
                    flashImage = "bolt.slash"
                    camera.flash = .off
                default:
                    return
                }
            }) {
                
                Image(systemName: flashImage)
                    .foregroundColor(.black)
                    .frame(width: 45, height: 45)
                    .background(.white.opacity(0.8))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            // タイマー設定用のボタン
            ZStack {
                
                // 背景
                Circle()
                    .fill(.white.opacity(0.8))
                
                // めんどくさいのでPickerを重ねる
                Picker("Time", selection: $camera.delay) {
                    
                    ForEach(0..<timerOptions.count) { id in
                        
                        Text(timerOptions[id]).tag(delay[id])
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            .frame(width: 45, height: 45)
            
            Spacer()
        }
        .frame(height: 60)
        .padding(.all, 30)
    }
}
