//
//  CourseAndProfileView.swift
//  QuickAlert
//
//  Created by Vasisht Kartik on 6/19/24.
//

import SwiftUI
import SwiftData

//TODO: action listener for each course
//TODO: Create 2 tab views upon tapping on a course - Customized assignment time completion view and view all assignemnt types of each course
//TODO: in the course file make sure to change the variable location into two variables, period and semester
//TODO: Landscape view does not work properly
//TODO: store name in EditProfileView
//TODO: Toggle Setting where Courses can be overridden upon app launch next time - show alert warning that all course deadlines and time taken to complete each deadline will also be purged
//TODO: HTML parsing - invalid date - should it show up as 0 days left OR N/A OR not show up at all?
//TODO: HTML parsing - maxgrade is zero - do we eliminate this from the deadline list?
//TODO: implement completion of course and pop up alert to capture & store time taken (total hrs and hrs per day) and store it for the appropriate deadline
//TODO: Save to CoursesData.json prior to app quit
//TODO: Updating actual hours means saving to CoursesData.json

/**
 Refresh icon in EditProfileView
 */

/**
 Read Deadlines from local HTML file for the course and display  in CourseListView

 Refresh triggered in EditProfileView by user at any time should not override completed assignments
 Loading new HTML files should only add new entries and modify if deadlines of entries have changed; title of assignment will be the key
 
 Display 2 sections - Completed and Upcoming as 2 minimizable views or use a web browser tab view
 
 */

/**
 Save deadline details from DeadlineEntryView
 */

/**
 Sequence Diagram of app usage - using mermaid.js
 Launch app - Display web page viewer and README button
 README - will have the steps outlined to store each course information locally on the app; CourseListView and EditProfileView will be empty
 User can then navigate to EditProfileView and click a refresh icon next to Courses - triggers parsing all course HTML files, displaying the course list and loads the default deadlines
 User can navigate to the CourseListView and click on a course to view deadlines
 
 
 NICE TO HAVE - send notification on iOS device to refresh HTML schedule
 
 */

/**
 creates 3 tab views: course list, profile, and web page viewer
 the view defaults the the profile view if there are no courses
 */
struct CourseAndProfileView: View {
    // invoking model data to load courses from existing HTML files
    @ObservedObject var modelData = ModelData()
    @State private var selectedTab: Int = 0
    
    var body: some View {
        TabView (selection: $selectedTab) {
            NotificationView(modelData: modelData)
                .tabItem {
                    VStack {
                        Image(systemName: "bell.circle")
                        Text("Notifications")
                    }
                }
                .tag(0)
            CoursesListView(modelData: modelData)
                .tabItem {
                    VStack {
                        Image(systemName: "c.circle.fill") // Use a system icon similar to "A+"
                        Text("Course List")
                    }
                }
                .tag(1)
            
            EditProfileView(modelData: modelData)
                .tabItem {
                    VStack {
                        Image(systemName: "person.circle")
                        Text("Profile")
                    }
                }
                .tag(2)
            WebPageView()
                .tabItem {
                    VStack {
                        Image(systemName: "w.circle")
                        Text("Web Page Viewer")
                    }
                }
                .tag(3)
        }
        .onAppear() {
            if modelData.courses.isEmpty {
                selectedTab = 1 // Switch to EditProfileView
            } else {
                selectedTab = 0 // Switch to Notification View
            }
            
            FileLogger.shared.log(message: "INIT VIEW - Model data details upon app loading")
//            FileLogger.shared.log(courses: modelData.courses)
            FileLogger.shared.log(message: modelData.getCourseInfo().studentName)
            FileLogger.shared.log(courseNames: modelData.getCourseInfo().courseNames)
        }
    }
}

#Preview {
    CourseAndProfileView()
}

//TODO: Remove Later
struct ProfileView: View {
    @ObservedObject var modelData : ModelData

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Name")
                    .font(.headline)
                
                Text("Courses")
                    .font(.headline)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: EditProfileView(modelData: modelData)) {
                        Text("Edit")
                    }
                }
            }
        }
        .onAppear() {
            FileLogger.shared.log(message: "PROFILE VIEW - Model data details upon app loading")
//            FileLogger.shared.log(courses: modelData.courses)
            FileLogger.shared.log(message: modelData.getCourseInfo().studentName)
            FileLogger.shared.log(courseNames: modelData.getCourseInfo().courseNames)
        }

    }
}
