//
//  NavStack.swift
//
//
//  Created by ErrorErrorError on 5/20/23.
//
//

@_spi(Presentation)
import ComposableArchitecture
import Foundation
import OrderedCollections
import SwiftUI
import ViewComponents

extension Animation {
  public static var navStackTransion: Animation { .timingCurve(0.31, 0.47, 0.31, 1, duration: 0.4) }
}

// MARK: - NavStack

public struct NavStack<State: Equatable, Action, Root: View, Destination: View>: View {
  private let store: Store<StackState<State>, StackAction<State, Action>>
  private let root: () -> Root
  private let destination: (Store<State, Action>) -> Destination

  public init(
    _ store: Store<StackState<State>, StackAction<State, Action>>,
    @ViewBuilder root: @escaping () -> Root,
    @ViewBuilder destination: @escaping (Store<State, Action>) -> Destination
  ) {
    self.store = store
    self.root = root
    self.destination = destination
  }

  public var body: some View {
    if #available(iOS 16.0, macOS 13.0, *) {
      NavigationStackStore(store) {
        root()
        #if os(iOS)
          .themeable()
        #endif
      } destination: { store in
        destination(store)
        #if os(iOS)
          .themeable()
        #endif
      }
    } else {
      #if os(iOS)
      NavigationView {
        ZStack {
          root()
            .themeable()

          Group {
            WithViewStore(store, observe: \.ids, removeDuplicates: areOrderedSetsDuplicates) { viewStore in
              ForEach(viewStore.state, id: \.self) { id in
                NavigationLink(
                  isActive: .init(
                    get: { viewStore.state.contains(id) },
                    set: { isActive, transaction in
                      if !isActive, viewStore.state.contains(id) {
                        viewStore.send(.popFrom(id: id), transaction: transaction)
                      }
                    }
                  )
                ) {
                  IfLetStore(
                    store.scope(
                      state: returningLastNonNilValue { $0[id: id] },
                      action: { .element(id: id, action: $0 as Action) }
                    )
                  ) { store in
                    destination(store)
                      .themeable()
                  }
                } label: {
                  EmptyView()
                }
                .isDetailLink(false)
                .hidden()
              }
            }
          }
          .hidden()
        }
      }
      .navigationViewStyle(.stack)
      #elseif os(macOS)
      // There is no support for stack-based views under macOS 13, so we create our own stack based
      // view, and to avoid toolbars from overlapping, we need to only allow one view at a time
      WithViewStore(store, observe: \.ids, removeDuplicates: areOrderedSetsDuplicates) { viewStore in
        if let id = viewStore.last {
          IfLetStore(
            store.scope(
              state: returningLastNonNilValue { $0[id: id] },
              action: { .element(id: id, action: $0 as Action) }
            ),
            then: destination
          )
          .toolbar {
            ToolbarItem(placement: .navigation) {
              Button {
                viewStore.send(.popFrom(id: id))
              } label: {
                Image(systemName: "chevron.left")
              }
              .keyboardShortcut("[", modifiers: .command)
            }
          }
        } else {
          root()
        }
      }
      #endif
    }
  }
}

extension NavStack {
  public init(
    _ store: Store<StackState<State>, StackAction<State, Action>>,
    @ViewBuilder destination: @escaping (Store<State, Action>) -> Destination
  ) where Root == EmptyView {
    self.init(
      store,
      root: EmptyView.init,
      destination: destination
    )
  }
}

// From: https://forums.swift.org/t/handling-the-new-forming-unsaferawpointer-warning/65523/5
@inlinable
func areOrderedSetsDuplicates<T>(_ lhs: OrderedSet<T>, _ rhs: OrderedSet<T>) -> Bool {
  withUnsafePointer(to: lhs) { lhs in
    withUnsafePointer(to: rhs) { rhs in
      memcmp(lhs, rhs, MemoryLayout<OrderedSet<T>>.size) == 0
    }
  } || rhs == lhs
}

// Source: https://github.com/pointfreeco/swift-composable-architecture/blob/a384c00a2c9f2e1beadfb751044a812a77d6d2ec/Sources/ComposableArchitecture/Internal/ReturningLastNonNilValue.swift
private func returningLastNonNilValue<A, B>(_ f: @escaping (A) -> B?) -> (A) -> B? {
  var lastWrapped: B?
  return { wrapped in
    lastWrapped = f(wrapped) ?? lastWrapped
    return lastWrapped
  }
}

extension View {
  @MainActor
  public func stackDestination<State, Action>(
    store: Store<PresentationState<State>, PresentationAction<Action>>,
    @ViewBuilder destination: @escaping (_ store: Store<State, Action>) -> some View
  ) -> some View {
    presentation(store: store) { `self`, $item, destinationContent in
      if #available(iOS 16.0, macOS 13.0, *) {
        self.navigationDestination(isPresented: $item.isPresent()) {
          destinationContent(destination)
            .themeable()
        }
      } else if #unavailable(iOS 16.0) {
        ZStack {
          NavigationLink(isActive: $item.isPresent()) {
            destinationContent(destination)
              .themeable()
          } label: {
            EmptyView()
          }
          #if os(iOS)
          .isDetailLink(false)
          #endif
          .hidden()

          self
        }
      } else {
        // macOS only
        ZStack {
          if $item.isPresent().wrappedValue {
            destinationContent(destination)
              .themeable()
          } else {
            self
          }
        }
        .animation(.interactiveSpring(duration: 0.3), value: $item.isPresent().wrappedValue)
      }
    }
  }
}

// MARK: - UINavigationController + UIGestureRecognizerDelegate

#if os(iOS)
// FIXME: This causes crashes on iOS 17?
/// Hacky way to allow swipe back navigation when status bar is hidden
extension UINavigationController: UIGestureRecognizerDelegate {
  override open func viewDidLoad() {
    super.viewDidLoad()
    interactivePopGestureRecognizer?.delegate = self
  }

  public func gestureRecognizerShouldBegin(_: UIGestureRecognizer) -> Bool {
    viewControllers.count > 1
  }
}
#endif
