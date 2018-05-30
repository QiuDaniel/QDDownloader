//
//  QDDownloadConfig.h
//  QDDownloader
//
//  Created by Daniel on 2018/5/19.
//  Copyright © 2018年 Daniel. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QDDownloadConfig : NSObject


/**
 下载任务数量，默认4
 */
@property (nonatomic, assign) NSUInteger maxConcurrentDownloads;

/**
 超时时间，默认30秒
 */
@property (nonatomic, assign) NSTimeInterval timeoutInterval;

/**
 重复下载。即使下载任务已经下载过，设置了该属性后，仍将重新下载。默认为NO

 */
@property (nonatomic, assign) BOOL reDownload;

@property (nonatomic, strong, readonly) NSURLSessionConfiguration *configureation;


@end
