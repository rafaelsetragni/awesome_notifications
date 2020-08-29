enum NotificationLayout : String, CaseIterable, AbstractEnum {
    
  case Default = "Default"
  case BigPicture = "BigPicture"
  case BigText = "BigText"
  case Inbox = "Inbox"
  case ProgressBar = "ProgressBar"
  case Messaging = "Messaging"
  case MediaPlayer = "MediaPlayer"
  
  static func fromString(_ value: String?) -> AbstractEnum? {
      if(value == nil) { return self.allCases[0] }
      return self.allCases.first{ "\($0)" == value }
  }
}

// pascualoto cnpj  - recovery grupo - Guilerme 0800-772-3331
