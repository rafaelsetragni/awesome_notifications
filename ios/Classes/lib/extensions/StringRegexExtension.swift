
extension String {
    
    func charAt(_ pos:Int) -> Character {
        if(pos < 0 || pos >= count) { return Character("") }
        return Array(self)[pos]
    }
    
    func index(from: Int) -> Index {
        return self.index(startIndex, offsetBy: from)
    }
    
    func indexOf(_ char: Character) -> Int? {
       return firstIndex(of: char)?.utf16Offset(in: self)
    }

    func substring(from: Int) -> String {
        let fromIndex = index(from: from)
        return String(self[fromIndex...])
    }

    func substring(_ from: Int,_ until: Int) -> String? {
        let fromIndex = index(from: from)
        let untilIndex = index(from: until)
        return String(self[fromIndex..<untilIndex])
    }
    
    func indexOf(_ char: Character, offsetBy:Int) -> Int? {
        return substring(from: offsetBy).firstIndex(of: char)?.utf16Offset(in: self)
    }
    
    var isDigits: Bool {
        let notDigits = NSCharacterSet.decimalDigits.inverted
        return rangeOfCharacter(from: notDigits, options: String.CompareOptions.literal, range: nil) == nil
    }
    
    var isLetters: Bool {
        let notLetters = NSCharacterSet.letters.inverted
        return rangeOfCharacter(from: notLetters, options: String.CompareOptions.literal, range: nil) == nil
    }
    
    var isAlphanumeric: Bool {
        let notAlphanumeric = NSCharacterSet.decimalDigits.union(NSCharacterSet.letters).inverted
        return rangeOfCharacter(from: notAlphanumeric, options: String.CompareOptions.literal, range: nil) == nil
    }

    func matches(_ expression: String) -> Bool {
        if let range = range(of: expression, options: .regularExpression, range: nil, locale: nil) {
            return range.lowerBound == startIndex && range.upperBound == endIndex
        } else {
            return false
        }
    }

    mutating func replaceRegex(_ pattern: String, replaceWith: String = "") -> Bool {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options.caseInsensitive)
            let range = NSMakeRange(0, self.count)
            self = regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: replaceWith)
            return true
        } catch {
            return false
        }
    }
    
}
