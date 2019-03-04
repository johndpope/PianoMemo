//
//  Diff3.swift
//  PianoNote
//
//  Created by 김범수 on 2018. 4. 3..
//  Copyright © 2018년 piano. All rights reserved.
//

import Foundation

private struct Stack<Element> {

    private var items = [Element]()

    var count: Int {
        return items.count
    }

    mutating func push(_ item: Element) {
        items.append(item)
    }

    mutating func pop() -> Element? {
        return count == 0 ? nil : items.removeLast()
    }

    func isEmpty() -> Bool {
        return self.count == 0
    }
}

enum Diff3Block {
    case add(Int, NSRange)
    case delete(NSRange)
    case change(NSRange, NSRange, NSRange) // o a b
    case conflict(NSRange, NSRange, NSRange)// o a b
}

class Diff3Maker {

    private let aDiffMaker: DiffMaker
    private let bDiffMaker: DiffMaker

    private lazy var oaDiffChunks: [DiffBlock] = aDiffMaker.parseTwoStrings()
    private lazy var obDiffChunks: [DiffBlock] = bDiffMaker.parseTwoStrings()

    private var conflictArray: [(bIndices: [Int], aIndices: [Int])] = []// bChunks, aChunks

    private var offsetArray: [Int] = []
    private var edges = [Int: [Int]]()

    init(ancestor: String, a: String, b: String, separator: String = "\n") {
        self.aDiffMaker = DiffMaker(aString: ancestor, bString: a, separator: separator)
        self.bDiffMaker = DiffMaker(aString: ancestor, bString: b, separator: separator)
    }

    private func constructEdges() {
        stride(from: 0, through: oaDiffChunks.count + obDiffChunks.count, by: 1).forEach { self.edges[$0] = [] }

        _ = obDiffChunks.enumerated().reduce(0) { index, diffChunk -> Int in
            let myRange = diffChunk.element.getARange()
            var currentAIndex = index

            while currentAIndex < oaDiffChunks.count && myRange.upperBound > oaDiffChunks[currentAIndex].getARange().lowerBound {

                if myRange.intersection(oaDiffChunks[currentAIndex].getARange()) != nil {
                    edges[diffChunk.offset]!.append(currentAIndex + obDiffChunks.count)
                    edges[currentAIndex + obDiffChunks.count]!.append(diffChunk.offset)

                }

                currentAIndex += 1
            }

            //If add & add matches
            if currentAIndex < oaDiffChunks.count && myRange == oaDiffChunks[currentAIndex].getARange() {
                edges[diffChunk.offset]!.append(currentAIndex + obDiffChunks.count)
                edges[currentAIndex + obDiffChunks.count]!.append(diffChunk.offset)
            }

            return currentAIndex > 0 ? currentAIndex - 1 : currentAIndex
        }
    }

    private func fillConflicts() {
        var visited = stride(from: 0, through: oaDiffChunks.count+obDiffChunks.count, by: 1).map {_ in return false}

        stride(from: 0, to: obDiffChunks.count, by: 1).forEach { index in
            if visited[index] {return}

            var connectedAs: [Int] = []
            var connectedBs: [Int] = []

            var stack = Stack<Int>()
            stack.push(index)

            while !stack.isEmpty() {
                let currentPoint = stack.pop()!

                visited[currentPoint] = true

                if currentPoint >= obDiffChunks.count {
                    connectedAs.append(currentPoint - obDiffChunks.count)
                } else {
                    connectedBs.append(currentPoint)
                }

                if let myEdges = edges[currentPoint] {
                    myEdges.filter {!visited[$0]}.forEach { stack.push($0) }
                }
            }

            conflictArray.append((connectedBs.sorted(), connectedAs.sorted()))
        }

    }

    private func getOffsets() {
        self.offsetArray = [Int](repeating: 0, count: obDiffChunks.count)

        _ = obDiffChunks.enumerated().reduce((0, 0)) { offsetTuple, diffblock -> (Int, Int) in
            var currentIndex = offsetTuple.0
            var currentOffset = offsetTuple.1

            let myRange = diffblock.element.getARange()

            while currentIndex < oaDiffChunks.count && oaDiffChunks[currentIndex].getARange().upperBound < myRange.lowerBound {

                switch oaDiffChunks[currentIndex] {
                case .add(_, let range) : currentOffset += range.length
                case .delete(let range, _) : currentOffset -= range.length
                case .change(let oldRange, let newRange) : currentOffset += newRange.length - oldRange.length
                default: break
                }

                currentIndex += 1
            }

            offsetArray[diffblock.offset] = currentOffset

            return (currentIndex, currentOffset)
        }
    }

    func mergeInLineLevel() -> [Diff3Block] {
        var diff3Chunks: [Diff3Block] = []

        constructEdges()
        fillConflicts()
        getOffsets()

        for conflict in conflictArray {
            let aBlock: DiffBlock
            let bBlock: DiffBlock

            if conflict.aIndices.count == 0 {
                aBlock = .empty
            } else if conflict.aIndices.count == 1 {
                aBlock = oaDiffChunks[conflict.aIndices.first!]
            } else {
                let myFirstRange = oaDiffChunks[conflict.aIndices.first!].getBRange()
                let myLastRange = oaDiffChunks[conflict.aIndices.last!].getBRange()
                let oFirstRange = oaDiffChunks[conflict.aIndices.first!].getARange()
                let oLastRange = oaDiffChunks[conflict.aIndices.last!].getARange()

                aBlock = .change(oFirstRange.union(oLastRange), myFirstRange.union(myLastRange))
            }

            if conflict.bIndices.count == 0 {
                bBlock = .empty
            } else if conflict.bIndices.count == 1 {
                bBlock = obDiffChunks[conflict.bIndices.first!]
            } else {
                let myFirstRange = obDiffChunks[conflict.bIndices.first!].getBRange()
                let myLastRange = obDiffChunks[conflict.bIndices.last!].getBRange()
                let oFirstRange = obDiffChunks[conflict.bIndices.first!].getARange()
                let oLastRange = obDiffChunks[conflict.bIndices.last!].getARange()

                bBlock = .change(oFirstRange.union(oLastRange), myFirstRange.union(myLastRange))
            }

            switch bBlock {
            case .add(let index, let bRange):
                let offset = offsetArray[conflict.bIndices.first!]
                let start: Int
                switch aBlock {
                case .delete(_, let index): start = index
                case .change(_, let range) : start = range.location
                default: start = index+offset
                }
                diff3Chunks.append(Diff3Block.add(start, bRange))

            case .delete(let oRange, _):
                let offset = offsetArray[conflict.bIndices.first!]
                switch aBlock {
                case .add(let index, let aRange):
                    let firstRange = NSRange(location: oRange.location+offset, length: index - oRange.location)
                    let secondRange = NSRange(location: aRange.upperBound, length: oRange.length - firstRange.length)
                    if firstRange.length == 0 {
                        diff3Chunks.append(.delete(secondRange))
                    } else if secondRange.length == 0 {
                        diff3Chunks.append(.delete(firstRange))
                    } else {
                        diff3Chunks.append(.delete(firstRange))
                        diff3Chunks.append(.delete(secondRange))
                    }
                case .delete(let range, let aIndex):
                    if range == oRange {break}
                    let differences = oRange.difference(to: range)

                    if differences.0 == nil && differences.1 == nil {break}
                    if differences.0 == nil {
                        diff3Chunks.append(.delete(NSRange(location: aIndex, length: differences.1!.length)))
                    } else if differences.1 == nil {
                        diff3Chunks.append(.delete(NSRange(location: aIndex - differences.0!.length, length: differences.0!.length)))
                    } else {
                        diff3Chunks.append(.delete(NSRange(location: aIndex - differences.0!.length, length: differences.0!.length)))
                        diff3Chunks.append(.delete(NSRange(location: aIndex, length: differences.1!.length)))
                    }
                case .change(let oaRange, let aaRange):
                    let differences = oRange.difference(to: oaRange)

                    if differences.0 == nil && differences.1 == nil {break}
                    if differences.0 == nil {
                        diff3Chunks.append(.delete(NSRange(location: aaRange.upperBound, length: differences.1!.length)))
                    } else if differences.1 == nil {
                        diff3Chunks.append(.delete(NSRange(location: aaRange.location - differences.0!.length, length: differences.0!.length)))
                    } else {
                        diff3Chunks.append(.delete(NSRange(location: aaRange.location - differences.0!.length, length: differences.0!.length)))
                        diff3Chunks.append(.delete(NSRange(location: aaRange.upperBound, length: differences.1!.length)))
                    }
                case .empty:
                    diff3Chunks.append(.delete(NSRange(location: oRange.location+offset, length: oRange.length)))

                }
            case .change(let oRange, let bRange):
                let offset = offsetArray[conflict.bIndices.first!]
                switch aBlock {
                case .add(let index, let aRange):
                    let firstRange = NSRange(location: oRange.location, length: index - oRange.location)
                    let secondRange = NSRange(location: index, length: oRange.length - firstRange.length)
                    diff3Chunks.append(.conflict(oRange, NSRange(location: aRange.location - firstRange.length, length: aRange.length + firstRange.length + secondRange.length), bRange))

                case .delete(let oaRange, let index):
                    let differences = oRange.difference(to: oaRange)
                    let unionedRange = oRange.union(oaRange)

                    if differences.0 == nil && differences.1 == nil {
                        diff3Chunks.append(.change(oRange, NSRange(location: index, length: 0), bRange))
                    } else if differences.0 == nil {
                        diff3Chunks.append(.change(unionedRange, NSRange(location: index, length: differences.1!.length), bRange))
                    } else if differences.1 == nil {
                        diff3Chunks.append(.change(unionedRange, NSRange(location: index - differences.0!.length, length: differences.0!.length), bRange))
                    } else {
                        diff3Chunks.append(.change(unionedRange, NSRange(location: index - differences.0!.length, length: differences.0!.length + differences.1!.length), bRange))
                    }
                case .change(let oaRange, let aaRange):

                    let differences = oRange.difference(to: oaRange)
                    let unionedRange = oRange.union(oaRange)

                    if differences.0 == nil && differences.1 == nil {
                        diff3Chunks.append(.conflict(unionedRange, aaRange, bRange))
                    } else if differences.0 == nil {
                        diff3Chunks.append(.conflict(unionedRange, NSRange(location: aaRange.location, length: aaRange.length + differences.1!.length), bRange))
                    } else if differences.1 == nil {
                        diff3Chunks.append(.conflict(unionedRange, NSRange(location: aaRange.location - differences.0!.length, length: aaRange.length + differences.0!.length), bRange))
                    } else {
                        diff3Chunks.append(.conflict(unionedRange, NSRange(location: aaRange.location - differences.0!.length, length: aaRange.length + differences.0!.length + differences.1!.length), bRange))
                    }

                case .empty:
                    diff3Chunks.append(.change(oRange, NSRange(location: oRange.location+offset, length: oRange.length), bRange))
                }

            default: break
            }
        }

        return diff3Chunks.map {

            switch $0 {
            case .add(let index, let range):

                let transformedIndex = aDiffMaker.realIndex(from: index, inA: false)
                let transformedRange = bDiffMaker.realRange(from: range, inA: false)

                return Diff3Block.add(transformedIndex, transformedRange)
            case .delete(let range):

                let transformedRange = aDiffMaker.realRange(from: range, inA: false)

                return Diff3Block.delete(transformedRange)
            case .change(let oRange, let aRange, let bRange):

                let transformedORange = aDiffMaker.realRange(from: oRange, inA: true)
                let transformedARange = aDiffMaker.realRange(from: aRange, inA: false)
                let transformedBRange = bDiffMaker.realRange(from: bRange, inA: false)

                return Diff3Block.change(transformedORange, transformedARange, transformedBRange)
            case .conflict(let oRange, let aRange, let bRange):

                let transformedORange = aDiffMaker.realRange(from: oRange, inA: true)
                let transformedARange = aDiffMaker.realRange(from: aRange, inA: false)
                let transformedBRange = bDiffMaker.realRange(from: bRange, inA: false)

                return Diff3Block.conflict(transformedORange, transformedARange, transformedBRange)
            }
        }
    }

    func mergeInWordLevel(oOffset: Int, aOffset: Int, bOffset: Int) -> [Diff3Block] {
        var diff3Chunks: [Diff3Block] = []

        constructEdges()
        fillConflicts()
        getOffsets()

        for conflict in conflictArray {
            let aBlock: DiffBlock
            let bBlock: DiffBlock

            if conflict.aIndices.count == 0 {
                aBlock = .empty
            } else if conflict.aIndices.count == 1 {
                aBlock = oaDiffChunks[conflict.aIndices.first!]
            } else {
                let myFirstRange = oaDiffChunks[conflict.aIndices.first!].getBRange()
                let myLastRange = oaDiffChunks[conflict.aIndices.last!].getBRange()
                let oFirstRange = oaDiffChunks[conflict.aIndices.first!].getARange()
                let oLastRange = oaDiffChunks[conflict.aIndices.last!].getARange()

                aBlock = .change(oFirstRange.union(oLastRange), myFirstRange.union(myLastRange))
            }

            if conflict.bIndices.count == 0 {
                bBlock = .empty
            } else if conflict.bIndices.count == 1 {
                bBlock = obDiffChunks[conflict.bIndices.first!]
            } else {
                let myFirstRange = obDiffChunks[conflict.bIndices.first!].getBRange()
                let myLastRange = obDiffChunks[conflict.bIndices.last!].getBRange()
                let oFirstRange = obDiffChunks[conflict.bIndices.first!].getARange()
                let oLastRange = obDiffChunks[conflict.bIndices.last!].getARange()

                bBlock = .change(oFirstRange.union(oLastRange), myFirstRange.union(myLastRange))
            }

            //            print("anc:\n\(aDiffMaker.aChunks.joined())")
            //            print("\na:\n\(aDiffMaker.bChunks.joined())")
            //            print("\nb:\n\(bDiffMaker.bChunks.joined())")
            //            print(aBlock, bBlock)

            switch bBlock {
            case .add(let index, let bRange):
                let offset = offsetArray[conflict.bIndices.first!]

                let start: Int
                switch aBlock {
                case .delete(_, let aIndex): start = aIndex
                case .change(_, let range) : start = range.location
                case .add(_, let aRange): start = aRange.location
                case .empty: start = index + offset
                }
                diff3Chunks.append(.add(start, bRange))

            case .delete(let oRange, _):
                let offset = offsetArray[conflict.bIndices.first!]

                switch aBlock {
                case .add(let index, let aRange):
                    let firstRange = NSRange(location: oRange.location+offset, length: index - oRange.location)
                    let secondRange = NSRange(location: aRange.upperBound, length: oRange.length - firstRange.length)
                    if firstRange.length == 0 {
                        diff3Chunks.append(.delete(secondRange))
                    } else if secondRange.length == 0 {
                        diff3Chunks.append(.delete(firstRange))
                    } else {
                        diff3Chunks.append(.delete(firstRange))
                        diff3Chunks.append(.delete(secondRange))
                    }
                case .delete(let range, let aIndex):
                    if range == oRange {break}
                    let differences = oRange.difference(to: range)

                    if differences.0 == nil && differences.1 == nil {break}
                    if differences.0 == nil {
                        diff3Chunks.append(.delete(NSRange(location: aIndex, length: differences.1!.length)))
                    } else if differences.1 == nil {
                        diff3Chunks.append(.delete(NSRange(location: aIndex - differences.0!.length, length: differences.0!.length)))
                    } else {
                        diff3Chunks.append(.delete(NSRange(location: aIndex - differences.0!.length, length: differences.0!.length)))
                        diff3Chunks.append(.delete(NSRange(location: aIndex, length: differences.1!.length)))
                    }
                case .change(let oaRange, let aaRange):
                    let differences = oRange.difference(to: oaRange)

                    if differences.0 == nil && differences.1 == nil {break}
                    if differences.0 == nil {
                        diff3Chunks.append(.delete(NSRange(location: aaRange.upperBound, length: differences.1!.length)))
                    } else if differences.1 == nil {
                        diff3Chunks.append(.delete(NSRange(location: aaRange.location - differences.0!.length, length: differences.0!.length)))
                    } else {
                        diff3Chunks.append(.delete(NSRange(location: aaRange.location - differences.0!.length, length: differences.0!.length)))
                        diff3Chunks.append(.delete(NSRange(location: aaRange.upperBound, length: differences.1!.length)))
                    }
                case .empty:
                    diff3Chunks.append(.delete(NSRange(location: oRange.location+offset, length: oRange.length)))
                }
            case .change(let oRange, let bRange):
                let offset = offsetArray[conflict.bIndices.first!]

                switch aBlock {
                case .add(let index, let aRange):
                    let firstRange = NSRange(location: oRange.location, length: index - oRange.location).shift(by: offset)
                    let secondRange = NSRange(location: aRange.upperBound, length: oRange.length - firstRange.length)

                    diff3Chunks.append(.delete(firstRange))
                    diff3Chunks.append(.delete(secondRange))
                    diff3Chunks.append(.add(secondRange.upperBound, bRange))

                case .delete(let oaRange, let index):
                    let differences = oRange.difference(to: oaRange)
                    let unionedRange = oRange.union(oaRange)

                    if differences.0 == nil && differences.1 == nil {

                        diff3Chunks.append(.add(index, oRange))
                        //add line & change it!!
                    } else if differences.0 == nil {
                        diff3Chunks.append(.change(unionedRange, NSRange(location: index, length: differences.1!.length), bRange))
                    } else if differences.1 == nil {
                        diff3Chunks.append(.change(unionedRange, NSRange(location: index - differences.0!.length, length: differences.0!.length), bRange))
                    } else {
                        diff3Chunks.append(.change(unionedRange, NSRange(location: index - differences.0!.length, length: differences.0!.length + differences.1!.length), bRange))
                    }
                case .change(let oaRange, let aaRange):

                    let differences = oRange.difference(to: oaRange)

                    if differences.0 == nil && differences.1 == nil {
                        diff3Chunks.append(.add(aaRange.location, bRange))
                    } else if differences.0 == nil {
                        diff3Chunks.append(.change(differences.1!, NSRange(location: aaRange.upperBound, length: differences.1!.length), bRange))
                    } else if differences.1 == nil {
                        diff3Chunks.append(.change(differences.0!, NSRange(location: aaRange.lowerBound - differences.0!.length, length: differences.0!.length), bRange))
                    } else {
                        diff3Chunks.append(.delete(NSRange(location: aaRange.lowerBound - differences.0!.length, length: differences.0!.length)))
                        diff3Chunks.append(.change(differences.1!, NSRange(location: aaRange.upperBound, length: differences.1!.length), bRange))
                    }

                case .empty:
                    diff3Chunks.append(.change(oRange, NSRange(location: oRange.location+offset, length: oRange.length), bRange))
                }
            default: break
            }
        }

        return diff3Chunks.map {

            switch $0 {
            case .add(let index, let range):

                let transformedIndex = aDiffMaker.realIndex(from: index, inA: false)
                let transformedRange = bDiffMaker.realRange(from: range, inA: false)

                return Diff3Block.add(transformedIndex + aOffset, transformedRange.shift(by: bOffset))
            case .delete(let range):

                let transformedRange = aDiffMaker.realRange(from: range, inA: false)

                return Diff3Block.delete(transformedRange.shift(by: aOffset))
            case .change(let oRange, let aRange, let bRange):

                let transformedORange = aDiffMaker.realRange(from: oRange, inA: true).shift(by: oOffset)
                let transformedARange = aDiffMaker.realRange(from: aRange, inA: false).shift(by: aOffset)
                let transformedBRange = bDiffMaker.realRange(from: bRange, inA: false).shift(by: bOffset)

                return Diff3Block.change(transformedORange, transformedARange, transformedBRange)
            default: fatalError("Something went wrong!. Conflict must not be happened in word level")
            }
        }
    }

}

extension NSRange {

    func difference(to range: NSRange) -> (NSRange?, NSRange?) {
        if let intersection = self.intersection(range) {

            if intersection.location == self.location {
                return intersection.length == self.length ? (nil, nil): (nil, NSRange(location: self.location + intersection.length, length: self.length - intersection.length))
            } else {
                let firstChunk = NSRange(location: self.location, length: intersection.location - self.location)
                let secondChunk = NSRange(location: intersection.upperBound, length: self.upperBound - intersection.upperBound)

                if secondChunk.length == 0 {
                    return (firstChunk, nil)
                } else {
                    return (firstChunk, secondChunk)
                }
            }
        }
        return (self, nil)
    }

    func shift(by offset: Int) -> NSRange {
        return NSRange(location: self.location + offset, length: self.length)
    }
}
