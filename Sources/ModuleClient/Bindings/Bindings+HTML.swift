//
//  HostModuleInterop+Html.swift
//
//
//  Created by ErrorErrorError on 5/9/23.
//
//

import Foundation
import SwiftSoup
import WasmInterpreter

// MARK: HTML Imports

// swiftlint:disable cyclomatic_complexity function_body_length closure_parameter_position
extension ModuleClient.Instance {
    func htmlImports() -> WasmInstance.Import {
        WasmInstance.Import(namespace: "html") {
            WasmInstance.Function("parse") { (
                strPtr: RawPtr,
                strLen: Int32
            ) -> Int32 in
                handleErrorAlloc { alloc in
                    let data = try memory.string(
                        byteOffset: .init(strPtr),
                        length: .init(strLen)
                    )

                    return try alloc.add(SwiftSoup.parse(data))
                }
            }

            WasmInstance.Function("parse_with_uri") { (
                strPtr: RawPtr,
                strLen: Int32,
                uriPtr: RawPtr,
                uriLen: Int32
            ) -> Int32 in
                handleErrorAlloc { alloc in
                    let data = try memory.string(
                        byteOffset: .init(strPtr),
                        length: .init(strLen)
                    )

                    if uriLen > 0 {
                        let baseURI = try memory.string(
                            byteOffset: .init(uriPtr),
                            length: .init(uriLen)
                        )
                        return try alloc.add(SwiftSoup.parse(data, baseURI))
                    } else {
                        return try alloc.add(SwiftSoup.parse(data))
                    }
                }
            }

            WasmInstance.Function("parse_fragment") { (
                strPtr: RawPtr,
                strLen: Int32
            ) -> Int32 in
                handleErrorAlloc { alloc in
                    let data = try memory.string(
                        byteOffset: .init(strPtr),
                        length: .init(strLen)
                    )

                    return try alloc.add(SwiftSoup.parseBodyFragment(data))
                }
            }

            WasmInstance.Function("parse_fragment_with_uri") { (
                strPtr: RawPtr,
                strLen: Int32,
                uriPtr: RawPtr,
                uriLen: Int32
            ) -> Int32 in
                handleErrorAlloc { alloc in
                    let data = try memory.string(
                        byteOffset: .init(strPtr),
                        length: .init(strLen)
                    )

                    if uriLen > 0 {
                        let baseURI = try memory.string(
                            byteOffset: .init(uriPtr),
                            length: .init(uriLen)
                        )
                        return try alloc.add(SwiftSoup.parseBodyFragment(data, baseURI))
                    } else {
                        return try alloc.add(SwiftSoup.parseBodyFragment(data))
                    }
                }
            }

            WasmInstance.Function("select") { (
                ptr: PtrRef,
                strPtr: RawPtr,
                strLen: Int32
            ) -> Int32 in
                handleErrorAlloc { alloc in
                    guard ptr >= 0 else {
                        return ptr
                    }

                    let selectorStr = try memory.string(
                        byteOffset: .init(strPtr),
                        length: .init(strLen)
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

            WasmInstance.Function("attr") { (
                ptr: PtrRef,
                strPtr: RawPtr,
                strLen: Int32
            ) -> Int32 in
                handleErrorAlloc { alloc in
                    guard ptr >= 0 else {
                        return ptr
                    }

                    let selectorStr = try memory.string(
                        byteOffset: .init(strPtr),
                        length: .init(strLen)
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

            WasmInstance.Function("set_text") { (
                ptr: PtrRef,
                strPtr: RawPtr,
                strLen: Int32
            ) -> Int32 in
                handleErrorAlloc { alloc in
                    guard ptr >= 0 else {
                        throw ModuleClient.Error.unknown()
                    }

                    let textStr = try memory.string(
                        byteOffset: .init(strPtr),
                        length: .init(strLen)
                    )

                    if (try? (alloc[ptr] as? SwiftSoup.Element)?.text(textStr)) != nil {
                        return 0
                    } else {
                        throw ModuleClient.Error.nullPtr()
                    }
                }
            }

            WasmInstance.Function("set_html") { (
                ptr: PtrRef,
                strPtr: RawPtr,
                strLen: Int32
            ) -> Int32 in
                handleErrorAlloc { alloc in
                    guard ptr >= 0 else {
                        return ptr
                    }

                    let htmlStr = try memory.string(
                        byteOffset: .init(strPtr),
                        length: .init(strLen)
                    )

                    if (try? (alloc[ptr] as? SwiftSoup.Element)?.html(htmlStr)) != nil {
                        return 0
                    } else {
                        throw ModuleClient.Error.nullPtr()
                    }
                }
            }

            WasmInstance.Function("prepend") { (
                ptr: PtrRef,
                strPtr: RawPtr,
                strLen: Int32
            ) -> Int32 in
                handleErrorAlloc { alloc in
                    guard ptr >= 0 else {
                        throw ModuleClient.Error.nullPtr()
                    }

                    let htmlStr = try memory.string(
                        byteOffset: .init(strPtr),
                        length: .init(strLen)
                    )

                    if (try? (alloc[ptr] as? SwiftSoup.Element)?.prepend(htmlStr)) != nil {
                        return 0
                    } else {
                        throw ModuleClient.Error.castError()
                    }
                }
            }

            WasmInstance.Function("append") { (
                ptr: PtrRef,
                strPtr: RawPtr,
                strLen: Int32
            ) -> Int32 in
                handleErrorAlloc { alloc in
                    guard ptr >= 0 else {
                        throw ModuleClient.Error.nullPtr()
                    }

                    let htmlStr = try memory.string(
                        byteOffset: .init(strPtr),
                        length: .init(strLen)
                    )

                    if (try? (alloc[ptr] as? SwiftSoup.Element)?.append(htmlStr)) != nil {
                        return 0
                    } else {
                        throw ModuleClient.Error.castError()
                    }
                }
            }

            WasmInstance.Function("first") { (ptr: PtrRef) -> PtrRef in
                handleErrorAlloc { alloc in
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

            WasmInstance.Function("last") { (ptr: PtrRef) -> PtrRef in
                handleErrorAlloc { alloc in
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

            WasmInstance.Function("next") { (ptr: PtrRef) -> PtrRef in
                handleErrorAlloc { alloc in
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

            WasmInstance.Function("previous") { (ptr: PtrRef) -> PtrRef in
                handleErrorAlloc { alloc in
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

            WasmInstance.Function("base_uri") { (ptr: PtrRef) -> PtrRef in
                handleErrorAlloc { alloc in
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

            WasmInstance.Function("body") { (ptr: PtrRef) -> PtrRef in
                handleErrorAlloc { alloc in
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

            WasmInstance.Function("text") { (ptr: PtrRef) -> PtrRef in
                handleErrorAlloc { alloc in
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

            WasmInstance.Function("untrimmed_text") { (ptr: PtrRef) -> PtrRef in
                handleErrorAlloc { alloc in
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

            WasmInstance.Function("own_text") { (ptr: PtrRef) -> PtrRef in
                handleErrorAlloc { alloc in
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

            WasmInstance.Function("data") { (ptr: PtrRef) -> PtrRef in
                handleErrorAlloc { alloc in
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

            WasmInstance.Function("array") { (ptr: PtrRef) -> PtrRef in
                handleErrorAlloc { alloc in
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

            WasmInstance.Function("html") { (ptr: PtrRef) -> PtrRef in
                handleErrorAlloc { alloc in
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

            WasmInstance.Function("outer_html") { (ptr: PtrRef) -> PtrRef in
                handleErrorAlloc { alloc in
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

            WasmInstance.Function("escape") { (ptr: PtrRef) -> PtrRef in
                handleErrorAlloc { alloc in
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

            WasmInstance.Function("unescape") { (ptr: PtrRef) -> PtrRef in
                handleErrorAlloc { alloc in
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

            WasmInstance.Function("id") { (ptr: PtrRef) -> PtrRef in
                handleErrorAlloc { alloc in
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

            WasmInstance.Function("tag_name") { (ptr: PtrRef) -> PtrRef in
                handleErrorAlloc { alloc in
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

            WasmInstance.Function("class_name") { (ptr: PtrRef) -> PtrRef in
                handleErrorAlloc { alloc in
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

            WasmInstance.Function("has_class") { (
                ptr: PtrRef,
                classNamePtr: RawPtr,
                classNameLen: Int32
            ) -> Int32 in
                handleErrorAlloc { alloc in
                    guard ptr >= 0 else {
                        return 0
                    }

                    guard let value = alloc[ptr] else {
                        return 0
                    }

                    guard let className = try? memory.string(
                        byteOffset: .init(classNamePtr),
                        length: .init(classNameLen)
                    ) else {
                        return 0
                    }

                    guard let value = value as? SwiftSoup.Element else {
                        return 0
                    }

                    return value.hasClass(className) ? 1 : 0
                }
            }

            WasmInstance.Function("has_attr") { (
                ptr: PtrRef,
                attrNamePtr: RawPtr,
                attrNameLen: Int32
            ) -> Int32 in
                handleErrorAlloc { alloc in
                    guard ptr >= 0 else {
                        return 0
                    }

                    guard let value = alloc[ptr] else {
                        return 0
                    }

                    guard let attrName = try? memory.string(
                        byteOffset: .init(attrNamePtr),
                        length: .init(attrNameLen)
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
    }
}
