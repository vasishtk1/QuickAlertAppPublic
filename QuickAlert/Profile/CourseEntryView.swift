//
//  CourseEntryView.swift
//  QuickAlert
//
//  Created by Vasisht Kartik on 7/1/24.
//

import SwiftUI
import SwiftData

struct CourseEntryView: View {
    @ObservedObject var modelData : ModelData
    var index: Int
    
    @Environment(\.presentationMode) var presentationMode
    
    @State private var period: String = ""
    @State private var instructor: String = ""
    @State private var title: String = ""
    @State private var term: String = ""

    @State private var showDeadlineEntryView: Bool = false
    
    let periods = ["p1", "p2", "p3", "p4", "p5", "p6", "p7"]
    let semesters = ["T1", "T2"]
    
    //TODO: hard coded courses data json file name
    func saveCourse() {
        //TODO: can this be a condition to use the course id instead?
        if (period.isEmpty) {
            let course = Course(term: term, title: title, period: period, instructor: instructor)
            modelData.saveCourseToFile(course: course, at: index,  "\(FileConstants.coursesFile)")
            modelData.courseInfo.courseNames[index] = title
            FileLogger.shared.log(message: "BEFORE SAVING - Course Details - ADD")
//            FileLogger.shared.log(courses: [course])
        } else {
            modelData.courses[index].period = period
            modelData.courses[index].title = title
            modelData.courses[index].term = term
            modelData.courses[index].instructor = instructor
            FileLogger.shared.log(message: "BEFORE SAVING - Course Details - UPDATE")
//            FileLogger.shared.log(courses: [modelData.courses[index]])
            modelData.saveCourseToFile(course: modelData.courses[index], at: index,  "\(FileConstants.coursesFile)")
            modelData.courseInfo.courseNames[index] = title
        }

        FileLogger.shared.log(message: "Course Entry View - On Save - Model data details")
//        FileLogger.shared.log(courses: modelData.courses)
        FileLogger.shared.log(message: modelData.getCourseInfo().studentName)
        FileLogger.shared.log(courseNames: modelData.getCourseInfo().courseNames)
        
    }

    var body: some View {
        NavigationView {
//        VStack(alignment: .leading) {
//            HStack {
//                Button(action: {
//                    presentationMode.wrappedValue.dismiss()
//                }) {
//                    Text("\(Image(systemName: "chevron.left")) Back")
//                }
//                Spacer()
//                Text("Course Details")
//                    .font(.headline)
//                Spacer()
//                Button(action: {
//                    saveCourse()
//                    presentationMode.wrappedValue.dismiss()
//                }) {
//                    Text("Save")
//                }
//            }
//            .padding()

            VStack {
                Text("Period")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Picker("Select period", selection: $period) {
                    ForEach(periods, id: \.self) { period in
                        Text(period).tag(period)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                Text("Teacher Name")
                    .frame(maxWidth: .infinity, alignment: .leading)
                TextField("Enter teacher name", text: $instructor)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                Text("Title")
                    .frame(maxWidth: .infinity, alignment: .leading)
                TextField("Enter course title", text: $title)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                Text("Term")
                    .frame(maxWidth: .infinity, alignment: .leading)
                //TODO: modify Term to picker with values T1 and T2
//                TextField("Enter term number", text: $term)
//                    .textFieldStyle(RoundedBorderTextFieldStyle())
//                    .padding()
                Picker("Select semester", selection: $term) {
                    ForEach(semesters, id: \.self) { term in
                        Text(term).tag(term)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                HStack {
                    Text("Add Deadlines Info")
                        .font(.title2)
                        .fontWeight(.medium)
                        .padding()
                    
                    Button(action: {
                        showDeadlineEntryView = true
                    }) {
                        Image(systemName: "plus.circle")
                            .padding()
                    }
//                    NavigationLink(destination: DeadlineEntryView(modelData: modelData, index: index)) {
//                        Image(systemName: "plus.circle")
//                            .padding()
//                    }
                }

                Spacer()
            }
            .padding()
            .onAppear {
                if let course = modelData.getCourse(at: index) {
                    self.period = course.period
                    self.instructor = course.instructor
                    self.title = course.title
                    self.term = course.term
                    // DEBUG
                    FileLogger.shared.log(message: "CourseEntryView (onAppear) - Course")
//                    FileLogger.shared.log(courses: [course])
                }
//                print("Period - ")
//                print(self.period)
                FileLogger.shared.log(message: "Course Entry View - Model data details")
//                FileLogger.shared.log(courses: modelData.courses)
                FileLogger.shared.log(message: modelData.getCourseInfo().studentName)
                FileLogger.shared.log(courseNames: modelData.getCourseInfo().courseNames)
                            }
        }
        .padding()
        .sheet(isPresented: $showDeadlineEntryView) {
            NavigationView {
                DeadlineEntryView(modelData: modelData, index: index)
            }
//            .navigationBarTitle("Deadlines Information", displayMode: .inline)
//            .navigationBarItems(trailing: Button(action: {
//                // Add your save action here (e.g., save data, dismiss view)
//                print("Save button tapped!")
//                presentationMode.wrappedValue.dismiss()
//                }) {
//                Text("Save")
//            })
        }
        .navigationBarTitle("Course Information", displayMode: .inline)
        .navigationBarItems(trailing: Button(action: {
            // Add your save action here (e.g., save data, dismiss view)
            FileLogger.shared.log(message: "Course Entry View - Save button tapped!")
            saveCourse()
            presentationMode.wrappedValue.dismiss()
            }) {
            Text("Save")
        })
    }
}



