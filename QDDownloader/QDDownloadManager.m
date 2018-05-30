//
//  QDDownloadManager.m
//  QDDownloader
//
//  Created by Daniel on 2018/5/19.
//  Copyright © 2018年 Daniel. All rights reserved.
//

#import "QDDownloadManager.h"
#import "QDDownloadTask.h"
#import "QDDownloadConfig.h"
#import "QDFileUtil.h"
#import <UIKit/UIKit.h>


#if __has_include(<AFNetworking/AFNetworking.h>)
#import <AFNetworking/AFNetworking.h>
#else
#import "AFNetworking.h"
#endif

#ifdef DEBUG
#define DEBUG_NSLog(format, ...) NSLog(format, ##__VA_ARGS__)
#else
#define DEBUG_NSLog(format, ...)
#endif

#define DownloadQueue ([_queue mutableArrayValueForKeyPath:@"downloadQueue"])


@interface QDDownloadManager ()

@property (nonatomic, strong) QDDownloadConfig *config;
@property (nonatomic, strong) QDDownloadQueue *queue;
@property (nonatomic, assign, getter=isTerminate) BOOL terminate;
@property (nonatomic, assign, getter=isResume) BOOL resume;

@property (nonatomic, strong) AFURLSessionManager *manager;

@end

static NSString *const kDefualtSavePath = @"/Library/Caches/QDDownload/";
static NSString *const kQDDownloadTasks = @"QDDownloadTasks";
static NSString *const kDestFilePath = @"DestFilePath";
static long int kDefaultTimeDifference = 1728000; //默认20天

@implementation QDDownloadManager

- (void)dealloc {
    [_queue removeObserver:self forKeyPath:@"downloadQueue"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (instancetype)manager {
    static QDDownloadManager *_downloadManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _downloadManager = [[self alloc] init];
    });
    return _downloadManager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    _config = [[QDDownloadConfig alloc] init];
    [self setupWithConfig:_config];
    _queue = [[QDDownloadQueue alloc] init];
    [_queue addObserver:self forKeyPath:@"downloadQueue" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
    _terminate = [[[NSUserDefaults standardUserDefaults] objectForKey:@"isTerminate"] boolValue];
    _resume = NO;
    [self configureAppState];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self dealTmpFile];
    });
}

- (void)setupWithConfig:(QDDownloadConfig *)config {
    _manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:_config.configureation];
}

- (void)configureAppState {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate) name:UIApplicationWillTerminateNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(afnetworkTaskDidComplete:) name:AFNetworkingTaskDidCompleteNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(taskDidComplete) name:QDDownloadTaskDidCompleteNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(taskDidComplete) name:QDDownloadTaskDidTimeOutNotification object:nil];
}

#pragma mark - ResponseEvent

- (void)applicationWillTerminate {
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:@"isTerminate"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)afnetworkTaskDidComplete:(NSNotification *)notify {
    for (QDDownloadTask *task in _queue.downloadQueue) {
        if (task.state == NSURLSessionTaskStateCompleted && task.isCancel) {
            [DownloadQueue removeObject:task];
            break;
        }
    }

    NSString *savePath = [[NSUserDefaults standardUserDefaults] objectForKey:kDestFilePath];
    NSError *error = notify.userInfo[AFNetworkingTaskDidCompleteErrorKey];
    if (!error) {
        return;
    }
    NSString *downloadURL = error.userInfo[NSURLErrorFailingURLStringErrorKey];
    NSData *resumeData = error.userInfo[NSURLSessionDownloadTaskResumeData];
    if (resumeData) {
        NSError *error;
        NSDictionary *resumeDictionary = [NSPropertyListSerialization propertyListWithData:resumeData options:NSPropertyListImmutable format:NULL error:&error];
        if (resumeDictionary && self.isTerminate) {
            self.resume = YES;
            QDDownloadTask *task = [[QDDownloadTask alloc] init];
            task.destFilePath = savePath;
            task.strUrl = downloadURL;
            [_queue.downloadQueue addObject:task];
            for (QDDownloadTask *task in _queue.downloadQueue) {
                if ([resumeDictionary[@"NSURLSessionDownloadURL"] containsString:task.strUrl]) {
                    [resumeDictionary writeToURL:[QDFileUtil incompleteDownloadTempPathForDownloadPath:[task getDownloadTargetPath]] atomically:YES];
                }
            }
        }
    }
}

- (void)taskDidComplete {
    for (QDDownloadTask *task in _queue.downloadQueue) {
        if (task.state == NSURLSessionTaskStateCompleted) {
            [DownloadQueue removeObject:task];
            break;
        }
    }
}

#pragma mark - Public

- (void)configureWithConfig:(QDDownloadConfig *)config {
    _config = config;
    [self setupWithConfig:config];
}

- (NSUInteger)downloadWithUrl:(NSString *)strUrl progress:(QDProgress)progressBlock didFinished:(QDDidFinished)didFinishedBlock {
    BOOL isZip = NO;
    NSString *suffix = [QDFileUtil formatFormPath:strUrl];
    if ([suffix isEqualToString:@"zip"]) {
        isZip = YES;
    }
    return [self downloadWithUrl:strUrl isZip:isZip progress:progressBlock didFinished:didFinishedBlock];
}

- (NSUInteger)downloadWithUrl:(NSString *)strUrl isZip:(BOOL)isZip progress:(QDProgress)progressBlock didFinished:(QDDidFinished)didFinishedBlock {
    return [self downloadWithUrl:strUrl md5:nil isZip:isZip progress:progressBlock didFinished:didFinishedBlock];
}

- (NSUInteger)downloadWithUrl:(NSString *)strUrl md5:(NSString *)md5 isZip:(BOOL)isZip progress:(QDProgress)progressBlock didFinished:(QDDidFinished)didFinishedBlock {
    return [self downloadWithUrl:strUrl md5:md5 isZip:isZip priority:QDDownloadPriorityHigh progress:progressBlock didFinished:didFinishedBlock];
}

- (NSUInteger)downloadWithUrl:(NSString *)strUrl md5:(NSString *)md5 isZip:(BOOL)isZip priority:(QDDownloadPriority)priority progress:(QDProgress)progressBlock didFinished:(QDDidFinished)didFinishedBlock {
    return [self downloadWithUrl:strUrl md5:md5 destFilePath:nil isZip:isZip priority:priority progress:progressBlock didFinished:didFinishedBlock];
}

- (NSUInteger)downloadWithUrl:(NSString *)strUrl md5:(NSString *)md5 destFilePath:(NSString *)destFilePath isZip:(BOOL)isZip priority:(QDDownloadPriority)priority progress:(QDProgress)progressBlock didFinished:(QDDidFinished)didFinishedBlock {
    if (destFilePath.length > 0) {
        [[NSUserDefaults standardUserDefaults] setObject:destFilePath forKey:kDestFilePath];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }

    QDDownloadTask *downloadTask = [self getDownloadtaskByUrl:strUrl];
    if (downloadTask) {
        if (downloadTask.state == 0) {
            if (self.isResume) {
                downloadTask.strUrl = strUrl;
                downloadTask.md5 = md5;
                downloadTask.destFilePath = destFilePath;
                downloadTask.zip = isZip;
                downloadTask.manager = _manager;
                downloadTask.progressBlock = progressBlock;
                downloadTask.didFinishedBlock = didFinishedBlock;
                downloadTask.reDownload = self.config.reDownload;
                [downloadTask prepareDownload];
                self.resume = NO;
            }
        } else {
            !didFinishedBlock? : didFinishedBlock(QDDidFinishedStatusDownloading, nil);
        }
        return downloadTask.taskIdentifier;
    }

    QDDownloadTask *task = [[QDDownloadTask alloc] init];
    task.strUrl = strUrl;
    task.md5 = md5;
    task.destFilePath = destFilePath;
    task.zip = isZip;
    task.manager = self.manager;
    task.progressBlock = progressBlock;
    task.didFinishedBlock = didFinishedBlock;
    task.reDownload = self.config.reDownload;
    NSString *downloadTargetPath = [task getDownloadTargetPath];
    [QDFileUtil createFileSavePath:[downloadTargetPath stringByDeletingLastPathComponent]];
    [task prepareDownload];
    if (!task.isDownload) {
        switch (priority) {
            case QDDownloadPriorityLow:
                [DownloadQueue addObject:task];
                break;
            case QDDownloadPriorityHigh:
                [DownloadQueue insertObject:task atIndex:0];
                break;
            default:
                break;
        }
    }
    return task.taskIdentifier;
}

- (void)pauseTask:(NSUInteger)taskId {
    QDDownloadTask *task = [self getDownloadTaskById:taskId];
    if (task) {
        [task suspend];
    }
}

- (void)cancelTask:(NSUInteger)taskId {
    self.terminate = NO;
    QDDownloadTask *task = [self getDownloadTaskById:taskId];
    if (task) {
        [task cancel];
    }
}

- (BOOL)taskDownloading:(NSUInteger)taskId {
    QDDownloadTask *task = [self getDownloadTaskById:taskId];
    if (task) {
        return task.state == NSURLSessionTaskStateRunning;
    }
    return NO;
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"downloadQueue"]) {
        if (_queue.downloadQueue.count <= self.config.maxConcurrentDownloads) {
            for (QDDownloadTask *task in _queue.downloadQueue) {
                if (task.state == NSURLSessionTaskStateSuspended) {
                    [task resume];
                }
            }
        } else {
            QDDownloadTask *task = _queue.downloadQueue[self.config.maxConcurrentDownloads];
            if (task.state == NSURLSessionTaskStateRunning) {
                [task suspend];
            }
            for (int i = 0; i < self.config.maxConcurrentDownloads; i++) {
                if (_queue.downloadQueue[i].state == NSURLSessionTaskStateSuspended) {
                    [_queue.downloadQueue[i] resume];
                }

            }
        }
    }
}

#pragma mark - Private

- (void)dealTmpFile {
    NSArray *tempFileList = [QDFileUtil enumerateTmpFileArrayFromPath:NSTemporaryDirectory()];
    if (tempFileList && tempFileList.count > 0) {
        [tempFileList enumerateObjectsUsingBlock:^(NSString * _Nonnull path, NSUInteger idx, BOOL * _Nonnull stop) {
            NSError *error;
            NSDictionary *fileAttributes = [[QDFileUtil fileManager] attributesOfItemAtPath:path error:&error];
            if (fileAttributes) {
                NSDate *modificationDate = fileAttributes[NSFileModificationDate];
                NSDate *currentDate = [NSDate date];
                NSTimeInterval secondsInterval= [currentDate timeIntervalSinceDate:modificationDate];
                if (lround(secondsInterval) > kDefaultTimeDifference) {
                    [QDFileUtil deleteFile:path];
                }
            }
        }];
    }
}

- (QDDownloadTask *)getDownloadtaskByUrl:(NSString *)url {
    QDDownloadTask *downloadTask = nil;
    for (QDDownloadTask *task in _queue.downloadQueue) {
        if ([task.strUrl isEqualToString:url]) {
            downloadTask = task;
            break;
        }
    }
    return downloadTask;
}

- (QDDownloadTask *)getDownloadTaskById:(NSUInteger)taskId {
    QDDownloadTask *downloadTask = nil;
    for (QDDownloadTask *task in _queue.downloadQueue) {
        if (task.taskIdentifier == taskId) {
            downloadTask = task;
            break;
        }
    }
    return downloadTask;
}

@end


@interface QDDownloadQueue ()

@property (nonatomic, strong, readwrite) NSMutableArray<QDDownloadTask *> *downloadQueue;

@end

@implementation QDDownloadQueue

- (NSMutableArray<QDDownloadTask *> *)downloadQueue {
    if (!_downloadQueue) {
        _downloadQueue = [[NSMutableArray alloc] init];
    }
    return _downloadQueue;
}

@end
