//
//  Entry.swift
//
//
//  Created by ErrorErrorError on 1/1/24.
//
//

import CoreDB
import Foundation
import Tagged

@Entity
public struct Entry {
  @Attribute public var repoId = Repo.ID(.init(string: "/").unsafelyUnwrapped)
  @Attribute public var moduleId = Module.ID("")
  @Attribute public var entryId = Tagged<Self, String>("")
  @Attribute public var title = String?.none
  @Attribute public var posterImage = URL?.none
  @Attribute public var bannerImage = URL?.none
  @Attribute public var url = URL(string: "/").unsafelyUnwrapped
  @Relation public var items = [Item]()
}
