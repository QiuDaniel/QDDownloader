//
//  QDDownloadManager.h
//  QDDownloader
//
//  Created by Daniel on 2018/5/19.
//  Copyright © 2018年 Daniel. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QDDownloadTask.h"

typedef NS_ENUM(NSUInteger, QDDownloadPriority) {
    QDDownloadPriorityHigh,
    QDDownloadPriorityLow
};

@class QDDownloadConfig;

@interface QDDownloadManager : NSObject

+ (instancetype)manager;

- (void)configureWithConfig:(QDDownloadConfig *)config;

- (NSUInteger)downloadWithUrl:(NSString *)strUrl progress:(QDProgress)progressBlock didFinished:(QDDidFinished)didFinishedBlock;

- (NSUInteger)downloadWithUrl:(NSString *)strUrl isZip:(BOOL)isZip progress:(QDProgress)progressBlock didFinished:(QDDidFinished)didFinishedBlock;

- (NSUInteger)downloadWithUrl:(NSString *)strUrl md5:(NSString *)md5 isZip:(BOOL)isZip progress:(QDProgress)progressBlock didFinished:(QDDidFinished)didFinishedBlock;

- (NSUInteger)downloadWithUrl:(NSString *)strUrl md5:(NSString *)md5 isZip:(BOOL)isZip priority:(QDDownloadPriority)priority progress:(QDProgress)progressBlock didFinished:(QDDidFinished)didFinishedBlock;

- (NSUInteger)downloadWithUrl:(NSString *)strUrl md5:(NSString *)md5 destFilePath:(NSString *)destFilePath isZip:(BOOL)isZip priority:(QDDownloadPriority)priority progress:(QDProgress)progressBlock didFinished:(QDDidFinished)didFinishedBlock;

- (void)pauseTask:(NSUInteger)taskId;

- (void)cancelTask:(NSUInteger)taskId;

/**
 下载任务是否正在执行
 @param taskId 下载任务id
 @return YES ／ NO
 */
- (BOOL)taskDownloading:(NSUInteger)taskId;

@end


@interface QDDownloadQueue : NSObject

@property (nonatomic, strong, readonly) NSMutableArray<QDDownloadTask *> *downloadQueue;

@end
