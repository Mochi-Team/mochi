//
// PlatformSet.swift
// Copyright (c) 2023 BrightDigit.
// Licensed under MIT License
//

protocol PlatformSet {
  @SupportedPlatformBuilder
  var body: any SupportedPlatforms { get }
}
