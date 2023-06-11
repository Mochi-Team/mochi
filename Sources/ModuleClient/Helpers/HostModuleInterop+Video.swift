//
//  HostModuleInterop+Video.swift
//  
//
//  Created by ErrorErrorError on 6/1/23.
//  
//

import Foundation
import SharedModels

// swiftlint:disable function_parameter_count
extension HostModuleInterop {
    func create_episode_source(
        id_ptr: Int32,
        id_len: Int32,
        display_name_ptr: Int32,
        display_name_len: Int32,
        description_ptr: Int32,
        description_len: Int32,
        servers_ptr: Int32
    ) -> Int32 {
        handleErrorAlloc { alloc in
            let id = try memory.string(
                byteOffset: .init(id_ptr),
                length: .init(id_len)
            )

            let displayName = try memory.string(
                byteOffset: .init(display_name_ptr),
                length: .init(display_name_len)
            )

            let description = try? memory.string(
                byteOffset: .init(description_ptr),
                length: .init(description_len)
            )

            let servers = (alloc[servers_ptr] as? [Any?])?
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

    func create_episode_server(
        id_ptr: Int32,
        id_len: Int32,
        display_name_ptr: Int32,
        display_name_len: Int32,
        description_ptr: Int32,
        description_len: Int32
    ) -> Int32 {
        handleErrorAlloc { alloc in
            let id = try memory.string(
                byteOffset: .init(id_ptr),
                length: .init(id_len)
            )

            let displayName = try memory.string(
                byteOffset: .init(display_name_ptr),
                length: .init(display_name_len)
            )

            let description = try? memory.string(
                byteOffset: .init(description_ptr),
                length: .init(description_len)
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

    func create_episode_server_response(
        links_ptr: Int32,
        subtitles_ptr: Int32,
        format_type: Int32
    ) -> Int32 {
        handleErrorAlloc { alloc in
            let links = (alloc[links_ptr] as? [Any?])?
                .compactMap { $0 as? Playlist.EpisodeServer.Link }

            let subtitles = (alloc[subtitles_ptr] as? [Any?])?
                .compactMap { $0 as? Playlist.EpisodeServer.Subtitle }

            return alloc.add(
                Playlist.EpisodeServerResponse(
                    links: links ?? [],
                    subtitles: subtitles ?? [],
                    formatType: .init(rawValue: format_type) ?? .hls
                )
            )
        }
    }

    func create_episode_server_link(
        url_ptr: Int32,
        url_len: Int32,
        quality: Int32
    ) -> Int32 {
        handleErrorAlloc { alloc in
            let url = try memory.string(
                byteOffset: .init(url_ptr),
                length: .init(url_len)
            )

            guard let url = URL(string: url) else {
                throw ModuleClient.Error.castError(got: "Invalid String.type", expected: "URL.type")
            }

            return alloc.add(
                Playlist.EpisodeServer.Link(
                    url: url,
                    quality: .init(rawValue: .init(quality)) ?? .auto
                )
            )
        }
    }

    func create_episode_server_subtitle(
        url_ptr: Int32,
        url_len: Int32,
        language_ptr: Int32,
        language_len: Int32
    ) -> Int32 {
        handleErrorAlloc { alloc in
            let url = try memory.string(
                byteOffset: .init(url_ptr),
                length: .init(url_len)
            )

            guard let url = URL(string: url) else {
                throw ModuleClient.Error.castError(got: "Invalid String.type", expected: "URL.type")
            }

            let language = try memory.string(
                byteOffset: .init(language_ptr),
                length: .init(language_len)
            )

            return alloc.add(
                Playlist.EpisodeServer.Subtitle(
                    url: url,
                    language: language
                )
            )
        }
    }
}
