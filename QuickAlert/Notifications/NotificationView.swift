//
//  NotificationView.swift
//  QuickAlert
//
//  Created by Vasisht Kartik on 8/8/24.
//

import Foundation
import SwiftData
import SwiftUI
import UserNotifications

/**
renders the list of courses
 */
struct NotificationView: View {
    @ObservedObject var modelData : ModelData
    @Environment(\.presentationMode) var presentationMode
    @State private var courses: [Course]?
    // Array to store filtered deadlines
    @State private var filteredDeadlines: [(course: Course, deadline: CourseDeadline)] = []
//    @State private var hasAppeared: Bool = false  // Track if `onAppear` has run
    
    // State variables for the popup inputs
    @State private var showPopup = false
    @State private var actualHrsPerDay: String = ""
    @State private var actualTotalHrs: String = ""
    @State private var selectedDeadline: (course: Course, deadline: CourseDeadline)?
    @State private var selectedDeadlineId: String = ""

    func convertDeadlineToDate(deadlineString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy HH:mm:ss"
        return formatter.date(from: deadlineString)
    }
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                FileLogger.shared.log(message: "Notification permission granted.")
            } else if let error = error {
                FileLogger.shared.log(message: "Notification permission denied due to error: \(error.localizedDescription)")
            }
        }
    }
    
    func scheduleNotification(for deadline: CourseDeadline, daysLeft: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Upcoming Deadline"
        content.body = "Your deadline for \(deadline.title) is approaching."
        content.sound = UNNotificationSound.default

        // Set trigger time based on days left
        var triggerDate = DateComponents()
        if daysLeft <= 2 {
            triggerDate.hour = 8
//            triggerDate.minute = 58
        } else if daysLeft <= 4 {
            triggerDate.hour = 12
        } else {
            triggerDate.hour = 17
        }
        FileLogger.shared.log(message: "Triggering Notification")
        FileLogger.shared.log(message: deadline.description)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: true)
        
        let request = UNNotificationRequest(identifier: deadline.id, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                FileLogger.shared.log(message: "Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
    
    private var listHeader: some View {
        HStack {
            Text("Due Date")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .center)
            Text("Course")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .center)
            Text("Title")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .listRowBackground(Color.gray.opacity(0.2))
    }
    
    private var headerView: some View {
        Text("Notifications (\(filteredDeadlines.count))")
            .font(.largeTitle)
            .fontWeight(.heavy)
    }
    
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
        VStack {
            headerView
            List {
                // Combine the header and the rows
                Section(header: listHeader) {
                    // Table Rows with swipe actions
    //                ForEach(0..<filteredDeadlines.count, id: \.self) { index in
                    ForEach(filteredDeadlines, id: \.deadline.id) { entry in
//                    List($filteredDeadlines, id: \.deadline) { entry in
                        let course = entry.course
                        let deadline = entry.deadline
    //                    let daysLeft = deadline.daysToDue
                        
    //                    let formatter = DateFormatter()
    //                    formatter.dateFormat = "MM/dd/yyyy HH:mm:ss"
    //                    let dueDateAsDate = formatter.date(from: deadline.dueDate)
                        let daysLeft: Int = {
                            if let dueDateAsDate = convertDeadlineToDate(deadlineString: deadline.dueDate) {
                                let calendar = Calendar.current
                                let components = calendar.dateComponents([.day], from: Date(), to: dueDateAsDate)
                                return components.day ?? 0
                            } else {
                                return 0
                            }
                        }()
                    
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
                        
                        HStack {
                            VStack(alignment: .center) {
                                Text(daysLeft < 0 ? "\(abs(daysLeft))" : "\(daysLeft)")
                                    .font(.largeTitle)
                                Text(daysLeft == -1 ? "day past due" : daysLeft == 1 ? "day left" : daysLeft < -1 ? "days past due" : "days left")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            .background(
                                RoundedRectangle(cornerRadius: 10) // Adjust corner radius as needed
                                    .fill(color)
                            )
                            Text("\(course.title)")
    //                        Text("\(deadline.roundedGrade, specifier: "%.2f")/\(deadline.maxGrade, specifier: "%.0f")")
                                .frame(maxWidth: .infinity, alignment: .center)
                                .font(.system(size: 13, weight: .regular))
//                                .font(.title3)
                            VStack(alignment: .center) {
                                Text("\(deadline.deadlineType.capitalized)")
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .font(.system(size: 16, weight: .medium))
                                Text("\(deadline.title)")
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .font(.system(size: 15, weight: .light))
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                // Store the selected deadline
                                selectedDeadline = entry
                                selectedDeadlineId = entry.deadline.id
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
            .onAppear()  {
                // Ensure this code runs only once
//                guard !hasAppeared else { return }
//                hasAppeared = true
                
                requestNotificationPermission()  // Request permission

                self.courses = modelData.courses
                FileLogger.shared.log(message: "Notification View - Model data details")
//                FileLogger.shared.log(courses: modelData.courses)
//                print(self.courses)
                filteredDeadlines = []

                for course in modelData.courses {
                    let courseFilteredDeadlines = modelData.filterDeadlines(course: course)
                    filteredDeadlines.append(contentsOf: courseFilteredDeadlines)
                }
                filteredDeadlines = modelData.sortCourseDeadlinesByDueDays(filteredDeadlines)
                FileLogger.shared.log(filteredDeadlines: filteredDeadlines)
                
                for entry in filteredDeadlines {
                    let daysLeft = entry.deadline.daysToDue
                    print("Scheduling notification for \(entry.deadline.title) with daysLeft: \(daysLeft)")
                    scheduleNotification(for: entry.deadline, daysLeft: daysLeft)
                }

            
            }
            .overlay(popupView)
            .animation(.easeInOut, value: showPopup) // Animate appearance
        }
        .padding()
    }
}



//                DispatchQueue.global(qos: .userInitiated).async {
//                    var deadlines: [(course: Course, deadline: CourseDeadline)] = []
//
//                    if let courses = self.courses {
//                        for course in courses {
//                            let courseFilteredDeadlines = modelData.filterDeadlines(course: course)
//                            deadlines.append(contentsOf: courseFilteredDeadlines)
//                        }
//                    }
//
//                    let sortedDeadlines = modelData.sortCourseDeadlinesByDueDays(deadlines)
//
//                    DispatchQueue.main.async {
//                        self.filteredDeadlines = sortedDeadlines
//                        FileLogger.shared.log(filteredDeadlines: sortedDeadlines)
//                    }
//                }

//                                        modelData.appendCoursesToDocumentDirectory(course: course, fileName: modelData.FileConstants.coursesFile)
                                        
//                                        filteredDeadlines = []
//                                        for course in modelData.courses {
//                                            let courseFilteredDeadlines = modelData.filterDeadlines(course: course)
//                                            filteredDeadlines.append(contentsOf: courseFilteredDeadlines)
//                                        }
