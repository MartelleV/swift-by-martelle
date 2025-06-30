//
//  ViewModels/TaskViewModel.swift
//
//  Created by Zayne Verlyn on 22/5/25.
//

import Foundation
import SwiftUI
import UserNotifications

class TaskViewModel: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    @Published var tasks: [Task] = []
    private let notificationCenter = UNUserNotificationCenter.current()

    override init() {
        super.init()
        notificationCenter.delegate = self // Set delegate here
        requestNotificationPermission()
        loadTasks()
    }

    // Handle notification presentation when the app is in the foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }

    func addTask(title: String, dueDate: Date) {
        let task = Task(title: title, dueDate: dueDate)
        tasks.append(task)
        saveTasks()
        scheduleNotification(for: task)
    }

    func toggleCompletion(task: Task) {
            if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                tasks[index].isCompleted.toggle()
                saveTasks()
                
                // Remove notifications if task is marked as completed
                if tasks[index].isCompleted {
                    removeNotifications(for: tasks[index])
                }
            }
        }

    func deleteTask(at indexSet: IndexSet) {
        // Remove notifications for deleted tasks
        indexSet.forEach { index in
            removeNotifications(for: tasks[index])
        }
        tasks.remove(atOffsets: indexSet)
        saveTasks()
    }

    // Helper function to remove notifications for a deleted/completed task
    private func removeNotifications(for task: Task) {
        let identifiers = [
            task.id.uuidString,
            "\(task.id.uuidString)-overdue",
            "\(task.id.uuidString)-nearDue"
        ]
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    private func saveTasks() {
        if let encoded = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(encoded, forKey: "tasks")
        }
    }

    private func loadTasks() {
        if let data = UserDefaults.standard.data(forKey: "tasks"),
           let decoded = try? JSONDecoder().decode([Task].self, from: data) {
            tasks = decoded
        }
    }

    private func requestNotificationPermission() {
        notificationCenter.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            if granted {
                print("Notifications allowed")
            }
        }
    }

    // Fix: Enhanced notification scheduling for immediate and future notifications
    private func scheduleNotification(for task: Task) {
        let currentDate = Date()
        if !task.isCompleted {
            if task.isOverdue {
                // Immediate notification for overdue tasks
                let content = UNMutableNotificationContent()
                content.title = "🔴 Task Overdue"
                content.body = "\(task.title) is overdue!"
                content.sound = .default

                let request = UNNotificationRequest(identifier: "\(task.id.uuidString)-overdue", content: content, trigger: nil) // nil trigger = immediate
                notificationCenter.add(request, withCompletionHandler: nil)
            } else if task.isNearDue {
                // Immediate notification for near-due tasks
                let nearDueContent = UNMutableNotificationContent()
                nearDueContent.title = "⏰ Task Approaching"
                nearDueContent.body = "\(task.title) is due soon!"
                nearDueContent.sound = .default

                let nearDueRequest = UNNotificationRequest(identifier: "\(task.id.uuidString)-nearDue", content: nearDueContent, trigger: nil)
                notificationCenter.add(nearDueRequest, withCompletionHandler: nil)

                // Also schedule the due notification if in the future
                if task.dueDate > currentDate {
                    let dueContent = UNMutableNotificationContent()
                    dueContent.title = "📌 Task Due"
                    dueContent.body = "\(task.title) is due now!"
                    dueContent.sound = .default

                    let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: task.dueDate)
                    let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

                    let dueRequest = UNNotificationRequest(identifier: task.id.uuidString, content: dueContent, trigger: trigger)
                    notificationCenter.add(dueRequest, withCompletionHandler: nil)
                }
            } else {
                // Logic for tasks more than an hour away
                let nearDueDate = task.dueDate.addingTimeInterval(-3600)
                if nearDueDate > currentDate {
                    let nearDueContent = UNMutableNotificationContent()
                    nearDueContent.title = "⏰ Task Approaching"
                    nearDueContent.body = "\(task.title) is due in 1 hour!"
                    nearDueContent.sound = .default

                    let nearDueTriggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: nearDueDate)
                    let nearDueTrigger = UNCalendarNotificationTrigger(dateMatching: nearDueTriggerDate, repeats: false)

                    let nearDueRequest = UNNotificationRequest(identifier: "\(task.id.uuidString)-nearDue", content: nearDueContent, trigger: nearDueTrigger)
                    notificationCenter.add(nearDueRequest, withCompletionHandler: nil)
                }

                if task.dueDate > currentDate {
                    let content = UNMutableNotificationContent()
                    content.title = "📌 Task Due"
                    content.body = "\(task.title) is due now!"
                    content.sound = .default

                    let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: task.dueDate)
                    let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

                    let request = UNNotificationRequest(identifier: task.id.uuidString, content: content, trigger: trigger)
                    notificationCenter.add(request, withCompletionHandler: nil)
                }
            }
        }
    }
}
