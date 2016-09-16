// The MIT License (MIT)
//
// Copyright (c) 2016 Alexander Grebenyuk (github.com/kean).

import Foundation

/**
 The state of the task. Allowed transitions include:
 - Suspended -> [Running, Cancelled]
 - Running -> [Cancelled, Completed]
 - Cancelled -> []
 - Completed -> []
*/
public enum ImageTaskState {
    case suspended, running, cancelled, completed
}

/// ImageTask completion block, gets called when task is either completed or cancelled.
public typealias ImageTaskCompletion = (ImageResponse) -> Void

/// Represents image task progress.
public struct ImageTaskProgress {
    /// Completed unit count.
    public var completed: Int64 = 0
    
    /// Total unit count.
    public var total: Int64 = 0
    
    /// The fraction of overall work completed. If the total unit count is 0 fraction completed is also 0.
    public var fractionCompleted: Double {
        return total == 0 ? 0.0 : Double(completed) / Double(total)
    }
}

/// Abstract class for image tasks. Tasks are always part of the image manager, you create a task by calling one of the methods on ImageManager.
open class ImageTask: Hashable {
    
    // MARK: Obtainig General Task Information
    
    /// The request that task was created with.
    open let request: ImageRequest

    /// The response which is set when task is either completed or cancelled.
    open internal(set) var response: ImageResponse?

    /// Return hash value for the receiver.
    open var hashValue: Int { return identifier }
    
    /// Uniquely identifies the task within an image manager.
    open let identifier: Int
    
    
    // MARK: Configuring Task

    /// Initializes task with a given request and identifier.
    public init(request: ImageRequest, identifier: Int) {
        self.request = request
        self.identifier = identifier
    }
    
    /**
     Adds a closure to be called on the main thread when task is either completed or cancelled.
     
     The closure is called synchronously when the requested image can be retrieved from the memory cache and the request was made from the main thread.
     
     The closure is called even if it is added to the already completed or cancelled task.
     */
    open func completion(_ completion: @escaping ImageTaskCompletion) -> Self { fatalError("Abstract method") }
    
    
    // MARK: Obraining Task Progress
    
    /// Return current task progress. Initial value is (0, 0).
    open internal(set) var progress = ImageTaskProgress()
    
    /// A progress closure that gets periodically during the lifecycle of the task.
    open var progressHandler: ((_ progress: ImageTaskProgress) -> Void)?
    
    
    // MARK: Controlling Task State
    
    /// The current state of the task.
    open internal(set) var state: ImageTaskState = .suspended
    
    /// Resumes the task if suspended. Resume methods are nestable.
    open func resume() -> Self { fatalError("Abstract method") }
    
    /// Cancels the task if it hasn't completed yet. Calls a completion closure with an error value of { ImageManagerErrorDomain, ImageManagerErrorCancelled }.
    open func cancel() -> Self { fatalError("Abstract method") }
}

/// Compares two image tasks by reference.
public func ==(lhs: ImageTask, rhs: ImageTask) -> Bool {
    return lhs === rhs
}
