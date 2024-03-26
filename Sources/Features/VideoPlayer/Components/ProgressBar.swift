//
//  ProgressBar.swift
//
//
//  Created by ErrorErrorError on 11/22/23.
//
//

import Architecture
import ComposableArchitecture
import Foundation
import PlayerClient
import SwiftUI
import ViewComponents

// MARK: - DragOffset

private struct DragOffset: Equatable {
  private let initialProgress: Double
  private var initialDrag: Double
  private var lastDrag: Double
  var offset: Double { lastDrag - initialDrag }

  var progress: Double { initialProgress + offset }

  init(progress: Double, initial: Double) {
    self.initialProgress = progress
    self.initialDrag = initial
    self.lastDrag = initial
  }

  mutating func callAsFunction(_ next: Double) {
    lastDrag = next
  }
}

// MARK: - ProgressBar

struct ProgressBar: View {
  let store: Store<PlayerClient.Status.Playback?, VideoPlayerFeature.Action>

  @ObservedObject private var viewState: ViewStore<PlayerClient.Status.Playback?, VideoPlayerFeature.Action.ViewAction>

  @SwiftUI.State private var dragged: DragOffset?

  @Dependency(\.dateComponentsFormatter) var formatter

  var progress: Double {
    if canUseControls {
      min(1.0, max(0, (dragged?.progress ?? viewState.state?.progress ?? .zero)))
    } else {
      .zero
    }
  }

  var canUseControls: Bool {
    if let totalDuration = viewState.state?.totalDuration {
      return !totalDuration.isNaN && !totalDuration.isInfinite && !totalDuration.isZero
    }
    return false
  }

  private static let defaultEmptyTime = "--:--"
  private static let defaultZeroTime = "00:00"

  init(store: Store<PlayerClient.Status.Playback?, VideoPlayerFeature.Action>) {
    self.store = store
    self.viewState = .init(store, observe: \.`self`)
  }

  var body: some View {
    HStack(alignment: .center, spacing: 12) {
      GeometryReader { proxy in
        ZStack(alignment: .leading) {
          ZStack(alignment: .leading) {
            Rectangle()
              .fill(.thinMaterial)
            Color.white
              .frame(
                width: proxy.size.width * progress,
                height: proxy.size.height,
                alignment: .leading
              )
          }
          .frame(
            width: proxy.size.width,
            height: dragged != nil ? 12 : 8
          )
          .clipShape(Capsule(style: .continuous))
        }
        .frame(
          width: proxy.size.width,
          height: proxy.size.height
        )
        .contentShape(Rectangle())
        .gesture(
          DragGesture(minimumDistance: 0)
            .onChanged { value in
              let percentageX = value.location.x / proxy.size.width

              dragged = dragged ?? .init(progress: progress, initial: percentageX)
              viewState.send(.didSeekTo(time: dragged?.progress ?? .zero))
              dragged?(percentageX)
            }
            .onEnded { value in
              if dragged?.offset == 0 {
                let percentageX = value.location.x / proxy.size.width

                viewState.send(.didSeekTo(time: percentageX))
              }
              dragged = nil
            }
        )
        .animation(.spring(response: 0.3), value: dragged != nil)
      }
      .frame(maxWidth: .infinity)
      .frame(height: 24)

      Text("\(progressDisplayTime) / \(durationDisplayTime)")
        .font(.caption.monospacedDigit())
        .foregroundColor(.white)
    }
    .disabled(!canUseControls)
    .preferredColorScheme(.dark)
  }

  private var progressDisplayTime: String {
    if canUseControls {
      formatter.playbackTimestamp(progress * (viewState.state?.totalDuration ?? .zero)) ?? Self.defaultZeroTime
    } else {
      Self.defaultEmptyTime
    }
  }

  private var durationDisplayTime: String {
    if canUseControls {
      formatter.playbackTimestamp(viewState.state?.totalDuration ?? .zero) ?? Self.defaultZeroTime
    } else {
      Self.defaultEmptyTime
    }
  }
}
