//
//  ScrollViewTracker.swift
//
//
//  Created by ErrorErrorError on 12/12/23.
//
//  Source: https://github.com/danielsaidi/ScrollKit/blob/main/Sources/ScrollKit/ScrollViewWithOffsetTracking.swift

import ComposableArchitecture
import Foundation
import SwiftUI

// MARK: - ScrollOffsetPreferenceKey

private struct ScrollOffsetPreferenceKey: SwiftUI.PreferenceKey {
  static var defaultValue: CGPoint = .zero
  static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {}
}

private let scrollOffsetNamespace = "scrollView"

@CasePathable
@dynamicMemberLookup
private enum RefreshableStatus: Equatable {
  case pending
  case refreshing(Task<Void, Never>)
  case finished
}

// MARK: - ScrollViewTracker

@MainActor
public struct ScrollViewTracker<Content: View>: View {
  public typealias ScrollAction = (_ offset: CGPoint) -> Void

  private let axis: Axis.Set
  private let showsIndicators: Bool
  private let content: () -> Content
  private let action: ScrollAction

  @Environment(\.refresh) private var refresh
  private let amountToPullBeforeRefreshing: CGFloat = 120
  @State private var refreshableState: RefreshableStatus?

  @MainActor
  public init(
    _ axis: Axis.Set = [.horizontal, .vertical],
    showsIndicators: Bool = true,
    onScroll: ScrollAction? = nil,
    @ViewBuilder content: @escaping () -> Content
  ) {
    self.axis = axis
    self.showsIndicators = showsIndicators
    self.action = onScroll ?? { _ in }
    self.content = content
  }

  @MainActor
  public var body: some View {
    ScrollView(axis, showsIndicators: showsIndicators) {
      ZStack(alignment: .top) {
        GeometryReader { geo in
          Color.clear
            .preference(
              key: ScrollOffsetPreferenceKey.self,
              value: geo.frame(in: .named(scrollOffsetNamespace)).origin
            )
        }
        .frame(height: 0)

        content()
          .safeAreaInset(edge: .top) {
            if let refreshableState, refreshableState != .finished {
              ProgressView()
                .padding(.vertical, refreshableState.is(\.refreshing) ? 24 : 0)
            }
          }
      }
    }
    .coordinateSpace(name: scrollOffsetNamespace)
    .onPreferenceChange(ScrollOffsetPreferenceKey.self, perform: action)
    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
      if #unavailable(iOS 16), refresh != nil {
        if value.y > 0 && refreshableState == nil {
          refreshableState = .pending
        } else if value.y > amountToPullBeforeRefreshing && refreshableState == .pending {
          #if canImport(UIKit)
          UIImpactFeedbackGenerator(style: .medium).impactOccurred()
          #endif
          refreshableState = .refreshing(
            Task {
              await refresh?()
              await MainActor.run {
                refreshableState = .finished
              }
            }
          )
        } else if value.y <= 0 && !(refreshableState?.is(\.refreshing) ?? false) {
          refreshableState = nil
        }
      }
    }
    .animation(.easeInOut, value: refreshableState)
  }
}
