//
//  Step.swift
//  Final Thesis
//
//  Created by doss on 8/11/22.
//

import Foundation

struct DataPoint: Identifiable {
    let value: Double
    let date: Date
    
    let id = UUID()
}
