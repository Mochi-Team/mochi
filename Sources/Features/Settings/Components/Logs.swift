//
//  Logs.swift
//
//
//  Created by ErrorErrorError on 11/29/23.
//
//

import Architecture
import ComposableArchitecture
import Foundation
import LoggerClient
import Logging
import ModuleClient
import ModuleLists
import SharedModels
import Styling
import SwiftUI
import ViewComponents

// MARK: - Logs

// @Reducer
public struct Logs: Reducer {
  enum Cancellable: Hashable {
    case observeLogs
  }

  public struct State: Equatable, Sendable {
    public var selected: Selection

    @PresentationState public var moduleLists: ModuleListsFeature.State?

    fileprivate var initialized = false

    init(
      selected _: Selection = .system(),
      moduleLists: ModuleListsFeature.State? = nil
    ) {
      self.moduleLists = moduleLists

      @Dependency(\.loggerClient) var loggerClient

      self.selected = .system(loggerClient.get())
    }

    @CasePathable
    @dynamicMemberLookup
    public enum Selection: Equatable, Sendable {
      case system([SystemLogEvent] = [])
      case module(id: RepoModuleID, module: Module.Manifest, events: [ModuleLoggerEvent] = [])

      var logsEmpty: Bool {
        switch self {
        case let .system(logs):
          logs.isEmpty
        case let .module(_, _, events):
          events.isEmpty
        }
      }
    }
  }

  @CasePathable
  @dynamicMemberLookup
  public enum Action: Equatable, Sendable {
    case onTask
    case didTapBackButton
    case didTapViewerList
    case updateSystemEvents([SystemLogEvent])
    case updateModuleEvents(id: RepoModuleID, [ModuleLoggerEvent])
    case moduleLists(PresentationAction<ModuleListsFeature.Action>)
  }

  @Dependency(\.moduleClient) var moduleClient
  @Dependency(\.loggerClient) var loggerClient
  @Dependency(\.dismiss) var dismiss

  public init() {}

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onTask:
        if !state.initialized {
          state.initialized = true
          return state.observeSystemLogs()
        }

      case let .updateSystemEvents(events):
        guard state.selected.is(\.system) else {
          break
        }
        state.selected = .system(events)

      case let .updateModuleEvents(id, events):
        guard let module = state.selected.module, module.id == id else {
          break
        }
        state.selected = .module(id: module.id, module: module.module, events: events)

      case .didTapViewerList:
        state.moduleLists = .init()

      case .didTapBackButton:
        return .run { await dismiss() }

      case let .moduleLists(.presented(.delegate(.selectedModule(selected)))):
        defer { state.moduleLists = nil }
        if let selected {
          state.selected = .module(id: selected.id, module: selected.module, events: [])
          return .run { send in
            try await withTaskCancellation(id: Cancellable.observeLogs, cancelInFlight: true) {
              for await events in try await moduleClient.withModule(id: selected.id, work: \.logs) {
                await send(.updateModuleEvents(id: selected.id, events))
              }
            }
          }
        } else {
          return state.observeSystemLogs()
        }

      case .moduleLists:
        break
      }
      return .none
    }
    .ifLet(\.$moduleLists, action: \.moduleLists) {
      ModuleListsFeature()
    }
  }
}

extension Logs.State {
  fileprivate mutating func observeSystemLogs() -> Effect<Logs.Action> {
    @Dependency(\.loggerClient) var loggerClient

    selected = .system(loggerClient.get())

    return .run { send in
      await withTaskCancellation(id: Logs.Cancellable.observeLogs, cancelInFlight: true) {
        for await events in loggerClient.observe() {
          await send(.updateSystemEvents(events))
        }
      }
    }
  }
}

// MARK: - Logs.View

extension Logs {
  @MainActor
  public struct View: SwiftUI.View {
    public let store: StoreOf<Logs>

    @Dependency(\.dateFormatter) var dateFormatter

    @MainActor
    public init(store: StoreOf<Logs>) {
      self.store = store
    }

    @MainActor public var body: some SwiftUI.View {
      ScrollView(.vertical) {
        LazyVStack(spacing: 12) {
          WithViewStore(store, observe: \.selected) { viewStore in
            if viewStore.logsEmpty {
              Text("No logs available.")
            } else {
              _VariadicView.Tree(Layout()) {
                switch viewStore.state {
                case let .system(events):
                  ForEach(events, id: \.timestamp) { event in
                    eventRow(
                      level: event.level.rawValue,
                      levelColor: event.level.color,
                      timeStamp: event.timestamp,
                      message: event.message
                    )
                  }
                case let .module(_, _, events):
                  ForEach(events, id: \.timestamp) { event in
                    eventRow(
                      level: event.level.rawValue,
                      levelColor: event.level.color,
                      timeStamp: event.timestamp,
                      message: event.body
                    )
                  }
                }
              }
            }
          }
        }
        .padding()
      }
      .moduleListsSheet(
        store.scope(
          state: \.$moduleLists,
          action: \.moduleLists
        )
      )
      #if os(iOS)
      .navigationTitle("")
      .navigationBarTitleDisplayMode(.inline)
      .navigationBarBackButtonHidden()
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button {
            store.send(.didTapBackButton)
          } label: {
            Image(systemName: "chevron.left")
          }
          .buttonStyle(.materialToolbarItem)
        }

        // TODO: Export logs
        // ToolbarItem(placement: .topBarTrailing) {
        //   Button {
        //   } label: {
        //     Image(systemName: "square.and.arrow.up")
        //   }
        //   .buttonStyle(.materialToolbarItem)
        // }
      }
      #else
      .navigationTitle("Logs")
      .toolbar {
        // TODO: Export logs
        // ToolbarItem(placement: .automatic) {
        //   Button {
        //   } label: {
        //     Image(systemName: "square.and.arrow.up")
        //   }
        // }
      }
      #endif
      .toolbar {
        ToolbarItem(placement: .navigation) {
          Button {
            store.send(.didTapViewerList)
          } label: {
            HStack {
              WithViewStore(store, observe: \.selected) { viewStore in
                switch viewStore.state {
                case .system:
                  Text("System")
                case let .module(_, module, _):
                  Text(module.name)
                }
              }

              Image(systemName: "chevron.down")
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            #if os(iOS)
            .background(.gray.opacity(0.12), in: Capsule())
            #elseif os(macOS)
            .background(.gray.opacity(0.12), in: RoundedRectangle(cornerRadius: 4, style: .continuous))
            #endif
          }
          .buttonStyle(.plain)
          .font(.footnote.weight(.medium))
        }
      }
      .initialTask {
        _ = await MainActor.run {
          store.send(.onTask)
        }
      }
    }

    @MainActor
    private func eventRow(
      level: String,
      levelColor: Color,
      timeStamp: Date,
      message: String
    ) -> some SwiftUI.View {
      VStack(alignment: .leading) {
        HStack {
          Text(level.capitalized)
            .foregroundColor(levelColor)
            .font(.caption.weight(.semibold))

          Spacer()

          Text(
            dateFormatter.withFormatter { formatter in
              formatter.dateFormat = "HH:mm:ss.SSS"
              return formatter.string(from: timeStamp)
            }
          )
          .font(.caption)
          .foregroundColor(.gray)
        }

        Text(message)
          .font(.footnote)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
      .frame(maxWidth: .infinity)
    }

    /// Source: https://movingparts.io/variadic-views-in-swiftui
    struct Layout: _VariadicView_UnaryViewRoot {
      @ViewBuilder
      func body(children: _VariadicView.Children) -> some SwiftUI.View {
        let last = children.last?.id
        VStack(spacing: 12) {
          ForEach(children) { child in
            child
            if child.id != last {
              Capsule()
                .fill(Color.gray.opacity(0.2))
                .frame(maxWidth: .infinity)
                .frame(height: 1)
            }
          }
        }
      }
    }
  }
}

extension Logging.Logger.Level {
  fileprivate var color: Color {
    switch self {
    case .trace:
      .white
    case .debug, .info:
      .blue
    case .notice, .warning:
      .orange
    case .error, .critical:
      .red
    }
  }
}

extension ModuleLoggerLevel {
  fileprivate var color: Color {
    switch self {
    case .log:
      .gray
    case .info, .debug:
      .blue
    case .warn:
      .orange
    case .error:
      .red
    }
  }
}

#Preview {
  Logs.View(
    store: .init(
      initialState: .init(),
      reducer: {
        EmptyReducer()
      },
      withDependencies: { deps in
        deps.loggerClient.get = {
          SystemLogEvent.stubs(count: 20)
        }
      }
    )
  )
  .themeable()
}
