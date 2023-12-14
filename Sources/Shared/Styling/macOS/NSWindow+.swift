//
//  NSWindow+.swift
//  Mochi
//
//  Created by ErrorErrorError on 11/23/23.
//
//

@_spi(Presentation)
import ComposableArchitecture
import Foundation
import SwiftUI
import ViewComponents

#if canImport(AppKit)
@MainActor
private class WindowViewModel: NSObject, ObservableObject, NSWindowDelegate {
  private var window: NSWindow

  @Published var dismissCount = 0

  override init() {
    self.window = .init(
      contentRect: .zero,
      styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
      backing: .buffered,
      defer: false
    )
    window.titlebarAppearsTransparent = true
    window.isReleasedWhenClosed = false
    super.init()
    window.delegate = self
  }

  @MainActor
  func show(_ content: () -> some View) {
    if !window.isVisible || window.contentView == nil {
      window.setFrame(.init(x: 0, y: 0, width: 1_280, height: 720), display: true)
      window.contentView = NSHostingView(rootView: content())
      window.center()
      window.makeKeyAndOrderFront(nil)
    }
  }

  @MainActor
  func close() {
    window.contentView = nil
    window.close()
  }

  func windowWillClose(_: Notification) {
    dismissCount += 1
  }
}

@MainActor
private struct NativeWindowModifier<Inner: View>: ViewModifier {
  @Binding var isPresented: Bool
  @ViewBuilder let inner: () -> Inner
  @StateObject var windowController = WindowViewModel()

  func body(content: Content) -> some View {
    content
      .onAppear {
        if isPresented {
          windowController.show(inner)
        }
      }
      .onChange(of: isPresented) { newValue in
        if newValue {
          windowController.show(inner)
        } else {
          windowController.close()
        }
      }
      .onChange(of: windowController.dismissCount) { _ in
        isPresented = false
      }
  }
}

extension View {
  public func window(
    isPresented: Binding<Bool>,
    @ViewBuilder content: @escaping () -> some View
  ) -> some View {
    modifier(NativeWindowModifier(isPresented: isPresented, inner: content))
  }

  public func window(
    item: Binding<(some Any)?>,
    @ViewBuilder content: @escaping () -> some View
  ) -> some View {
    window(
      isPresented: item.isPresent(),
      content: content
    )
  }

  public func window<State: Equatable, Action>(
    store: Store<PresentationState<State>, PresentationAction<Action>>,
    @ViewBuilder content: @escaping (Store<State, Action>) -> some View
  ) -> some View {
    presentation(store: store) { `self`, $item, destination in
      self.window(
        item: $item
      ) {
        destination(content)
      }
    }
  }

  public func window<State: Equatable, Action, DestinationState, DestinationAction>(
    store: Store<PresentationState<State>, PresentationAction<Action>>,
    state toDestinationState: @escaping (State) -> DestinationState?,
    action fromDestinationAction: @escaping (DestinationAction) -> Action,
    @ViewBuilder content: @escaping (Store<DestinationState, DestinationAction>) -> some View
  ) -> some View {
    presentation(
      store: store,
      state: toDestinationState,
      action: fromDestinationAction
    ) { `self`, $item, destination in
      self.window(
        item: $item
      ) {
        destination(content)
      }
    }
  }
}
#endif
