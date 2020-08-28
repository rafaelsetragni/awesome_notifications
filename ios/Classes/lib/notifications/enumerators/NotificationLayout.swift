enum NotificationLayout : CaseIterable, AbstractEnum {
    
  static let Default = "Default"
  static let BigPicture = "BigPicture"
  static let BigText = "BigText"
  static let Inbox = "Inbox"
  static let ProgressBar = "ProgressBar"
  static let Messaging = "Messaging"
  static let MediaPlayer = "MediaPlayer"
  
  static func fromString(_ value: String?) -> AbstractEnum? {
      if(value == nil) { return self.allCases[0] }
      return self.allCases.first{ "\($0)" == value }
  }
}
