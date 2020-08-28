
class DateUtils {

    public static let utcTimeZone :TimeZone = TimeZone(secondsFromGMT: 0)!;

    public static func parseDate(dateTime:String) -> Date {
        let dateFormatter = DateFormatter()

        dateFormatter.timeZone = self.utcTimeZone
        dateFormatter.dateFormat = Definitions.DATE_FORMAT

        let date = dateFormatter.date(from: dateTime)!
        return date
    }

    public static func getUTCDate() -> String {
        let dateUtc = getUTCDateTime()
        let formatter = DateFormatter()
        formatter.dateFormat = Definitions.DATE_FORMAT
        
        return formatter.string(from:dateUtc)
    }

    public static func getUTCDateTime() -> Date {
        return Date();
    }
}
