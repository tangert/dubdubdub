import SceneKit

protocol Graphable {
    var x: Float! { get set }
    var y: Float! { get set }
    var coordinates: (Float, Float)! { get }
}

class Centroid: Graphable {
    
    var x: Float!
    var y: Float!
    var coordinates: (Float, Float)! {
        return (x, y)
    }
    
    init() {
        self.x = 0
        self.y = 0
    }
    
    init(x: Float, y: Float) {
        self.x = x
        self.y = y
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class DataPoint: Graphable {
    
    //Adjusts on each iteration
    var previousCentroid = Centroid()
    var currentCentroid = Centroid()
    
    //Coordinate info
    var x: Float!
    var y: Float!
    var coordinates: (Float, Float)! {
        return (x, y)
    }
    
    init() {
        self.x = 0
        self.y = 0
    }
    
    init(x: Float, y: Float) {
        self.x = x
        self.y = y
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}


// K-means functions
func distance(point1: Graphable, point2: Graphable) -> Float {
    let yDist = point2.y - point1.y
    let xDist = point2.x - point1.x
    let totalDist = sqrt(powf(yDist, 2.0) + powf(xDist, 2.0))
    return totalDist
}

// Helper functions
func random(start: Int, end: Int) -> Int {
    var a = start
    var b = end
    // swap to prevent negative integer crashes
    if a > b {
        swap(&a, &b)
    }
    return Int(arc4random_uniform(UInt32(b - a + 1))) + a
}


////////////////////////////////////
// MARK: K MEANS IMPLEMENTATION
////////////////////////////////////

// Set k
let k = 5

// Create the data points
var dataPoints = [DataPoint]()

let start = 0
let end = 50

//Form the data points in clusters
for num in start..<end {
    let x = Float(random(start: num, end: end))
    let y = Float(random(start: num, end: end))
    let point = DataPoint(x: x, y: y)
    dataPoints.append(point)
}


// Initialize centroids array
var centroids = [Centroid]()

// Initialize random centroid locations
for _ in 0..<k {
    let x = Float(random(start: start, end: end))
    let y = Float(random(start: start, end: end))
    let centroid = Centroid(x: x, y: y)
    centroids.append(centroid)
}

// How to calculate whether it has converged?
var converged = false
var iterations = 0

while !converged {
    
    print("\n\nITERATION \(iterations):")
    
    // Checks convergence by comparing the previous and current centroids of all data points
    var allSame = true
    
    for point in dataPoints {
        
        var minDist = Float.greatestFiniteMagnitude
        var closestCentroid: Centroid!
        
        for centroid in centroids {
            let dist = distance(point1: point, point2: centroid)
            if dist <= minDist {
                minDist = dist
                closestCentroid = centroid
            }
        }
        
        point.previousCentroid = point.currentCentroid
        point.currentCentroid = closestCentroid
        
        if point.currentCentroid.coordinates! != point.previousCentroid.coordinates! {
            allSame = false
        }
        
        print("point: \(point.coordinates!)")
        print("min dist: \(minDist) | centroid: \(closestCentroid.coordinates!)")
        print("point current centroid: \(point.currentCentroid.coordinates!) | previous centroid: \(point.previousCentroid.coordinates!)\n")

    }
    
    if allSame {
        print("CONVERGING!")
        converged = true
    }
    
    iterations += 1
    
}


