//
//  FileLogger.swift
//  QuickAlert
//
//  Created by Vasisht Kartik on 6/29/24.
//

import Foundation

class FileLogger {
    static let shared = FileLogger()
    
    private let logFileURL: URL
    
    private init() {
        // Define the file path for the log file
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.logFileURL = documentsURL.appendingPathComponent("QuickAlertApp.log")
    }
    
    func ensureLogFileExists() {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: logFileURL.path) {
            // Create an empty log file
            let emptyLogMessage = "Log file created on \(Date().description(with: .current))\n"
            if let data = emptyLogMessage.data(using: .utf8) {
                try? data.write(to: logFileURL, options: .atomicWrite)
            }
        }
    }

    func log(message: String) {
        let timestamp = Date().description(with: .current)
        let logMessage = "[\(timestamp)] \(message)\n"
        
        // Write the log message to the file
        if let data = logMessage.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: logFileURL.path) {
                // Append to existing file
                if let fileHandle = try? FileHandle(forWritingTo: logFileURL) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                }
            } else {
                // Create a new file and write the message
                try? data.write(to: logFileURL, options: .atomicWrite)
            }
        }
    }
    
    func readLogs() -> String? {
        return try? String(contentsOf: logFileURL, encoding: .utf8)
    }
    
    func log(courses: [Course]) {
        for course in courses {
            log(message: course.description)
        }
    }
    
    func log(courseNames: [String]) {
        for course in courseNames {
            log(message: course)
        }
    }
    
    func log(filteredDeadlines: [(Course, CourseDeadline)]) {
        for (course, deadline) in filteredDeadlines {
            log(message: "Course: \(course.title)")
            log(message: deadline.description)
        }
    }
    
}
