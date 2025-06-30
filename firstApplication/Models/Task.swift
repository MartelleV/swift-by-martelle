//
//  Models/Task.swift
//
//  Created by Zayne Verlyn on 22/5/25.
//

import Foundation
import SwiftUI

struct Task: Identifiable, Codable {
    var id = UUID()
    var title: String
    var isCompleted: Bool = false
    var dueDate: Date

    var isOverdue: Bool {
        !isCompleted && dueDate < Date()
    }

    var isNearDue: Bool {
        if isCompleted || isOverdue { return false }
        let timeInterval = dueDate.timeIntervalSinceNow
        return timeInterval > 0 && timeInterval <= 3600
    }

    var status: String {
        if isCompleted {
            return "Completed"
        }
        else if isOverdue {
            return "Overdue"
        }
        else if isNearDue {
            return "Near Due"
        }
        else {
            return "Pending"
        }
    }

    var statusColor: Color {
        switch status {
            case "Completed": return .green
            case "Overdue": return .red
            case "Near Due": return .yellow
            default: return .gray
        }
    }
}
