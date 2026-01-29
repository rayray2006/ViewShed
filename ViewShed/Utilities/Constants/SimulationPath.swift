import Foundation
import CoreLocation

struct SimulationPath {
    /// US Highway 2: Scenic -> Stevens Pass -> Berne
    static let highway2: [Coordinate] = [
        Coordinate(latitude: 47.7126, longitude: -121.1477), // Scenic
        Coordinate(latitude: 47.7150, longitude: -121.1400),
        Coordinate(latitude: 47.7180, longitude: -121.1300),
        Coordinate(latitude: 47.7220, longitude: -121.1200),
        Coordinate(latitude: 47.7280, longitude: -121.1100),
        Coordinate(latitude: 47.7350, longitude: -121.1000),
        Coordinate(latitude: 47.7400, longitude: -121.0950),
        Coordinate(latitude: 47.7465, longitude: -121.0890), // Stevens Pass
        Coordinate(latitude: 47.7500, longitude: -121.0800),
        Coordinate(latitude: 47.7550, longitude: -121.0700),
        Coordinate(latitude: 47.7600, longitude: -121.0600),
        Coordinate(latitude: 47.7650, longitude: -121.0500),
        Coordinate(latitude: 47.7700, longitude: -121.0300),
        Coordinate(latitude: 47.7750, longitude: -121.0100),
        Coordinate(latitude: 47.7780, longitude: -120.9900),
        Coordinate(latitude: 47.7787, longitude: -120.9750)  // Berne
    ]
    
    /// Interpolate points between key waypoints to create a smooth path
    static func interpolatedPath(steps: Int = 100) -> [Coordinate] {
        guard highway2.count >= 2 else { return highway2 }
        
        var smoothedPath: [Coordinate] = []
        let totalSegments = highway2.count - 1
        let stepsPerSegment = max(1, steps / totalSegments)
        
        for i in 0..<totalSegments {
            let start = highway2[i]
            let end = highway2[i+1]
            
            for j in 0..<stepsPerSegment {
                let fraction = Double(j) / Double(stepsPerSegment)
                let lat = start.latitude + (end.latitude - start.latitude) * fraction
                let lon = start.longitude + (end.longitude - start.longitude) * fraction
                smoothedPath.append(Coordinate(latitude: lat, longitude: lon))
            }
        }
        
        smoothedPath.append(highway2.last!)
        return smoothedPath
    }
}
