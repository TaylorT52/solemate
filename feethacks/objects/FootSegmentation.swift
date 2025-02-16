import Foundation
import ARKit

actor FootSegmentation {
    private let yCutoffThreshold: Float = 0.05
    private let maxDistance: Float = 0.5  //max distance allowed (meters)
    
    //color threshold for white
    private let colorThreshold: Float = 0.7
    
    func segmentFoot(pointCloud: PointCloud, cameraPosition: SCNVector3) async -> PointCloud {
        let newPointCloud = PointCloud()
        let vertices = await pointCloud.vertices
        
        //lowest y as a reference
        let lowestY = vertices.values.map { $0.position.y }.min() ?? 0
        let cutoffHeight = lowestY + yCutoffThreshold
        
        //filter on y, distance, color
        for (key, vertex) in vertices {
            //above height cutoff
            if vertex.position.y > cutoffHeight {
                
                //within distance threshold
                let dx = vertex.position.x - cameraPosition.x
                let dy = vertex.position.y - cameraPosition.y
                let dz = vertex.position.z - cameraPosition.z
                let distance = sqrt(dx * dx + dy * dy + dz * dz)
                
                guard distance < maxDistance else { continue }
                
                //check if color is near white
                // vertex.color is in [0..1] for R, G, B, A
                let r = vertex.color.x
                let g = vertex.color.y
                let b = vertex.color.z
                
                //keep point if white enough
                if r > colorThreshold && g > colorThreshold && b > colorThreshold {
                    await newPointCloud.addVertex(key: key, vertex: vertex)
                }
            }
        }
        
        return newPointCloud
    }
}

// Extension to PLYFile for segmentation
extension PLYFile {
    static func createSegmented(from pointCloud: PointCloud, cameraPosition: SCNVector3) async -> PLYFile {
        let segmentation = FootSegmentation()
        let segmentedCloud = await segmentation.segmentFoot(pointCloud: pointCloud, cameraPosition: cameraPosition)
        return PLYFile(pointCloud: segmentedCloud)
    }
}
