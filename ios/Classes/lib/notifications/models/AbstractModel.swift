

protocol AbstractModel {

    func fromMap(arguments: [String : AnyObject?]) -> AbstractModel
    func toMap() -> [String : AnyObject?]

    func validate() throws
}
