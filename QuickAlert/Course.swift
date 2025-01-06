//
//  Course.swift
//  QuickAlert
//
//  Created by Vasisht Kartik on 6/19/24.
//

import Foundation
import SwiftData

/**
 data structure to store course information - title, instructor name, period, and term
 */
struct Course: Identifiable, Hashable, Codable, CustomStringConvertible {
    static func == (lhs: Course, rhs: Course) -> Bool {
        return lhs.id == rhs.id // compare based on unique id
    }
    
    @Attribute(.unique) var id: UUID
    @Attribute var term: String
    @Attribute var title: String
    @Attribute var period: String
    @Attribute var instructor: String
    @Attribute var deadlines: [CourseDeadline]? = nil // Optional array of deadlines
    @Attribute var assignmentTimeTaken: CourseAssignmentTimeTaken? = nil

    init(id: UUID = UUID(), term: String, title: String, period: String, instructor: String, deadlines: [CourseDeadline]? = nil, assignmentTimeTaken: CourseAssignmentTimeTaken? = nil) {
        self.id = id
        self.term = term
        self.title = title
        self.period = period
        self.instructor = instructor
        self.deadlines = deadlines
        self.assignmentTimeTaken = assignmentTimeTaken
    }
    
    // Method to add a deadline and keep the array sorted
    mutating func addDeadline(_ deadline: CourseDeadline) {
        if deadlines == nil {
            deadlines = [deadline]
        } else {
            deadlines?.append(deadline)
            deadlines?.sort { $0.dueDateAsDate ?? Date.distantPast < $1.dueDateAsDate ?? Date.distantPast }
        }
    }
    
    // Method to replace the entire deadlines array, ensuring it remains sorted
    mutating func setDeadlines(_ newDeadlines: [CourseDeadline]) {
        deadlines = newDeadlines.sorted { $0.dueDateAsDate ?? Date.distantPast < $1.dueDateAsDate ?? Date.distantPast }
    }
    
    mutating func updateDeadline(_ newDeadline: CourseDeadline, actualHrsPerDay: Double, actualTotalHrs: Double) {
        guard var deadlines = self.deadlines else {
            return // No deadlines to update
        }

        // Find the index of the deadline to update
        if let index = deadlines.firstIndex(where: { $0.title == newDeadline.title && $0.link == newDeadline.link }) {
            // Update the deadline at the found index
            deadlines[index].updateIfNecessary(with: newDeadline)

            // Update the actual hours per day and actual total hours
            deadlines[index].actualHrsPerDay = Int(actualHrsPerDay)
            deadlines[index].actualTotalHrs = Int(actualTotalHrs)
            deadlines[index].isCompleted = true

            FileLogger.shared.log(message: "Updated Deadline with actual hours")
            FileLogger.shared.log(message: deadlines[index].description)
            
            // Reassign the updated deadlines array back to the course
            self.deadlines = deadlines.sorted { $0.dueDateAsDate ?? Date.distantPast < $1.dueDateAsDate ?? Date.distantPast }
        } else {
            // If the deadline isn't found, log a message
            FileLogger.shared.log(message: "Deadline with title \(newDeadline.title) and link \(newDeadline.link) not found in course \(self.title).")
        }
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(term)
        hasher.combine(title)
        hasher.combine(period)
        hasher.combine(instructor)
        // Optionally, consider including deadlines if they are unique identifiers
    }
    
    var description: String {
        var description = "Course:\n"
        description += "  ID: \(id)\n"
        description += "  Term: \(term)\n"
        description += "  Title: \(title)\n"
        description += "  Period: \(period)\n"
        description += "  Instructor: \(instructor)\n"
        if let assignmentTime = assignmentTimeTaken {
            description += "  Assignment Time Taken:\n\(assignmentTime)\n"
        } else {
            description += "  Assignment Time Taken: None\n"
        }
        if let deadlines = deadlines {
            description += "  Deadlines:\n"
            for deadline in deadlines {
                description += "    - \(deadline)\n"
            }
        } else {
            description += "  Deadlines: None\n"
        }
        return description
    }

}

struct CourseDeadlineTuple: Identifiable {
    let course: Course
    let deadline: CourseDeadline

    var id: String {
        "\(course.id)-\(deadline.id)" // Replace with appropriate identifiers
    }
}


/**
 struct to store course names and student name
 */
struct CourseInfo {
    var studentName: String
    var courseNames: [String]
}

/**
 TODO: Pending Documentation
 */
struct CourseDeadline: Codable, CustomStringConvertible, Hashable, Identifiable {
    var link: String
    var dueDate: String // String representation in MM/dd/yyyy HH:mm:ss format
    var maxGrade: Double
    var title: String
    var roundedGrade: Double
    var deadlineType: String
    var expectedTotalHrs: Int
    var expectedHrsPerDay: Int
    var actualTotalHrs: Int
    var actualHrsPerDay: Int
    var isCompleted: Bool = false

    var id: String { "\(title)_\(link)" }
    
    // Decoder to handle date formatting during decoding
    private enum CodingKeys: String, CodingKey {
        case link, maxGrade, title, roundedGrade, deadlineType, expectedTotalHrs, expectedHrsPerDay, actualTotalHrs, actualHrsPerDay, isCompleted
        case dueDate = "dueDate" // Use the exact key name from JSON
    }

    init(link: String, dueDate: String, maxGrade: Double, title: String, roundedGrade: Double, deadlineType: String, expectedTotalHrs: Int, expectedHrsPerDay: Int, actualTotalHrs: Int, actualHrsPerDay: Int, isCompleted: Bool = false) {
        self.link = link
        self.dueDate = dueDate
        self.maxGrade = maxGrade
        self.title = title
        self.roundedGrade = roundedGrade
        self.deadlineType = deadlineType
        self.expectedTotalHrs = expectedTotalHrs
        self.expectedHrsPerDay = expectedHrsPerDay
        self.actualTotalHrs = actualTotalHrs
        self.actualHrsPerDay = actualHrsPerDay
        self.isCompleted = isCompleted
    }
    
    init(link: String, dueDate: String, maxGrade: Double, title: String, roundedGrade: Double, deadlineType: String) {
        self.link = link
        self.dueDate = dueDate
        self.maxGrade = maxGrade
        self.title = title
        self.roundedGrade = roundedGrade
        self.deadlineType = deadlineType
        self.expectedTotalHrs = 0 // Default value
        self.expectedHrsPerDay = 0 // Default value
        self.actualTotalHrs = 0 // Default value
        self.actualHrsPerDay = 0 // Default value
        self.isCompleted = false // Default value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        link = try container.decode(String.self, forKey: .link)
        maxGrade = try container.decode(Double.self, forKey: .maxGrade)
        title = try container.decode(String.self, forKey: .title)
        roundedGrade = try container.decode(Double.self, forKey: .roundedGrade)
        dueDate = try container.decode(String.self, forKey: .dueDate)
        deadlineType = try container.decode(String.self, forKey: .deadlineType)
        expectedTotalHrs = try container.decode(Int.self, forKey: .expectedTotalHrs)
        expectedHrsPerDay = try container.decode(Int.self, forKey: .expectedHrsPerDay)
        actualTotalHrs = try container.decode(Int.self, forKey: .actualTotalHrs)
        actualHrsPerDay = try container.decode(Int.self, forKey: .actualHrsPerDay)
        isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
    }
    
    var description: String {
        return """
        Title: \(title)
        Due Date: \(dueDate)
        Max Grade: \(maxGrade)
        Rounded Grade: \(roundedGrade)
        Link: \(link)
        Deadline Type: \(deadlineType)
        Expected Total Hours: \(expectedTotalHrs)
        Expected Hours Per Day: \(expectedHrsPerDay)
        Actual Total Hours: \(actualTotalHrs)
        Actual Hours Per Day: \(actualHrsPerDay)
        Is Completed: \(isCompleted)
        """
    }
    
    var dueDateAsDate: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy HH:mm:ss"
        return formatter.date(from: dueDate)
    }
    
    var daysToDue: Int {
        guard let dueDateAsDate = dueDateAsDate else {
            return 0
        }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: dueDateAsDate)
        
//        // Debugging information
//        print("Current Date: \(Date())")
//        print("Due Date: \(dueDateAsDate)")
//        print("Days to Due Date: \(components.day ?? 0)")
    
        return components.day ?? 0
    }

    mutating func updateIfNecessary(with newDeadline: CourseDeadline) {
        guard self.link == newDeadline.link, self.title == newDeadline.title else { return }

        if let currentDueDate = self.dueDateAsDate, let newDueDate = newDeadline.dueDateAsDate {
            if newDueDate != currentDueDate || self.roundedGrade != newDeadline.roundedGrade || self.maxGrade != newDeadline.maxGrade {
                FileLogger.shared.log(message: "due date, rounded grade or max grade has changed for \(newDeadline.title)")
//                FileLogger.shared.log(message: "new params - \(newDeadline.dueDate) -- \(newDeadline.roundedGrade) -- \(newDeadline.maxGrade)")
//                FileLogger.shared.log(message: "existing params - \(self.dueDate) -- \(self.roundedGrade) -- \(self.maxGrade)")
                self.dueDate = newDeadline.dueDate
                self.roundedGrade = newDeadline.roundedGrade
                self.maxGrade = newDeadline.maxGrade
                self.expectedTotalHrs = newDeadline.expectedTotalHrs
                self.expectedHrsPerDay = newDeadline.expectedHrsPerDay
            } else if self.roundedGrade != newDeadline.roundedGrade || self.maxGrade != newDeadline.maxGrade {
                FileLogger.shared.log(message: "rounded grade or max grade has changed for \(newDeadline.title)")
//                FileLogger.shared.log(message: "new params - \(newDeadline.dueDate) -- \(newDeadline.roundedGrade) -- \(newDeadline.maxGrade)")
//                FileLogger.shared.log(message: "existing params - \(self.dueDate) -- \(self.roundedGrade) -- \(self.maxGrade)")
                self.roundedGrade = newDeadline.roundedGrade
                self.maxGrade = newDeadline.maxGrade
                self.expectedTotalHrs = newDeadline.expectedTotalHrs
                self.expectedHrsPerDay = newDeadline.expectedHrsPerDay
            } else {
                // Third condition to always update expected hours
                FileLogger.shared.log(message: "No significant changes, updating expected hours for \(newDeadline.title)")
                self.expectedTotalHrs = newDeadline.expectedTotalHrs
                self.expectedHrsPerDay = newDeadline.expectedHrsPerDay
            }
        }
        
        FileLogger.shared.log(message: "current params (post update) - \(self.dueDate) -- \(self.roundedGrade) -- \(self.maxGrade)")

    }
    

}


struct CourseAssignmentTimeTaken: Codable, CustomStringConvertible {
    var hwTotalHrs: Int = 0
    var hwHrsPerDay: Int = 0
    var quizTotalHrs: Int = 0
    var quizHrsPerDay: Int = 0
    var testTotalHrs: Int = 0
    var testHrsPerDay: Int = 0
    var cwTotalHrs: Int = 0
    var cwHrsPerDay: Int = 0
    var labTotalHrs: Int = 0
    var labHrsPerDay: Int = 0
    
    init() {
        self.hwTotalHrs = CourseWorkloadConstants.hwTotalHrs
        self.hwHrsPerDay = CourseWorkloadConstants.hwHrsPerDay
        self.quizTotalHrs = CourseWorkloadConstants.quizTotalHrs
        self.quizHrsPerDay = CourseWorkloadConstants.quizHrsPerDay
        self.testTotalHrs = CourseWorkloadConstants.testTotalHrs
        self.testHrsPerDay = CourseWorkloadConstants.testHrsPerDay
        self.cwTotalHrs = CourseWorkloadConstants.cwTotalHrs
        self.cwHrsPerDay = CourseWorkloadConstants.cwHrsPerDay
        self.labTotalHrs = CourseWorkloadConstants.labTotalHrs
        self.labHrsPerDay = CourseWorkloadConstants.labHrsPerDay
    }
    
    mutating func setTimeTaken(hwTotalHrs: Int, hwHrsPerDay: Int, quizTotalHrs: Int, quizHrsPerDay: Int, testTotalHrs: Int, testHrsPerDay: Int, cwTotalHrs: Int, cwHrsPerDay: Int, labTotalHrs: Int, labHrsPerDay: Int) {
        self.hwTotalHrs = hwTotalHrs
        self.hwHrsPerDay = hwHrsPerDay
        self.quizTotalHrs = quizTotalHrs
        self.quizHrsPerDay = quizHrsPerDay
        self.testTotalHrs = testTotalHrs
        self.testHrsPerDay = testHrsPerDay
        self.cwTotalHrs = cwTotalHrs
        self.cwHrsPerDay = cwHrsPerDay
        self.labTotalHrs = labTotalHrs
        self.labHrsPerDay = labHrsPerDay
    }
    
    var description: String {
        return """
        Homework Total Hours: \(hwTotalHrs), Homework Hours Per Day: \(hwHrsPerDay)
        Quiz Total Hours: \(quizTotalHrs), Quiz Hours Per Day: \(quizHrsPerDay)
        Test Total Hours: \(testTotalHrs), Test Hours Per Day: \(testHrsPerDay)
        Classwork Total Hours: \(cwTotalHrs), Classwork Hours Per Day: \(cwHrsPerDay)
        Lab Total Hours: \(labTotalHrs), Lab Hours Per Day: \(labHrsPerDay)
        """
    }
    
    enum DeadlineType {
        case homework
        case quiz
        case test
        case classwork
        case lab
        
        init?(from string: String) {
            switch string.lowercased() {
            case "homework":
                self = .homework
            case "quiz":
                self = .quiz
            case "test":
                self = .test
            case "classwork":
                self = .classwork
            case "lab":
                self = .lab
            default:
                return nil
            }
        }
    }

    
    func getHours(for type: DeadlineType) -> (totalHours: Int, hoursPerDay: Int) {
        switch type {
        case .homework:
            return (hwTotalHrs, hwHrsPerDay)
        case .quiz:
            return (quizTotalHrs, quizHrsPerDay)
        case .test:
            return (testTotalHrs, testHrsPerDay)
        case .classwork:
            return (cwTotalHrs, cwHrsPerDay)
        case .lab:
            return (labTotalHrs, labHrsPerDay)
        }
    }
}



