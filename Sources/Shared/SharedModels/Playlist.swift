//
//  Playlist.swift
//
//
//  Created by ErrorErrorError on 5/29/23.
//
//

import Foundation
import JSValueCoder
import OrderedCollections
import Tagged

// MARK: - Playlist

public struct Playlist: Sendable, Identifiable, Hashable, Codable {
  public let id: Tagged<Self, String>
  public let title: String?
  public let posterImage: URL?
  public let bannerImage: URL?
  public let url: URL
  public let status: Status
  public let type: PlaylistType

  public init(
    id: ID,
    title: String?,
    posterImage: URL?,
    bannerImage: URL?,
    url: URL,
    status: Status,
    type: PlaylistType
  ) {
    self.id = id
    self.title = title
    self.posterImage = posterImage
    self.bannerImage = bannerImage
    self.url = url
    self.status = status
    self.type = type
  }

  public enum PlaylistType: Int, Sendable, Hashable, Codable {
    case video
    case image
    case text
  }

  public enum Status: Int, Sendable, Hashable, Codable {
    case unknown
    case upcoming
    case ongoing
    case completed
    case paused
    case cancelled
  }
}

// MARK: Playlist.Details

extension Playlist {
  public struct Details: Sendable, Equatable, Codable {
    public let synopsis: String?
    public let altTitles: [String]
    public let altPosters: [URL]
    public let altBanners: [URL]
    public let genres: [String]
    public let yearReleased: Int?
    public let ratings: Int?
    public let previews: [Preview]

    public init(
      synopsis: String? = nil,
      altTitles: [String] = [],
      altPosters: [URL] = [],
      altBanners: [URL] = [],
      genres: [String] = [],
      yearReleased: Int? = nil,
      ratings: Int? = nil,
      previews: [Preview] = []
    ) {
      self.synopsis = synopsis
      self.altTitles = altTitles
      self.altPosters = altPosters
      self.altBanners = altBanners
      self.genres = genres
      self.yearReleased = yearReleased
      self.ratings = ratings
      self.previews = previews
    }

    public struct Preview: Sendable, Equatable, Codable {
      public let title: String?
      public let description: String?
      public let thumbnail: URL?
      public let link: URL
      public let type: PreviewType

      public enum PreviewType: Int, Sendable, Equatable, Codable {
        case video
        case image
      }

      public init(
        title: String? = nil,
        description: String? = nil,
        thumbnail: URL? = nil,
        link: URL,
        type: PreviewType
      ) {
        self.title = title
        self.description = description
        self.thumbnail = thumbnail
        self.link = link
        self.type = type
      }
    }
  }
}

// MARK: Playlist.Item

extension Playlist {
  public struct Item: Sendable, Equatable, Identifiable, Codable {
    public let id: Tagged<Self, String>
    public let title: String?
    public let description: String?
    public let thumbnail: URL?
    public let number: Double
    public let timestamp: String?
    public let tags: [String]

    public init(
      id: Self.ID,
      title: String? = nil,
      description: String? = nil,
      thumbnail: URL? = nil,
      number: Float64,
      timestamp: String? = nil,
      tags: [String] = []
    ) {
      self.id = id
      self.title = title
      self.description = description
      self.thumbnail = thumbnail
      self.number = number
      self.timestamp = timestamp
      self.tags = tags
    }
  }
}

extension Playlist {
  // TODO: Write a codable that handles all the boilerplate when converting associated enum to JSValue
  public enum ItemsRequestOptions: Sendable, Equatable, Encodable {
    case group(Playlist.Group.ID)
    case variant(Playlist.Group.ID, Playlist.Group.Variant.ID)
    case page(Playlist.Group.ID, Playlist.Group.Variant.ID, PagingID)

    var type: String {
      switch self {
      case .group:
        "group"
      case .variant:
        "variant"
      case .page:
        "page"
      }
    }

    enum GroupCodingKeys: JSValueEnumCodingKey {
      case type
      case groupId
    }

    enum VariantCodingKeys: JSValueEnumCodingKey {
      case type
      case groupId
      case variantId
    }

    enum PageCodingKeys: JSValueEnumCodingKey {
      case type
      case groupId
      case variantId
      case pageId
    }

    public func encode(to encoder: Encoder) throws {
      switch self {
      case let .group(groupId):
        var container = encoder.container(keyedBy: GroupCodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(groupId, forKey: .groupId)
      case let .variant(groupId, variantId):
        var container = encoder.container(keyedBy: VariantCodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(groupId, forKey: .groupId)
        try container.encode(variantId, forKey: .variantId)
      case let .page(groupId, variantId, pageId):
        var container = encoder.container(keyedBy: PageCodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(groupId, forKey: .groupId)
        try container.encode(variantId, forKey: .variantId)
        try container.encode(pageId, forKey: .pageId)
      }
    }
  }

  public typealias ItemsResponse = [Playlist.Group]

  public struct Group: Sendable, Equatable, Identifiable, Decodable {
    public let id: Tagged<Self, String>
    public let number: Double
    public let altTitle: String?
    public let variants: Loadable<Variants>
    public let `default`: Bool?

    public typealias Variants = [Variant]

    public init(
      id: Self.ID,
      number: Double,
      altTitle: String? = nil,
      variants: Loadable<Variants> = .pending,
      default: Bool? = nil
    ) {
      self.id = id
      self.number = number
      self.altTitle = altTitle
      self.variants = variants
      self.default = `default`
    }

    public struct Variant: Sendable, Equatable, Identifiable, Decodable {
      public let id: Tagged<Self, String>
      public let title: String
      public let pagings: Loadable<Pagings>

      public typealias Pagings = [LoadablePaging<Playlist.Item>]

      public init(
        id: Self.ID,
        title: String,
        pagings: Loadable<Pagings> = .pending
      ) {
        self.id = id
        self.title = title
        self.pagings = pagings
      }
    }
  }
}

// MARK: - PlaylistInfo

@dynamicMemberLookup
public struct PlaylistInfo: Equatable, Sendable, Codable {
  let playlist: Playlist
  let details: Playlist.Details

  public init(
    playlist: Playlist,
    details: Playlist.Details = .init()
  ) {
    self.playlist = playlist
    self.details = details
  }

  public subscript<Value>(dynamicMember dynamicMember: KeyPath<Playlist, Value>) -> Value {
    playlist[keyPath: dynamicMember]
  }

  public subscript<Value>(dynamicMember dynamicMember: KeyPath<Playlist.Details, Value>) -> Value {
    details[keyPath: dynamicMember]
  }
}

extension Playlist {
  public static let empty: Self = .init(
    id: "",
    title: "",
    posterImage: nil,
    bannerImage: nil,
    url: .init(string: "/").unsafelyUnwrapped,
    status: .unknown,
    type: .video
  )

  public static func placeholder(_ id: Int) -> Self {
    .init(
      id: "\(id)",
      title: "Placeholder \(id)",
      posterImage: nil,
      bannerImage: nil,
      url: .init(string: "/").unsafelyUnwrapped,
      status: .unknown,
      type: .video
    )
  }
}

// MARK: - OrderedDictionary + Sendable

extension OrderedDictionary: @unchecked Sendable where Key: Sendable, Value: Sendable {}
