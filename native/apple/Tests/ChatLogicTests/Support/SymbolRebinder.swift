import Foundation
import MachO

/// Test-only rebinding of an imported C function inside this test bundle's own
/// image (the technique of Facebook's fishhook): the bundle's GOT slot of
/// [symbol] is pointed at [replacement], and `restore()` puts the original back.
///
/// Used to stand in for `SecTaskCopyValueForEntitlement`, which reads the
/// entitlements of the running process: the test runner (`xctest`) can't hold
/// the Communication Notifications entitlement a chat app has. Production code
/// is untouched; only the symbol pointer of the loaded test image changes.
final class SymbolRebinder {

    private var patched: [(slot: UnsafeMutablePointer<UnsafeRawPointer?>, original: UnsafeRawPointer?)] = []

    /// Rebinds [symbol] (C name, without the leading underscore) in the loaded
    /// image whose path contains [imageNameFragment]. Returns how many slots
    /// were patched.
    @discardableResult
    func rebind(_ symbol: String, to replacement: UnsafeRawPointer, inImage imageNameFragment: String) -> Int {
        let target = "_" + symbol
        var count = 0
        for index in 0..<_dyld_image_count() {
            guard let name = _dyld_get_image_name(index), String(cString: name).contains(imageNameFragment),
                  let header = _dyld_get_image_header(index) else { continue }
            count += rebind(target, replacement, header, _dyld_get_image_vmaddr_slide(index))
        }
        return count
    }

    func restore() {
        for (slot, original) in patched.reversed() { write(slot, original) }
        patched.removeAll()
    }

    private func rebind(
        _ target: String, _ replacement: UnsafeRawPointer,
        _ header: UnsafePointer<mach_header>, _ slide: Int
    ) -> Int {
        var linkedit: segment_command_64?
        var symtab: symtab_command?
        var dysymtab: dysymtab_command?
        var pointerSections: [section_64] = []

        var cursor = UnsafeRawPointer(header) + MemoryLayout<mach_header_64>.size
        for _ in 0..<header.pointee.ncmds {
            let command = cursor.load(as: load_command.self)
            switch command.cmd {
            case UInt32(LC_SEGMENT_64):
                let segment = cursor.load(as: segment_command_64.self)
                if Self.name(segment.segname) == SEG_LINKEDIT {
                    linkedit = segment
                } else {
                    var sectionCursor = cursor + MemoryLayout<segment_command_64>.size
                    for _ in 0..<segment.nsects {
                        let section = sectionCursor.load(as: section_64.self)
                        let type = Int32(bitPattern: section.flags) & SECTION_TYPE
                        if type == S_NON_LAZY_SYMBOL_POINTERS || type == S_LAZY_SYMBOL_POINTERS {
                            pointerSections.append(section)
                        }
                        sectionCursor += MemoryLayout<section_64>.size
                    }
                }
            case UInt32(LC_SYMTAB):
                symtab = cursor.load(as: symtab_command.self)
            case UInt32(LC_DYSYMTAB):
                dysymtab = cursor.load(as: dysymtab_command.self)
            default:
                break
            }
            cursor += Int(command.cmdsize)
        }
        guard let linkedit = linkedit, let symtab = symtab, let dysymtab = dysymtab else { return 0 }

        let base = UInt(bitPattern: slide) &+ UInt(linkedit.vmaddr) &- UInt(linkedit.fileoff)
        guard let symbols = UnsafePointer<nlist_64>(bitPattern: base + UInt(symtab.symoff)),
              let strings = UnsafePointer<CChar>(bitPattern: base + UInt(symtab.stroff)),
              let indirect = UnsafePointer<UInt32>(bitPattern: base + UInt(dysymtab.indirectsymoff))
        else { return 0 }

        var count = 0
        for section in pointerSections {
            guard let slots = UnsafeMutablePointer<UnsafeRawPointer?>(
                bitPattern: UInt(bitPattern: slide) &+ UInt(section.addr)) else { continue }
            let indices = indirect + Int(section.reserved1)
            for item in 0..<Int(section.size) / MemoryLayout<UnsafeRawPointer>.size {
                let symbolIndex = indices[item]
                if symbolIndex & UInt32(INDIRECT_SYMBOL_ABS) != 0
                    || symbolIndex & UInt32(INDIRECT_SYMBOL_LOCAL) != 0 { continue }
                let stringIndex = Int(symbols[Int(symbolIndex)].n_un.n_strx)
                guard String(cString: strings + stringIndex) == target else { continue }
                let slot = slots + item
                patched.append((slot, slot.pointee))
                write(slot, replacement)
                count += 1
            }
        }
        return count
    }

    /// Writes a GOT slot, which lives in read-only `__DATA_CONST` once loaded.
    private func write(_ slot: UnsafeMutablePointer<UnsafeRawPointer?>, _ value: UnsafeRawPointer?) {
        let pageSize = UInt(getpagesize())
        let address = UInt(bitPattern: slot)
        let page = address & ~(pageSize - 1)
        _ = vm_protect(mach_task_self_, vm_address_t(page), vm_size_t(pageSize), 0,
                       VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY)
        slot.pointee = value
        _ = vm_protect(mach_task_self_, vm_address_t(page), vm_size_t(pageSize), 0, VM_PROT_READ)
    }

    private static func name(_ tuple: (CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar,
                                       CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar)) -> String {
        var copy = tuple
        return withUnsafeBytes(of: &copy) { raw in
            String(decoding: raw.prefix { $0 != 0 }, as: UTF8.self)
        }
    }
}
