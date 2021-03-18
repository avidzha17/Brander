import Cocoa

if #available(OSX 10.12, *) {
    let homeDirectory = FileManager.default.homeDirectoryForCurrentUser

    let fileUrl = homeDirectory
        .appendingPathComponent("Desktop")
        .appendingPathComponent("temp")
        .appendingPathExtension("txt")

    guard FileManager.default.fileExists(atPath: fileUrl.path) else {
        preconditionFailure("\(fileUrl.absoluteString) is missing")
    }
    
    var inputData = [[Int]]()
    do {
        let textOfFile = try String(contentsOf: fileUrl)
        
        for line in textOfFile.split(separator: "\n") {
            let intRepresentationOfFile = String(line.filter { !"\t".contains($0) }).transformToArrayOfInt()
            inputData.append(intRepresentationOfFile)
        }
    } catch let error as NSError {
        print(error)
    }
    
    let numberOfRows = inputData[0].first!
    let numberOfColumns = inputData[1].first!
    let startPointCoordinates = inputData[2].map {$0 - 1}
    let endPointCoordinates = inputData[3].map {$0 - 1}
    var linesForMatrix = inputData.suffix(9)
    
    var matrixOfZerosAndOnes = [[Int]]()
    for _ in linesForMatrix {
        if let matrixRow = linesForMatrix.popFirst() {
            matrixOfZerosAndOnes.append(matrixRow)
        }
    }
    
    let cellWithBall = 100
    
    var matrixOfDistance = Array(repeating: Array(repeating: 0, count: numberOfColumns), count: numberOfRows)
    var resultMatrix = Array(repeating: Array(repeating: " ", count: numberOfColumns), count: numberOfRows)
    
    for row in 0...numberOfRows - 1 {
        for column in 0...numberOfColumns - 1 {
            if matrixOfZerosAndOnes[row][column] == 1 {
                matrixOfDistance[row][column] = cellWithBall
                resultMatrix[row][column] = "O"
            }
        }
    }
        
    var cellsWithDistance = Set<[Int]>()
    cellsWithDistance.insert(startPointCoordinates)
    
    matrixOfDistance[startPointCoordinates.first!][startPointCoordinates.last!] = 0
    var distanceToEndPoint = 1

    func addDistance(toMatrixOfDistance matrix: [[Int]]) -> [[Int]] {
        var newMatrixOfDistance = Array(repeating: Array(repeating: 0, count: numberOfColumns), count: numberOfRows)
        var newCellsWithDistancePerIteration = Set<[Int]>()
        
        for row in 0...numberOfRows - 1 {
            for column in 0...numberOfColumns - 1 {
                
                let currentCell = [row, column]
                                
                let downCell = [row + 1, column]
                let upperCell = [row - 1, column]
                let rightCell = [row, column + 1]
                let leftCell = [row, column - 1]
                let adjacentCells = Set(arrayLiteral: downCell, upperCell, rightCell, leftCell)
    
                let adjacentCellsWithDistance = Array(adjacentCells.intersection(cellsWithDistance))
    
                if matrix[row][column] != cellWithBall, !cellsWithDistance.contains(currentCell), !adjacentCellsWithDistance.isEmpty {
                    newMatrixOfDistance[row][column] = distanceToEndPoint
                    newCellsWithDistancePerIteration.insert(currentCell)
                } else if matrix[row][column] == cellWithBall {
                    newMatrixOfDistance[row][column] = cellWithBall
                } else {
                    newMatrixOfDistance[row][column] = matrix[row][column]
                }
            }
        }
        cellsWithDistance = cellsWithDistance.union(newCellsWithDistancePerIteration)
        return newMatrixOfDistance
    }
    
    var amountOfRowsWithZeros = matrixOfDistance.filter({ $0.contains(0) })
    
    while (matrixOfDistance[endPointCoordinates[0]][endPointCoordinates[1]] == 0 || amountOfRowsWithZeros.count > 1) {
        matrixOfDistance = addDistance(toMatrixOfDistance: matrixOfDistance)
        distanceToEndPoint += 1
        amountOfRowsWithZeros = matrixOfDistance.filter({ $0.contains(0) })
    }
    

    
    var pathToStartPoint = [String]()
    
    func getNextCell(byCell cell: [Int]) -> [Int] {
        
        var adjacentCells = Dictionary<String, Int>()

        if cell[0] - 1 >= 0 {
            let upperCell = matrixOfDistance[cell[0] - 1][cell[1]]
            adjacentCells["U"] = upperCell
        }
        if cell[0] + 1 <= 8 {
            let downCell = matrixOfDistance[cell[0] + 1][cell[1]]
            adjacentCells["D"] = downCell
        }
        if cell[1] - 1 >= 0 {
            let leftCell = matrixOfDistance[cell[0]][cell[1] - 1]
            adjacentCells["L"] = leftCell
        }
        if cell[1] + 1 <= 8 {
            let rightCell = matrixOfDistance[cell[0]][cell[1] + 1]
            adjacentCells["R"] = rightCell
        }
        let distanceToStartPoint = matrixOfDistance[cell[0]][cell[1]]
        
        var newCell = [Int]()

        for (direction, distance) in adjacentCells {
            if distanceToStartPoint - distance == 1 {
                switch direction {
                case "U": newCell = [cell[0] - 1, cell[1]]
                    resultMatrix[cell[0] - 1][cell[1]] = "D"
                case "D": newCell = [cell[0] + 1, cell[1]]
                    resultMatrix[cell[0] + 1][cell[1]] = "U"
                case "L": newCell = [cell[0], cell[1] - 1]
                    resultMatrix[cell[0]][cell[1] - 1] = "R"
                case "R": newCell = [cell[0], cell[1] + 1]
                    resultMatrix[cell[0]][cell[1] + 1] = "L"
                default: break
                }
                pathToStartPoint.append(direction)
                break
            }
        }
        return newCell
    }
    
    func resultOutput() {
        let pathToEndPoint = pathToStartPoint.reversed().map { direction ->  String in
            switch direction {
            case "U": return "D"
            case "D": return "U"
            case "R": return "L"
            case "L": return "R"
            default: return "X"
            }
        }
        
        resultMatrix[endPointCoordinates[0]][endPointCoordinates[1]] = "F"
        resultMatrix[startPointCoordinates[0]][startPointCoordinates[1]] = "S"

        for line in resultMatrix {
            print(line)
        }
        
        print("\n",pathToEndPoint)
        print("\n lenght of the path:", pathToEndPoint.count)
    }

    var endPointOfPath = endPointCoordinates
    if matrixOfDistance[endPointCoordinates[0]][endPointCoordinates[1]] != 0, matrixOfZerosAndOnes[startPointCoordinates[0]][startPointCoordinates[1]] == 1, matrixOfZerosAndOnes[endPointCoordinates[0]][endPointCoordinates[1]] == 0 {
        while endPointOfPath != startPointCoordinates {
            endPointOfPath = getNextCell(byCell: endPointOfPath)
        }
        resultOutput()
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
