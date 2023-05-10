//
//  Live+Imports+Html.swift
//  
//
//  Created by ErrorErrorError on 5/9/23.
//  
//

import Foundation
import SwiftSoup

// MARK: - SwiftSoup Imports

extension HostModuleIntercommunication {
    func scraper_parse(
        string_ptr: RawPtr,
        string_len: Int32
    ) -> PtrRef {
        self.handleErrorAlloc { alloc in
            let data = try memory.string(
                byteOffset: .init(string_ptr),
                length: .init(string_len)
            )

            return try alloc.add(SwiftSoup.parse(data))
        }
    }

    func scraper_parse_with_uri(
        string_ptr: RawPtr,
        string_len: Int32,
        base_uri_ptr: RawPtr,
        base_uri_len: Int32
    ) -> PtrRef {
        self.handleErrorAlloc { alloc in
            let data = try memory.string(
                byteOffset: .init(string_ptr),
                length: .init(string_len)
            )

            if base_uri_len > 0 {
                let baseURI = try memory.string(
                    byteOffset: .init(base_uri_ptr),
                    length: .init(base_uri_len)
                )
                return try alloc.add(SwiftSoup.parse(data, baseURI))
            } else {
                return try alloc.add(SwiftSoup.parse(data))
            }
        }
    }

    func scraper_parse_fragment(
        string_ptr: RawPtr,
        string_len: Int32
    ) -> PtrRef {
        self.handleErrorAlloc { alloc in
            let data = try memory.string(
                byteOffset: .init(string_ptr),
                length: .init(string_len)
            )

            return try alloc.add(SwiftSoup.parseBodyFragment(data))
        }
    }

    func scraper_parse_fragment_with_uri(
        string_ptr: RawPtr,
        string_len: Int32,
        base_uri_ptr: RawPtr,
        base_uri_len: Int32
    ) -> PtrRef {
        self.handleErrorAlloc { alloc in
            let data = try memory.string(
                byteOffset: .init(string_ptr),
                length: .init(string_len)
            )

            if base_uri_len > 0 {
                let baseURI = try memory.string(
                    byteOffset: .init(base_uri_ptr),
                    length: .init(base_uri_len)
                )
                return try alloc.add(SwiftSoup.parseBodyFragment(data, baseURI))
            } else {
                return try alloc.add(SwiftSoup.parseBodyFragment(data))
            }
        }
    }

    func scraper_select(
        ptr: PtrRef,
        selector_ptr: RawPtr,
        selector_len: Int32
    ) -> PtrRef {
        self.handleErrorAlloc { alloc in
            guard ptr >= 0 else {
                return ptr
            }

            let selectorStr = try memory.string(
                byteOffset: .init(selector_ptr),
                length: .init(selector_len)
            )

            if let object = try? (alloc[ptr] as? SwiftSoup.Element)?.select(selectorStr) {
                return alloc.add(object)
            } else if let object = try? (alloc[ptr] as? SwiftSoup.Elements)?.select(selectorStr) {
                return alloc.add(object)
            } else {
                throw ModuleClient.Error.nullPtr()
            }
        }
    }

    func scraper_attr(
        ptr: PtrRef,
        selector_ptr: RawPtr,
        selector_len: Int32
    ) -> PtrRef {
        self.handleErrorAlloc { alloc in
            guard ptr >= 0 else {
                return ptr
            }

            let selectorStr = try memory.string(
                byteOffset: .init(selector_ptr),
                length: .init(selector_len)
            )

            if let object = try? (alloc[ptr] as? SwiftSoup.Element)?.attr(selectorStr) {
                return alloc.add(object)
            } else if let object = try? (alloc[ptr] as? SwiftSoup.Elements)?.attr(selectorStr) {
                return alloc.add(object)
            } else {
                throw ModuleClient.Error.nullPtr()
            }
        }
    }

    func scraper_set_text(
        ptr: PtrRef,
        text: RawPtr,
        text_len: Int32
    ) -> Int32 {
        self.handleErrorAlloc { alloc in
            guard ptr >= 0 else {
                throw ModuleClient.Error.unknown()
            }

            let textStr = try memory.string(
                byteOffset: .init(text),
                length: .init(text_len)
            )

            if (try? (alloc[ptr] as? SwiftSoup.Element)?.text(textStr)) != nil {
                return 0
            } else {
                throw ModuleClient.Error.nullPtr()
            }
        }
    }

    func scraper_set_html(
        ptr: PtrRef,
        html: RawPtr,
        html_len: Int32
    ) -> Int32 {
        self.handleErrorAlloc { alloc in
            guard ptr >= 0 else {
                return ptr
            }

            let htmlStr = try memory.string(
                byteOffset: .init(html),
                length: .init(html_len)
            )

            if (try? (alloc[ptr] as? SwiftSoup.Element)?.html(htmlStr)) != nil {
                return 0
            } else {
                throw ModuleClient.Error.nullPtr()
            }
        }
    }

    func scraper_prepend(
        ptr: PtrRef,
        html: RawPtr,
        html_len: Int32
    ) -> Int32 {
        self.handleErrorAlloc { alloc in
            guard ptr >= 0 else {
                throw ModuleClient.Error.nullPtr()
            }

            let htmlStr = try memory.string(
                byteOffset: .init(html),
                length: .init(html_len)
            )

            if (try? (alloc[ptr] as? SwiftSoup.Element)?.prepend(htmlStr)) != nil {
                return 0
            } else {
                throw ModuleClient.Error.castError()
            }
        }
    }

    func scraper_append(
        ptr: PtrRef,
        html: RawPtr,
        html_len: Int32
    ) -> Int32 {
        self.handleErrorAlloc { alloc in
            guard ptr >= 0 else {
                throw ModuleClient.Error.nullPtr()
            }

            let htmlStr = try memory.string(
                byteOffset: .init(html),
                length: .init(html_len)
            )

            if (try? (alloc[ptr] as? SwiftSoup.Element)?.append(htmlStr)) != nil {
                return 0
            } else {
                throw ModuleClient.Error.castError()
            }
        }
    }

    func scraper_first(ptr: PtrRef) -> PtrRef {
        self.handleErrorAlloc { alloc in
            guard ptr >= 0 else {
                throw ModuleClient.Error.nullPtr()
            }

            if let elements = alloc[ptr] as? SwiftSoup.Elements,
               let element = elements.first() {
                return alloc.add(element)
            } else {
                throw ModuleClient.Error.nullPtr()
            }
        }
    }

    func scraper_last(ptr: PtrRef) -> PtrRef {
        self.handleErrorAlloc { alloc in
            guard ptr >= 0 else {
                throw ModuleClient.Error.nullPtr()
            }

            if let elements = alloc[ptr] as? SwiftSoup.Elements,
               let element = elements.last() {
                return alloc.add(element)
            } else {
                throw ModuleClient.Error.nullPtr()
            }
        }
    }

    func scraper_next(ptr: PtrRef) -> PtrRef {
        self.handleErrorAlloc { alloc in
            guard ptr >= 0 else {
                throw ModuleClient.Error.nullPtr()
            }

            if let element = alloc[ptr] as? SwiftSoup.Element,
               let nextElement = try? element.nextElementSibling() {
                return alloc.add(nextElement)
            } else {
                throw ModuleClient.Error.nullPtr()
            }
        }
    }

    func scraper_previous(ptr: PtrRef) -> PtrRef {
        self.handleErrorAlloc { alloc in
            guard ptr >= 0 else {
                throw ModuleClient.Error.nullPtr()
            }

            if let element = alloc[ptr] as? SwiftSoup.Element,
               let previousElement = try? element.previousElementSibling() {
                return alloc.add(previousElement)
            } else {
                throw ModuleClient.Error.nullPtr()
            }
        }
    }

    func scraper_base_uri(ptr: PtrRef) -> PtrRef {
        self.handleErrorAlloc { alloc in
            guard ptr >= 0 else {
                return ptr
            }

            if let node = alloc[ptr] as? SwiftSoup.Node {
                return alloc.add(node.getBaseUri())
            } else {
                throw ModuleClient.Error.castError()
            }
        }
    }

    func scraper_body(ptr: PtrRef) -> PtrRef {
        self.handleErrorAlloc { alloc in
            guard ptr >= 0 else {
                return ptr
            }

            guard let value = alloc[ptr] else {
                throw ModuleClient.Error.nullPtr()
            }

            if let document = value as? SwiftSoup.Document {
                if let body = document.body() {
                    return alloc.add(body)
                } else {
                    throw ModuleClient.Error.nullPtr()
                }
            } else {
                throw ModuleClient.Error.castError()
            }
        }
    }

    func scraper_text(ptr: PtrRef) -> PtrRef {
        self.handleErrorAlloc { alloc in
            guard ptr >= 0 else {
                return ptr
            }

            guard let value = alloc[ptr] else {
                throw ModuleClient.Error.nullPtr()
            }

            if let elements = value as? SwiftSoup.Elements,
               let string = try? elements.text(trimAndNormaliseWhitespace: true) {
                return alloc.add(string)
            } else if let element = value as? SwiftSoup.Element,
                      let string = try? element.text(trimAndNormaliseWhitespace: true) {
                return alloc.add(string)
            } else if let string = value as? String {
                if !string.isEmpty, let firstChar = string.first, let lastChar = string.last {
                    if firstChar.isWhitespace || lastChar.isWhitespace || firstChar == "\n" || lastChar == "\n" {
                        return alloc.add(string.trimmingCharacters(in: .whitespacesAndNewlines))
                    }
                }
                return alloc.add(string)
            }
            throw ModuleClient.Error.castError()
        }
    }

    func scraper_untrimmed_text(ptr: PtrRef) -> PtrRef {
        self.handleErrorAlloc { alloc in
            guard ptr >= 0 else {
                return ptr
            }

            guard let value = alloc[ptr] else {
                throw ModuleClient.Error.nullPtr()
            }

            if let elements = value as? SwiftSoup.Elements,
               let string = try? elements.text(trimAndNormaliseWhitespace: false) {
                return alloc.add(string)
            } else if let element = value as? SwiftSoup.Element,
                      let string = try? element.text(trimAndNormaliseWhitespace: false) {
                return alloc.add(string)
            } else if let string = value as? String {
                return alloc.add(string)
            }
            throw ModuleClient.Error.castError()
        }
    }

    func scraper_own_text(ptr: PtrRef) -> PtrRef {
        self.handleErrorAlloc { alloc in
            guard ptr >= 0 else {
                return ptr
            }

            guard let value = alloc[ptr] else {
                throw ModuleClient.Error.nullPtr()
            }

            if let element = value as? SwiftSoup.Element {
                return alloc.add(element.ownText())
            } else if let string = value as? String {
                return alloc.add(string)
            }
            throw ModuleClient.Error.castError()
        }
    }

    func scraper_data(ptr: PtrRef) -> PtrRef {
        self.handleErrorAlloc { alloc in
            guard ptr >= 0 else {
                return ptr
            }

            guard let value = alloc[ptr] else {
                throw ModuleClient.Error.nullPtr()
            }

            if let element = value as? SwiftSoup.Element {
                return alloc.add(element.data())
            } else if let string = value as? String {
                return alloc.add(string)
            }
            throw ModuleClient.Error.castError()
        }
    }

    func scraper_array(ptr: PtrRef) -> PtrRef {
        self.handleErrorAlloc { alloc in
            guard ptr >= 0 else {
                return ptr
            }

            guard let value = alloc[ptr] else {
                throw ModuleClient.Error.nullPtr()
            }

            if let elements = value as? SwiftSoup.Elements {
                return alloc.add(elements.array())
            }
            throw ModuleClient.Error.castError()
        }
    }

    func scraper_html(ptr: PtrRef) -> PtrRef {
        self.handleErrorAlloc { alloc in
            guard ptr >= 0 else {
                return ptr
            }

            guard let value = alloc[ptr] else {
                throw ModuleClient.Error.nullPtr()
            }

            if let elements = value as? SwiftSoup.Elements,
               let html = try? elements.html() {
                return alloc.add(html)
            } else if let element = value as? SwiftSoup.Element,
                      let html = try? element.html() {
                return alloc.add(html)
            }
            throw ModuleClient.Error.castError()
        }
    }

    func scraper_outer_html(ptr: PtrRef) -> PtrRef {
        self.handleErrorAlloc { alloc in
            guard ptr >= 0 else {
                return ptr
            }

            guard let value = alloc[ptr] else {
                throw ModuleClient.Error.nullPtr()
            }

            if let elements = value as? SwiftSoup.Elements,
               let html = try? elements.outerHtml() {
                return alloc.add(html)
            } else if let element = value as? SwiftSoup.Element,
                      let html = try? element.outerHtml() {
                return alloc.add(html)
            }
            throw ModuleClient.Error.castError()
        }
    }

    func scraper_escape(ptr: PtrRef) -> PtrRef {
        self.handleErrorAlloc { alloc in
            guard ptr >= 0 else {
                return ptr
            }

            guard let value = alloc[ptr] else {
                throw ModuleClient.Error.nullPtr()
            }

            if let elements = value as? SwiftSoup.Elements,
               let string = try? elements.text() {
                return alloc.add(Entities.escape(string))
            } else if let element = value as? SwiftSoup.Element,
                      let string = try? element.text() {
                return alloc.add(Entities.escape(string))
            } else if let string = value as? String {
                return alloc.add(Entities.escape(string))
            }
            throw ModuleClient.Error.castError()
        }
    }

    func scraper_unescape(ptr: PtrRef) -> PtrRef {
        self.handleErrorAlloc { alloc in
            guard ptr >= 0 else {
                return ptr
            }

            guard let value = alloc[ptr] else {
                throw ModuleClient.Error.nullPtr()
            }

            if let elements = value as? SwiftSoup.Elements,
               let string = try? elements.text() {
                return alloc.add((try? Entities.unescape(string)) ?? "")
            } else if let element = value as? SwiftSoup.Element,
                      let string = try? element.text() {
                return alloc.add((try? Entities.unescape(string)) ?? "")
            } else if let string = value as? String {
                return alloc.add((try? Entities.unescape(string)) ?? "")
            }
            throw ModuleClient.Error.castError()
        }
    }

    func scraper_id(ptr: PtrRef) -> PtrRef {
        self.handleErrorAlloc { alloc in
            guard ptr >= 0 else {
                return ptr
            }

            guard let value = alloc[ptr] else {
                throw ModuleClient.Error.nullPtr()
            }

            if let element = value as? SwiftSoup.Element {
                return alloc.add(element.id())
            }
            throw ModuleClient.Error.castError()
        }
    }

    func scraper_tag_name(ptr: PtrRef) -> PtrRef {
        self.handleErrorAlloc { alloc in
            guard ptr >= 0 else {
                return ptr
            }

            guard let value = alloc[ptr] else {
                throw ModuleClient.Error.nullPtr()
            }

            if let element = value as? SwiftSoup.Element {
                return alloc.add(element.tagName())
            }
            throw ModuleClient.Error.castError()
        }
    }

    func scraper_class_name(ptr: PtrRef) -> PtrRef {
        self.handleErrorAlloc { alloc in
            guard ptr >= 0 else {
                return ptr
            }

            guard let value = alloc[ptr] else {
                throw ModuleClient.Error.nullPtr()
            }

            if let element = value as? SwiftSoup.Element,
               let className = try? element.className() {
                return alloc.add(className)
            }
            throw ModuleClient.Error.castError()
        }
    }

    func scraper_has_class(
        ptr: PtrRef,
        class_name_ptr: RawPtr,
        class_name_length: Int32
    ) -> Int32 {
        self.handleErrorAlloc { alloc in
            guard ptr >= 0 else {
                return 0
            }

            guard let value = alloc[ptr] else {
                return 0
            }

            guard let className = try? memory.string(
                byteOffset: .init(class_name_ptr),
                length: .init(class_name_length)
            ) else {
                return 0
            }

            guard let value = value as? SwiftSoup.Element else {
                return 0
            }

            return value.hasClass(className) ? 1 : 0
        }
    }

    func scraper_has_attr(
        ptr: PtrRef,
        attr_name_ptr: RawPtr,
        attr_name_length: Int32
    ) -> Int32 {
        self.handleErrorAlloc { alloc in
            guard ptr >= 0 else {
                return 0
            }

            guard let value = alloc[ptr] else {
                return 0
            }

            guard let attrName = try? memory.string(
                byteOffset: .init(attr_name_ptr),
                length: .init(attr_name_length)
            ) else {
                return 0
            }

            guard let value = value as? SwiftSoup.Element else {
                return 0
            }

            return value.hasAttr(attrName) ? 1 : 0
        }
    }
}
