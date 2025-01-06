//
//  ContentView.swift
//  QuickAlert
//
//  Created by Vasisht Kartik on 6/19/24.
//

import SwiftUI
import SwiftData

//TODO: action listener for each course
//TODO: Create 2 tab views upon tapping on a course - Customized assignment time completion view and view all assignemnt types of each course
//TODO: create content of all assignments for each course
//TODO: in the course file make sure to change the variable location into two variables, period and semester

struct CourseAndProfileView: View {
    @ObservedObject var modelData = ModelData()
    @State private var selectedTab: Int = 0
    
//    @Query private var courses: [Course]
//    @Environment(\.modelContext) private var context
    var body: some View {
        TabView (selection: $selectedTab) {
            CoursesListView(modelData: modelData)
                .tabItem {
                    VStack {
                        Image(systemName: "c.circle.fill") // Use a system icon similar to "A+"
                        Text("Course List")
                    }
                }
                .tag(0)
            
            EditProfileView(modelData: modelData)
                .tabItem {
                    VStack {
                        Image(systemName: "person.circle")
                        Text("Profile")
                    }
                }
                .tag(1)
        }
        .onAppear() {
            if modelData.courses.isEmpty {
                selectedTab = 1 // Switch to EditProfileView
            } else {
                selectedTab = 0 // Switch to CoursesListView
            }
            
            print("INIT VIEW - Model data details upon app loading")
            print(modelData.courses)
            print(modelData.getCourseInfo().studentName)
            print(modelData.getCourseInfo().courseNames)
        }
    }
}

struct CoursesListView: View {
    @ObservedObject var modelData : ModelData
    
    var courses: [Course] {
        modelData.courses
    }
    
    var body: some View {
        VStack {
            Text("Course List")
                .font(.title)
                .fontWeight(.heavy)

            NavigationSplitView {
                List {
                    ForEach(courses) { course in
                        NavigationLink(destination: CourseDetails(course: course)) {
                            CourseInfoView(course: course)
                        }
                    }
                    .padding()
                }
            } detail: {
                Text("Select a Course")
            }
        }
    }
}

struct EditProfileView: View {
    @ObservedObject var modelData : ModelData
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        
        VStack {
//        NavigationStack {
            Text("Name and Course Details")
                .font(.title)
                .fontWeight(.heavy)
            
            NavigationSplitView {
//            VStack (alignment: .leading, spacing: 10) {
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

            } detail: {
                Text("")
            }
            
        }
        .padding()
        .onAppear {
            print("Edit Profile View - Model data details upon app loading")
            print(modelData.courses)
            print(modelData.getCourseInfo().studentName)
            print(modelData.getCourseInfo().courseNames)
        }
    }
}


struct CourseEntryView: View {
    @ObservedObject var modelData : ModelData
    var index: Int
    
    @Environment(\.presentationMode) var presentationMode
    
    @State private var period: String = ""
    @State private var instructor: String = ""
    @State private var title: String = ""
    @State private var term: String = ""
    
    let periods = ["P1", "P2", "P3", "P4", "P5", "P6", "P7"]
    
    func saveCourse() {
        let course = Course(term: term, title: title, period: period, instructor: instructor)
        print("BEFORE SAVING - Course Details")
        print(course)
        modelData.saveCourseToFile(course: course, at: index,  "CoursesData.json")
        modelData.courseInfo.courseNames[index] = title
        print("Course Entry View - On Save - Model data details")
        print(modelData.courses)
        print(modelData.getCourseInfo().studentName)
        print(modelData.getCourseInfo().courseNames)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("\(Image(systemName: "chevron.left")) Back")
                }
                Spacer()
                Text("Course Details")
                    .font(.headline)
                Spacer()
                Button(action: {
                    saveCourse()
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Save")
                }
            }
            .padding()

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
                TextField("Enter term number", text: $term)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Spacer()
            }
            .padding()
            .onAppear {
                if let course = modelData.getCourse(at: index) {
                    self.period = course.period
                    self.instructor = course.instructor
                    self.title = course.title
                    self.term = course.term
                }
                print("Course Entry View - Model data details")
                print(modelData.courses)
                print(modelData.getCourseInfo().studentName)
                print(modelData.getCourseInfo().courseNames)
            }
        }
        .padding()
        .navigationBarBackButtonHidden(true)
    }
}


struct CourseInfoView: View {
    var course: Course

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(course.term)
                .font(.subheadline)
                .foregroundColor(.gray)
            Text(course.title)
                .font(.headline)
                .foregroundColor(.blue)
            HStack {
                Text(course.period)
                    .font(.subheadline)
                Spacer()
                Text(course.instructor)
                    .font(.subheadline)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
    }
}

struct CourseDetails: View {
    var course: Course
    
    var body: some View {
        Text("Course Details")
            .font(.largeTitle)
            .foregroundColor(.gray)
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text("Term: \(course.term)")
                    .font(.headline)
                Text("Title: \(course.title)")
                    .font(.subheadline)
                Text("Period: \(course.period)")
                    .font(.subheadline)
                Text("Instructor: \(course.instructor)")
                    .font(.subheadline)
            }
            .padding()
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
            print("PROFILE VIEW - Model data details upon app loading")
            print(modelData.courses)
            print(modelData.getCourseInfo().studentName)
            print(modelData.getCourseInfo().courseNames)
        }

    }
}
