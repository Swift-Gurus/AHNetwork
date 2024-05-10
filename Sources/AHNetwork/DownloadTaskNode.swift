//
//  DownloadTaskNode.swift
//  AHFuture
//
//  Created by Esteban Garro on 2019-01-10.
//

import Foundation
import AHFunctionalSwift
@available(OSX 10.15, *)

class DownloadTaskNode: BasicTaskNode {
    var downloadAdapter: INetworkDownloadAdapter = AHNetworkResponseAdapter()
    var observation: NSKeyValueObservation?
    
    
    
    override func send(request: NetworkTaskRequest, completion: completionHandler?, progress: progressTracker?) -> ICancellable {
        guard case .download = request.type else {
            return super.send(request: request, completion: completion, progress: progress)
        }

        let task = session.downloadTask(with: request.urlRequest,
                                        completionHandler:{[weak self] (localURL, response, error) in
                                            guard let self = self else {  return }
            self.downloadAdapter.response(from: localURL, with: response, and: error)
                                 »  { completion?($0) }
            
        })
        
        task.resume()
        observation = task.observe(\.progress.fractionCompleted, options: .new) { (downloadTask, _) in
            progress?(downloadTask.progress.fractionCompleted)
        }
        return task
    }
}
