//
//  ScreenTimeView.swift
//  Final Thesis
//
//  Created by doss on 8/24/22.
//

import SwiftUI
import FamilyControls

struct ScreenTimeView: View {
    @State var selection = FamilyActivitySelection()
    
    var body: some View {
        VStack {
            FamilyActivityPicker(selection: $selection)
            Label(selection.applicationTokens.first!)
        }
    }
}

struct ScreenTimeView_Previews: PreviewProvider {
    static var previews: some View {
        ScreenTimeView()
    }
}
