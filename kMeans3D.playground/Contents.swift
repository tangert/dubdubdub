import SceneKit
import PlaygroundSupport

/*
 Playground stuff
 */

PlaygroundPage.current.needsIndefiniteExecution = true

protocol Graphable {
    var x: Float! { get set }
    var y: Float! { get set }
    var coordinates: (Float, Float)! { get }
    var vector: SCNVector3! { get }
}

class Centroid: Graphable {
    
    var x: Float!
    var y: Float!
    var coordinates: (Float, Float)! {
        return (x, y)
    }
    var vector: SCNVector3! {
        return SCNVector3.init(x, y, 0)
    }
    var allCoordinates = [(Float, Float)]()
    var allVectors = [SCNVector3]()
    var color: UIColor!
    
    init() {
        self.x = 0
        self.y = 0
    }
    
    // Constructor with x and y
    init(x: Float, y: Float) {
        self.x = x
        self.y = y
    }
    
    // Constructor with coordinate pair
    init(coordinate: (Float, Float)) {
        self.x = coordinate.0
        self.y = coordinate.1
    }
    
    func setCoord(x: Float, y: Float) {
        self.x = x
        self.y = y
    }
    
}

enum centroidType {
    case previous
    case current
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
    var vector: SCNVector3! {
        return SCNVector3.init(x, y, 0)
    }
    
    init() {
        self.x = 0
        self.y = 0
    }
    
    // Constructor with x and y
    init(x: Float, y: Float) {
        self.x = x
        self.y = y
    }
    
    // Constructor with coordinate pair
    init(coordinate: (Float, Float)) {
        self.x = coordinate.0
        self.y = coordinate.1
    }
    
    func setCentroid(type: centroidType, centroid: Centroid) {
        switch type{
        case .current:
            self.currentCentroid = centroid
        case .previous:
            self.previousCentroid = centroid
        }
    }
    
}

// SceneKit objects
// Used for 3D plotting
// Eventually will contain actual animatable 3D models
class BaseNode: SCNNode {
    
    var point: Graphable!
    
    override init() {
        super.init()
    }
    
    init(point: Graphable, geometry: SCNGeometry) {
        super.init()
        self.geometry = geometry
        self.point = point
        self.position = point.vector
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
struct kMeansManager {
    
    var k: Int!
    var data = [DataPoint]()
    
    // Data production variables
    var dataStart = 0
    var dataEnd = 25

    init(k: Int, data: [DataPoint]) {
        self.k = k
        self.data = data
    }
    
    init(k: Int) {
        self.k = k
    }
    
    mutating func generateData() {
        for _ in dataStart..<dataEnd {
            let x = Float(random(start: dataStart, end: dataEnd))
            let y = Float(random(start: dataStart, end: dataEnd))
            let point = DataPoint(x: x, y: y)
            data.append(point)
        }
    }
}

// Set k
var kMeans = kMeansManager(k: 2)
let k = 3

// Create the data points
var dataPoints = [DataPoint]()

let start = 0
let end = 50

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
    
    iterations += 1
    
    print("\n\nITERATION \(iterations):")
    
    // Checks convergence by comparing the previous and current centroids of all data points
    var allSame = true
    
    // Assign the points to each centroid
    for point in dataPoints {
        
        var minDist = Float.greatestFiniteMagnitude
        var closestCentroid: Centroid!
        
        // Iterate through each centroid and find the closest one to the current point
        for centroid in centroids {
            let dist = distance(point1: point, point2: centroid)
            if dist <= minDist {
                minDist = dist
                closestCentroid = centroid
            }
        }
        
        point.setCentroid(type: .previous, centroid: point.currentCentroid)
        point.setCentroid(type: .current, centroid: closestCentroid)
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
        centroid.setCoord(x: newLocation.0, y: newLocation.1)
    }
    
    if allSame {
        print("CONVERGING!")
        converged = true
    }
    
}

// 3D plotting!
//Scene kit setup
let scene = SCNScene()
let light = SCNLight()
light.type = SCNLight.LightType.omni
let lightNode = SCNNode()
lightNode.light = light
lightNode.position = SCNVector3(8,12,15)
scene.rootNode.addChildNode(lightNode)

// Plot in 3D!
for centroid in centroids {
    
    let box = SCNBox.init(width: 2.5, height: 2.5, length: 2.5, chamferRadius: 0.5)
    let node = BaseNode(point: centroid, geometry: box)
    let material = SCNMaterial()
    material.diffuse.contents = UIColor.white
    node.geometry?.materials = [material]
    
    scene.rootNode.addChildNode(node)
    
}

for dataPoint in dataPoints {
    
    let sphere = SCNSphere.init(radius: 1)
    let node = BaseNode(point: dataPoint, geometry: sphere)
    let material = SCNMaterial()
    material.diffuse.contents = dataPoint.currentCentroid.color
    node.geometry?.materials = [material]
    scene.rootNode.addChildNode(node)
    
}

let view = SCNView(frame: CGRect(x: 0, y: 0, width: 1000, height: 1000))
view.allowsCameraControl = true
view.autoenablesDefaultLighting = true
view.showsStatistics = true
view.scene = scene
view.backgroundColor = UIColor.black
PlaygroundPage.current.liveView = view

