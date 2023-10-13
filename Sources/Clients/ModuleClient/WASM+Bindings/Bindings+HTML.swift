//
//  Bindings+HTML.swift
//
//
//  Created by ErrorErrorError on 5/9/23.
//
//

import Foundation
import SwiftSoup
import WasmInterpreter

// MARK: HTML Imports

// swiftlint:disable closure_parameter_position
extension ModuleClient.Instance {
    func htmlImports() -> WasmInstance.Import {
        WasmInstance.Import(namespace: "html") {
            WasmInstance.Function("parse") { (
                strPtr: RawPtr,
                strLen: Int32
            ) -> Int32 in
                hostBindings.scraper_parse(string_ptr: strPtr, string_len: strLen)
            }

            WasmInstance.Function("parse_with_uri") { (
                strPtr: RawPtr,
                strLen: Int32,
                uriPtr: RawPtr,
                uriLen: Int32
            ) -> Int32 in
                hostBindings.scraper_parse_with_uri(
                    string_ptr: strPtr,
                    string_len: strLen,
                    base_uri_ptr: uriPtr,
                    base_uri_len: uriLen
                )
            }

            WasmInstance.Function("parse_fragment") { (
                strPtr: RawPtr,
                strLen: Int32
            ) -> Int32 in
                hostBindings.scraper_parse_fragment(string_ptr: strPtr, string_len: strLen)
            }

            WasmInstance.Function("parse_fragment_with_uri") { (
                strPtr: RawPtr,
                strLen: Int32,
                uriPtr: RawPtr,
                uriLen: Int32
            ) -> Int32 in
                hostBindings.scraper_parse_with_uri(
                    string_ptr: strPtr,
                    string_len: strLen,
                    base_uri_ptr: uriPtr,
                    base_uri_len: uriLen
                )
            }

            WasmInstance.Function("select") { (
                ptr: PtrRef,
                strPtr: RawPtr,
                strLen: Int32
            ) -> Int32 in
                hostBindings.scraper_select(
                    ptr: ptr,
                    selector_ptr: strPtr,
                    selector_len: strLen
                )
            }

            WasmInstance.Function("attr") { (
                ptr: PtrRef,
                strPtr: RawPtr,
                strLen: Int32
            ) -> Int32 in
                hostBindings.scraper_attr(
                    ptr: ptr,
                    selector_ptr: strPtr,
                    selector_len: strLen
                )
            }

            WasmInstance.Function("set_text") { (
                ptr: PtrRef,
                strPtr: RawPtr,
                strLen: Int32
            ) -> Int32 in
                hostBindings.scraper_set_text(
                    ptr: ptr,
                    text: strPtr,
                    text_len: strLen
                )
            }

            WasmInstance.Function("set_html") { (
                ptr: PtrRef,
                strPtr: RawPtr,
                strLen: Int32
            ) -> Int32 in
                hostBindings.scraper_set_html(
                    ptr: ptr,
                    html: strPtr,
                    html_len: strLen
                )
            }

            WasmInstance.Function("prepend") { (
                ptr: PtrRef,
                strPtr: RawPtr,
                strLen: Int32
            ) -> Int32 in
                hostBindings.scraper_prepend(
                    ptr: ptr,
                    html: strPtr,
                    html_len: strLen
                )
            }

            WasmInstance.Function("append") { (
                ptr: PtrRef,
                strPtr: RawPtr,
                strLen: Int32
            ) -> Int32 in
                hostBindings.scraper_append(
                    ptr: ptr,
                    html: strPtr,
                    html_len: strLen
                )
            }

            WasmInstance.Function("first") { (ptr: PtrRef) -> PtrRef in
                hostBindings.scraper_first(ptr: ptr)
            }

            WasmInstance.Function("last") { (ptr: PtrRef) -> PtrRef in
                hostBindings.scraper_last(ptr: ptr)
            }

            WasmInstance.Function("next") { (ptr: PtrRef) -> PtrRef in
                hostBindings.scraper_next(ptr: ptr)
            }

            WasmInstance.Function("previous") { (ptr: PtrRef) -> PtrRef in
                hostBindings.scraper_previous(ptr: ptr)
            }

            WasmInstance.Function("base_uri") { (ptr: PtrRef) -> PtrRef in
                hostBindings.scraper_base_uri(ptr: ptr)
            }

            WasmInstance.Function("body") { (ptr: PtrRef) -> PtrRef in
                hostBindings.scraper_body(ptr: ptr)
            }

            WasmInstance.Function("text") { (ptr: PtrRef) -> PtrRef in
                hostBindings.scraper_text(ptr: ptr)
            }

            WasmInstance.Function("untrimmed_text") { (ptr: PtrRef) -> PtrRef in
                hostBindings.scraper_untrimmed_text(ptr: ptr)
            }

            WasmInstance.Function("own_text") { (ptr: PtrRef) -> PtrRef in
                hostBindings.scraper_own_text(ptr: ptr)
            }

            WasmInstance.Function("data") { (ptr: PtrRef) -> PtrRef in
                hostBindings.scraper_data(ptr: ptr)
            }

            WasmInstance.Function("array") { (ptr: PtrRef) -> PtrRef in
                hostBindings.scraper_array(ptr: ptr)
            }

            WasmInstance.Function("html") { (ptr: PtrRef) -> PtrRef in
                hostBindings.scraper_html(ptr: ptr)
            }

            WasmInstance.Function("outer_html") { (ptr: PtrRef) -> PtrRef in
                hostBindings.scraper_outer_html(ptr: ptr)
            }

            WasmInstance.Function("escape") { (ptr: PtrRef) -> PtrRef in
                hostBindings.scraper_escape(ptr: ptr)
            }

            WasmInstance.Function("unescape") { (ptr: PtrRef) -> PtrRef in
                hostBindings.scraper_unescape(ptr: ptr)
            }

            WasmInstance.Function("id") { (ptr: PtrRef) -> PtrRef in
                hostBindings.scraper_id(ptr: ptr)
            }

            WasmInstance.Function("tag_name") { (ptr: PtrRef) -> PtrRef in
                hostBindings.scraper_tag_name(ptr: ptr)
            }

            WasmInstance.Function("class_name") { (ptr: PtrRef) -> PtrRef in
                hostBindings.scraper_class_name(ptr: ptr)
            }

            WasmInstance.Function("has_class") { (
                ptr: PtrRef,
                classNamePtr: RawPtr,
                classNameLen: Int32
            ) -> Int32 in
                hostBindings.scraper_has_class(ptr: ptr, class_name_ptr: classNamePtr, class_name_length: classNameLen)
            }

            WasmInstance.Function("has_attr") { (
                ptr: PtrRef,
                attrNamePtr: RawPtr,
                attrNameLen: Int32
            ) -> Int32 in
                hostBindings.scraper_has_attr(
                    ptr: ptr,
                    attr_name_ptr: attrNamePtr,
                    attr_name_length: attrNameLen
                )
            }
        }
    }
}
// swiftlint:enable closure_parameter_position
