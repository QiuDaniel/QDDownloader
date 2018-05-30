//
//  DownloadModel.m
//  Example
//
//  Created by Daniel on 2018/5/21.
//  Copyright © 2018年 Daniel. All rights reserved.
//

#import "DownloadModel.h"
#import <QDDownloader/QDFileUtil.h>

@implementation DownloadModel

- (BOOL)isDownloaded {
    if (self.downloadUrl.length == 0) {
        return YES;
    }
    NSString *downloadPath = [self fileDirPath];
    BOOL isDic = NO;
    BOOL isExist = [[NSFileManager defaultManager] fileExistsAtPath:downloadPath isDirectory:&isDic];
    return isExist;
}


- (NSString *)fileDirPath {
    NSString *kDefualtSavePath = @"/Library/Caches/QDDownload/";
    NSString *md5String = [QDFileUtil md5StringFormString:self.downloadUrl];

    NSString *fileName;
    NSString *suffix = [QDFileUtil formatFormPath:self.downloadUrl];
    if ([suffix isEqualToString:@"zip"]) {
        fileName = [QDFileUtil fileNameFromStringPath:self.downloadUrl];
    } else {
        fileName = [NSString stringWithFormat:@"%@.%@", md5String, suffix];
    }

    NSString *savePath;
    if ([suffix isEqualToString:@"zip"]) {
        savePath = [NSString stringWithFormat:@"%@%@%@",NSHomeDirectory(), kDefualtSavePath, md5String];
        return savePath;
    } else {
        savePath = [NSString stringWithFormat:@"%@%@", NSHomeDirectory(), kDefualtSavePath];
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

@end
