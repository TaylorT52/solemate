//
//  FootMeasurement.swift
//  feethacks
//
//  Created by Taylor Tam on 2/15/25.
//

import Foundation
import ARKit
import simd

actor FootMeasurement {
    struct FootDimensions {
        let length: Float       // in meters
        let confidence: Float   // 0-1 scale
        let startPoint: SCNVector3  // For visualization
        let endPoint: SCNVector3    // For visualization
    }
    
    // Clustering parameters
    private let clusterThreshold: Float = 0.01  // 1cm threshold for clustering
    private let minClusterSize = 10  // Minimum points for valid cluster
    
    func measureFootLength(pointCloud: PointCloud) async -> FootDimensions {
        let vertices = await pointCloud.vertices
        guard !vertices.isEmpty else {
            return FootDimensions(
                length: 0,
                confidence: 0,
                startPoint: SCNVector3Zero,
                endPoint: SCNVector3Zero
            )
        }
        
        let positions = vertices.values.map { $0.position }
        
        // 1. Find rough orientation using PCA
        let centroid = calculateCentroid(positions)
        let (principalAxes, _) = performPCA(positions, centroid)
        let primaryAxis = principalAxes[0]
        
        // 2. Project points onto primary axis
        let projectedPoints = positions.map { pos -> (SCNVector3, Float) in
            let point = simd_float3(pos.x, pos.y, pos.z)
            let projValue = simd_dot(point - simd_float3(centroid.x, centroid.y, centroid.z), primaryAxis)
            return (pos, projValue)
        }.sorted { $0.1 < $1.1 }
        
        // 3. Cluster points along primary axis
        var clusters: [[SCNVector3]] = []
        var currentCluster: [SCNVector3] = []
        
        for i in 0..<projectedPoints.count {
            if currentCluster.isEmpty {
                currentCluster.append(projectedPoints[i].0)
            } else {
                let lastProj = projectedPoints[i-1].1
                let currentProj = projectedPoints[i].1
                
                if abs(currentProj - lastProj) < clusterThreshold {
                    currentCluster.append(projectedPoints[i].0)
                } else {
                    if currentCluster.count >= minClusterSize {
                        clusters.append(currentCluster)
                    }
                    currentCluster = [projectedPoints[i].0]
                }
            }
        }
        
        if currentCluster.count >= minClusterSize {
            clusters.append(currentCluster)
        }
        
        // 4. Find start and end points from valid clusters
        guard clusters.count >= 2 else {
            return FootDimensions(
                length: 0,
                confidence: 0,
                startPoint: SCNVector3Zero,
                endPoint: SCNVector3Zero
            )
        }
        
        let startCluster = clusters.first!
        let endCluster = clusters.last!
        
        let startPoint = averagePosition(of: startCluster)
        let endPoint = averagePosition(of: endCluster)
        
        // 5. Calculate length and confidence
        let length = distance(from: startPoint, to: endPoint)
        let confidence = calculateClusterConfidence(
            clusterCount: clusters.count,
            pointCount: positions.count,
            startClusterSize: startCluster.count,
            endClusterSize: endCluster.count
        )
        
        return FootDimensions(
            length: length,
            confidence: confidence,
            startPoint: startPoint,
            endPoint: endPoint
        )
    }
    
    private func averagePosition(of points: [SCNVector3]) -> SCNVector3 {
        let sum = points.reduce(SCNVector3Zero) { result, point in
            SCNVector3(
                result.x + point.x,
                result.y + point.y,
                result.z + point.z
            )
        }
        let count = Float(points.count)
        return SCNVector3(
            sum.x / count,
            sum.y / count,
            sum.z / count
        )
    }
    
    private func calculateClusterConfidence(
        clusterCount: Int,
        pointCount: Int,
        startClusterSize: Int,
        endClusterSize: Int
    ) -> Float {
        // Higher confidence if:
        // 1. We have enough total points
        // 2. Start and end clusters are well-defined
        // 3. We have a reasonable number of clusters
        
        let pointDensity = min(Float(pointCount) / 1000.0, 1.0)
        let clusterQuality = min(Float(startClusterSize + endClusterSize) / 100.0, 1.0)
        let clusterCountScore = min(Float(clusterCount) / 5.0, 1.0) // Normalize to expecting about 5 clusters
        
        return (pointDensity + clusterQuality + clusterCountScore) / 3.0
    }
    
    // Keep existing helper functions
    private func calculateCentroid(_ positions: [SCNVector3]) -> simd_float3 {
        let sum = positions.reduce(simd_float3.zero) { sum, pos in
            sum + simd_float3(pos.x, pos.y, pos.z)
        }
        return sum / Float(positions.count)
    }
    
    private func performPCA(_ positions: [SCNVector3], _ centroid: simd_float3) -> (axes: [simd_float3], eigenvalues: [Float]) {
        // Keep existing PCA implementation
        var covMatrix = matrix_float3x3()
        let centerAdjusted = positions.map { pos -> simd_float3 in
            simd_float3(pos.x, pos.y, pos.z) - centroid
        }
        
        for i in 0..<3 {
            for j in 0..<3 {
                var sum: Float = 0
                for point in centerAdjusted {
                    sum += point[i] * point[j]
                }
                covMatrix[i][j] = sum / Float(positions.count)
            }
        }
        
        let xAxis = simd_float3(1, 0, 0)
        let yAxis = simd_float3(0, 1, 0)
        let zAxis = simd_float3(0, 0, 1)
        
        let variances = centerAdjusted.reduce(into: simd_float3.zero) { result, point in
            result.x += point.x * point.x
            result.y += point.y * point.y
            result.z += point.z * point.z
        }
        let eigenvalues = [variances.x, variances.y, variances.z].map { $0 / Float(positions.count) }
        
        return ([xAxis, yAxis, zAxis], eigenvalues)
    }
    
    private func distance(from p1: SCNVector3, to p2: SCNVector3) -> Float {
        let dx = p2.x - p1.x
        let dy = p2.y - p1.y
        let dz = p2.z - p1.z
        return sqrt(dx*dx + dy*dy + dz*dz)
    }
}
