//
//  EntryItem.swift
//
//
//  Created by ErrorErrorError on 1/2/24.
//
//

import CoreDB
import Foundation
import Tagged

// MARK: - Entry.Item

extension Entry {
  @Entity
  public struct Item {
    @Attribute public var id = Tagged<Self, String>("")
    @Attribute public var number = Double.zero
    @Attribute public var title = String?.none
    @Attribute public var progress = Double.zero
    // @Attribute public var downloaded = DownloadedItem?.none
  }
}

extension Entry.Item {
  public static var entityName: String { "EntryItem" }
}

// MARK: - Entry.Item.DownloadedItem

extension Entry.Item {
  public enum DownloadedItem {}
}
