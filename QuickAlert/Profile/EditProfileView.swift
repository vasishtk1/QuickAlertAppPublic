//
//  EditProfileView.swift
//  QuickAlert
//
//  Created by Vasisht Kartik on 7/1/24.
//

import SwiftUI
import SwiftData

//TODO: enter period in the wrong order and correct the order on profile view
struct EditProfileView: View {
    @ObservedObject var modelData: ModelData
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            VStack {
                Text("Name and Course Details")
                    .font(.title)
                    .fontWeight(.heavy)
//                    padding(.top)

                ScrollView {
                    VStack {
                        Group {
                            Text("Name")
                                .padding()
                                .font(.title)

                            TextField("Enter your name", text: $modelData.courseInfo.studentName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding()
                                .keyboardType(.default)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }

                        Group {
                            Text("Courses")
                                .padding()
                                .font(.title)

                            ForEach(0..<7, id: \.self) { index in
                                HStack {
                                    TextField("Enter course for period \(index + 1)", text: $modelData.courseInfo.courseNames[index])
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .padding(.horizontal)
                                        .padding(.vertical, 5)
                                        .disabled(true)  // Make the text field not editable

                                    NavigationLink(destination: CourseEntryView(modelData: modelData, index: index)) {
                                        Image(systemName: "plus.circle")
                                            .padding()
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .onAppear {
            FileLogger.shared.log(message: "Edit Profile View - Model data details upon app loading")
//            FileLogger.shared.log(courses: modelData.courses)
            FileLogger.shared.log(message: modelData.getCourseInfo().studentName)
            FileLogger.shared.log(courseNames: modelData.getCourseInfo().courseNames)
        }
    }
}
