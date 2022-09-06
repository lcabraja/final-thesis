//
//  HealthStore.swift
//  Final Thesis
//
//  Created by doss on 8/11/22.
//

import Foundation
import HealthKit

extension Date {
    static func mondayAt12AM() -> Date {
        return Calendar(identifier: .iso8601)
            .date(from: Calendar(identifier: .iso8601).dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
    }
}

class HealthStore {
    var healthStore: HKHealthStore?
    var stepQuery: HKStatisticsCollectionQuery?
    var exerciseQuery: HKStatisticsCollectionQuery?
    var sleepQuery: HKSampleQuery?
    
    init() {
        if HKHealthStore.isHealthDataAvailable() {
            healthStore = HKHealthStore()
        }
    }
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        let stepType = HKQuantityType
            .quantityType(forIdentifier: .stepCount)!
        let sleepType = HKObjectType
            .categoryType(forIdentifier:
                            HKCategoryTypeIdentifier.sleepAnalysis)!
        let exerciseType = HKQuantityType
            .quantityType(forIdentifier: .appleExerciseTime)!
        
        guard let healthStore = self.healthStore else {
            return completion(false)
        }
        
        healthStore.requestAuthorization(
            toShare: [],
            read: [
                stepType,
                sleepType,
                exerciseType
            ]) { (success, error) in
            completion(success)
        }
    }
    
    func calculateSteps(completion: @escaping (HKStatisticsCollection?) -> Void) {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())
        let anchorDate = Date.mondayAt12AM()
        let daily = DateComponents(day: 1)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictEndDate)
        
        stepQuery = HKStatisticsCollectionQuery(
            quantityType: stepType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum,
            anchorDate: anchorDate,
            intervalComponents: daily
        )
        stepQuery!.initialResultsHandler = { _, statisticsCollection, error in
            completion(statisticsCollection)
        }
        
        if let healthStore = healthStore, let query = self.stepQuery {
            healthStore.execute(query)
        }
    }
    
    func calculateSleep(completion: @escaping ([HKSample]?) -> Void) {
        let sleepType = HKObjectType.categoryType(forIdentifier: HKCategoryTypeIdentifier.sleepAnalysis)!
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictEndDate)
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        sleepQuery = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: 100, sortDescriptors: [sortDescriptor]) { (_, tmpResult, error) -> Void in
//            print("Health Data: \(String(describing: tmpResult![0]))")
            completion(tmpResult)
        }
        
        if let healthStore = healthStore, let query = self.sleepQuery {
            healthStore.execute(query)
        }
    }
    
    func calculateExercise(completion: @escaping (HKStatisticsCollection?) -> Void) {
        let exerciseType = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime)!
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())
        let anchorDate = Date.mondayAt12AM()
        let daily = DateComponents(day: 1)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictEndDate)
        
        exerciseQuery = HKStatisticsCollectionQuery(
            quantityType: exerciseType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum,
            anchorDate: anchorDate,
            intervalComponents: daily
        )
        exerciseQuery!.initialResultsHandler = { _, statisticsCollection, error in
            completion(statisticsCollection)
        }
        
        if let healthStore = healthStore, let query = self.exerciseQuery {
            healthStore.execute(query)
        }
    }
    
}
