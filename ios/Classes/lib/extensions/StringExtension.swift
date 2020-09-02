
extension String {
    
    public func charAt(_ pos:Int) -> Character {
        if(pos < 0 || pos >= count) { return Character("") }
        return Array(self)[pos]
    }
    
    public func index(from: Int) -> Index {
        return self.index(startIndex, offsetBy: from)
    }
    
    public func indexOf(_ char: Character) -> Int? {
       return firstIndex(of: char)?.utf16Offset(in: self)
    }

    public func substring(from: Int) -> String {
        let fromIndex = index(from: from)
        return String(self[fromIndex...])
    }

    public func substring(_ from: Int,_ until: Int) -> String? {
        let fromIndex = index(from: from)
        let untilIndex = index(from: until)
        return String(self[fromIndex..<untilIndex])
    }
    
    public func indexOf(_ char: Character, offsetBy:Int) -> Int? {
        return substring(from: offsetBy).firstIndex(of: char)?.utf16Offset(in: self)
    }
    
    public var isDigits: Bool {
        let notDigits = NSCharacterSet.decimalDigits.inverted
        return rangeOfCharacter(from: notDigits, options: String.CompareOptions.literal, range: nil) == nil
    }
    
    public var isLetters: Bool {
        let notLetters = NSCharacterSet.letters.inverted
        return rangeOfCharacter(from: notLetters, options: String.CompareOptions.literal, range: nil) == nil
    }
    
    public var isAlphanumeric: Bool {
        let notAlphanumeric = NSCharacterSet.decimalDigits.union(NSCharacterSet.letters).inverted
        return rangeOfCharacter(from: notAlphanumeric, options: String.CompareOptions.literal, range: nil) == nil
    }

    public func matches(_ expression: String) -> Bool {
        if let range = range(of: expression, options: .regularExpression, range: nil, locale: nil) {
            return range.lowerBound == startIndex && range.upperBound == endIndex
        } else {
            return false
        }
    }

    public mutating func replaceRegex(_ pattern: String, replaceWith: String = "") -> Bool {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options.caseInsensitive)
            let range = NSMakeRange(0, self.count)
            self = regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: replaceWith)
            return true
        } catch {
            return false
        }
    }

    func toDate(withFormat format: String = "yyyy-MM-dd HH:mm:ss", withFormat timeZone: TimeZone = TimeZone(abbreviation: "UTC")!)-> Date?{

        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = timeZone
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        dateFormatter.dateFormat = format
        let date = dateFormatter.date(from: self)

        return date
    }

    func split(regex pattern: String) -> [String] {

        guard let re = try? NSRegularExpression(pattern: pattern, options: [])
            else { return [] }

        let nsString = self as NSString // needed for range compatibility
        let stop = "<SomeStringThatYouDoNotExpectToOccurInSelf>"
        let modifiedString = re.stringByReplacingMatches(
            in: self,
            options: [],
            range: NSRange(location: 0, length: nsString.length),
            withTemplate: stop)
        return modifiedString.components(separatedBy: stop)
    }
    
}
