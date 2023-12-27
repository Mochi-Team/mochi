//
//  FillAspectImage.swift
//
//
//  Created by ErrorErrorError on 10/25/22.
//
//

import NukeUI
import SwiftUI

// MARK: - FillAspectImage

public struct FillAspectImage: View {
  let url: URL?
  let transaction: Transaction
  var averageColor: ((Color?) -> Void)?

  public init(
    url: URL?,
    transaction: Transaction = .init(animation: .easeInOut(duration: 0.4)),
    averageColor: ((Color?) -> Void)? = nil
  ) {
    self.url = url
    self.averageColor = averageColor
    self.transaction = transaction
  }

  public var body: some View {
    GeometryReader { proxy in
      LazyImage(
        url: url,
        transaction: transaction
      ) { state in
        if let image = state.image {
          image
            .resizable()
            .onAppear { averageColor?(state.imageContainer?.image.averageColor) }
        } else {
          Color.gray.opacity(0.2)
        }
      }
      .onCompletion { averageColor?(try? $0.get().image.averageColor) }
      .scaledToFill()
      .frame(
        width: proxy.size.width,
        height: proxy.size.height,
        alignment: .center
      )
      .contentShape(Rectangle())
      .clipped()
    }
  }

  public func onAverageColor(_ callback: @escaping (Color?) -> Void) -> Self {
    var copy = self
    copy.averageColor = callback
    return copy
  }
}

#if canImport(AppKit)
typealias PlatformImage = NSImage

extension Image {
  init(_ image: PlatformImage) {
    self.init(nsImage: image)
  }
}
#else
typealias PlatformImage = UIImage
extension Image {
  init(_ image: PlatformImage) {
    self.init(uiImage: image)
  }
}

#endif

extension PlatformImage {
  var averageColor: Color? {
    #if canImport(AppKit)
    var rect = NSRect(origin: .zero, size: size)
    guard let cgImage = cgImage(forProposedRect: &rect, context: .current, hints: nil) else {
      return nil
    }
    let inputImage = CIImage(cgImage: cgImage)
    #else
    guard let inputImage = CIImage(image: self) else {
      return nil
    }
    #endif

    let extentVector = CIVector(
      x: inputImage.extent.origin.x,
      y: inputImage.extent.origin.y,
      z: inputImage.extent.size.width,
      w: inputImage.extent.size.height
    )

    guard let filter = CIFilter(
      name: "CIAreaAverage",
      parameters: [
        kCIInputImageKey: inputImage,
        kCIInputExtentKey: extentVector
      ]
    ) else {
      return nil
    }

    guard let outputImage = filter.outputImage else {
      return nil
    }

    var bitmap = [UInt8](repeating: 0, count: 4)
    let context = CIContext(options: [.workingColorSpace: kCFNull as Any])
    context.render(
      outputImage,
      toBitmap: &bitmap,
      rowBytes: 4,
      bounds: .init(x: 0, y: 0, width: 1, height: 1),
      format: .RGBA8,
      colorSpace: nil
    )

    return .init(
      .sRGB,
      red: CGFloat(bitmap[0]) / 255,
      green: CGFloat(bitmap[1]) / 255,
      blue: CGFloat(bitmap[2]) / 255,
      opacity: CGFloat(bitmap[3]) / 255
    )
  }
}
