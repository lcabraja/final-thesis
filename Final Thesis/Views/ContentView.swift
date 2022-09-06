//
//  ContentView.swift
//  Final Thesis
//
//  Created by lcabraja on 8/10/22.
//

import SwiftUI
import Charts
import HealthKit

struct ContentView: View {
    
    private var healthStore: HealthStore?
    @State private var steps: [DataPoint] = [DataPoint]()
    @State private var sleeps: [DataPoint] = [DataPoint]()
    @State private var exercises: [DataPoint] = [DataPoint]()
    
    init() {
        healthStore = HealthStore()
    }
    
    private func updateSteps(_ statisticsColection: HKStatisticsCollection) {
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let endDate = Date()
        
//        print("\(String(describing: statisticsColection))")
        
        statisticsColection.enumerateStatistics(from: startDate, to: endDate) { (statistics, stop) in
            let count = statistics.sumQuantity()?.doubleValue(for: .count())
            let step = DataPoint(value: count ?? 0, date: statistics.startDate)
            steps.append(step)
        }
    }
    
    private func updateSleeps(_ samples: [HKSample]) {
        var tempStore = [String: DataPoint]()
        let format = DateFormatter()
        format.dateFormat = "yyyy-MM-dd"
        
        samples.forEach { sample in
            let count = sample.startDate.distance(to: sample.endDate)
            if let value = tempStore[format.string(from: sample.startDate)] {
                tempStore[format.string(from: sample.startDate)] = DataPoint(value: value.value + count / 3600.0, date: value.date)
            } else {
                let sleep = DataPoint(value: count / 3600.0, date: format.date(from: format.string(from: sample.startDate))!)
                tempStore[format.string(from: sample.startDate)] = sleep
            }
        }
        
        
        
        sleeps = tempStore.map { _, sleep in sleep }
    }
    
    private func updateExercises(_ statisticsColection: HKStatisticsCollection) {
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let endDate = Date()
        
//        print("\(String(describing: statisticsColection))")
        
        statisticsColection.enumerateStatistics(from: startDate, to: endDate) { (statistics, stop) in
            let count = statistics.sumQuantity()?.doubleValue(for: .minute())
            let exercise = DataPoint(value: count ?? 0, date: statistics.startDate)
            exercises.append(exercise)
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Steps Taken")) {
                    Chart(steps) { step in
                        LineMark(x: .value("Date", step.date), y: .value("Count", step.value))
                    }
                    .padding(.vertical)
                    .frame(minHeight: 150)
                }
                
                Section(header: Text("Hours Asleep")) {
                    Chart(sleeps) { sleep in
                        BarMark(x: .value("Date", sleep.date), y: .value("Count", sleep.value))
                    }
                    .padding(.vertical)
                    .frame(minHeight: 150)
                }
                
                Section(header: Text("Exercise Minutes")) {
                    Chart(exercises) { exercise in
                        AreaMark(x: .value("Date", exercise.date), y: .value("Minutes", exercise.value))
                    }
                    .padding(.vertical)
                    .frame(minHeight: 150)
                }
            }
            .navigationTitle("Health App ML")
        }
        .onAppear {
            if let healthStore = healthStore {
                healthStore.requestAuthorization { success in
                    if success {
                        healthStore.calculateSteps { statisticsCollection in
                            if let statisticsCollection = statisticsCollection {
                                updateSteps(statisticsCollection)
                            }
                        }
                        healthStore.calculateSleep { samples in
                            if let samples = samples {
                                updateSleeps(samples)
                            }
                        }
                        healthStore.calculateExercise { statisticsCollection in
                            if let statisticsCollection = statisticsCollection {
                                updateExercises(statisticsCollection)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
