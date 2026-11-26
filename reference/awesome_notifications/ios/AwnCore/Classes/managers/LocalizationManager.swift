//
//  LocalizationManager.swift
//  IosAwnCore
//
//  Created by Rafael Setragni on 18/02/23.
//

import Foundation

class LocalizationManager {
    static let shared = LocalizationManager()
    
    func setLocalization(languageCode: String? = nil) -> Bool {
        let langCode =
            languageCode ??
            Locale.preferredLanguages[0]
        
        switch SQLitePrimitivesDB.shared.setString(
            tag: "localization",
            key: "languageCode",
            value: langCode
                .lowercased()
                .replacingOccurrences(of: "_", with: "-")
        ) {
        case .success():
            return true
        case .failure(let error):
            let awnError = ExceptionFactory.shared.createNewAwesomeException(
                className: "LocalizationManager",
                code: ExceptionCode.CODE_INSUFFICIENT_PERMISSIONS,
                message: "SQLitePrimitivesDB is not available \(error.localizedDescription)",
                detailedCode: ExceptionCode.DETAILED_INSUFFICIENT_PERMISSIONS+".setLocalization"
            )
            print(awnError)
            return false
        }
    }
    
    func getLocalization() -> String {
        let appLangCode = Locale.preferredLanguages[0]
        
        switch SQLitePrimitivesDB.shared.getString(
            tag: "localization",
            key: "languageCode"
        ) {
            
        case .success(let value):
            return (value ?? appLangCode)
                .lowercased()
                .replacingOccurrences(of: "_", with: "-")
            
        case .failure(let error):
            let error = ExceptionFactory.shared.createNewAwesomeException(
                className: "LocalizationManager",
                code: ExceptionCode.CODE_INSUFFICIENT_PERMISSIONS,
                message: "SQLitePrimitivesDB is not available \(error.localizedDescription)",
                detailedCode: ExceptionCode.DETAILED_INSUFFICIENT_PERMISSIONS+".getLocalization"
            )
            print(error)
            return appLangCode
                .lowercased()
                .replacingOccurrences(of: "_", with: "-")
        }
    }
}
