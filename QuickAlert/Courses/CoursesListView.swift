//
//  CoursesListView.swift
//  QuickAlert
//
//  Created by Vasisht Kartik on 7/1/24.
//

import SwiftData
import SwiftUI

/**
renders the list of courses
 */
struct CoursesListView: View {
    @ObservedObject var modelData : ModelData
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            Text("Course List")
                .font(.title)
                .fontWeight(.heavy)

            NavigationSplitView {
                List {
                    ForEach(0..<modelData.courses.count, id: \.self) { index in
                        NavigationLink(destination: CourseDetails(modelData: modelData, index: index)) {
                            CourseInfoView(modelData: modelData, index: index)
                        }
                    }
                    .padding()
                }
            } detail: {
                Text("Select a Course")
            }
        }
        .onAppear() {
            FileLogger.shared.log(message: "Courses List View - Model data details")
//            FileLogger.shared.log(courses: modelData.courses)
            FileLogger.shared.log(message: modelData.getCourseInfo().studentName)
            FileLogger.shared.log(courseNames: modelData.getCourseInfo().courseNames)
        }
    }
}


/**
shows the summary of the course information on course list view
 */
struct CourseInfoView: View {
    @ObservedObject var modelData : ModelData
    var index: Int

    var body: some View {
        VStack(alignment: .leading) {
            Text(modelData.courses[index].period)
                .font(.title3)
                .foregroundColor(.purple)
            Text(modelData.courses[index].title)
                .font(.headline)
                .foregroundColor(.blue)
            HStack {
                Text(modelData.courses[index].term)
                    .font(.subheadline)
                Spacer()
                Text(modelData.courses[index].instructor)
                    .font(.subheadline)
            }
            .foregroundColor(.gray)
        }
        .padding(.vertical, -10)
        .padding(.horizontal)
        .onAppear() {
            FileLogger.shared.log(message: "Course Info View - Course data details")
//            FileLogger.shared.log(courses: [modelData.courses[index]])
        }
    }
}

/**
 shows individual course information along with the deadline information
 */
//TODO: add deadline information
struct CourseDetails: View {
    @ObservedObject var modelData : ModelData
    var index: Int
    
    @State private var course: Course?
    // Array to store filtered deadlines
    @State private var filteredDeadlines: [(course: Course, deadline: CourseDeadline)] = []
//    @State private var hasAppeared: Bool = false  // Track if `onAppear` has run

    // State variables for the popup inputs
    @State private var showPopup = false
    @State private var actualHrsPerDay: String = ""
    @State private var actualTotalHrs: String = ""
    @State private var selectedDeadline: (course: Course, deadline: CourseDeadline)?
    @State private var selectedDeadlineId: String = ""

//    var deadlines: [CourseDeadline] = (modelData.courses[index].deadlines)!
    
    var deadlines: [CourseDeadline] {
        modelData.courses[index].deadlines ?? []
    }
    
    let columns3x2 = [
        GridItem(.flexible()),
//        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private var popupView: some View {
        
        // Popup view
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Spacer()
                Text("Enter Actual Hours")
                    .font(.title)
                    .fontWeight(.bold)
                Spacer()
            }
            
            if let courseDeadline = selectedDeadline {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Course:")
                        .font(.body)
                        .fontWeight(.regular)
                    Text(courseDeadline.course.title)
                        .font(.caption)
                    
                    Text("Deadline:")
                        .font(.body)
                        .fontWeight(.regular)
                    Text(courseDeadline.deadline.title)
                        .font(.caption)
                        .lineLimit(nil)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                
                TextField("Actual Total Hours", text: $actualTotalHrs)
                    .keyboardType(.decimalPad)
                    .padding(.horizontal, 8) // Reduce horizontal padding
                    .frame(height: 40) // Set a fixed height
                    .background(Color(.systemGray6))
                    .cornerRadius(8)

                TextField("Actual Hours Per Day", text: $actualHrsPerDay)
                    .keyboardType(.decimalPad)
                    .padding(.horizontal, 8) // Reduce horizontal padding
                    .frame(height: 40) // Set a fixed height
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                
                HStack {
                    Button("Cancel") {
                        hideKeyboard()
                        showPopup = false
                    }
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .font(.system(size: 14, weight: .medium))
                    
                    Spacer()
                    
                    Button("Save") {
                        hideKeyboard()
                        if let courseDeadline = selectedDeadline {
                            let index = modelData.indexOfCourse(in: modelData.courses, newCourse: courseDeadline.course)
                            if index >= 0 && index < modelData.courses.count {
                                var course = modelData.courses[index]
                                course.updateDeadline(courseDeadline.deadline, actualHrsPerDay: Double(actualHrsPerDay) ?? 0, actualTotalHrs: Double(actualTotalHrs) ?? 0)
                                
                                modelData.courses[index] = course
                                do {
                                    try modelData.writeCoursesToJSON(modelData.courses)
                                } catch {
                                    FileLogger.shared.log(message: "Error writing courses to JSON: \(error)")
                                }
                                filteredDeadlines.removeAll { $0.deadline.id == courseDeadline.deadline.id }
                                filteredDeadlines = modelData.sortCourseDeadlinesByDueDays(filteredDeadlines)

                                showPopup = false
                            }
                        }
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .font(.system(size: 14, weight: .medium))
                }
            } else {
                Text("No deadline selected")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .frame(width: 300, height: 400)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 20)
        .opacity(showPopup ? 1 : 0) // Control visibility
        .animation(.easeInOut, value: showPopup) // Animate appearance
    }
    var body: some View {
        
        VStack(alignment: .leading, spacing: 2) {
//            Text("Course Details")
//                .font(.largeTitle)
//                .foregroundColor(.gray)
            
            LazyVGrid(columns: columns3x2, alignment: .center, spacing: 1) {
                Text("Period/Term")
                    .multilineTextAlignment(.center)
                    .bold()
//                Text("Term")
//                    .multilineTextAlignment(.center)
//                    .bold()
                Text("Course Name")
                    .multilineTextAlignment(.center)
                    .bold()
                Text("Instructor")
                    .multilineTextAlignment(.center)
                    .bold()
                Text("\(modelData.courses[index].period) / \(modelData.courses[index].term)")
                    .disabled(true)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 14))
//                Text("\(modelData.courses[index].term)")
//                    .disabled(true)
//                    .multilineTextAlignment(.center)
//                    .font(.system(size: 14))
                Text("\(modelData.courses[index].title)")
                    .disabled(true)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 14))
                Text("\(modelData.courses[index].instructor)")
                    .disabled(true)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 14))
            }
            .padding(.horizontal) // Padding adjusted here
            .padding(.bottom, 2) // Reduced bottom padding here
            
            Text("Upcoming Deadlines")
                .font(.largeTitle)
                .frame(maxWidth: .infinity, alignment: .center)
                .foregroundColor(.gray)
                .padding(.top, 2) // Reduced padding above this text
            
            List {
                // Combine the header and the rows
                Section(header:
                    HStack {
                        Text("Due Date")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .center)
                        Text("Title")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .center)
                        Text("Grade")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .listRowBackground(Color.gray.opacity(0.2))
                ) {
                    // Table Rows with swipe actions
                    ForEach(deadlines.indices.filter { !deadlines[$0].isCompleted }, id: \.self) { deadlineIndex in
                        let deadline = deadlines[deadlineIndex]
                        let daysLeft = deadline.daysToDue
                        let color: Color = {
                            if daysLeft <= 1 {
                                return .red
                            } else if daysLeft <= 4 {
                                return .orange
                            } else if daysLeft <= 7 {
                                return Color(red: 240/255, green: 200/255, blue: 0) // trying instead of .yellow
//                                return .yellow
                            } else {
                                return .green
                            }
                        }()
                        
//                        print("Color for \(deadlines[deadlineIndex].title) is \(color) with \(daysLeft) due days left")
                        
                        HStack {
//                            Text("\(deadlines[deadlineIndex].daysToDue) \n days left")
//                                .frame(maxWidth: .infinity, alignment: .center)
//                            VStack(alignment: .center) {
//                                Text("\(deadlines[deadlineIndex].daysToDue)")
//                                    .font(.title) // Adjust font as needed
//                                Text("days left")
//                                    .font(.caption) // Adjust font as needed
//                            }
//                            .frame(maxWidth: .infinity, alignment: .center)
                            VStack(alignment: .center) {
                                Text(daysLeft < 0 ? "\(abs(daysLeft))" : "\(daysLeft)")
                                    .font(.largeTitle)
//                                    .foregroundColor(color)
                                Text(daysLeft == -1 ? "day past due" : daysLeft == 1 ? "day left" : daysLeft < -1 ? "days past due" : "days left")
                                    .font(.caption)
//                                    .foregroundColor(color)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            .background(
                                RoundedRectangle(cornerRadius: 10) // Adjust corner radius as needed
                                    .fill(color)
                            )
                            VStack(alignment: .center) {
                                Text("\(deadlines[deadlineIndex].deadlineType.capitalized)")
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .font(.system(size: 16, weight: .medium))
//                                    .background(Color.gray)
//                                    .background(Color(red: 64/255, green: 64/255, blue: 64/255))
                                Text("\(deadlines[deadlineIndex].title)")
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .font(.system(size: 14, weight: .light))
                            }
//                            Text("\(deadlines[deadlineIndex].deadlineType) \n \(deadlines[deadlineIndex].title)")
//                                .frame(maxWidth: .infinity, alignment: .center)
//                                .font(.system(size: 14))
//                            VStack(alignment: .center, spacing: 1) {
//                                Text("\(deadlines[deadlineIndex].roundedGrade, specifier: "%.2f")")
//                                    .frame(maxWidth: .infinity, alignment: .center)
//                                    .font(.title2)
//                                Text("-----")
//                                    .frame(maxWidth: .infinity, alignment: .center)
//                                    .font(.title2)
//                                Text("\(deadlines[deadlineIndex].maxGrade, specifier: "%.0f")")
//                                    .frame(maxWidth: .infinity, alignment: .center)
//                                    .font(.title2)
//                            }
                            Text("\(deadlines[deadlineIndex].roundedGrade, specifier: "%.2f")/\(deadlines[deadlineIndex].maxGrade, specifier: "%.0f")")
                                .frame(maxWidth: .infinity, alignment: .center)
                                .font(.title3)
//                            Text("\(deadlines[deadlineIndex].roundedGrade, specifier: "%.2f")")
//                                        .foregroundColor(.blue)
//                                    + Text("/")
//                                    + Text("\(deadlines[deadlineIndex].maxGrade, specifier: "%.0f")")
//                            VStack(alignment: .center, spacing: 1) {
//                                Text("\(deadlines[deadlineIndex].roundedGrade, specifier: "%.2f")")
//                                    .frame(maxWidth: .infinity, alignment: .center)
//                                    .font(.title2)
//                                Text("max: \(deadlines[deadlineIndex].maxGrade, specifier: "%.0f")")
//                                    .frame(maxWidth: .infinity, alignment: .center)
//                                    .font(.caption)
//                            }
                        }
//                        .background(
//                            RoundedRectangle(cornerRadius: 10)
//                                .stroke(color, lineWidth: 0.1) // Thin line border
//                        )
//                        .swipeActions(edge: .trailing) {
//                            Button(role: .destructive) {
//                                // Handle delete
//                            } label: {
//                                Label("Delete", systemImage: "trash")
//                            }
//                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                // Store the selected deadline
                                selectedDeadline = (modelData.courses[index], deadlines[deadlineIndex])
                                selectedDeadlineId = deadlines[deadlineIndex].id
                                // Show the popup
                                showPopup = true
                            } label: {
                                Label("Mark as Done", systemImage: "checkmark")
                            }
                            .tint(.green)
                        }
                    }
                }
            }
            .listStyle(PlainListStyle())
            .overlay(popupView)
            .animation(.easeInOut, value: showPopup) // Animate appearance
            .onAppear()  {
//                var deadlines: [CourseDeadline] {
//                    modelData.courses[index].deadlines ?? []
//                }
//                // Ensure this code runs only once
//                guard !hasAppeared else { return }
//                hasAppeared = true
//                
//                self.course = modelData.courses[index]
//                FileLogger.shared.log(message: "Course Details View - Model data details")
//                filteredDeadlines = []
////                print("Course: ")
////                print(self.course)
//                
//                if let course = self.course {
////                    print("Course = ")
////                    print(course)
//                    let courseFilteredDeadlines = modelData.filterCompletedDeadlines(course: course)
////                    print("Filtered Deadlines - on appear of Course Details View")
////                    print(courseFilteredDeadlines)
//                    filteredDeadlines.append(contentsOf: courseFilteredDeadlines)
//                } else {
//                    FileLogger.shared.log(message: "No courses available.")
//                }
//                filteredDeadlines = modelData.sortCourseDeadlinesByDueDays(filteredDeadlines)
//                FileLogger.shared.log(filteredDeadlines: filteredDeadlines)
//                            
            }
        }

        
    }
}
