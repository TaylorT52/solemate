//
//  PointCloud.swift
//  feethacks
//
//  Created by Taylor Tam on 2/15/25.
//

import Foundation
import ARKit


actor PointCloud {
    //to create a point cloud
    struct GridKey: Hashable {
        static let density: Float = 100
        private let id: Int
        
        init(_ position: SCNVector3) {
            var hasher = Hasher()
            for component in [position.x, position.y, position.z] {
               hasher.combine(Int(round(component * Self.density)))
           }
           id = hasher.finalize()
        }
    }
    
    //3d position and color for each point
    struct Vertex {
         let position: SCNVector3
         let color: simd_float4
    }
    
    //create arr of vertices
    private(set) var vertices: [GridKey: Vertex] = [:]
    
    //process frame by frame
    func process(frame: ARFrame) async {
        guard let depth = (frame.smoothedSceneDepth ?? frame.sceneDepth),
              let depthBuffer = PixelBuffer<Float32>(pixelBuffer: depth.depthMap),
              let confidenceMap = depth.confidenceMap,
              let confidenceBuffer = PixelBuffer<UInt8>(pixelBuffer: confidenceMap),
              let imageBuffer = YCBCRBuffer(pixelBuffer: frame.capturedImage) else { return }
           
        let rotateToARCamera = makeRotateToARCameraMatrix(orientation: .portrait)
        let cameraTransform = frame.camera.viewMatrix(for: .portrait).inverse * rotateToARCamera
        
        // iterate through pixels in depth buffer
        for row in 0..<depthBuffer.size.height {
            for col in 0..<depthBuffer.size.width {
                // get confidence value
                let confidenceRawValue = Int(confidenceBuffer.value(x: col, y: row))
                guard let confidence = ARConfidenceLevel(rawValue: confidenceRawValue) else {
                    continue
                }
                            
                // filter by confidence
                if confidence != .high { continue }
                            
                // get distance value from
                let depth = depthBuffer.value(x: col, y: row)
                            
                // filter points by distance
                if depth > 2 { return }
                            
                let normalizedCoord = simd_float2(Float(col) / Float(depthBuffer.size.width),
                                                  Float(row) / Float(depthBuffer.size.height))
                            
                let imageSize = imageBuffer.size.asFloat
                let screenPoint = simd_float3(normalizedCoord * imageSize, 1)

                // Transform the 2D screen point into local 3D camera space
                let localPoint = simd_inverse(frame.camera.intrinsics) * screenPoint * depth
                    
                // Converts the local camera space 3D point into world space.
                let worldPoint = cameraTransform * simd_float4(localPoint, 1)
                    
                // Normalizes the result.
                let resulPosition = (worldPoint / worldPoint.w)
                    
                let pointPosition = SCNVector3(x: resulPosition.x,
                                               y: resulPosition.y,
                                               z: resulPosition.z)

                let key = PointCloud.GridKey(pointPosition)
                    
                if vertices[key] == nil {
                    let pixelRow = Int(round(normalizedCoord.y * imageSize.y))
                    let pixelColumn = Int(round(normalizedCoord.x * imageSize.x))
                    let color = imageBuffer.color(x: pixelColumn, y: pixelRow)


                    vertices[key] = PointCloud.Vertex(position: pointPosition,
                                                      color: color)
                }
            }
        }
    }
    
    func makeRotateToARCameraMatrix(orientation: UIInterfaceOrientation) -> matrix_float4x4 {
        //flip y, z to align with ARKit's coordinates
        let flipYZ = matrix_float4x4(
            [1, 0, 0, 0],
            [0, -1, 0, 0],
            [0, 0, -1, 0],
            [0, 0, 0, 1]
        )
        
        //rotaton angle in radians
        let rotationAngle: Float = switch orientation {
        case .landscapeLeft: .pi
        case .portrait: .pi / 2
        case .portraitUpsideDown: -.pi / 2
        default: 0
            
        }
        //create a rotation matrix about the z-axis
        let quaternion = simd_quaternion(rotationAngle, simd_float3(0, 0, 1))
        let rotationMatrix = matrix_float4x4(quaternion)
        
        return flipYZ * rotationMatrix
    }
    
    
    //struct for storing CVPixelBuffer resolution
    struct Size {
        let width: Int
        let height: Int
        
        var asFloat: simd_float2 {
            simd_float2(Float(width), Float(height))
        }
    }
    
    //******* Data structures *******//
    
    //create a pixel buffer
    final class PixelBuffer<T> {
        
        let size: Size
        let bytesPerRow: Int

        private let pixelBuffer: CVPixelBuffer
        private let baseAddress: UnsafeMutableRawPointer
        
        init?(pixelBuffer: CVPixelBuffer) {
            self.pixelBuffer = pixelBuffer

            // lock the buffer while we are getting its values
            CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
            
            guard let baseAddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0) else {
                CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
                return nil
            }
            self.baseAddress = baseAddress
            
            size = .init(width: CVPixelBufferGetWidth(pixelBuffer),
                         height: CVPixelBufferGetHeight(pixelBuffer))
            bytesPerRow =  CVPixelBufferGetBytesPerRow(pixelBuffer)
        }
        
        // obtain value from pixel buffer in specified coordinates
        func value(x: Int, y: Int) -> T {

            // move to the specified address and get the value bounded to our type
            let rowPtr = baseAddress.advanced(by: y * bytesPerRow)
            return rowPtr.assumingMemoryBound(to: T.self)[x]
        }
        
        deinit {
            CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
        }
    }
    
    //ycbcr buffer is how we store image
    final class YCBCRBuffer {
        
        let size: Size
        
        private let pixelBuffer: CVPixelBuffer
        private let yPlane: UnsafeMutableRawPointer
        private let cbCrPlane: UnsafeMutableRawPointer
        private let ySize: Size
        private let cbCrSize: Size
        
        init?(pixelBuffer: CVPixelBuffer) {
            self.pixelBuffer = pixelBuffer
            CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
            
            guard let yPlane = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0),
                    let cbCrPlane = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1) else {
                CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
                return nil
            }
            
            self.yPlane = yPlane
            self.cbCrPlane = cbCrPlane
     
            size = .init(width: CVPixelBufferGetWidth(pixelBuffer),
                         height: CVPixelBufferGetHeight(pixelBuffer))
            
            ySize = .init(width: CVPixelBufferGetWidthOfPlane(pixelBuffer, 0),
                          height: CVPixelBufferGetHeightOfPlane(pixelBuffer, 0))
            
            cbCrSize = .init(width: CVPixelBufferGetWidthOfPlane(pixelBuffer, 1),
                             height: CVPixelBufferGetHeightOfPlane(pixelBuffer, 1))
        }
        
        func color(x: Int, y: Int) -> simd_float4 {
            let yIndex = y * CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0) + x
            let uvIndex = y / 2 * CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1) + x / 2 * 2
            
            // Extract the Y, Cb, and Cr values
            let yValue = yPlane.advanced(by: yIndex)
                    .assumingMemoryBound(to: UInt8.self).pointee

            let cbValue = cbCrPlane.advanced(by: uvIndex)
                    .assumingMemoryBound(to: UInt8.self).pointee

            let crValue = cbCrPlane.advanced(by: uvIndex + 1)
                    .assumingMemoryBound(to: UInt8.self).pointee
            
            // Convert YCbCr to RGB
            let y = Float(yValue) - 16
            let cb = Float(cbValue) - 128
            let cr = Float(crValue) - 128
            
            let r = 1.164 * y + 1.596 * cr
            let g = 1.164 * y - 0.392 * cb - 0.813 * cr
            let b = 1.164 * y + 2.017 * cb
            
            // normalize rgb components
            return simd_float4(max(0, min(255, r)) / 255.0,
                               max(0, min(255, g)) / 255.0,
                               max(0, min(255, b)) / 255.0, 1.0)
        }
        
        deinit {
            CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
        }
    }
}
