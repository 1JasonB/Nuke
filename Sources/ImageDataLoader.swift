// The MIT License (MIT)
//
// Copyright (c) 2016 Alexander Grebenyuk (github.com/kean).

import Foundation

// MARK: - ImageDataLoading

/// Data loading completion closure.
public typealias ImageDataLoadingCompletion = (_ data: Data?, _ response: URLResponse?, _ error: Error?) -> Void

/// Data loading progress closure.
public typealias ImageDataLoadingProgress = (_ completed: Int64, _ total: Int64) -> Void

/// Performs loading of image data.
public protocol ImageDataLoading {
    /// Creates task with a given request. Task is resumed by the object calling the method.
    func taskWith(_ request: ImageRequest, progress: @escaping ImageDataLoadingProgress, completion: @escaping ImageDataLoadingCompletion) -> URLSessionTask

    /// Invalidates the receiver.
    func invalidate()

    /// Clears the receiver's cache storage (in any).
    func removeAllCachedImages()
}


// MARK: - ImageDataLoader

/// Provides basic networking using NSURLSession.
open class ImageDataLoader: NSObject, URLSessionDataDelegate, ImageDataLoading {

    open fileprivate(set) var session: Foundation.URLSession!
    fileprivate var handlers = [URLSessionTask: DataTaskHandler]()
    fileprivate var lock = NSRecursiveLock()

    /// Initialzies data loader by creating a session with a given session configuration.
    public init(sessionConfiguration: URLSessionConfiguration) {
        super.init()
        self.session = Foundation.URLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: nil)
    }

    /// Initializes the receiver with a default NSURLSession configuration and NSURLCache with memory capacity set to 0, disk capacity set to 200 Mb.
    public convenience override init() {
        let conf = URLSessionConfiguration.default
        conf.urlCache = URLCache(memoryCapacity: 0, diskCapacity: (200 * 1024 * 1024), diskPath: "com.github.kean.nuke-cache")
        self.init(sessionConfiguration: conf)
    }
    
    // MARK: ImageDataLoading

    /// Creates task for the given request.
    open func taskWith(_ request: ImageRequest, progress: @escaping ImageDataLoadingProgress, completion: @escaping ImageDataLoadingCompletion) -> URLSessionTask {
        let task = taskWith(request)
        lock.lock()
        handlers[task] = DataTaskHandler(progress: progress, completion: completion)
        lock.unlock()
        return task
    }
    
    /// Factory method for creating session tasks for given image requests.
    open func taskWith(_ request: ImageRequest) -> URLSessionTask {
        return session.dataTask(with: request.URLRequest)
    }

    /// Invalidates the instance of NSURLSession class that the receiver was initialized with.
    open func invalidate() {
        session.invalidateAndCancel()
    }

    /// Removes all cached images from the instance of NSURLCache class from the NSURLSession configuration.
    open func removeAllCachedImages() {
        session.configuration.urlCache?.removeAllCachedResponses()
    }
    
    // MARK: NSURLSessionDataDelegate
    
    open func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        lock.lock()
        if let handler = handlers[dataTask] {
            handler.data.append(data)
            handler.progress(dataTask.countOfBytesReceived, dataTask.countOfBytesExpectedToReceive)
        }
        lock.unlock()
    }
    
    open func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        lock.lock()
        if let handler = handlers[task] {
            handler.completion(handler.data as Data, task.response, error)
            handlers[task] = nil
        }
        lock.unlock()
    }
}

private class DataTaskHandler {
    let data = NSMutableData()
    let progress: ImageDataLoadingProgress
    let completion: ImageDataLoadingCompletion
    
    init(progress: @escaping ImageDataLoadingProgress, completion: @escaping ImageDataLoadingCompletion) {
        self.progress = progress
        self.completion = completion
    }
}
