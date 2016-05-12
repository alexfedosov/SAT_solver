//
//  SATSolver.swift
//  PaintShopProblem
//
//  Created by Alexander Fedosov on 09.02.16.
//  Copyright © 2016 Alexander Fedosov. All rights reserved.
//

import Foundation

typealias IntMatrix = Array<Array<Int>>

public class SatSolver {
    
    var satisfable = false
    var solution = Array<Int>()
    
    private var clauseTruthValues = Dictionary<Int,Int>()
    private var outputLiterals = Array<Int>()
    
    private var totalNumberOfVariables: Int
    private var totalNumberOfClauses: Int
    
    private var clause: IntMatrix
    private var copyClause: IntMatrix
    
    init(totalNumberOfVariables: Int, totalNumberOfClauses: Int, clause: IntMatrix) {
        self.totalNumberOfVariables = totalNumberOfVariables
        self.totalNumberOfClauses = totalNumberOfClauses
        self.clause = clause
        copyClause = IntMatrix(clause)
    }
    
    func solve() -> (Bool, Array<Int>) {
        var checkSatisfiability = false
        var variable: Int
        
        for (var i = 0; i < clause.count; i++) {
            for (var j = 0; j < clause[i].count; j++) {
                variable = clause[i][j]
                if (!clauseTruthValues.keys.contains(variable)) {
                    clauseTruthValues.updateValue(0, forKey: variable)
                }
            }
        }
        
        unitPropogation(&clause,truthValues: &clauseTruthValues)
        if (clause.count == 0) {
            checkSatisfiability = true
        }
        
        var pureSatisfy = true
        while(pureSatisfy) {
            pureSatisfy = pureLiteral(&clause,truthValues: &clauseTruthValues)
        }
        
        if (clause.count==0) {
            checkSatisfiability = true
        }
        
        var tempTruthValues = Dictionary<Int, Int>()
        
        if (clause.count>0) {
            var tempArray = Array<Array<Int>>()
            var aList = Array<Int>()
            
            _ = clauseTruthValues.map{tempTruthValues.updateValue($1, forKey: $0)}
            
            for (var i = 0; i < clause.count; i++) {
                aList = Array<Int>()
                
                for (var j = 0; j < clause[i].count; j++) {
                    aList.append(clause[i][j])
                }
                
                tempArray.append(aList)
            }
            checkSatisfiability = splitAndBackTrack(&clause, tempArray: &tempArray,truthValues: &clauseTruthValues,tempTruthValues: tempTruthValues)
        }
        
        satisfable = checkSatisfiability
        
        if (satisfable) {
            satisfable = true
            
            _ = clauseTruthValues.map({ (key, value) in
                
                if (value == 1) {
                    solution.append(key)
                }
            })
        }
        
        return (satisfable, solution)
    }
    
    private func checkUnitPropogation(inout anyClause: IntMatrix, inout truthValues: Dictionary<Int,Int>) -> Int{
        var returnUnit = -1
        
        for (var i = 0; i < anyClause.count; i++) {
            
            if (anyClause[i].count == 1) {
                
                returnUnit = anyClause[i][0]
                
                for (var k = i; k < anyClause.count; k++) {
                    
                    for (var j = 0; j < anyClause[i].count; j++) {
                        
                        if (anyClause[k].count == 1 && (anyClause[k][j] == -returnUnit)) {
                            return Int.min;
                        }
                    }
                }
                
                truthValues.updateValue(1, forKey: returnUnit)
                anyClause.removeAtIndex(i);
                
                return returnUnit;
            }
        }
        
        return 0;
    }
    
    private func computeUnitClause(inout anyClause: IntMatrix, unit: Int) -> Bool{
        var testVariableClause = false
        var testVariable = false
        
        if (anyClause.count != 0) {
            for (var i = 0; i < anyClause.count; i++) {
                
                if (anyClause[i].count > 1) {
                    for (var j = 0; j < anyClause[i].count; j++) {
                        
                        if (unit == anyClause[i][j]) {
                            testVariableClause = true
                            anyClause.removeAtIndex(i)
                            
                            if (testVariableClause && i == 0) {
                                i = -1
                                testVariableClause = false
                            }
                            
                            if (testVariableClause && i > 0) {
                                i--
                                testVariableClause = false
                            }
                            
                            break;
                        }
                        else if (unit == -1 * anyClause[i][j]) {
                            
                            testVariable = true
                            anyClause[i].removeAtIndex(j)
                            if (anyClause[i].count == 0) {
                                return false
                            }
                            if (testVariable && j == 0) {
                                j = -1
                                testVariable = false
                            }
                            
                            if (testVariable && j > 0) {
                                j--
                                testVariable = false
                            }
                        }
                    }
                }
            }
        }
        return true
    }
    
    
    private func unitPropogation(inout anyClause: IntMatrix, inout truthValues: Dictionary<Int,Int>) -> Bool{
        var satisfiabilityCheck=true
        var unit = checkUnitPropogation(&anyClause,truthValues:&truthValues)
        while(unit != 0) {
            if (unit == Int.min) {
                satisfiabilityCheck = false
                return satisfiabilityCheck
            }
            
            satisfiabilityCheck = computeUnitClause(&anyClause, unit: unit)
            if (satisfiabilityCheck) {
                unit=checkUnitPropogation(&anyClause,truthValues: &truthValues)
            } else {
                break
            }
        }
        
        return satisfiabilityCheck
    }
    
    private func pureLiteral(inout anyClause: IntMatrix, inout truthValues: Dictionary<Int,Int>) -> Bool{
        var key = 0
        var positive = Dictionary<Int,Int>()
        var negative = Dictionary<Int,Int>()
        
        var returnBool = false
        
        for (var i = 0; i < anyClause.count; i++) {
            for (var j = 0; j < anyClause[i].count; j++) {
                key = anyClause[i][j]
                if (key > 0) {
                    positive.updateValue(1, forKey: key)
                }
                else if (key < 0) {
                    negative.updateValue(1, forKey: abs(key))
                }
                
            }
        }
        
        for (var i = 0; i < anyClause.count; i++) {
            for (var j = 0; j < anyClause[i].count; j++) {
                key = anyClause[i][j]
                if (positive.keys.contains(abs(key)) && !negative.keys.contains(abs(key))) {
                    returnBool = true
                    positive.removeValueForKey(key)
                    truthValues.updateValue(1, forKey: key)
                    
                    for (var k = 0; k < anyClause.count; k++) {
                        if (anyClause[k].contains(key)) {
                            anyClause.removeAtIndex(k)
                            k--
                        }
                    }
                    
                    return returnBool
                }
                
                if (!positive.keys.contains(abs(key)) && negative.keys.contains(abs(key))) {
                    returnBool = true
                    negative.removeValueForKey(abs(key))
                    truthValues.updateValue(1, forKey: key)
                    
                    for (var k = 0; k < anyClause.count; k++) {
                        if (anyClause[k].contains(key)) {
                            anyClause.removeAtIndex(k)
                            k--
                        }
                    }
                    
                    return returnBool
                }
            }
        }
        
        return returnBool
    }
    
    
    private func computeForSatisfiability(inout anyClause: IntMatrix, value: Int, inout truthValues: Dictionary<Int,Int>) -> Bool{
        var testVariableClause = false
        var testVariable = false
        var checkSatisfiability = false
        
        for (var i = 0; i < anyClause.count; i++) {
            for (var j = 0; j < anyClause[i].count; j++) {
                if (value == anyClause[i][j]) {
                    testVariableClause = true
                    anyClause.removeAtIndex(i)
                    
                    if (testVariableClause && i == 0) {
                        i = -1
                        testVariableClause = false
                    }
                    
                    if (testVariableClause && i > 0) {
                        i--
                        testVariableClause = false
                    }
                    break
                }else if (value == -1 * anyClause[i][j]) {
                    testVariable = true
                    anyClause[i].removeAtIndex(j)
                    
                    if (testVariable && j == 0) {
                        j = -1
                        testVariable = false
                    }
                    
                    if (testVariable && j > 0) {
                        j = j-1
                        testVariable = false
                    }
                }
            }
        }
        
        checkSatisfiability = unitPropogation(&anyClause,truthValues: &truthValues)
        
        if (checkSatisfiability == false) {
            return false
        }
        
        var pureSatisfy = true
        while(pureSatisfy) {
            pureSatisfy = pureLiteral(&anyClause,truthValues: &truthValues)
        }
        
        clauseTruthValues = truthValues
        var totalElements = 0
        var tempTruthValues = Dictionary<Int,Int>()
        
        _ = truthValues.map{tempTruthValues.updateValue($1, forKey: $0)}
        _ = anyClause.map({totalElements += $0.count})
        
        var tempArray = IntMatrix()
        
        if (totalElements > anyClause.count) {
            for (var i = 0; i < anyClause.count; i++) {
                var aList = Array<Int>()
                for (var j = 0; j < anyClause[i].count; j++) {
                    aList.append(anyClause[i][j])
                }
                
                tempArray.append(aList)
            }
        }
        
        if (anyClause.count > 0) {
            checkSatisfiability = splitAndBackTrack(&anyClause,tempArray: &tempArray,truthValues: &truthValues,tempTruthValues: tempTruthValues)
        }
        
        return checkSatisfiability
    }
    
    private func splitAndBackTrack(inout anyClause: IntMatrix,inout tempArray:IntMatrix, inout truthValues: Dictionary<Int,Int>, var tempTruthValues: Dictionary<Int,Int>) -> Bool{
        
        var value = 0
        var checkSatisfiability: Bool
        
        for (var i = 0; i < anyClause.count; i++) {
            if (anyClause[i].count > 1) {
                value = momHeuristic(&anyClause)
                truthValues.updateValue(1, forKey: value)
                break
            }
        }
        
        checkSatisfiability = computeForSatisfiability(&anyClause,value: value,truthValues: &truthValues)
        
        if (checkSatisfiability) {
            return true
        } else {
            value = -value
            tempTruthValues.updateValue(1, forKey: value)
            checkSatisfiability = computeForSatisfiability(&tempArray, value: value,truthValues: &tempTruthValues)
            if (checkSatisfiability) {
                return true
            } else {
                return false
            }
        }
    }
    
    // Find the maximum repetitive element
    private func momHeuristic(inout anyClause: IntMatrix) -> Int{
        
        var min = Int.max
        for (var i = 0; i < anyClause.count; i++) {
            if (min > anyClause[i].count) {
                min = anyClause[i].count
            }
        }
        
        var maxVariable = 0
        var map = Dictionary<Int,Array<Int>>()
        
        var key = 0
        var incrementValue = 0
        var largestValue = 0
        var value1: Int
        var value2: Int
        var signInformation = Array<Int>()
        
        for (var i = 0; i < anyClause.count; i++) {
            
            if (anyClause[i].count == min) {
                
                for (var j = 0; j < anyClause[i].count; j++) {
                    
                    key = anyClause[i][j]
                    
                    if (map.keys.contains(abs(key))) {
                        signInformation = map[abs(key)]!
                        
                        if (key > 0) {
                            value1 = signInformation[0]
                            value1++
                            value2 = signInformation[1]
                            incrementValue = value1 + value2
                            
                            if (largestValue < incrementValue) {
                                largestValue = incrementValue
                                if (value1 > value2) {
                                    maxVariable = abs(key)
                                } else {
                                    maxVariable = -1 * abs(key)
                                }
                            }
                            
                            signInformation[0] = value1
                            map.updateValue(signInformation, forKey:abs(key))
                        }else if (key < 0) {
                            value1 = signInformation[0]
                            value2 = signInformation[1]
                            value2++
                            
                            incrementValue = value1 + value2
                            if (largestValue < incrementValue) {
                                largestValue=incrementValue
                                if (value1 > value2) {
                                    maxVariable = abs(key)
                                } else {
                                    maxVariable = -1 * abs(key)
                                }
                            }
                            signInformation[1] = value2
                            map.updateValue(signInformation, forKey: abs(key))
                        }
                    }
                    else{
                        signInformation = Array<Int>()
                        if (key > 0) {
                            signInformation.append(1)
                            signInformation.append(0)
                            
                            if (largestValue == 0) {
                                largestValue = 1
                                maxVariable = abs(key)
                            }
                            
                            map.updateValue(signInformation, forKey: abs(key))
                        }
                        else if (key < 0) {
                            signInformation.append(0)
                            signInformation.append(1)
                            if (largestValue == 0)
                            {
                                largestValue = 1
                                maxVariable = -1 * abs(key)
                            }
                            
                            map.updateValue(signInformation, forKey: abs(key))
                        }
                    }
                }
            }
        }
        return maxVariable;
    }
}