//
//  FootSegmentation.swift
//  feethacks
//
//  Created by Taylor Tam on 2/15/25.
//

import Foundation
import ARKit

actor FootSegmentation {
    private let yCutoffThreshold: Float = 0.05  
    
    func segmentFoot(pointCloud: PointCloud) async -> PointCloud {
        let newPointCloud = PointCloud()
        let vertices = await pointCloud.vertices
        
        // Find the lowest point in the scan to use as reference
        let lowestY = vertices.values.map { $0.position.y }.min() ?? 0
        let cutoffHeight = lowestY + yCutoffThreshold
        
        // Keep only points above the cutoff
        for (key, vertex) in vertices {
            if vertex.position.y > cutoffHeight {
                await newPointCloud.addVertex(key: key, vertex: vertex)
            }
        }
        
        return newPointCloud
    }
}

// Extension to PLYFile for segmentation
extension PLYFile {
    static func createSegmented(from pointCloud: PointCloud) async -> PLYFile {
        let segmentation = FootSegmentation()
        let segmentedCloud = await segmentation.segmentFoot(pointCloud: pointCloud)
        return PLYFile(pointCloud: segmentedCloud)
    }
}
