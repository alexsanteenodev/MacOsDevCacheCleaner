//
//  ContentView.swift
//  DevCacheCleaner
//
//  Created by Oleksandr Hanhaliuk on 19/01/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject internal var viewModel = ContentViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Text("Dev Cache Cleaner")
                    .font(.headline)
                
                Spacer()
                
                Button(action: viewModel.refreshTools) {
                    Image(systemName: "arrow.clockwise")
                        .rotationEffect(.degrees(viewModel.isRefreshing ? 360 : 0))
                        .animation(viewModel.isRefreshing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: viewModel.isRefreshing)
                }
                .buttonStyle(.borderless)
                .disabled(viewModel.isLoading)
                .help("Refresh tools status")
                
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Image(systemName: "power")
                }
                .buttonStyle(.borderless)
                .help("Quit Dev Cache Cleaner")
            }
            .padding(12)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    // Select All Section
                    VStack(alignment: .leading, spacing: 4) {
                        Toggle(isOn: $viewModel.isAllSelected) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Select All")
                                    .font(.system(.body, weight: .medium))
                                Text("Toggle all available items")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .toggleStyle(.checkbox)
                        .accessibilityIdentifier("SelectAllButton")
                        #if compiler(>=5.9)
                        .onChange(of: viewModel.isAllSelected) { _, _ in
                            viewModel.toggleSelectAll()
                        }
                        #else
                        .onChange(of: viewModel.isAllSelected) { _ in
                            viewModel.toggleSelectAll()
                        }
                        #endif
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(NSColor.controlBackgroundColor))
                    
                    // Cache Options List
                    ForEach($viewModel.cacheOptions) { $option in
                        CacheOptionRow(option: $option)
                            .opacity(option.isAvailable ? 1 : 0.6)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                    }
                }
            }
            
            Divider()
            
            VStack(spacing: 12) {
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                if let date = viewModel.lastCleanedDate {
                    Text("Last cleaned: \(date.formatted(.dateTime))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Button(action: viewModel.cleanSelectedCaches) {
                    if viewModel.isLoading {
                        ProgressView()
                            .controlSize(.small)
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Clean Selected")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityIdentifier("CleanSelectedButton")
                .disabled(viewModel.isLoading || !viewModel.cacheOptions.contains { $0.isSelected })
                .padding(.horizontal)
            }
            .padding(.vertical, 16)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 320, height: 500)
        .task {
            await viewModel.checkAvailableCommands()
        }
    }
}

struct CacheOptionRow: View {
    @Binding var option: CacheOption
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Toggle("", isOn: $option.isSelected)
                .toggleStyle(.checkbox)
                .disabled(!option.isAvailable)
                .accessibilityIdentifier(option.title)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(option.title)
                    .font(.system(.body, weight: .medium))
                Text(option.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let error = option.error {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.top, 2)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if option.isAvailable {
                option.isSelected.toggle()
            }
        }
    }
}

#Preview {
    ContentView()
}
