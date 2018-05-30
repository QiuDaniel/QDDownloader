//
//  QDDownloadTask.h
//  QDDownloader
//
//  Created by Daniel on 2018/5/19.
//  Copyright © 2018年 Daniel. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString *const QDDownloadTaskDidCompleteNotification;
FOUNDATION_EXPORT NSString *const QDDownloadTaskDidTimeOutNotification;

/**
 下载任务结束原因状态

 - QDDidFinishedStatusSuceess: 下载任务成功
 - QDDidFinishedStatusCancel: 下载任务取消
 - QDDidFinishedStatusFault: 下载任务发生错误
 - QDDidFinishedStatusTimeOut: 下载任务超时
 - QDDidFinishedStatusDownloading： 已经有相同的下载任务正在下载中
 */

typedef NS_ENUM(NSUInteger, QDDidFinishedStatus) {
    QDDidFinishedStatusSuceess = 0,
    QDDidFinishedStatusCancel,
    QDDidFinishedStatusFault,
    QDDidFinishedStatusTimeOut,
    QDDidFinishedStatusDownloading,
};

/**
下载进度回调

@param completedUnitCount 已经下载的数据
@param totalUnitCount 总数据
*/
typedef void(^QDProgress)(int64_t completedUnitCount, int64_t totalUnitCount);

/**
 下载任务结束回调

 @param status 下载任务结束原因状态
 @param filePath 下载内容存放地址
 */
typedef void(^QDDidFinished)(QDDidFinishedStatus status, NSString *filePath);

@class AFURLSessionManager;

@interface QDDownloadTask : NSObject <NSCoding>

@property (nonatomic, copy, readonly) NSString *key;
@property (nonatomic, readonly) NSUInteger taskIdentifier;
@property (nonatomic, readonly) NSURLSessionTaskState state;

@property (nonatomic, copy) QDProgress progressBlock;
@property (nonatomic, copy) QDDidFinished didFinishedBlock;

@property (nonatomic, strong) AFURLSessionManager *manager;
@property (nonatomic, copy) NSString *strUrl;
@property (nonatomic, copy) NSString *md5;
@property (nonatomic, copy) NSString *destFilePath;
@property (nonatomic, assign) BOOL reDownload;
@property (nonatomic, assign, getter=isZip) BOOL zip;
@property (nonatomic, assign, getter=isDownload) BOOL download;
@property (nonatomic, assign, readonly, getter=isCancel) BOOL cancel;


- (void)prepareDownload;
- (void)resume;
- (void)cancel;
- (void)suspend;

- (NSString *)getDownloadTargetPath;

@end
