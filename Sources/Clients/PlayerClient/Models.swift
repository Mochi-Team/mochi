//
//  Models.swift
//
//
//  Created by ErrorErrorError on 5/26/23.
//
//

import CasePaths
import Foundation

// MARK: - PlayerClient.Status

extension PlayerClient {
  // TODO: Add metadata in the status
  @CasePathable
  @dynamicMemberLookup
  public enum Status: Hashable, Sendable {
    case idle
    case loading
    case playback(Playback)
    case error

    public struct Playback: Hashable, Sendable {
      public let state: State
      public let duration: Double
      public let buffered: Double
      public let totalDuration: Double

      public let selections: [MediaSelectionGroup]

      public var reachedEnd: Bool {
        progress >= 1.0
      }

      public var progress: Double {
        totalDuration != .zero ? (duration / totalDuration) : .zero
      }

      public var bufferedProgress: Double {
        totalDuration != .zero ? (buffered / totalDuration) : .zero
      }

      // TODO: List out option types, quality, subtitles, ect.

      @CasePathable
      public enum State: Hashable, Sendable {
        case buffering
        case playing
        case paused
      }
    }
  }
}

extension PlayerClient {
  public struct VideoCompositionItem {
    let link: URL
    let headers: [String: String]
    let subtitles: [Subtitle]
    let metadata: SourceMetadata
    let format: Format
    let progress: Double?

    public enum Format {
      case hls
      case dash
    }

    public init(
      link: URL,
      headers: [String: String] = [:],
      subtitles: [Subtitle] = [],
      metadata: SourceMetadata,
      format: Format,
      progress: Double?
    ) {
      self.link = link
      self.headers = headers
      self.subtitles = subtitles
      self.metadata = metadata
      self.format = format
      self.progress = progress
    }

    public struct Subtitle {
      let name: String
      let `default`: Bool
      let autoselect: Bool
      let forced: Bool
      let link: URL

      public init(
        name: String,
        default: Bool = false,
        autoselect: Bool,
        forced: Bool = false,
        link: URL
      ) {
        self.name = name
        self.default = `default`
        self.autoselect = autoselect
        self.forced = forced
        self.link = link
      }
    }
  }

  public struct SourceMetadata {
    let title: String?
    let subtitle: String?
    let artworkImage: URL?
    let author: String?

    public init(
      title: String? = nil,
      subtitle: String? = nil,
      artworkImage: URL? = nil,
      author: String? = nil
    ) {
      self.title = title
      self.subtitle = subtitle
      self.artworkImage = artworkImage
      self.author = author
    }
  }
}
