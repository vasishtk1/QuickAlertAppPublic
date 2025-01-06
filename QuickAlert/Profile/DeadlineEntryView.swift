//
//  DeadlineEntryView.swift
//  QuickAlert
//
//  Created by Vasisht Kartik on 7/2/24.
//

import Foundation
import SwiftUI
import SwiftData


struct DeadlineEntryView: View {
    @ObservedObject var modelData : ModelData
    var index: Int
    @Environment(\.presentationMode) var presentationMode
    
    @State private var period: String = ""
    @State private var instructor: String = ""
    @State private var title: String = ""
    @State private var term: String = ""
//    @State private var assignmentTime: CourseAssignmentTimeTaken!
    
    @State private var hwTotalHrs: Int = (CourseWorkloadConstants.hwTotalHrs)
    @State private var hwHrsPerDay: Int = (CourseWorkloadConstants.hwHrsPerDay)
    @State private var quizTotalHrs: Int = (CourseWorkloadConstants.quizTotalHrs)
    @State private var quizHrsPerDay: Int = (CourseWorkloadConstants.quizHrsPerDay)
    @State private var testTotalHrs: Int = (CourseWorkloadConstants.testTotalHrs)
    @State private var testHrsPerDay: Int = (CourseWorkloadConstants.testHrsPerDay)
    @State private var cwTotalHrs: Int = (CourseWorkloadConstants.cwTotalHrs)
    @State private var cwHrsPerDay: Int = (CourseWorkloadConstants.cwHrsPerDay)
    @State private var labTotalHrs: Int = (CourseWorkloadConstants.labTotalHrs)
    @State private var labHrsPerDay: Int = (CourseWorkloadConstants.labHrsPerDay)
    
    let columns2x2 = [
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]
    
    func saveDeadlineEntries() {
//        var assignmentTime = CourseAssignmentTimeTaken(hwTotalHrs: 0, hwHrsPerDay: 0, quizTotalHrs: 0, quizHrsPerDay: 0, testTotalHrs: 0, testHrsPerDay: 0, cwTotalHrs: 0, cwHrsPerDay: 0, labTotalHrs: 0, labHrsPerDay: 0)
        var assignmentTime = CourseAssignmentTimeTaken()

        assignmentTime.setTimeTaken(hwTotalHrs: hwTotalHrs, hwHrsPerDay: hwHrsPerDay, quizTotalHrs: quizTotalHrs, quizHrsPerDay: quizHrsPerDay, testTotalHrs: testTotalHrs, testHrsPerDay: testHrsPerDay, cwTotalHrs: cwTotalHrs, cwHrsPerDay: cwHrsPerDay, labTotalHrs: labTotalHrs, labHrsPerDay: labHrsPerDay)
        
        modelData.courses[index].assignmentTimeTaken = assignmentTime
        
        modelData.saveCourseToFile(course: modelData.courses[index], at: index,  "\(FileConstants.coursesFile)")
        
        FileLogger.shared.log(message: "Deadline Entry View - On Save - Model data details")
//        FileLogger.shared.log(courses: modelData.courses)
        FileLogger.shared.log(message: modelData.getCourseInfo().studentName)
        FileLogger.shared.log(courseNames: modelData.getCourseInfo().courseNames)
    }
    
    //TODO: unused, remove in next code refactoring
    struct StepperView: View {
        var label: String
        @Binding var value: Int
        
        var body: some View {
            HStack {
                Button(action: {
                    print("minus - value before minus button click - \(value)")
                    value = max(value - 1, 0)
                    print("minus - value after minus button click - \(value)")
                }) {
                    Image(systemName: "minus.circle")
                }
                Text("\(value)")
                    .frame(width: 30)
                    .multilineTextAlignment(.center)
                Button(action: {
                    print("plus - value before plus button click - \(value)")
                    value = min(value + 1, 99)
                    print("plus - value after plus button click - \(value)")
                }) {
                    Image(systemName: "plus.circle")
                }
                Text(label)
            }
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                LazyVGrid(columns: columns2x2, alignment: .center, spacing: 15) {
                    Text("Period")
                        .multilineTextAlignment(.center)
                        .bold()
                    Text("Course Name")
                        .multilineTextAlignment(.center)
                        .bold()
                    TextField("", text: $period)
                        .disabled(true)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 14))
                    TextField("", text: $title)
                        .disabled(true)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 14))
                }
                .padding()
                
                Spacer().frame(height: 20)
                
                //homework
                Text("Homework")
                    .font(.title3)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity, alignment: .leading)
                HStack {
                    VStack {
                        HStack {
                            Button(action: {
                              if hwTotalHrs > 0 {
                                  hwTotalHrs -= 1
                              }
                            }) {
                            Image(systemName: "minus.circle")
                            }
                                TextField("Count", value: $hwTotalHrs, format: .number)
                                .frame(width: 30)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.center)
                            Button(action: {
                              if hwTotalHrs < 99 {
                                  hwTotalHrs += 1
                              }
                            }) {
                            Image(systemName: "plus.circle")
                            }
                        }
                        Text("total hrs")
                            .font(.caption)
                            .fontWeight(.light)

                    }
                    .padding(.horizontal, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    VStack {
                        HStack {
                            Button(action: {
                              if hwHrsPerDay > 0 {
                                  hwHrsPerDay -= 1
                              }
                            }) {
                            Image(systemName: "minus.circle")
                            }
                                TextField("Count", value: $hwHrsPerDay, format: .number)
                                .frame(width: 30)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.center)
                            Button(action: {
                              if hwHrsPerDay < 99 {
                                  hwHrsPerDay += 1
                              }
                            }) {
                            Image(systemName: "plus.circle")
                            }
                        }
                        Text("hrs per day")
                            .font(.caption)
                            .fontWeight(.light)
                    }
                    .padding(.horizontal, 10)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding()
                
                Spacer().frame(height: 20)
                
                //quiz
                Text("Quiz")
                    .font(.title3)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity, alignment: .leading)
                HStack {
                    VStack {
                        HStack {
                            Button(action: {
                              if quizTotalHrs > 0 {
                                  quizTotalHrs -= 1
                              }
                            }) {
                            Image(systemName: "minus.circle")
                            }
                                TextField("Count", value: $quizTotalHrs, format: .number)
                                .frame(width: 30)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.center)
                            Button(action: {
                              if quizTotalHrs < 99 {
                                  quizTotalHrs += 1
                              }
                            }) {
                            Image(systemName: "plus.circle")
                            }
                        }
                        Text("total hrs")
                            .font(.caption)
                            .fontWeight(.light)

                    }
                    .padding(.horizontal, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    VStack {
                        HStack {
                            Button(action: {
                              if quizHrsPerDay > 0 {
                                  quizHrsPerDay -= 1
                              }
                            }) {
                            Image(systemName: "minus.circle")
                            }
                                TextField("Count", value: $quizHrsPerDay, format: .number)
                                .frame(width: 30)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.center)
                            Button(action: {
                              if quizHrsPerDay < 99 {
                                  quizHrsPerDay += 1
                              }
                            }) {
                            Image(systemName: "plus.circle")
                            }
                        }
                        Text("hrs per day")
                            .font(.caption)
                            .fontWeight(.light)
                    }
                    .padding(.horizontal, 10)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding()
                
                Spacer().frame(height: 20)
                
                //test
                Text("Test")
                    .font(.title3)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity, alignment: .leading)
                HStack {
                    VStack {
                        HStack {
                            Button(action: {
                              if testTotalHrs > 0 {
                                  testTotalHrs -= 1
                              }
                            }) {
                            Image(systemName: "minus.circle")
                            }
                                TextField("Count", value: $testTotalHrs, format: .number)
                                .frame(width: 30)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.center)
                            Button(action: {
                              if testTotalHrs < 99 {
                                  testTotalHrs += 1
                              }
                            }) {
                            Image(systemName: "plus.circle")
                            }
                        }
                        Text("total hrs")
                            .font(.caption)
                            .fontWeight(.light)

                    }
                    .padding(.horizontal, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    VStack {
                        HStack {
                            Button(action: {
                              if testHrsPerDay > 0 {
                                  testHrsPerDay -= 1
                              }
                            }) {
                            Image(systemName: "minus.circle")
                            }
                                TextField("Count", value: $testHrsPerDay, format: .number)
                                .frame(width: 30)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.center)
                            Button(action: {
                              if testHrsPerDay < 99 {
                                  testHrsPerDay += 1
                              }
                            }) {
                            Image(systemName: "plus.circle")
                            }
                        }
                        Text("hrs per day")
                            .font(.caption)
                            .fontWeight(.light)
                    }
                    .padding(.horizontal, 10)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding()                
                
                Spacer().frame(height: 20)
                
                //classword
                Text("Classwork")
                    .font(.title3)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity, alignment: .leading)
                HStack {
                    VStack {
                        HStack {
                            Button(action: {
                              if cwTotalHrs > 0 {
                                  cwTotalHrs -= 1
                              }
                            }) {
                            Image(systemName: "minus.circle")
                            }
                                TextField("Count", value: $cwTotalHrs, format: .number)
                                .frame(width: 30)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.center)
                            Button(action: {
                              if cwTotalHrs < 99 {
                                  cwTotalHrs += 1
                              }
                            }) {
                            Image(systemName: "plus.circle")
                            }
                        }
                        Text("total hrs")
                            .font(.caption)
                            .fontWeight(.light)

                    }
                    .padding(.horizontal, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    VStack {
                        HStack {
                            Button(action: {
                              if cwHrsPerDay > 0 {
                                  cwHrsPerDay -= 1
                              }
                            }) {
                            Image(systemName: "minus.circle")
                            }
                                TextField("Count", value: $cwHrsPerDay, format: .number)
                                .frame(width: 30)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.center)
                            Button(action: {
                              if cwHrsPerDay < 99 {
                                  cwHrsPerDay += 1
                              }
                            }) {
                            Image(systemName: "plus.circle")
                            }
                        }
                        Text("hrs per day")
                            .font(.caption)
                            .fontWeight(.light)
                    }
                    .padding(.horizontal, 10)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding()
                Spacer().frame(height: 20)
                
                //Lab
                Text("Lab")
                    .font(.title3)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity, alignment: .leading)
                HStack {
                    VStack {
                        HStack {
                            Button(action: {
                              if labTotalHrs > 0 {
                                  labTotalHrs -= 1
                              }
                            }) {
                            Image(systemName: "minus.circle")
                            }
                                TextField("Count", value: $labTotalHrs, format: .number)
                                .frame(width: 30)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.center)
                            Button(action: {
                              if labTotalHrs < 99 {
                                  labTotalHrs += 1
                              }
                            }) {
                            Image(systemName: "plus.circle")
                            }
                        }
                        Text("total hrs")
                            .font(.caption)
                            .fontWeight(.light)

                    }
                    .padding(.horizontal, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    VStack {
                        HStack {
                            Button(action: {
                              if labHrsPerDay > 0 {
                                  labHrsPerDay -= 1
                              }
                            }) {
                            Image(systemName: "minus.circle")
                            }
                                TextField("Count", value: $labHrsPerDay, format: .number)
                                .frame(width: 30)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.center)
                            Button(action: {
                              if labHrsPerDay < 99 {
                                  labHrsPerDay += 1
                              }
                            }) {
                            Image(systemName: "plus.circle")
                            }
                        }
                        Text("hrs per day")
                            .font(.caption)
                            .fontWeight(.light)
                    }
                    .padding(.horizontal, 10)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding()

                Spacer()
                
            }

        }
        .onAppear {
            if let course = modelData.getCourse(at: index) {
                self.period = course.period
                self.instructor = course.instructor
                self.title = course.title
                self.term = course.term
                
                if let assignmentTime = course.assignmentTimeTaken {
                    self.hwTotalHrs = assignmentTime.hwTotalHrs
                    self.hwHrsPerDay = assignmentTime.hwHrsPerDay
                    self.quizTotalHrs = assignmentTime.quizTotalHrs
                    self.quizHrsPerDay = assignmentTime.quizHrsPerDay
                    self.testTotalHrs = assignmentTime.testTotalHrs
                    self.testHrsPerDay = assignmentTime.testHrsPerDay
                    self.cwTotalHrs = assignmentTime.cwTotalHrs
                    self.cwHrsPerDay = assignmentTime.cwHrsPerDay
                    self.labTotalHrs = assignmentTime.labTotalHrs
                    self.labHrsPerDay = assignmentTime.labHrsPerDay
                }
                FileLogger.shared.log(message: "DeadlineEntryView (onAppear) - Course")
//                FileLogger.shared.log(courses: [course])
            }
            
            FileLogger.shared.log(message: "Deadline Entry View - Model data details")
//            FileLogger.shared.log(courses: modelData.courses)
            FileLogger.shared.log(message: modelData.getCourseInfo().studentName)
            FileLogger.shared.log(courseNames: modelData.getCourseInfo().courseNames)
        }
        .listRowInsets(EdgeInsets(top: -5, leading: 0, bottom: -5, trailing: 0))
        .navigationBarTitle("Deadlines Information", displayMode: .inline)
        .navigationBarItems(trailing: Button(action: {
            // Add your save action here (e.g., save data, dismiss view)
            FileLogger.shared.log(message: " Deadline Entry View - Save button tapped!")
            saveDeadlineEntries()
            presentationMode.wrappedValue.dismiss()
            }) {
            Text("Save")
        })
    }
}
