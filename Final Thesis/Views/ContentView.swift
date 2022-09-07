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
    @State private var dataPoints: [String: [DataPoint]] = [:]
    @State private var isPresentingAddPane = false
    @State private var isPresentingConfigurationPane = false
    @State private var selectedDataPoint: String = ""
    @State private var selectedDateRange: DateRange = .Year
    
    init() {
        healthStore = HealthStore()
    }
    
    private func updateSteps(_ statisticsColection: HKStatisticsCollection) {
        let startDate = Calendar.current.date(byAdding: .day, value: -selectedDateRange.rawValue, to: Date())!
        let endDate = Date()
        
        // print("\(String(describing: statisticsColection))")
        
        var tempStore = [DataPoint]()
        statisticsColection.enumerateStatistics(from: startDate, to: endDate) { (statistics, stop) in
            let count = statistics.sumQuantity()?.doubleValue(for: .count())
            let step = DataPoint(value: count ?? 0, date: statistics.startDate)
            tempStore.append(step)
        }
        
        dataPoints["Steps Taken"] = tempStore.map { steps in steps }
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
        
        dataPoints["Hours Asleep"] = tempStore.map { _, sleep in sleep }.sorted { first, second in first.date > second.date }
        print("\(String(describing: dataPoints["Hours Asleep"]!))")
        print("\(String(describing: tempStore))")
    }
    
    private func updateExercises(_ statisticsColection: HKStatisticsCollection) {
        let startDate = Calendar.current.date(byAdding: .day, value: -selectedDateRange.rawValue, to: Date())!
        let endDate = Date()
        
        //        print("\(String(describing: statisticsColection))")
        
        var tempStore = [DataPoint]()
        statisticsColection.enumerateStatistics(from: startDate, to: endDate) { (statistics, stop) in
            let count = statistics.sumQuantity()?.doubleValue(for: .minute())
            let exercise = DataPoint(value: count ?? 0, date: statistics.startDate)
            tempStore.append(exercise)
        }
        
        dataPoints["Minutes Exercised"] = tempStore.map { steps in steps }
        
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("Time Frame", selection: $selectedDateRange) {
                    Text("Week").tag(DateRange.Week)
                    Text("Month").tag(DateRange.Month)
                    Text("Year").tag(DateRange.Year)
                }
                .pickerStyle(.segmented)
                Button("Train Model") {
                    trainData()
                }
                List {
                    ForEach(Array(dataPoints.keys), id: \.self) { key in
                        Section(header: Text(key)) {
                            NavigationLink(destination: DetailView(key: key, data: dataPoints[key]!)) {
                                Chart(dataPoints[key]!) { dataPoint in
                                    LineMark(x: .value("Date", dataPoint.date), y: .value("Value", dataPoint.value))
                                }
                                .padding(.vertical)
                                .frame(minHeight: 150)
                            }
                        }
                    }
                    //                Section(header: Text("Steps Taken")) {
                    //                    Chart(steps) { step in
                    //                        LineMark(x: .value("Date", step.date), y: .value("Count", step.value))
                    //                    }
                    //                    .padding(.vertical)
                    //                    .frame(minHeight: 150)
                    //                }
                    //
                    //                Section(header: Text("Hours Asleep")) {
                    //                    Chart(sleeps) { sleep in
                    //                        BarMark(x: .value("Date", sleep.date), y: .value("Count", sleep.value))
                    //                    }
                    //                    .padding(.vertical)
                    //                    .frame(minHeight: 150)
                    //                }
                    //
                    //                Section(header: Text("Exercise Minutes")) {
                    //                    Chart(exercises) { exercise in
                    //                        AreaMark(x: .value("Date", exercise.date), y: .value("Minutes", exercise.value))
                    //                    }
                    //                    .padding(.vertical)
                    //                    .frame(minHeight: 150)
                    //                }
                }
                .navigationTitle("Health App ML")
                .toolbar {
                    Button(action: {
                        isPresentingAddPane = true
                    }) {
                        Image(systemName: "plus")
                    }
                    Button(action: {
                        isPresentingConfigurationPane = true
                    }) {
                        Image(systemName: "gear")
                    }
                }
            }
        }
        .onChange(of: selectedDateRange) { newDateRange in
            calculateHealthKitData(newDateRange)
        }
        .onAppear(perform: {calculateHealthKitData(selectedDateRange)} )
        .sheet(isPresented: $isPresentingAddPane) { AddView(dataPoints: $dataPoints, isEnabled: $isPresentingAddPane) }
        .sheet(isPresented: $isPresentingConfigurationPane) {ConfigurationView(keys: Array(dataPoints.keys), selection: $selectedDataPoint) }
        
    }
    
    func calculateHealthKitData(_ dateRange: DateRange) {
        clearData()
        if let healthStore = healthStore {
            healthStore.requestAuthorization { success in
                if success {
                    healthStore.calculateSteps(dateRange: dateRange.rawValue) { statisticsCollection in
                        if let statisticsCollection = statisticsCollection {
                            updateSteps(statisticsCollection)
                        }
                    }
                    healthStore.calculateSleep(dateRange: dateRange.rawValue) { samples in
                        if let samples = samples {
                            updateSleeps(samples)
                        }
                    }
                    healthStore.calculateExercise(dateRange: dateRange.rawValue) { statisticsCollection in
                        if let statisticsCollection = statisticsCollection {
                            updateExercises(statisticsCollection)
                        }
                    }
                }
            }
        }
    }
    
    func clearData() {
        dataPoints.forEach { key, _ in
            dataPoints[key] = [DataPoint]()
        }
    }
    
    func trainData() {
        
        
        
    }
}

struct DetailView: View {
    let key: String
    let data: [DataPoint]
    
    var body: some View {
        NavigationView {
            List(data) { dataPoint in
                HStack {
                    Text(dataPoint.date.formatted())
                    Spacer()
                    Text(dataPoint.value.formatted())
                }
            }
            .navigationTitle(key)
        }
    }
}

struct AddView: View {
    @Binding var dataPoints: [String: [DataPoint]]
    @Binding var isEnabled: Bool
    @State private var text: String = ""
    @State private var unit: String = ""
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Unit", text: $unit)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .border(.secondary)
                TextEditor(text: $text)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .border(.secondary)
                HStack {
                    Button("Add Data") {
                        let format = DateFormatter()
                        format.dateFormat = "yyyy-MM-dd"
                        do {
                            var tempStore = [DataPoint]()
                            text.split(separator: "\n").forEach { line in
                                let lineData = line.split(separator: ",")
                                let stringValue: String = String(lineData[1])
                                let doubleValue: Double =  Double(stringValue)!
                                let secondStringValue: String = String(lineData[0])
                                let dateValue: Date = format.date(from: secondStringValue)!
                                let dataPoint = DataPoint(value: doubleValue, date: dateValue)
                                tempStore.append(dataPoint)
                            }
                            dataPoints[unit] = tempStore.map { item in item }
                            isEnabled = false
                        } catch {
                            print("upsich")
                        }
                    }
                }
            }
            .padding()
        }
    }
}

struct ConfigurationView: View {
    let keys: [String]
    @Binding var selection: String
    
    var body: some View {
        Form {
            Picker("Observed Data", selection: $selection) {
                ForEach(keys, id: \.self) { key in
                    Text(key)
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
