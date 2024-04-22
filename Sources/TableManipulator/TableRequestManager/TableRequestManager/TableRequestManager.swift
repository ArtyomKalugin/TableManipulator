import Foundation

/// Класс для работы с сетью
final public class TableRequestManager {
    
    // MARK: - Private properties
    
    private(set) var requestModel: TableRequestModel
    
    private var pollingStartTime = Date()
    private var pollingTimers: [Timer] = []
    
    init(requestModel: TableRequestModel) {
        self.requestModel = requestModel
    }
    
    // MARK: - Methods
    
    public func start<ResponseModelType: Decodable>(
        success: @escaping ((_ responseModel: ResponseModelType?) -> Void),
        failure: @escaping (NSError) -> Void
    ) {
        guard requestModel.pollingModel != nil else {
            startResult(success: success, failure: failure)
            return
        }
        
        startPolling(success: success, failure: failure)
    }
    
    public func stopPolling() {
        cancelPollingTimers()
    }
    
    public func makeResultRequestAfterPolling<ResponseModelType: Decodable>(
        success: @escaping ((_ responseModel: ResponseModelType?) -> Void),
        failure: @escaping (NSError) -> Void
    ) {
        startResult(success: success, failure: failure)
    }
    
    // MARK: - Private methods
    
    private func startPolling<ResponseModelType: Decodable>(
        success: @escaping ((_ responseModel: ResponseModelType?) -> Void),
        failure: @escaping (NSError) -> Void
    ) {
        guard let pollingModel = requestModel.pollingModel else {
            failure(.init(
                domain: "com.itis",
                code: .zero,
                userInfo: [NSLocalizedDescriptionKey: "Что-то пошло не так"]
            ))
            return
        }
        
        let completion: (Result<ResponseModelType, NSError>) -> Void = { [weak self] result in
            switch result {
            case .success(let response):
                success(response)
            case .failure(let error):
                self?.cancelPollingTimers()
                failure(error)
            }
        }
        
        pollingStartTime = Date()
        pollingTimers.append(makeTimer(
            delay: .zero,
            completion: completion
        ))
        
        if pollingModel.isPollingEqualTimes {
            guard let equalTime = pollingModel.requestEqualTime else {
                failure(.init(
                    domain: "com.itis",
                    code: .zero,
                    userInfo: [NSLocalizedDescriptionKey: "Что-то пошло не так"]
                ))
                return
            }
            
            var delay = equalTime
            let pollingCounts = Int(floor(pollingModel.timeout / equalTime)) - 1
            
            if pollingCounts > 1 {
                for _ in (0..<pollingCounts) {
                    pollingTimers.append(makeTimer(
                        delay: TimeInterval(delay),
                        completion: completion
                    ))
                    delay += equalTime
                }
            }
            
        } else {
            guard let times = pollingModel.requestsTimes else {
                failure(.init(
                    domain: "com.itis",
                    code: .zero,
                    userInfo: [NSLocalizedDescriptionKey: "Что-то пошло не так"]
                ))
                return
            }
            
            var delay: Float = .zero
            for time in times {
                delay += time
                pollingTimers.append(makeTimer(
                    delay: TimeInterval(delay),
                    completion: completion
                ))
            }
        }
    }
    
    private func startResult<ResponseModelType: Decodable>(
        success: @escaping ((_ responseModel: ResponseModelType?) -> Void),
        failure: @escaping (NSError) -> Void
    ) {
        let completion: (Result<ResponseModelType, NSError>) -> Void = { result in
            switch result {
            case .success(let response):
                success(response)
            case .failure(let error):
                failure(error)
            }
        }
        
        makeRequest(
            url: requestModel.resultModel.URL,
            httpMethod: requestModel.resultModel.URLHttpMethod,
            timeout: requestModel.resultModel.timeout,
            completion: completion
        )
    }
    
    private func makeRequest<ResponseModelType: Decodable>(
        url: URL?,
        httpMethod: String?,
        timeout: Float?,
        completion: @escaping (Result<ResponseModelType, NSError>) -> Void
        
    ) {
        guard let url = url,
              let timeout = timeout
        else {
            completion(.failure(.init(
                domain: "com.itis",
                code: .zero,
                userInfo: [NSLocalizedDescriptionKey: "Что-то пошло не так"]
            )))
            return
        }
        
        var request = URLRequest(
            url: url,
            cachePolicy: .useProtocolCachePolicy,
            timeoutInterval: TimeInterval(timeout)
        )
        request.httpMethod = httpMethod
        
        if let body = requestModel.requestBody {
            let bodyData = try? JSONSerialization.data(withJSONObject: body)
            request.httpBody = bodyData
        }
        
        if let headers = requestModel.requestHeaders {
            for header in headers {
                request.setValue(header.key, forHTTPHeaderField: header.value)
            }
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            var result: Result<ResponseModelType, NSError>
            
            defer {
                completion(result)
            }
            
            if let error {
                result = .failure(.init(
                    domain: "com.itis",
                    code: .zero,
                    userInfo: [NSLocalizedDescriptionKey: error.localizedDescription]
                ))
                return
            }
            
            guard let data = data, !data.isEmpty else {
                result = .failure(.init(
                    domain: "com.itis",
                    code: .zero,
                    userInfo: [NSLocalizedDescriptionKey: "Невалидные данные"]
                ))
                return
            }
            
            do {
                let responseObject = try JSONDecoder().decode(ResponseModelType.self, from: data)
                result = .success(responseObject)
            } catch let error as DecodingError {
                result = .failure(.init(
                    domain: "com.itis",
                    code: .zero,
                    userInfo: [NSLocalizedDescriptionKey: error.localizedDescription]
                ))
            } catch {
                result = .failure(.init(
                    domain: "com.itis",
                    code: .zero,
                    userInfo: [NSLocalizedDescriptionKey: "Что-то пошло не так"]
                ))
            }
        }
        
        task.resume()
    }
    
    private func makeTimer<ResponseModelType: Decodable>(
        delay: TimeInterval,
        repeats: Bool = false,
        completion: @escaping (Result<ResponseModelType, NSError>) -> Void
    ) -> Timer {
        return Timer.scheduledTimer(
            withTimeInterval: delay,
            repeats: repeats,
            block: { [weak self] timer in
                guard let self = self,
                      let pollingModel = requestModel.pollingModel
                else {
                    timer.invalidate()
                    return
                }
                
                let floatTime = Float(Calendar.current.dateComponents([.second], from: self.pollingStartTime, to: Date()).second ?? 60)
                if floatTime < pollingModel.timeout {
                    self.makeRequest(
                        url: pollingModel.URL,
                        httpMethod: pollingModel.URLHttpMethod,
                        timeout: pollingModel.timeout,
                        completion: completion
                    )
                } else {
                    cancelPollingTimers()
                    
                    if pollingModel.shouldTryResultAfterTimeout {
                        makeRequest(
                            url: self.requestModel.resultModel.URL,
                            httpMethod: self.requestModel.resultModel.URLHttpMethod,
                            timeout: self.requestModel.resultModel.timeout,
                            completion: completion
                        )
                    }
                }
                
                timer.invalidate()
            }
        )
    }
    
    private func cancelPollingTimers() {
        pollingTimers.forEach { $0.invalidate() }
    }
}
