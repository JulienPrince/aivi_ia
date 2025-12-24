//
//  Logger.swift
//  AITextAssistantMac
//
//  Created by Julien Prince on 24/12/2025.
//

import Foundation
import os.log

enum LogLevel {
    case debug
    case info
    case error
}

struct Logger {
    private static let subsystem = "com.prince.AITextAssistantMac"
    private static let category = "App"
    
    private static let logger = os.Logger(subsystem: subsystem, category: category)
    
    static func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        logger.debug("\(fileName):\(line) \(function) - \(message)")
    }
    
    static func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        logger.info("\(fileName):\(line) \(function) - \(message)")
    }
    
    static func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        logger.error("\(fileName):\(line) \(function) - \(message)")
    }
    
    static func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        logger.warning("\(fileName):\(line) \(function) - \(message)")
    }
    
    static func log(_ level: LogLevel, _ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        switch level {
        case .debug:
            debug(message, file: file, function: function, line: line)
        case .info:
            info(message, file: file, function: function, line: line)
        case .error:
            error(message, file: file, function: function, line: line)
        }
    }
}
