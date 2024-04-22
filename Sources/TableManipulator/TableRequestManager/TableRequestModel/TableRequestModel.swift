import Foundation

public struct TableRequestModel {
    let pollingModel: TableRequestPollingModel?
    let resultModel: TableRequestResultModel
    var requestBody: [String: Any]? = nil
    var requestHeaders: [String: String]? = nil
}

public struct TableRequestPollingModel {
    let URL: URL
    var URLHttpMethod: String = "get"
    var timeout: Float = 60
    var requestsTimes: [Float]? = nil
    var requestEqualTime: Float? = nil
    var isPollingEqualTimes: Bool = false
    var shouldTryResultAfterTimeout: Bool = true
}

public struct TableRequestResultModel {
    let URL: URL
    var URLHttpMethod: String = "get"
    var timeout: Float = 60
}
