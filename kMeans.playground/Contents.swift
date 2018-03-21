import SceneKit
import PlaygroundSupport

/*
 Playground stuff
 */
let WIDTH = 500
let HEIGHT = 500

let container = UIView(frame: CGRect(x: 0, y: 0, width: WIDTH, height: HEIGHT))
PlaygroundPage.current.liveView = container
PlaygroundPage.current.needsIndefiniteExecution = true

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
    var allCoordinates = [(Float, Float)]()
    var color: UIColor!
    
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
    var allCentroids = [Centroid]()
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
func euclideanAverage(dataPoints: [DataPoint]) -> (Float, Float) {
    var sumX: Float = 0
    var sumY: Float = 0
    
    for point in dataPoints {
        sumX += point.x
        sumY += point.y
    }
    
    let avgX = sumX/Float(dataPoints.count)
    let avgY = sumY/Float(dataPoints.count)
    
    return (avgX, avgY)
}

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

func generateRandomColor() -> UIColor {
    let hue : CGFloat = CGFloat(arc4random() % 256) / 256 // use 256 to get full range from 0.0 to 1.0
    let saturation : CGFloat = CGFloat(arc4random() % 128) / 256 + 0.75 // from 0.5 to 1.0 to stay away from white
    let brightness : CGFloat = CGFloat(arc4random() % 128) / 256 + 0.75 // from 0.5 to 1.0 to stay away from black
    
    return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1)
}

func printInfo(point: DataPoint) {
    print("point: \(point.coordinates!)")
    print("point current centroid: \(point.currentCentroid.coordinates!) | previous centroid: \(point.previousCentroid.coordinates!)\n")
}


////////////////////////////////////
// MARK: K MEANS IMPLEMENTATION
////////////////////////////////////

// Set k
let k = 3

// Create the data points
var dataPoints = [DataPoint]()

let start = 0
let end = 100

//Form the data points in clusters
//Form k clusters
for _ in start..<end {
    let x = Float(random(start: start, end: end))
    let y = Float(random(start: start, end: end))
    let point = DataPoint(x: x, y: y)
    dataPoints.append(point)
}


// Initialize centroids array
var centroids = [Centroid]()

// Initialize random centroid locations
for i in 1...k {
    let x = Float(random(start: start, end: end/i))
    let y = Float(random(start: start, end: end/i))
    let centroid = Centroid(x: x, y: y)
    centroid.allCoordinates.append((x, y))
    centroid.color = generateRandomColor()
    centroids.append(centroid)
}

// How to calculate whether it has converged?
var converged = false
var iterations = 0

while !converged {
    
    print("\n\nITERATION \(iterations):")
    
    // Checks convergence by comparing the previous and current centroids of all data points
    var allSame = true
    
    // Assign the points to each centroid
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
        point.allCentroids.append(closestCentroid)
        
        if point.currentCentroid.coordinates! != point.previousCentroid.coordinates! {
            allSame = false
        }
    }
    
    // Get the new location for each centroid
    for centroid in centroids {
        
        var currentPoints = [DataPoint]()
        
        for data in dataPoints {
            if data.currentCentroid.coordinates == centroid.coordinates {
                currentPoints.append(data)
            }
        }
        
        let newLocation = euclideanAverage(dataPoints: currentPoints)
        centroid.allCoordinates.append(newLocation)
        centroid.x = newLocation.0
        centroid.y = newLocation.1
    }
    
    if allSame {
        print("CONVERGING!")
        converged = true
    }
    
    iterations += 1
    
}

// Plot the centroids
for centroid in centroids {
    for i in 1...centroid.allCoordinates.count {
        
        let coord = centroid.allCoordinates[i-1]
        let scaledX = (coord.0)/Float(end) * Float(WIDTH)
        let scaledY = (coord.1)/Float(end) * Float(HEIGHT)
        
        let dataView = UIView(frame: CGRect(x: Double(scaledX), y: Double(scaledY), width: 15, height: 15))
        print ("i: \(i) | count: \(centroid.allCoordinates.count)")
        let opacity = Double(i)/Double(centroid.allCoordinates.count)
        print("OPACITY: \(opacity)")
        
        dataView.backgroundColor = UIColor.white.withAlphaComponent(CGFloat(opacity))
        dataView.layer.cornerRadius = 10
        container.addSubview(dataView)
    }
}

// Plot the data
for data in dataPoints {
    let scaledX = (data.x)/Float(end) * Float(WIDTH)
    let scaledY = (data.y)/Float(end) * Float(HEIGHT)
    
    let dataView = UIView(frame: CGRect(x: Double(scaledX), y: Double(scaledY), width: 10, height: 10))
    dataView.backgroundColor = data.currentCentroid.color.withAlphaComponent(0.75)
    dataView.layer.cornerRadius = 7.5
    container.addSubview(dataView)
}
