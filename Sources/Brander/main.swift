import Cocoa

if #available(OSX 10.12, *) {
    let homeDirectory = FileManager.default.homeDirectoryForCurrentUser

    let fileUrl = homeDirectory
        .appendingPathComponent("Desktop")
        .appendingPathComponent("temp")
        .appendingPathExtension("txt")


    // make sure the file exists
    guard FileManager.default.fileExists(atPath: fileUrl.path) else {
        preconditionFailure("file expected at \(fileUrl.absoluteString) is missing")
    }

    // open the file for reading
    // note: user should be prompted the first time to allow reading from this location
    guard let filePointer:UnsafeMutablePointer<FILE> = fopen(fileUrl.path,"r") else {
        preconditionFailure("Could not open file at \(fileUrl.absoluteString)")
    }

    // a pointer to a null-terminated, UTF-8 encoded sequence of bytes
    var lineByteArrayPointer: UnsafeMutablePointer<CChar>? = nil

    // the smallest multiple of 16 that will fit the byte array for this line
    var lineCap: Int = 0

    // initial iteration
    var bytesRead = getline(&lineByteArrayPointer, &lineCap, filePointer)

    defer {
        // remember to close the file when done
        fclose(filePointer)
    }
    
    var lines = [[Int]]()
    
    while (bytesRead > 0) {
        // note: this translates the sequence of bytes to a string using UTF-8 interpretation
        let lineAsString = String.init(cString:lineByteArrayPointer!)
        
        // do whatever you need to do with this single line of text
        // for debugging, can print it
        
        
        let cleanLine = String(lineAsString.filter { !"\n\t".contains($0) } )
        let numbers = cleanLine.transformToArrayOfInt()
        lines.append(numbers)

        // updates number of bytes read, for the next iteration
        bytesRead = getline(&lineByteArrayPointer, &lineCap, filePointer)
    }
    
    let numberOfRows = lines[0].first!
    let numberOfColumns = lines[1].first!
    var startPointCoordinates = lines[2]
    startPointCoordinates[0] -= 1
    startPointCoordinates[1] -= 1
    var endPointCoordinates = lines[3]
    endPointCoordinates[0] -= 1
    endPointCoordinates[1] -= 1
    var gridLines = lines.suffix(9)
    
    var grid = [[Int]]()
    for _ in gridLines {
        if let gridRow = gridLines.popFirst() {
            grid.append(gridRow)
        }
    }
    
    let cellWithBall = 100
    var gridOfDistance = Array(repeating: Array(repeating: 0, count: numberOfColumns), count: numberOfRows)
    var resultGrid = Array(repeating: Array(repeating: " ", count: numberOfColumns), count: numberOfRows)
    for row in 0...numberOfRows - 1 {
        for column in 0...numberOfColumns - 1 {
            if grid[row][column] == 1 {
                gridOfDistance[row][column] = cellWithBall
                resultGrid[row][column] = "O"
            }
        }
    }
    
    var cellsWithDistance = Set<[Int]>()
    cellsWithDistance.insert(startPointCoordinates)
    gridOfDistance[startPointCoordinates.first!][startPointCoordinates.last!] = 0
    var distanceToEndPoint = 1

    func addToTheGridNumbersOfDistance(_ grid: [[Int]]) -> [[Int]] {
        var newGrid = Array(repeating: Array(repeating: 0, count: numberOfColumns), count: numberOfRows)
        var newCellsWithDistancePerIteration = Set<[Int]>()
        
        for row in 0...numberOfRows - 1 {
            for column in 0...numberOfColumns - 1 {
                
                let cell = [row, column]
                let downCell = [row + 1, column]
                let upperCell = [row - 1, column]
                let rightCell = [row, column + 1]
                let leftCell = [row, column - 1]
                let adjacentCells = Set(arrayLiteral: downCell, upperCell, rightCell, leftCell)
    
                let intersecion = Array(adjacentCells.intersection(cellsWithDistance))
    
                if grid[row][column] != cellWithBall, !cellsWithDistance.contains(cell), !intersecion.isEmpty {
                    newGrid[row][column] = distanceToEndPoint
                    newCellsWithDistancePerIteration.insert(cell)
                } else if grid[row][column] == cellWithBall {
                    newGrid[row][column] = cellWithBall
                } else {
                    newGrid[row][column] = grid[row][column]
                }
            }
        }
        cellsWithDistance = cellsWithDistance.union(newCellsWithDistancePerIteration)
        return newGrid
    }
    
    while distanceToEndPoint < 16 {
        gridOfDistance = addToTheGridNumbersOfDistance(gridOfDistance)
        distanceToEndPoint += 1
    }
    
    var returnPath = [String]()
    func getNextCell(byCell cell: [Int]) -> [Int] {
        var newCell = [Int]()
        var upperCell = Int()
        var downCell = Int()
        var rightCell = Int()
        var leftCell = Int()
        var adjacentCells = Dictionary<String, Int>()

        if cell[0] - 1 >= 0 {
            upperCell = gridOfDistance[cell[0] - 1][cell[1]]
            adjacentCells["U"] = upperCell
        }
        if cell[0] + 1 <= 8 {
            downCell = gridOfDistance[cell[0] + 1][cell[1]]
            adjacentCells["D"] = downCell
        }
        if cell[1] - 1 >= 0 {
            leftCell = gridOfDistance[cell[0]][cell[1] - 1]
            adjacentCells["L"] = leftCell
        }
        if cell[1] + 1 <= 8 {
            rightCell = gridOfDistance[cell[0]][cell[1] + 1]
            adjacentCells["R"] = rightCell
        }
        let valueOfCell = gridOfDistance[cell[0]][cell[1]]
        
        for (name, value) in adjacentCells {
            if valueOfCell - value == 1 {
                switch name {
                case "U": newCell = [cell[0] - 1, cell[1]]
                    resultGrid[cell[0] - 1][cell[1]] = "D"
                case "D": newCell = [cell[0] + 1, cell[1]]
                    resultGrid[cell[0] + 1][cell[1]] = "U"
                case "L": newCell = [cell[0], cell[1] - 1]
                    resultGrid[cell[0]][cell[1] - 1] = "R"
                case "R": newCell = [cell[0], cell[1] + 1]
                    resultGrid[cell[0]][cell[1] + 1] = "L"
                default: break
                }
                returnPath.append(name)
                break
            }
        }
        return newCell
    }

    var endPointOfPath = endPointCoordinates
    if gridOfDistance[endPointCoordinates[0]][endPointCoordinates[1]] != 0 {
        while endPointOfPath != startPointCoordinates {
            endPointOfPath = getNextCell(byCell: endPointOfPath)
        }
        
        returnPath = returnPath.reversed().map { direction ->  String in
            switch direction {
            case "U": return "D"
            case "D": return "U"
            case "R": return "L"
            case "L": return "R"
            default: return "X"
            }
        }
        
        resultGrid[endPointCoordinates[0]][endPointCoordinates[1]] = "F"
        resultGrid[startPointCoordinates[0]][startPointCoordinates[1]] = "S"

        for line in resultGrid {
            print(line)
        }
        print(returnPath)
        print("lenght of path:", returnPath.count)
    } else {
        print("there is no path")
    }



}
    
extension String {
    func transformToArrayOfInt() -> [Int] {
        var arrayOfInt = [Int]()
        for character in self {
            if let number = Int(String(character)) {
                arrayOfInt.append(number)
            }
        }
        return arrayOfInt
    }
}
