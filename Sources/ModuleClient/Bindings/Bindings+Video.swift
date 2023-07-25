//
//  HostModuleInterop+Video.swift
//
//
//  Created by ErrorErrorError on 6/1/23.
//
//

import Foundation
import SharedModels
import WasmInterpreter

// MARK: Video Structs Imports

// swiftlint:disable closure_parameter_position
extension ModuleClient.Instance {
    func videoStructsImports() -> WasmInstance.Import {
        WasmInstance.Import(namespace: "structs_video") {
            WasmInstance.Function("create_episode_source") { [self] (
                idPtr: Int32,
                idLen: Int32,
                displayNamePtr: Int32,
                displayNameLen: Int32,
                descriptionPtr: Int32,
                descriptionLen: Int32,
                serversPtr: Int32
            ) -> Int32 in
                handleErrorAlloc { alloc in
                    let id = try memory.string(
                        byteOffset: .init(idPtr),
                        length: .init(idLen)
                    )

                    let displayName = try memory.string(
                        byteOffset: .init(displayNamePtr),
                        length: .init(displayNameLen)
                    )

                    let description = try? memory.string(
                        byteOffset: .init(descriptionPtr),
                        length: .init(descriptionLen)
                    )

                    let servers = (alloc[serversPtr] as? [Any?])?
                        .compactMap { $0 as? Playlist.EpisodeServer }

                    return alloc.add(
                        Playlist.EpisodeSource(
                            id: .init(id),
                            displayName: displayName,
                            description: description,
                            servers: servers ?? []
                        )
                    )
                }
            }

            WasmInstance.Function("create_episode_server") { [self] (
                idPtr: Int32,
                idLen: Int32,
                displayNamePtr: Int32,
                displayNameLen: Int32,
                descriptionPtr: Int32,
                descriptionLen: Int32
            ) -> Int32 in
                handleErrorAlloc { alloc in
                    let id = try memory.string(
                        byteOffset: .init(idPtr),
                        length: .init(idLen)
                    )

                    let displayName = try memory.string(
                        byteOffset: .init(displayNamePtr),
                        length: .init(displayNameLen)
                    )

                    let description = try? memory.string(
                        byteOffset: .init(descriptionPtr),
                        length: .init(descriptionLen)
                    )

                    return alloc.add(
                        Playlist.EpisodeServer(
                            id: .init(id),
                            displayName: displayName,
                            description: description
                        )
                    )
                }
            }

            WasmInstance.Function("create_episode_server_response") { [self] (
                linksPtr: Int32,
                subtitlesPtr: Int32,
                skipTimesPtr: Int32,
                headersPtr: Int32
            ) -> Int32 in
                handleErrorAlloc { alloc in
                    let links = (alloc[linksPtr] as? [Any?])?
                        .compactMap { $0 as? Playlist.EpisodeServer.Link }

                    let subtitles = (alloc[subtitlesPtr] as? [Any?])?
                        .compactMap { $0 as? Playlist.EpisodeServer.Subtitle }

                    let skipTimes = (alloc[skipTimesPtr] as? [Any?])?
                        .compactMap { $0 as? Playlist.EpisodeServer.SkipTime }

                    let headers = (alloc[headersPtr] as? [String: String])

                    return alloc.add(
                        Playlist.EpisodeServerResponse(
                            links: links ?? [],
                            subtitles: subtitles ?? [],
                            headers: headers ?? [:],
                            skipTimes: skipTimes ?? []
                        )
                    )
                }
            }

            WasmInstance.Function("create_episode_server_link") { [self] (
                urlPtr: Int32,
                urlLen: Int32,
                quality: Int32,
                format: Int32
            ) -> Int32 in
                handleErrorAlloc { alloc in
                    let url = try memory.string(
                        byteOffset: .init(urlPtr),
                        length: .init(urlLen)
                    )

                    guard let url = URL(string: url) else {
                        throw ModuleClient.Error.castError(got: "Invalid String.type", expected: "URL.type")
                    }

                    return alloc.add(
                        Playlist.EpisodeServer.Link(
                            url: url,
                            quality: .init(rawValue: .init(quality)) ?? .auto,
                            format: .init(rawValue: format) ?? .hls
                        )
                    )
                }
            }

            WasmInstance.Function("create_episode_server_subtitle") { [self] (
                urlPtr: Int32,
                urlLen: Int32,
                namePtr: Int32,
                nameLen: Int32,
                format: Int32,
                `default`: Int32,
                autoselect: Int32
            ) -> Int32 in
                handleErrorAlloc { alloc in
                    let url = try memory.string(
                        byteOffset: .init(urlPtr),
                        length: .init(urlLen)
                    )

                    guard let url = URL(string: url) else {
                        throw ModuleClient.Error.castError(got: "Invalid String.type", expected: "URL.type")
                    }

                    let name = try memory.string(
                        byteOffset: .init(namePtr),
                        length: .init(nameLen)
                    )

                    return alloc.add(
                        Playlist.EpisodeServer.Subtitle(
                            url: url,
                            name: name,
                            format: .init(rawValue: format) ?? .vtt,
                            default: `default` == 1,
                            autoselect: autoselect == 1
                        )
                    )
                }
            }

            WasmInstance.Function("create_episode_server_skip_time") { [self] (
                startTime: Float32,
                endTime: Float32,
                skipType: Int32
            ) -> Int32 in
                handleErrorAlloc { alloc in
                    alloc.add(
                        Playlist.EpisodeServer.SkipTime(
                            startTime: .init(startTime),
                            endTime: .init(endTime),
                            type: .init(rawValue: skipType) ?? .opening
                        )
                    )
                }
            }
        }
    }
}
