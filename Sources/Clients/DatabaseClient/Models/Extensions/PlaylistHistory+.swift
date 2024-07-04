//
//  PlaylistHistory+.swift
//
//
//  Created by MochiTeam on 31.01.2024.
//

import Foundation
import Tagged

// MARK: - PlaylistHistory + Identifiable

extension PlaylistHistory: Identifiable {
  public var id: Tagged<Self, String?> { .init(UUID().uuidString) }
}
