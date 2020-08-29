

protocol AbstractModel {

    func fromMap(arguments: [String : Any?]?) -> AbstractModel
    func toMap() -> [String : Any?]

    func validate() throws
}
