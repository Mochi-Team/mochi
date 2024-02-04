//
//  PlayerItem+DASH.swift
//
//
//  Created by ErrorErrorError on 12/27/23.
//
//

import AVFoundation
import AVKit
import Foundation
import XMLCoder

// MARK: - MPD

// swiftlint:disable identifier_name
struct MPD: Codable {
  var Period: Period
  var mediaPresentationDuration: String

  func hlsAttributes(audio: Bool) -> [String] {
    // swiftformat:disable redundantSelf
    self.Period.AdaptationSet
      .flatMap { adaption in
        adaption.Representation
          .filter { $0.mimeType.contains(audio ? "audio" : "video") }
          .filter { Int($0.bandwidth) ?? .zero < 14_000_000 }
          .map(\.hlsAttribute)
      }
  }
}

// MARK: MPD.Period

extension MPD {
  struct Period: Codable {
    var AdaptationSet: [AdaptationSet] = []
  }
}

// MARK: - MPD.Period.AdaptationSet

extension MPD.Period {
  struct AdaptationSet: Codable {
    let id: String?
    let group: String
    let subsegmentAlignment: String?
    let subsegmentStartsWithSAP: String
    let Representation: [Representation]
  }
}

// MARK: - MPD.Period.AdaptationSet.Representation

extension MPD.Period.AdaptationSet {
  struct Representation: Codable {
    let BaseURL: String
    let id: String
    let mimeType: String
    let codecs: String
    let bandwidth: String
    let width: String?
    let height: String?
    let frameRate: String?
    let sar: String?
    var segmentBase: SegmentBase?

    var hlsAttribute: String {
      if mimeType.contains("audio") {
        return [
          "#EXT-X-MEDIA:TYPE=AUDIO",
          "GROUP-ID=\"audio\"",
          "NAME=\"merge\"",
          "DEFAULT=YES",
          "AUTOSELECT=YES",
          "URI=\"\(id).m3u8#\(BaseURL)\""
        ]
        .joined(separator: ",")
      } else {
        var resolutionString = ""
        if let width, let height {
          resolutionString = "RESOLUTION=\(width)x\(height)"
        }
        return [
          "#EXT-X-STREAM-INF:PROGRAM-ID=1",
          "BANDWIDTH=\(bandwidth)",
          resolutionString,
          "CODECS=\"\(codecs)\"",
          "AUDIO=\"audio\""
        ]
        .filter { !$0.isEmpty }
        .joined(separator: ",")
        .appending("\n\(id).m3u8#\(mimeType)#\(BaseURL)")
      }
    }
  }
}

// MARK: - MPD.Period.AdaptationSet.Representation.SegmentBase

// swiftlint:enable identifier_name

extension MPD.Period.AdaptationSet.Representation {
  struct SegmentBase: Codable {
    let indexRangeExact: String
    let indexRange: String
    let initialization: Initialization?

    struct Initialization: Codable {
      let range: String
    }
  }
}

extension String {
  var toMPDDuration: TimeInterval? {
    guard var timeValue = components(separatedBy: "PT").last,
          !timeValue.isEmpty else {
      return nil
    }

    var duration: TimeInterval = .zero
    if timeValue.contains("H"),
       let value = timeValue.components(separatedBy: "H").first,
       let integer = Int(value) {
      duration += TimeInterval(integer * 3_600)
      timeValue = timeValue.components(separatedBy: "H").last ?? ""
    }

    if timeValue.contains("M"),
       let value = timeValue.components(separatedBy: "M").first,
       let integer = Int(value) {
      duration += TimeInterval(integer * 60)
      timeValue = timeValue.components(separatedBy: "M").last ?? ""
    }

    if timeValue.contains("S"),
       let value = timeValue.components(separatedBy: "S").first,
       let time = TimeInterval(value) {
      duration += time
    }

    return duration
  }
}

extension PlayerItem {
  static let dashCustomPlaylistScheme = "mochi-mpd"

  func handleDASHRequest(_ loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
    guard let url = loadingRequest.request.url else {
      return false
    }
    if url.pathExtension == "ts" {
      loadingRequest.redirect = URLRequest(url: url.recoveryScheme)
      loadingRequest.response = HTTPURLResponse(
        url: url.recoveryScheme,
        statusCode: 302,
        httpVersion: nil,
        headerFields: nil
      )
      loadingRequest.finishLoading()
      return true
    } else if url.absoluteString.localizedCaseInsensitiveContains("m3u8") {
      makeMediaM3U8(url) { result in
        switch result {
        case let .success(data):
          loadingRequest.dataRequest?.respond(with: data)
          loadingRequest.finishLoading()
        case let .failure(error):
          loadingRequest.finishLoading(with: error)
        }
      }
      return true
    } else if url.absoluteString.contains(Self.dashCustomPlaylistScheme) {
      URLSession.shared.dataTask(with: url.recoveryScheme) { [weak self] data, response, error in
        if let error {
          loadingRequest.finishLoading(with: error)
          return
        }

        guard (response as? HTTPURLResponse)?.statusCode != nil, let data else {
          loadingRequest.finishLoading(with: ResourceLoaderError.emptyData)
          return
        }

        self?.parseXML(data) { result in
          switch result {
          case let .success(data):
            loadingRequest.dataRequest?.respond(with: data)
            loadingRequest.finishLoading()
          case let .failure(error):
            loadingRequest.finishLoading(with: error)
          }
        }
      }
      .resume()
      return true
    }
    return false
  }

  private func parseXML(
    _ data: Data,
    _ completion: @escaping (Result<Data, Error>) -> Void
  ) {
    do {
      let mpd = try XMLDecoder()
        .decode(MPD.self, from: data)
      makeMasterM3U8(mpd, completion)
      self.payload.mpdData = mpd
    } catch {
      completion(.failure(error))
      self.payload.mpdData = nil
    }
  }

  private func makeMediaM3U8(
    _ url: URL,
    _ completion: @escaping (Result<Data, Error>) -> Void
  ) {
    guard let mpd = self.payload.mpdData else {
      completion(.failure(ResourceLoaderError.failedToCreateM3U8))
      return
    }

    let id = url.lastPathComponent.components(separatedBy: ".").first

    guard let representation = mpd.Period.AdaptationSet
      .flatMap(\.Representation)
      .first(where: { $0.id == id || (id == nil) }) else {
      completion(.failure(ResourceLoaderError.failedToCreateM3U8))
      return
    }

    var lines = ["#EXTM3U"]
    let mediaDuration = mpd.mediaPresentationDuration.toMPDDuration ?? 0

    lines.append(contentsOf: [
      "#EXT-X-TARGETDURATION:\(mediaDuration)",
      "#EXT-X-VERSION:6",
      "#EXT-X-MEDIA-SEQUENCE:0",
      "#EXT-X-PLAYLIST-TYPE:VOD"
    ])

    lines
      .append(
        "#EXTINF:\(String(format: "%.3f", mediaDuration)),\(representation.mimeType.contains("video") ? "video" : "audio"),"
      )
    lines.append(representation.BaseURL)
    lines.append("#EXT-X-ENDLIST")

    if let data = lines.joined(separator: "\n").data(using: .utf8) {
      print("\n" + String(decoding: data, as: UTF8.self) + "\n")
      completion(.success(data))
    } else {
      completion(.failure(ResourceLoaderError.failedToCreateM3U8))
    }
  }

  private func makeMasterM3U8(
    _ mpd: MPD,
    _ completion: @escaping (Result<Data, Error>) -> Void
  ) {
    var lines = ["#EXTM3U"]
    lines.append(contentsOf: mpd.hlsAttributes(audio: true))
    lines.append(contentsOf: mpd.hlsAttributes(audio: false))

    if let data = lines
      .joined(separator: "\n")
      .data(using: .utf8) {
      completion(.success(data))
    } else {
      completion(.failure(ResourceLoaderError.failedToCreateM3U8))
    }
  }
}
