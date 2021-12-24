//
//  CameraView.swift
//  SnapShots
//  
//  Created by Gomatamago on 2021/12/15
//  
//

import SwiftUI

struct CameraView: View {
    
    @StateObject var camera = CameraModel()
    
    var body: some View {
        ZStack {
                        
            PreviewField(camera: camera)
            
            VStack {
                
                UpperPart(camera: camera)
                
                Spacer()
                
                LowerPart(camera: camera)
            }
        }
        .onAppear(perform: {
            
            camera.check()
            camera.detector?.check()
        })
        .onChange(of: camera.willTake) { state in
            
            if state {
                
                camera.camSequence()
            }
        }
    }
}

struct CameraView_Previews: PreviewProvider {
    static var previews: some View {
        CameraView()
    }
}
