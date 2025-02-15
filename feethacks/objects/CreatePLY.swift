//
//  CreatePLY.swift
//  feethacks
//
//  Created by Taylor Tam on 2/15/25.
//

import Foundation
import SwiftUI

//create a ply file for export
struct PLYFile: Transferable {
    
    let pointCloud: PointCloud
    
    enum Error: LocalizedError {
        case cannotExport
    }
    
    func export() async throws -> Data {
        let vertices = await pointCloud.vertices
        
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
        
        uploadData(plyData: data)
        
        return data
    }
    
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .data) {
            try await $0.export()
        }.suggestedFileName("exported.ply")
    }
    
    //write the ply data to a temporary file
    func writePLYDataToTempFile(data: Data) throws -> URL {
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent("exported.ply")
        try data.write(to: fileURL)
        return fileURL
    }
    
    func uploadData(plyData: Data) {
        let uploader = GCPUploader()
        
        //upload the data to a GCP bucket
        Task {
            do {
                uploader.uploadFile(data: plyData, fileName: genUniqueFilename()) { success in
                    if success {
                        print("Upload to GCP completed.")
                    } else {
                        print("Upload to GCP failed.")
                    }
                }
            }
        }
    }
    
    //generate a unique filename for uploads
    func genUniqueFilename(withExtension ext: String = "ply") -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        let uuid = UUID().uuidString
        return "\(timestamp)-\(uuid).\(ext)"
    }
}
