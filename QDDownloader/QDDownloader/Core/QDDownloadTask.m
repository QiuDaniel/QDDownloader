//
//  QDDownloadTask.m
//  QDDownloader
//
//  Created by Daniel on 2018/5/19.
//  Copyright © 2018年 Daniel. All rights reserved.
//

#import "QDDownloadTask.h"
#import "QDFileUtil.h"
#import "QDGCDUtils.h"

#if __has_include(<ZipArchive/ZipArchive.h>)
#import <ZipArchive/ZipArchive.h>
#else
#import "ZipArchive.h"
#endif

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

@interface QDDownloadTask ()

@property (nonatomic, strong) NSURLSessionDownloadTask *downloadTask;
@property (nonatomic, assign, readwrite, getter=isCancel) BOOL cancel;
@property (nonatomic, readwrite) NSUInteger taskIdentifier;


@end

NSString *const QDDownloadTaskDidCompleteNotification = @"com.qd.download.task.complete";
NSString *const QDDownloadTaskDidTimeOutNotification = @"com.qd.download.task.timeout";

static NSString *const kDefualtSavePath = @"/Library/Caches/QDDownload/";

@implementation QDDownloadTask

- (instancetype)init {
    self = [super init];
    if (self) {
        _taskIdentifier = 0;
        _download = NO;
        _reDownload = NO;
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.strUrl forKey:@"strUrl"];
    [aCoder encodeObject:self.md5 forKey:@"md5"];
    [aCoder encodeObject:self.destFilePath forKey:@"destFilePath"];
    [aCoder encodeObject:[NSNumber numberWithBool:self.isZip] forKey:@"zip"];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        self.strUrl = [aDecoder decodeObjectForKey:@"strUrl"];
        self.md5 = [aDecoder decodeObjectForKey:@"md5"];
        self.destFilePath = [aDecoder decodeObjectForKey:@"destFilePath"];
        self.zip = [[aDecoder decodeObjectForKey:@"zip"] boolValue];
    }
    return self;
}

#pragma mark - Public

- (void)prepareDownload {
    NSString *downloadTargetPath = [self getDownloadTargetPath];
    if (self.reDownload) {
        self.download = NO;
        NSString *targetPath = downloadTargetPath;
        if ([downloadTargetPath containsString:@".zip"]) {
            targetPath = [downloadTargetPath stringByDeletingPathExtension];
        }
        [QDFileUtil deleteFile:targetPath];
        [self downloadWithProgress:self.progressBlock didFinished:self.didFinishedBlock];
        return;
    }

    if ([[QDFileUtil fileManager] fileExistsAtPath:downloadTargetPath]) {
        if ([downloadTargetPath containsString:@".zip"]) {
            dispatch_global_async(^{
                [self unzipFileAtPath:downloadTargetPath toDestination:[downloadTargetPath stringByDeletingPathExtension] didFinished:self.didFinishedBlock];
            });
        } else {
            !self.didFinishedBlock? :self.didFinishedBlock(QDDidFinishedStatusSuceess, downloadTargetPath);
        }
        self.download = YES;
    } else {
        if ([QDFileUtil isDirectoryFromPath:[downloadTargetPath stringByDeletingPathExtension]]) {
            !self.didFinishedBlock? : self.didFinishedBlock(QDDidFinishedStatusSuceess, [downloadTargetPath stringByDeletingPathExtension]);
        } else {
            [self downloadWithProgress:self.progressBlock didFinished:self.didFinishedBlock];
        }
    }
}

- (void)resume {
    [_downloadTask resume];
}

- (void)cancel {
    _cancel = YES;
    [_downloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {

    }];
}

- (void)suspend {
    [_downloadTask suspend];
}

- (NSString *)getDownloadTargetPath {
    NSString *md5String;
    if (!self.md5 || self.md5.length == 0) {
        md5String = [QDFileUtil md5StringFormString:self.strUrl];
    } else {
        md5String = [self.md5 copy];
    }
    NSString *fileName;
    NSString *suffix = [QDFileUtil formatFormPath:self.strUrl];
    if (self.isZip) {
        fileName = [QDFileUtil fileNameFromStringPath:self.strUrl];
    } else {
        fileName = [NSString stringWithFormat:@"%@.%@", md5String, suffix];
    }

    NSString *savePath;
    if (!self.destFilePath || self.destFilePath.length == 0) {
        if (self.isZip) {
            savePath = [NSString stringWithFormat:@"%@%@%@",NSHomeDirectory(), kDefualtSavePath, md5String];
        } else {
            savePath = [NSString stringWithFormat:@"%@%@", NSHomeDirectory(), kDefualtSavePath];
        }
    } else {
        savePath = [NSString stringWithFormat:@"%@%@",NSHomeDirectory(),self.destFilePath];
    }
    // If targetPath is a directory, use the file name we got from the url or md5String.
    // Make sure downloadTargetPath is always a file, not directory.
    NSString *downloadTargetPath;
    if ([[savePath substringFromIndex:savePath.length - 1] isEqualToString:@"/"]) {
        downloadTargetPath = [NSString stringWithFormat:@"%@%@",savePath, fileName];
    } else {
        downloadTargetPath = [NSString stringWithFormat:@"%@/%@",savePath, fileName];
    }
    return downloadTargetPath;
}

#pragma mark - Download

- (void)downloadWithProgress:(QDProgress)progressBlock didFinished:(QDDidFinished)didFinishedBlock {
    NSURL *URL = [NSURL URLWithString:self.strUrl];
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:URL];
    NSString *path = [self getDownloadTargetPath];
    BOOL resumeDataFileExists = [[NSFileManager defaultManager] fileExistsAtPath:[QDFileUtil incompleteDownloadTempPathForDownloadPath:path].path];
    NSData *data = [NSData dataWithContentsOfURL:[QDFileUtil incompleteDownloadTempPathForDownloadPath:path]];
    BOOL resumeDataIsValid = [QDFileUtil validateResumeData:data];
    BOOL canBeResumed = resumeDataFileExists && resumeDataIsValid;
    BOOL resumeSucceeded = NO;
    if (canBeResumed) {
        __weak typeof(self)weakSelf = self;
        @try {
            _downloadTask = [self.manager downloadTaskWithResumeData:data
                                                            progress:^(NSProgress * _Nonnull downloadProgress) {
                                                                progressBlock(downloadProgress.completedUnitCount, downloadProgress.totalUnitCount);

                                                            }
                                                         destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
                                                             return [NSURL fileURLWithPath:path isDirectory:NO];
                                                         }
                                                   completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
                                                       __strong typeof(weakSelf)strongSelf = weakSelf;
                                                       [strongSelf requestDidWithError:error incompleteTempPath:[QDFileUtil incompleteDownloadTempPathForDownloadPath:path] filePath:filePath.path didFinished:didFinishedBlock];
                                                   }];
            resumeSucceeded = YES;

        } @catch (NSException *exception) {
            DEBUG_NSLog(@"Resume download failed, reason = %@",exception.reason);
            resumeSucceeded = NO;
        }
    }

    if (!resumeSucceeded) {
        __weak typeof(self)weakSelf = self;
        _downloadTask = [self.manager downloadTaskWithRequest:urlRequest
                                                     progress:^(NSProgress * _Nonnull downloadProgress) {
                                                         progressBlock(downloadProgress.completedUnitCount, downloadProgress.totalUnitCount);

                                                     }
                                                  destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
                                                      return [NSURL fileURLWithPath:path isDirectory:NO];
                                                  }
                                            completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
                                                __strong typeof(weakSelf)strongSelf = weakSelf;
                                                [strongSelf requestDidWithError:error incompleteTempPath:[QDFileUtil incompleteDownloadTempPathForDownloadPath:path] filePath:filePath.path didFinished:didFinishedBlock];
                                            }];

    }
    self.taskIdentifier = _downloadTask.taskIdentifier;
}

#pragma mark - Unzip

- (void)unzipFileAtPath:(NSString *)path toDestination:(NSString *)destination didFinished:(QDDidFinished)didFinishedBlock {
    [SSZipArchive unzipFileAtPath:path toDestination:destination progressHandler:nil completionHandler:^(NSString * _Nonnull path, BOOL succeeded, NSError * _Nonnull error) {
        if (succeeded) {
            dispatch_main_async_safe(^{
                if (didFinishedBlock) {
                    didFinishedBlock(QDDidFinishedStatusSuceess, [path stringByDeletingPathExtension]);
                }
                [[NSNotificationCenter defaultCenter] postNotificationName:QDDownloadTaskDidCompleteNotification object:nil];
            });
            [QDFileUtil deleteFile:path];
        }
    }];
}

#pragma mark - HandleError

- (void)requestDidWithError:(NSError *)error incompleteTempPath:(NSURL *)tempPath filePath:(NSString *)filePath didFinished:(QDDidFinished)didFinishedBlock {
    if (error) {
        NSData *resumeData = error.userInfo[NSURLSessionDownloadTaskResumeData];
        if (resumeData) {
            [resumeData writeToURL:tempPath atomically:YES];
        }
        dispatch_main_async_safe(^{
            if (didFinishedBlock) {
                if (self.isCancel) {
                    didFinishedBlock(QDDidFinishedStatusCancel, filePath);
                } else {
                    if (error.code == -1001) {
                        didFinishedBlock(QDDidFinishedStatusTimeOut, filePath);
                        [[NSNotificationCenter defaultCenter] postNotificationName:QDDownloadTaskDidTimeOutNotification object:nil];
                    } else {
                        didFinishedBlock(QDDidFinishedStatusFault, filePath);
                        [[NSNotificationCenter defaultCenter] postNotificationName:QDDownloadTaskDidCompleteNotification object:nil];
                    }
                }
            }
        });
    } else {
        if (self.isZip) {
            dispatch_global_async(^{
                [self unzipFileAtPath:filePath toDestination:[filePath stringByDeletingPathExtension] didFinished:didFinishedBlock];
            });
        } else {
            dispatch_main_async_safe(^{
                if (didFinishedBlock) {
                    didFinishedBlock(QDDidFinishedStatusSuceess, filePath);
                }
                [[NSNotificationCenter defaultCenter] postNotificationName:QDDownloadTaskDidCompleteNotification object:nil];
            });
            [QDFileUtil deleteFile:tempPath.path];
        }
    }
}

#pragma mark - Getter

- (NSString *)key {
    return [QDFileUtil md5StringFormString:[self getDownloadTargetPath]];
}

- (NSURLSessionTaskState)state {
    return _downloadTask.state;
}

@end
