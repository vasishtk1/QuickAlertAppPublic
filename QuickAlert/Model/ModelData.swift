//
//  ModelData.swift
//  QuickAlert
//
//  Created by Vasisht Kartik on 6/19/24.
//

import Foundation
import SwiftSoup

struct FileConstants {
    // static file names for courses
    static let courseInfoFileName = "CoursesData"
    static let courseInfoFileName_parsed = "CoursesData_Parsed"
    static let courseInfoFileExtension = ".json"
    static let coursesFile = "CoursesData.json"
}

struct CourseWorkloadConstants {
    static let hwTotalHrs: Int = 3
    static let hwHrsPerDay: Int = 1
    static let quizTotalHrs: Int = 5
    static let quizHrsPerDay: Int = 1
    static let testTotalHrs: Int = 10
    static let testHrsPerDay: Int = 3
    static let cwTotalHrs: Int = 4
    static let cwHrsPerDay: Int = 1
    static let labTotalHrs: Int = 5
    static let labHrsPerDay: Int = 2
}

struct CourseCategories {
    static let phraseMap: [String: String] = [
        "Minor Assessments and Exams": "test",
        "Major Assessments and Exams": "test",
        "Misc. Assignments": "classwork",
        "Quick Checks and Audits": "classwork"
    ]

    static let keywordMap: [(String, String)] = [
//        "homework": "homework",
//        "assignment": "homework",
//        "assignments": "homework",
//        "assessments": "quiz",
//        "assessment": "quiz",
//        "final": "test",
//        "test": "test",
//        "quiz": "quiz",
//        "lab": "lab",
//        "checks": "classwork",
//        "audits": "classwork",
//        "assign": "homework",
//        "tests": "test",
//        "project": "test"
        ("homework", "homework"),
        ("assignment", "homework"),
        ("assignments", "homework"),
        ("assessments", "quiz"),
        ("assessment", "quiz"),
        ("final", "test"),
        ("test", "test"),
        ("tests", "test"),
        ("quiz", "quiz"),
        ("lab", "lab"),
        ("checks", "classwork"),
        ("audits", "classwork"),
        ("assign", "homework"),
        ("project", "test")
    ]

}

class ModelData: ObservableObject {
    // struct for storing courses 
    @Published var courses: [Course]
    @Published var courseInfo: CourseInfo

    init() {
        // initialized struct
        self.courses = []
        self.courseInfo = CourseInfo(studentName: "", courseNames: Array(repeating: "", count: 7))
        
        // read course info if Course Data file exists
        self.courses = self.loadCoursesFromDocumentDirectory("\(FileConstants.coursesFile)")
        updateCourseNames()
        FileLogger.shared.log(message: "Course Names before initial loading")
//        FileLogger.shared.log(courses: courses)
        FileLogger.shared.log(message: "Student Name and Course Names before initial loading")
        FileLogger.shared.log(message: courseInfo.studentName)
        FileLogger.shared.log(courseNames: courseInfo.courseNames)

        // process static HTML files in Resources to parse for each course and its deadlines and stores it in json format
        // assumption: one static HTML file per course that includes all the course deadlines
        // TODO: add instructions to download via webpage viewer
        // TODO: needs fix as relaunch of app is NOT checking for existing CoursesData.json and re-populating in the CoursesListView
        processAllHTMLFilesInResources()

        // update course info if Course Data File exists or if a new Course Data File was created
        self.courses = self.loadCoursesFromDocumentDirectory("\(FileConstants.coursesFile)")
        updateCourseNames()
        FileLogger.shared.log(message: "Course Names after initial loading")
//        FileLogger.shared.log(courses: courses)
        FileLogger.shared.log(message: "Student Name and Course Names after initial loading")
        FileLogger.shared.log(message: courseInfo.studentName)
        FileLogger.shared.log(courseNames: courseInfo.courseNames)
        
        FileLogger.shared.log(message: "Distinct Deadline Types - after initial loading")
        FileLogger.shared.log(courseNames: findDistinctDeadlineTypes(courses: courses))

    }
    
    func findDistinctDeadlineTypes(courses: [Course]) -> [String] {
        // Use a Set to collect unique deadline types
        var distinctTypes: Set<String> = Set()
        
        for course in courses {
            if let deadlines = course.deadlines {
                for deadline in deadlines {
                    distinctTypes.insert(deadline.deadlineType)
                }
            }
        }
        
        return Array(distinctTypes)
    }
    
    /**
    Helper function to save JSON to DocumentDirectory
    */
    func saveCourseDeadlinesToDocumentDirectory(jsonData: Data, fileName: String) {
        let fileManager = FileManager.default
        if let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let jsonFilePath = documentDirectory.appendingPathComponent("\(fileName).json")
            do {
                try jsonData.write(to: jsonFilePath)
                FileLogger.shared.log(message:"JSON file saved successfully at \(jsonFilePath)")
                print("JSON file saved successfully at \(jsonFilePath)")
            } catch {
                FileLogger.shared.log(message:"Failed to save JSON file: \(error)")
            }
        }
    }
    
    // Function to write data to JSON file
    func writeCoursesToJSON(_ courses: [Course]) throws {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
          fatalError("Failed to locate documents directory")
        }

        let fileURL = documentsDirectory.appendingPathComponent(FileConstants.coursesFile)

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys, .prettyPrinted] // Optional: format JSON for readability

            let data = try encoder.encode(courses)
            try data.write(to: fileURL)
            FileLogger.shared.log(message: "Courses data written successfully to \(fileURL.path)")
        } catch {
            FileLogger.shared.log(message: "Error writing courses to JSON: \(error)")
        }

    }
    
    /**
     Function to append or update the course in the file
     creates an empty file if not found
     */
    func appendCoursesToDocumentDirectory(course: Course, fileName: String) {
        let fileManager = FileManager.default
        if let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let jsonFilePath = documentDirectory.appendingPathComponent("\(fileName)")
            do {
                var courses: [Course] = []
                
                if fileManager.fileExists(atPath: jsonFilePath.path) {
                    FileLogger.shared.log(message:"File exists at path: \(jsonFilePath.path)")
                    let existingData = try Data(contentsOf: jsonFilePath)
                    courses = try JSONDecoder().decode([Course].self, from: existingData)
                    
                    FileLogger.shared.log(message:"Reading Courses from file - ")
//                    FileLogger.shared.log(courses:courses)
                    
                    FileLogger.shared.log(message:"Passed course into function")
//                    FileLogger.shared.log(courses:[course])
                    
                    if let index = courses.firstIndex(where: { $0.period == course.period }) {
                        FileLogger.shared.log(message:"Updating entry with period: \(course.period)")
                        // modify only title, period, instructor and term fields; leave CourseAssignmentTimeTaken struct intact
                        courses[index].period = course.period
                        courses[index].title = course.title
                        courses[index].term = course.term
                        courses[index].instructor = course.instructor
                        courses[index].deadlines = course.deadlines
                        courses[index].assignmentTimeTaken = course.assignmentTimeTaken
//                        courses[index] = course
                    } else {
                        FileLogger.shared.log(message:"Appending new entry with period: \(course.period)")
                        courses.append(course)
                    }
                } else {
                    FileLogger.shared.log(message:"File does not exist. Creating new file at path: \(jsonFilePath.path)")
                    courses.append(course)
                }
                
                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted
                let updatedData = try encoder.encode(courses)
                try updatedData.write(to: jsonFilePath)
                FileLogger.shared.log(message:"JSON data written successfully at \(jsonFilePath)")
            } catch {
                FileLogger.shared.log(message:"Failed to append or update JSON data: \(error)")
            }
        }
    }

//    func assignDeadlineType(inputString: String, keywordMap: [String: String]) -> String {
//        var deadlineType: String = ""
//        let lowerCaseString = inputString.lowercased()
//        for (keyword, deadlineType) in keywordMap {
//            if lowerCaseString.contains(keyword) {
//                FileLogger.shared.log(message: "Found \(deadlineType) for \(keyword)")
//                return deadlineType
//            }
//        }
//        return deadlineType // No matching keyword found
//    }
//    
    func assignDeadlineType(inputString: String, keywordMap: [(String, String)]) -> String {
        let lowerCaseString = inputString.lowercased()
        for (keyword, deadlineType) in keywordMap {
            if lowerCaseString.contains(keyword) {
                FileLogger.shared.log(message: "Found \(deadlineType) for \(keyword)")
                return deadlineType
            }
        }
        return "" // No matching keyword found
    }
    /**
    Function to parse HTML and save data to JSON
    parses for *tr.report-row.item-row* in the HTML file
    extracts course title, instructor name, period, and term
    extracts course deadlines - title, link, due date, rounded grade, max grade
     */
    func parseHTMLAndSaveToDocumentDirectory(fileName: String) {
        if let htmlString = readHTMLFile(fileName: fileName) {
            do {
                let doc: Document = try SwiftSoup.parse(htmlString)
                let categoryRows = try doc.select("tr.report-row.category-row.has-children")
//                let reportRows = try doc.select("tr.report-row.item-row")

                var courseDeadlineEntries: [[String: Any]] = []
                var course = Course(term: "", title: "", period: "", instructor: "")
                var courseDeadlines: [CourseDeadline] = []
                
                var newCourse = Course(term: "", title: "", period: "", instructor: "")
                var assignmentTimeTaken = CourseAssignmentTimeTaken()
                
                // Extract and parse title tag information
                if let titleTag = try doc.select("title").first() {
                   let fullTitle = try titleTag.text()
                   let components = fullTitle.components(separatedBy: ": ")
                   if components.count >= 2 {
                       let courseInfo = components[1].components(separatedBy: " ")
                       if courseInfo.count >= 3 {
                           let title = components[0]
                           let instructor = courseInfo[0]
                           let period = courseInfo[1]
                           let term = courseInfo[2].components(separatedBy: " |").first ?? ""
                           
                           course = Course(term: term, title: title, period: period, instructor: instructor)
                           course.assignmentTimeTaken = assignmentTimeTaken
                           FileLogger.shared.log(message:"Parsed Course Details")
//                           FileLogger.shared.log(courses:[course])
                       }
                   }
                }
                
                for categoryRow in categoryRows {
                    // Get the deadlineType from the category row
                    let deadlineType = try categoryRow.text().trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    //Assign deadline type based on prec-configured map
                    var assignedDeadlineType: String = ""
                    
                    // Iterate over sibling rows until the next category or end
                    var nextRow = try categoryRow.nextElementSibling()
                    while let reportRow = nextRow, !reportRow.hasClass("category-row") {
                        if (reportRow.hasClass("item-row") && reportRow.hasClass("is-grade-column")) ||
                            reportRow.hasClass("item-row") ||
//                            (reportRow.attr("class") == "report-row item-row is-grade-column") ||
                            (reportRow.hasClass("item-row") && reportRow.hasClass("last-row-of-tier")) {
                            if let titleElement = try reportRow.select("span.title").first() {
                                
                                let dueDateElement = try? reportRow.select("span.due-date").first()?.text()
                                let roundedGradeElement = try? reportRow.select("span.rounded-grade span.awarded-grade").first()?.text()
                                let maxGradeElement = try? reportRow.select("span.max-grade").first()?.text()
//                                let rubricGradeElement = try? reportRow.select("span.rubric-grade-value").first()?.text()
                                
                                let title = try String(titleElement.text().split(separator: " ").dropLast().joined(separator: " "))
                                let link = try titleElement.select("a").first()?.text() ?? ""
                                let dueDate = (dueDateElement?.replacingOccurrences(of: "Due ", with: "")) ?? ""
//                                let roundedGrade = Int((try roundedGradeElement.text()).replacingOccurrences(of: "%", with: "").trimmingCharacters(in: .whitespaces)) ?? 0
                                let roundedGrade = Double((roundedGradeElement ?? "").replacingOccurrences(of: "%", with: "").trimmingCharacters(in: .whitespaces)) ?? 0.0
                                let maxGrade = Double((maxGradeElement ?? "").replacingOccurrences(of: "/", with: "").trimmingCharacters(in: .whitespaces)) ?? 0.0
                                
                                var deadlineTypeVal: String = String(link.split(separator: " ").last ?? "")
                                assignedDeadlineType = assignDeadlineType(inputString: deadlineTypeVal, keywordMap: (CourseCategories.keywordMap))
            //                    assignedDeadlineType = assignDeadlineType(inputString: deadlineType, keywordMap: (CourseCategories.phraseMap))

                                // DEBUG
                                FileLogger.shared.log(message: title)
                                FileLogger.shared.log(message: link)
                                FileLogger.shared.log(message: dueDate)
                                FileLogger.shared.log(message: String(roundedGrade))
                                FileLogger.shared.log(message: String(maxGrade))
                                FileLogger.shared.log(message: deadlineTypeVal)
                                FileLogger.shared.log(message: assignedDeadlineType)
                                
                                // Attempt to parse due date with multiple formats
                                let dateFormats = ["M/dd/yy h:mma", "MM/dd/yy h:mma", "MM/dd/yy", "M/dd/yy"]
                                var dueDateParsed: Date? = nil
                                for format in dateFormats {
                                    let dateFormatter = DateFormatter()
                                    dateFormatter.dateFormat = format
                                    if let date = dateFormatter.date(from: dueDate) {
                                        dueDateParsed = date
                                        break
                                    }
                                }
                                
                                var dueDateFormatted = "Invalid Date"
                                if let dueDateParsed = dueDateParsed {
                                    let outputDateFormatter = DateFormatter()
                                    outputDateFormatter.dateFormat = "MM/dd/yyyy HH:mm:ss"
                                    dueDateFormatted = outputDateFormatter.string(from: dueDateParsed)
                                }
                                
                                let courseDeadlineEntry: [String: Any] = [
                                    "title": title,
                                    "link": link,
                                    "dueDate": dueDateFormatted,
                                    "roundedGrade": roundedGrade,
                                    "maxGrade": maxGrade,
                                    "deadlineType": assignedDeadlineType
                                ]
                                courseDeadlineEntries.append(courseDeadlineEntry)

                                var courseDeadline = CourseDeadline(link: link, dueDate: dueDateFormatted, maxGrade: maxGrade, title: title, roundedGrade: roundedGrade, deadlineType: assignedDeadlineType)
                                let deadlineType = CourseAssignmentTimeTaken.DeadlineType(from: assignedDeadlineType)
                                let (expectedTotalHrs, expectedHrsPerDay): (Int, Int)

                                if let deadlineType = deadlineType {
                                    (expectedTotalHrs, expectedHrsPerDay) = assignmentTimeTaken.getHours(for: deadlineType)
                                } else {
                                    (expectedTotalHrs, expectedHrsPerDay) = (CourseWorkloadConstants.hwTotalHrs, CourseWorkloadConstants.hwHrsPerDay)
                                }
                                FileLogger.shared.log(message: "Total Hours: \(expectedTotalHrs), Hours Per Day: \(expectedHrsPerDay)")
                                courseDeadline.expectedTotalHrs = expectedTotalHrs
                                courseDeadline.expectedHrsPerDay = expectedHrsPerDay
                                courseDeadlines.append(courseDeadline)
                            }
                        }
                        // Move to the next sibling element
                        nextRow = try reportRow.nextElementSibling()
                    }
                }
                
//                for reportRow in reportRows {
//                    //TODO: check parsing of rounded grade
//                    if let titleElement = try reportRow.select("span.title").first(),
//                       let linkElement = try titleElement.select("a").first(),
//                       let dueDateElement = try reportRow.select("span.due-date").first(),
//                       let roundedGradeElement = try reportRow.select("span.rounded-grade").first(),
//                       let maxGradeElement = try reportRow.select("span.max-grade").first() {
//                        
//                        let title = try titleElement.text()
//                        let deadlineType = title.split(separator: " ").last ?? ""
//                        let link = try linkElement.text()
//                        let dueDate = try dueDateElement.text().replacingOccurrences(of: "Due ", with: "")
//                        let roundedGrade = Int((try roundedGradeElement.text()).replacingOccurrences(of: "%", with: "").trimmingCharacters(in: .whitespaces)) ?? 0
//                        let maxGrade = Int((try maxGradeElement.text()).replacingOccurrences(of: "/", with: "").trimmingCharacters(in: .whitespaces)) ?? 0
//                        
//                        // Attempt to parse due date with multiple formats
//                        let dateFormats = ["M/dd/yy h:mma", "MM/dd/yy h:mma", "MM/dd/yy", "M/dd/yy"]
//                        var dueDateParsed: Date? = nil
//                        for format in dateFormats {
//                            let dateFormatter = DateFormatter()
//                            dateFormatter.dateFormat = format
//                            if let date = dateFormatter.date(from: dueDate) {
//                                dueDateParsed = date
//                                break
//                            }
//                        }
//                        
//                        var dueDateFormatted = "Invalid Date"
//                        if let dueDateParsed = dueDateParsed {
//                            let outputDateFormatter = DateFormatter()
//                            outputDateFormatter.dateFormat = "MM/dd/yyyy HH:mm:ss"
//                            dueDateFormatted = outputDateFormatter.string(from: dueDateParsed)
//                        }
//                        
//                        let courseDeadlineEntry: [String: Any] = [
//                            "title": title,
//                            "link": link,
//                            "dueDate": dueDateFormatted,
//                            "roundedGrade": roundedGrade,
//                            "maxGrade": maxGrade,
//                            "deadlineType": deadlineType
//                        ]
//                        courseDeadlineEntries.append(courseDeadlineEntry)
//
//                        let courseDeadline = CourseDeadline(link: link, dueDate: dueDate, maxGrade: maxGrade, title: title, roundedGrade: roundedGrade, deadlineType: String(deadlineType))
//                        courseDeadlines.append(courseDeadline)
//                    }
//                }
                
                // Attach the deadline entries to the appropriate course
                // TODO: Check for duplicaets before replacing it
                // Find course in self.courses and return deadlines - assign it to currentDeadlines
                // convert courseDeadlineEntries into an array of CourseDeadline - assign it to newDeadlines
                let courseExists = isCourseInArray(courses, newCourse: course)
                let courseIndex = indexOfCourse(in: courses, newCourse: course)
//                FileLogger.shared.log(courses: courses) // DEBUG
//                FileLogger.shared.log(courses: [course])
                if (courseIndex != -1) {
                    FileLogger.shared.log(message: "Reading HTML File - Course exists")
                    newCourse = self.getCourse(at: courseIndex)!
                    // accounting for newCourse.deadlines being nil
//                    updateDeadlines(current: &(newCourse.deadlines!), new: courseDeadlines) // BUG!
                    if var deadlines = newCourse.deadlines {
                        updateDeadlines(current: &deadlines, new: courseDeadlines)
                        newCourse.deadlines = deadlines
                    } else {
                        // Handle the case where `deadlines` is nil, maybe initialize it
                        var deadlines = [CourseDeadline]()
                        updateDeadlines(current: &deadlines, new: courseDeadlines)
                        newCourse.deadlines = deadlines
                    }
//                    newCourse.deadlines = courseDeadlines
                    newCourse.assignmentTimeTaken = assignmentTimeTaken // TODO: need to validate course initialized also has assignmentTaken initialized and NOT override here
//                    newCourse.deadlines = sortDeadlines(newCourse.deadlines!)
                    newCourse.setDeadlines(newCourse.deadlines!)
                    FileLogger.shared.log(message: "Modifying existing course deadlines")
//                    FileLogger.shared.log(courses: [newCourse])
                    course = newCourse
//                    self.courses[courseIndex] = newCourse
                }
                else {
                    FileLogger.shared.log(message: "Reading HTML File - Course does not exist")
//                    courseDeadlines = sortDeadlines(courseDeadlines)
//                    course.deadlines = courseDeadlines
                    course.setDeadlines(courseDeadlines)
                    course.assignmentTimeTaken = assignmentTimeTaken
                    self.courses.append(course)
                }
                
                // Convert entries array to JSON data
                let courseDeadlineEntriesJSONData = try JSONSerialization.data(withJSONObject: courseDeadlineEntries, options: .prettyPrinted)
                
                // Save JSON data to DocumentDirectory
                saveCourseDeadlinesToDocumentDirectory(jsonData: courseDeadlineEntriesJSONData, fileName: fileName)
                
                FileLogger.shared.log(message: "Course info being passed")
//                FileLogger.shared.log(courses: [course])
                
                // Append JSON data to CoursesData.json
                appendCoursesToDocumentDirectory(course: course, fileName: FileConstants.coursesFile)
                
            } catch Exception.Error(let type, let message) {
                FileLogger.shared.log(message:"Error: \(type) - \(message)")
            } catch {
                FileLogger.shared.log(message:"Unexpected error: \(error)")
            }
        }
    }

    
    /**
     
     */
    func isCourseInArray(_ courses: [Course], newCourse: Course) -> Bool {
        return courses.contains { course in
            return course.term == newCourse.term &&
                   course.title == newCourse.title &&
                   course.period == newCourse.period &&
                   course.instructor == newCourse.instructor
        }
    }
    
    func indexOfCourse(in courses: [Course], newCourse: Course) -> Int {
        for (index, course) in courses.enumerated() {
            if course.term == newCourse.term &&
               course.title == newCourse.title &&
               course.period == newCourse.period &&
               course.instructor == newCourse.instructor {
                return index
            }
        }
        return -1 // Sentinel value indicating the course was not found
    }
    
    /*
     sorts an array of CourseDeadline objects based on their dueDate
     */
    func sortDeadlines(_ deadlines: [CourseDeadline]) -> [CourseDeadline] {
        return deadlines.sorted {
            guard let date1 = $0.dueDateAsDate, let date2 = $1.dueDateAsDate else {
                return false
            }
            return date1 < date2
        }
    }
    
    /**
        Usage: updateDeadlines(current: &currentDeadlines, new: newDeadlines)
     */
    func updateDeadlines(current: inout [CourseDeadline], new: [CourseDeadline]) {
        var currentDict = Dictionary(uniqueKeysWithValues: current.map { ($0.link + $0.title, $0) })

        for newDeadline in new {
            let key = newDeadline.link + newDeadline.title
            if var currentDeadline = currentDict[key] {
                currentDeadline.updateIfNecessary(with: newDeadline)
                FileLogger.shared.log(message: "new params - \(newDeadline.title) -- \(newDeadline.link) -- \(newDeadline.dueDate) -- \(newDeadline.roundedGrade) -- \(newDeadline.maxGrade)")
                FileLogger.shared.log(message: "modified params (if applicable) -  \(currentDeadline.title) -- \(currentDeadline.link) -- \(currentDeadline.dueDate) -- \(currentDeadline.roundedGrade) -- \(currentDeadline.maxGrade)")
                currentDict[key] = currentDeadline
            } else {
                currentDict[key] = newDeadline
            }
        }

        current = Array(currentDict.values)
    }
    
    // Method to filter deadlines based on each deadline's expected total hours and expected hours per day
    func filterDeadlines(course: Course) -> [(course: Course, deadline: CourseDeadline)] {
        guard let deadlines = course.deadlines else { return [] }
        
        var filteredDeadlines: [(course: Course, deadline: CourseDeadline)] = []
        let currentDate = Date()
        
        // DEBUG - print current date
        // Formatted output using DateFormatter
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let formattedDate = dateFormatter.string(from:
         currentDate)
        FileLogger.shared.log(message: formattedDate)
        
//        print("Deadlines - ")
//        print(deadlines)
        for deadline in deadlines where !deadline.isCompleted {
            guard let dueDate = deadline.dueDateAsDate else { continue }
            
            let d1 = Calendar.current.dateComponents([.day], from: currentDate, to: dueDate).day ?? Int.max
            let d2 = (deadline.expectedTotalHrs + deadline.expectedHrsPerDay - 1) / deadline.expectedHrsPerDay
//            FileLogger.shared.log(message: "Advance Notification - Deadline Description")
//            FileLogger.shared.log(message: "d1: \(d1) & d2: \(d2)")
//            FileLogger.shared.log(message: deadline.description)
            
            if d1 <= d2 {
                filteredDeadlines.append((course, deadline))
            }
        }
        
        // Sort by daysToDue
        filteredDeadlines.sort { $0.deadline.daysToDue < $1.deadline.daysToDue }
        
        return filteredDeadlines
    }
    
    // Method to filter deadlines based on each deadline's expected total hours and expected hours per day
    func filterCompletedDeadlines(course: Course) -> [(course: Course, deadline: CourseDeadline)] {
        guard let deadlines = course.deadlines else { return [] }
        
        var filteredDeadlines: [(course: Course, deadline: CourseDeadline)] = []
        let currentDate = Date()
        
        // DEBUG - print current date
        // Formatted output using DateFormatter
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let formattedDate = dateFormatter.string(from:
         currentDate)
        FileLogger.shared.log(message: formattedDate)
        
//        print("Filtering Completed Deadlines - ")
//        print(deadlines)
        for deadline in deadlines where !deadline.isCompleted {
//            print(deadline)
            filteredDeadlines.append((course, deadline))
        }
        
        // Sort by daysToDue
        filteredDeadlines.sort { $0.deadline.daysToDue < $1.deadline.daysToDue }
        
        return filteredDeadlines
    }
    
    // Method ot sort deadlines after collating it from all the courses
    func sortCourseDeadlinesByDueDays(_ courseDeadlines: [(Course, CourseDeadline)]) -> [(Course, CourseDeadline)] {
        return courseDeadlines.sorted {
            if $0.1.daysToDue == $1.1.daysToDue {
                return $0.1.title < $1.1.title
            }
            return $0.1.daysToDue < $1.1.daysToDue
        }
    }
    
    /**
     Function to read the HTML file from the resources directory
     */
    func readHTMLFile(fileName: String) -> String? {
        guard let filePath = Bundle.main.path(forResource: fileName, ofType: "html") else {
            FileLogger.shared.log(message:"File not found")
            return nil
        }

        do {
            let htmlString = try String(contentsOfFile: filePath, encoding: .utf8)
            return htmlString
        } catch {
            FileLogger.shared.log(message:"Error reading file: \(error.localizedDescription)")
            return nil
        }
    }
    
    /**
        searches for all HTML files in Document Directory
        parses all the deadlines and stores it in a json file for each HTML course file
     */
    func processAllHTMLFilesInDocumentsDirectory() {
        createEmptyCourseInDocumentDirectory("\(FileConstants.coursesFile)")
        let fileManager = FileManager.default
        
        // Get the path to the Documents directory
        if let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.path {
            do {
                let files = try fileManager.contentsOfDirectory(atPath: documentsPath)
                let htmlFiles = files.filter { $0.hasSuffix(".html") }
                
                for htmlFile in htmlFiles {
                    let fileName = htmlFile.replacingOccurrences(of: ".html", with: "")
                    parseHTMLAndSaveToDocumentDirectory(fileName: fileName)
                }
            } catch {
                FileLogger.shared.log(message:"Failed to list files in Documents directory: \(error)")
            }
        }
    }
    
    /**
        searches for all HTML files in Resources
        parses all the deadlines and stores it in a json file for each HTML course file
     */
    func processAllHTMLFilesInResources() {
        createEmptyCourseInDocumentDirectory("\(FileConstants.coursesFile)")
        let fileManager = FileManager.default
        if let resourcesPath = Bundle.main.resourcePath {
            do {
                let files = try fileManager.contentsOfDirectory(atPath: resourcesPath)
                let htmlFiles = files.filter { $0.hasSuffix(".html") }
                
                for htmlFile in htmlFiles {
                    let fileName = htmlFile.replacingOccurrences(of: ".html", with: "")
                    parseHTMLAndSaveToDocumentDirectory(fileName: fileName)
                }
            } catch {
                FileLogger.shared.log(message:"Failed to list files in Resources directory: \(error)")
            }
        }
    }
    
    /**
     returns course info
     */
    func getCourseInfo() -> CourseInfo {
           return courseInfo
   }

    /**
     returns the course information at the index
     */
    func getCourse(at index: Int) -> Course? {
            guard index >= 0 && index < courses.count else {
                return nil
            }
            return courses[index]
    }
    
    /**
     updates course info struct  by iterating through each course name
     */
    func updateCourseNames() {
        // Sort courses by period
        let sortedCourses = self.courses.sorted { $0.period < $1.period }
        
        // Update courseNames in courseInfo based on sorted courses
        for i in 0..<min(7, sortedCourses.count) {
            self.courseInfo.courseNames[i] = sortedCourses[i].title
        }
        
        self.courses = sortedCourses
    }
    
    /**
     save course at the appropriate index to file
     */
    func saveCourseToFile(course: Course, at index: Int,  _ filename:String) {
        let data: Data

        // Locate the JSON file in the document directory
        let fileManager = FileManager.default
        guard let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("Couldn't locate document directory.")
        }
        
        let fileURL = documentDirectory.appendingPathComponent(filename)

        do {
            // Load the contents of the file into a Data object
            data = try Data(contentsOf: fileURL)
            // Debugging: Log the contents of the file
            if let jsonString = String(data: data, encoding: .utf8) {
//                FileLogger.shared.log(message: "Contents of \(filename): \(jsonString)")
            }
        } catch {
            fatalError("Couldn't load \(filename) from document directory:\n\(error)")
        }

        do {
            // Decode the data into the specified type
            let decoder = JSONDecoder()
            self.courses = try decoder.decode([Course].self, from: data)
            self.courses.sort { $0.period < $1.period }
            FileLogger.shared.log(message:"READ - List of Courses from data store")
//            FileLogger.shared.log(courses: courses)
            // update or add new course
            // TODO: incorrect logic; use the id to update
            if index < self.courses.count {
                self.courses[index] = course
            } else {
                self.courses.append(course)
            }
            // DEBUG
            FileLogger.shared.log(message:"Original Course Info")
//            FileLogger.shared.log(courses:[course])
            FileLogger.shared.log(message:"After updating Course Info")
//            FileLogger.shared.log(courses:[courses[index]])
            FileLogger.shared.log(message:"Courses in modelData")
//            FileLogger.shared.log(courses:self.courses)
            
            self.courses.sort { $0.period < $1.period } // Sort courses by period
            
            //write back to file
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let jsonData = try encoder.encode(self.courses)
            try jsonData.write(to: fileURL, options: .atomic)
            
            FileLogger.shared.log(message: "Added \(course) to \(fileURL)")
        } catch {
            FileLogger.shared.log(message: "Failed to decode \(filename): \(error.localizedDescription)")
            fatalError("Couldn't parse \(filename) as \([Course].self):\n\(error)")
        }
        
    }
    
    /**
     initializes an empty course JSON file
     */
    func createEmptyCourseInDocumentDirectory(_ filename: String) {
        //TODO: Modify code when settings is created for refreshing course names
        // Get the document directory path
        if let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            // Create the full file path
            let fileURL = documentDirectory.appendingPathComponent(filename)
            
            // Check if the file already exists
            if FileManager.default.fileExists(atPath: fileURL.path) {
                FileLogger.shared.log(message: "File already exists at \(fileURL.path)")
            } else {
                // Define an empty JSON object
                let emptyJSONObject: [Course] = []
                
                do {
                    // Convert the empty JSON object to Data
                    let jsonData = try JSONSerialization.data(withJSONObject: emptyJSONObject, options: .prettyPrinted)
                    
                    // Write the JSON data to the file
                    try jsonData.write(to: fileURL, options: .atomic)
                    
                    FileLogger.shared.log(message: "Empty JSON file created at \(fileURL.path)")
                } catch {
                    FileLogger.shared.log(message: "Failed to create JSON file: \(error)")
                }
            }
        }
    }
    
    /**
     returns a list of courses
     initializes an empty list if courses JSON file is not found
     */
    func loadCoursesFromDocumentDirectory(_ filename: String) -> [Course] {
        let data: Data

        // Locate the JSON file in the document directory
        let fileManager = FileManager.default
        guard let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("Couldn't locate document directory.")
        }
        
        let fileURL = documentDirectory.appendingPathComponent(filename)
        
        // Create empty JSON file if file does not exist initially
        if !fileManager.fileExists(atPath: fileURL.path) {
            // Create an empty array for the initial JSON content
            let emptyData: [Course] = []

            // Convert the empty array to JSON data
            do {
                let jsonData = try JSONEncoder().encode(emptyData)
                try jsonData.write(to: fileURL, options: .atomic)
                FileLogger.shared.log(message: "Created an empty \(filename) file.")
            } catch {
                FileLogger.shared.log(message: "Failed to create \(filename) file: \(error.localizedDescription)")
                fatalError("Failed to create \(filename) file: \(error.localizedDescription)")
            }
        } else {
                FileLogger.shared.log(message: "\(filename) already exists.")
            FileLogger.shared.log(message:"\(filename) already exists.")
        }
        FileLogger.shared.log(message: "Loading data from file -  \(fileURL)")
        
        // Check if the file exists
        guard fileManager.fileExists(atPath: fileURL.path) else {
            fatalError("Couldn't find \(filename) in document directory.")
        }

        do {
            // Load the contents of the file into a Data object
            data = try Data(contentsOf: fileURL)
            // Debugging: Log the contents of the file
            if let jsonString = String(data: data, encoding: .utf8) {
//                FileLogger.shared.log(message: "Contents of \(filename): \(jsonString)")
            }
        } catch {
            fatalError("Couldn't load \(filename) from document directory:\n\(error)")
        }

        do {
            // Decode the data into the specified type
            let decoder = JSONDecoder()
            let courses = try decoder.decode([Course].self, from: data)
            FileLogger.shared.log(message:"Courses Read via JSONDecoder()")
//            FileLogger.shared.log(courses:courses)
            return try decoder.decode([Course].self, from: data)
        } catch {
            FileLogger.shared.log(message: "Failed to decode \(filename): \(error.localizedDescription)")
            fatalError("Couldn't parse \(filename) as \([Course].self):\n\(error)")
        }
    }


}
