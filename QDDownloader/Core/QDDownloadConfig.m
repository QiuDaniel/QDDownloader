//
//  QDDownloadConfig.m
//  QDDownloader
//
//  Created by Daniel on 2018/5/19.
//  Copyright © 2018年 Daniel. All rights reserved.
//

#import "QDDownloadConfig.h"

@interface QDDownloadConfig ()

@property (nonatomic, strong, readwrite) NSURLSessionConfiguration *configuration;

@end

@implementation QDDownloadConfig

- (instancetype)init {
    if (self) {
        _reDownload = NO;
        _timeoutInterval = 30.0;
        _maxConcurrentDownloads = 4;
        _configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"com.qd.QDDownloader"];
        _configureation.timeoutIntervalForResource = _timeoutInterval;
    }
    return self;
}

- (void)setTimeoutInterval:(NSTimeInterval)timeoutInterval {
    _timeoutInterval = timeoutInterval;
    _configureation = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"com.qd.QDDownloader.ChangeTimeout"];
    _configuration.timeoutIntervalForResource = timeoutInterval;
}

@end
