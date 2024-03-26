//
//  PlayerItem.swift
//
//
//  Created by ErrorErrorError on 6/18/23.
//
//

import AVFoundation
import AVKit
import Foundation

// MARK: - MetaPayload

@dynamicMemberLookup
struct MetaPayload {
  let modifiedLink: URL
  let payload: PlayerClient.VideoCompositionItem
  var mpdData: MPD?

  subscript<Value>(dynamicMember keyPath: KeyPath<PlayerClient.VideoCompositionItem, Value>) -> Value {
    payload[keyPath: keyPath]
  }
}

// MARK: - PlayerItem

final class PlayerItem: AVPlayerItem {
  var payload: MetaPayload

  private let resourceQueue: DispatchQueue

  enum ResourceLoaderError: Swift.Error {
    case responseError
    case emptyData
    case failedToCreateM3U8
  }

  init(_ payload: PlayerClient.VideoCompositionItem) {
    self.resourceQueue = DispatchQueue(label: "playeritem-\(payload.link.absoluteString)", qos: .utility)

    let headers = payload.headers
    if payload.subtitles.isEmpty {
      self.payload = .init(modifiedLink: payload.link, payload: payload)
    } else {
      self.payload = .init(modifiedLink: payload.link.change(scheme: Self.hlsCommonScheme), payload: payload)
    }

    let asset = AVURLAsset(
      url: self.payload.modifiedLink,
      // TODO: Validate if this is allowed or considered a private api
      options: ["AVURLAssetHTTPHeaderFieldsKey": headers]
    )

    super.init(
      asset: asset,
      automaticallyLoadedAssetKeys: [
        "duration",
        "availableMediaCharacteristicsWithMediaSelectionOptions"
      ]
    )

    asset.resourceLoader.setDelegate(self, queue: resourceQueue)
  }
}

// MARK: AVAssetResourceLoaderDelegate

extension PlayerItem: AVAssetResourceLoaderDelegate {
  func resourceLoader(
    _: AVAssetResourceLoader,
    shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest
  ) -> Bool {
    if payload.format == .dash {
      handleDASHRequest(loadingRequest)
    } else {
      handleHLSRequest(loadingRequest: loadingRequest)
    }
  }
}

extension URL {
  func change(scheme: String) -> URL {
    var component = URLComponents(url: self, resolvingAgainstBaseURL: false)
    component?.scheme = scheme
    return component?.url ?? self
  }

  var recoveryScheme: URL {
    var component = URLComponents(url: self, resolvingAgainstBaseURL: false)
    let isDataScheme = component?.path.starts(with: "application/x-mpegURL") ?? false
    component?.scheme = isDataScheme ? "data" : "https"
    return component?.url ?? self
  }
}
