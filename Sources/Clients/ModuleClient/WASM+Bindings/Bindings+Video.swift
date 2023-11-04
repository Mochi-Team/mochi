//
//  Bindings+Video.swift
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
extension ModuleClient.WAInstance {
    func videoImports() -> WasmInstance.Import {
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
                hostBindings.video_create_episode_source(
                    id_ptr: idPtr,
                    id_len: idLen,
                    display_name_ptr: displayNamePtr,
                    display_name_len: displayNameLen,
                    description_ptr: descriptionPtr,
                    description_len: descriptionLen,
                    servers_ptr: serversPtr
                )
            }

            WasmInstance.Function("create_episode_server") { [self] (
                idPtr: Int32,
                idLen: Int32,
                displayNamePtr: Int32,
                displayNameLen: Int32,
                descriptionPtr: Int32,
                descriptionLen: Int32
            ) -> Int32 in
                hostBindings.video_create_episode_server(
                    id_ptr: idPtr,
                    id_len: idLen,
                    display_name_ptr: displayNamePtr,
                    display_name_len: displayNameLen,
                    description_ptr: descriptionPtr,
                    description_len: descriptionLen
                )
            }

            WasmInstance.Function("create_episode_server_response") { [self] (
                linksPtr: Int32,
                subtitlesPtr: Int32,
                skipTimesPtr: Int32,
                headersPtr: Int32
            ) -> Int32 in
                hostBindings.video_create_episode_server_response(
                    links_ptr: linksPtr,
                    subtitles_ptr: subtitlesPtr,
                    skip_times_ptr: skipTimesPtr,
                    headers_ptr: headersPtr
                )
            }

            WasmInstance.Function("create_episode_server_link") { [self] (
                urlPtr: Int32,
                urlLen: Int32,
                quality: Int32,
                format: Int32
            ) -> Int32 in
                hostBindings.video_create_episode_server_link(
                    url_ptr: urlPtr,
                    url_len: urlLen,
                    quality: quality,
                    format: format
                )
            }

            WasmInstance.Function("create_episode_server_subtitle") { [self] (
                urlPtr: Int32,
                urlLen: Int32,
                namePtr: Int32,
                nameLen: Int32,
                format: Int32,
                default: Int32,
                autoselect: Int32
            ) -> Int32 in
                hostBindings.video_create_episode_server_subtitle(
                    url_ptr: urlPtr,
                    url_len: urlLen,
                    name_ptr: namePtr,
                    name_len: nameLen,
                    format: format,
                    default: `default`,
                    autoselect: autoselect
                )
            }

            WasmInstance.Function("create_episode_server_skip_time") { [self] (
                start_time: Float32,
                end_time: Float32,
                skip_type: Int32
            ) -> Int32 in
                hostBindings.video_create_episode_server_skip_time(
                    start_time: start_time,
                    end_time: end_time,
                    skip_type: skip_type
                )
            }
        }
    }
}

// swiftlint:enable closure_parameter_position
