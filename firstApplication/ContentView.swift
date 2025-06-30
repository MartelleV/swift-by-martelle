//
//  ContentView.swift
//
//  Created by Zayne Verlyn on 21/5/25.
//

import SwiftUI

struct ContentView: View {
    @State private var taskTitle = ""
    @State private var dueDate = Date()
    @State private var showingAddTask = false
    @StateObject private var viewModel = TaskViewModel()
    @State private var deleteIndexSet: IndexSet?
    @State private var showDeleteConfirmation = false
    @State private var timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.tasks) { task in
                    TaskRowView(task: task) {
                        viewModel.toggleCompletion(task: task)
                    }
                }
                .onDelete { indexSet in
                    if let index = indexSet.first, !viewModel.tasks[index].isCompleted {
                        deleteIndexSet = indexSet
                        showDeleteConfirmation = true
                    } else {
                        viewModel.deleteTask(at: indexSet)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("📋 To-Do List")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddTask = true
                    } label: {
                        Label("Add Task", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTask) {
                NavigationView {
                    Form {
                        Section(header: Text("New Task")) {
                            TextField("Task Title", text: $taskTitle)
                            DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                        }

                        HStack {
                            Spacer()
                            Button("Add Task") {
                                viewModel.addTask(title: taskTitle, dueDate: dueDate)
                                taskTitle = ""
                                showingAddTask = false
                            }
                            .buttonStyle(.borderedProminent)
                            .frame(maxWidth: .infinity, alignment: .center)
                            Spacer()
                        }
                        .listRowBackground(Color.clear) // Remove white background around the Add Task button
                    }
                    .navigationTitle("Add Task")
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
            .confirmationDialog("Are you sure you want to delete this task? You have not completed it yet!", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    if let indexSet = deleteIndexSet {
                        viewModel.deleteTask(at: indexSet)
                    }
                    deleteIndexSet = nil
                }
                Button("Cancel", role: .cancel) {
                    deleteIndexSet = nil
                }
            }
            .onReceive(timer) { _ in
                viewModel.objectWillChange.send()
            }
        }
    }
}

// Split the View so the app does not go into performance bottlenecks
struct TaskRowView: View {
    let task: Task
    let toggleCompletion: () -> Void

    var backgroundColor: Color {
        if task.isCompleted {
            return Color.green.opacity(0.1)
        } else if task.isOverdue {
            return Color.red.opacity(0.1)
        } else if task.isNearDue {
            return Color.yellow.opacity(0.1)
        } else {
            return Color(.systemBackground)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(task.title)
                    .font(.headline)
                    .strikethrough(task.isCompleted)
                    .foregroundColor(task.isCompleted ? .gray : .primary)

                Spacer()

                if task.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }

            HStack {
                Text(task.status)
                    .font(.caption2)
                    .padding(4)
                    .background(task.statusColor.opacity(0.2))
                    .foregroundColor(task.statusColor)
                    .cornerRadius(4)

                Spacer()

                Text(task.dueDate, format: .dateTime.day().month().hour().minute())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 12).fill(backgroundColor))
        .onTapGesture {
            withAnimation {
                toggleCompletion()
            }
        }
        .listRowSeparatorTint(Color.gray.opacity(0.3))
    }
}

#Preview {
    ContentView()
}
