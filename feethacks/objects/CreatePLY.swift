//
//  CreatePLY.swift
//  feethacks
//
//  Created by Taylor Tam on 2/15/25.
//

import Foundation
import SwiftUI
import ARKit

import Foundation
import SwiftUI
import ARKit

struct PLYFile: Transferable {
    let pointCloud: PointCloud
    
    enum Error: LocalizedError {
        case cannotExport
    }
    
    // Add a struct to hold scan results
    struct ScanResults {
        let data: Data
        let footLength: Float
        let confidence: Float
    }
    
    // Updated export function which takes cameraPosition as an argument
    func export(cameraPosition: SCNVector3) async throws -> Data {
        print("Starting export process...")
        
        // First segment the foot using both y cutoff and distance filtering
        let segmentation = FootSegmentation()
        print("Segmenting foot...")
        let segmentedCloud = await segmentation.segmentFoot(pointCloud: pointCloud, cameraPosition: cameraPosition)
        
        // Measure the foot
        print("Measuring foot...")
        let measurement = FootMeasurement()
        let dimensions = await measurement.measureFootLength(pointCloud: segmentedCloud)
        
        // Get vertices for PLY creation
        let vertices = await segmentedCloud.vertices
        
        var plyContent = """
        ply
        format ascii 1.0
        element vertex \(vertices.count)
        property float x
        property float y
        property float z
        property uchar red
        property uchar green
        property uchar blue
        property uchar alpha
        end_header
        """
        
        for vertex in vertices.values {
            // Convert position and color
            let x = vertex.position.x
            let y = vertex.position.y
            let z = vertex.position.z
            let r = UInt8(vertex.color.x * 255)
            let g = UInt8(vertex.color.y * 255)
            let b = UInt8(vertex.color.z * 255)
            let a = UInt8(vertex.color.w * 255)
            
            // Append the vertex data
            plyContent += "\n\(x) \(y) \(z) \(r) \(g) \(b) \(a)"
        }
        
        guard let data = plyContent.data(using: .ascii) else {
            throw Error.cannotExport
        }
        
        // Upload the PLY data
        uploadData(plyData: data)
        
        // Print measurements with more detail
        print("-------- Foot Measurements --------")
        print("Length: \(String(format: "%.1f", dimensions.length * 100)) cm")
        print("Confidence: \(String(format: "%.1f", dimensions.confidence * 100))%")
        print("----------------------------------")
        
        return data
    }
    
    // Updated exportWithMeasurements to include cameraPosition
    func exportWithMeasurements(cameraPosition: SCNVector3) async throws -> ScanResults {
        // First segment the foot with distance filtering
        print("Segmenting foot...")
        let segmentation = FootSegmentation()
        let segmentedCloud = await segmentation.segmentFoot(pointCloud: pointCloud, cameraPosition: cameraPosition)
        
        print("Measuring foot...")
        let measurement = FootMeasurement()
        let dimensions = await measurement.measureFootLength(pointCloud: segmentedCloud)
        
        let linePoints = createMeasurementLine(start: dimensions.startPoint, end: dimensions.endPoint, numberOfPoints: 100)
                
        // Get vertices for PLY creation
        let vertices = await segmentedCloud.vertices
        
        let totalVertices = vertices.count + linePoints.count
        
        var plyContent = """
        ply
        format ascii 1.0
        element vertex \(totalVertices)
        property float x
        property float y
        property float z
        property uchar red
        property uchar green
        property uchar blue
        property uchar alpha
        end_header
        """
        
        for vertex in vertices.values {
            // Convert position and color
            let x = vertex.position.x
            let y = vertex.position.y
            let z = vertex.position.z
            let r = UInt8(vertex.color.x * 255)
            let g = UInt8(vertex.color.y * 255)
            let b = UInt8(vertex.color.z * 255)
            let a = UInt8(vertex.color.w * 255)
            
            // Append the vertex data
            plyContent += "\n\(x) \(y) \(z) \(r) \(g) \(b) \(a)"
        }
        
        for point in linePoints {
            plyContent += "\n\(point.x) \(point.y) \(point.z) 255 0 0 255"
        }
                
        guard let data = plyContent.data(using: .ascii) else {
            throw Error.cannotExport
        }
        
        // Upload the PLY data
        uploadData(plyData: data)
        
        print("length: \(dimensions.length)")
        
        // Return both the PLY data and the measurements
        return ScanResults(
            data: data,
            footLength: dimensions.length,
            confidence: dimensions.confidence
        )
    }
    
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .data) {
            try await $0.export(cameraPosition: SCNVector3(0, 0, 0))
        }.suggestedFileName("exported.ply")
    }
    
    // Write the ply data to a temporary file
    func writePLYDataToTempFile(data: Data) throws -> URL {
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent("exported.ply")
        try data.write(to: fileURL)
        return fileURL
    }
    
    private func createMeasurementLine(start: SCNVector3, end: SCNVector3, numberOfPoints: Int) -> [SCNVector3] {
        var linePoints: [SCNVector3] = []
        
        for i in 0...numberOfPoints {
            let t = Float(i) / Float(numberOfPoints)
            let point = SCNVector3(
                x: start.x + (end.x - start.x) * t,
                y: start.y + (end.y - start.y) * t,
                z: start.z + (end.z - start.z) * t
            )
            linePoints.append(point)
        }
        
        return linePoints
    }
    
    func uploadData(plyData: Data) {
        let uploader = GCPUploader()
        
        Task {
            uploader.uploadFile(data: plyData, fileName: genUniqueFilename()) { success, filePath in
                if success {
                    print("Upload to GCP completed. File path: \(filePath ?? "No file path returned")")
                } else {
                    print("Upload to GCP failed.")
                }
            }
        }
    }
    
    func genUniqueFilename(withExtension ext: String = "ply") -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        let uuid = UUID().uuidString
        return "\(timestamp)-\(uuid).\(ext)"
    }
}
