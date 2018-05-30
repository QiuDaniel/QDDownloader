//
//  QDFileUtil.m
//  QDDownloader
//
//  Created by Daniel on 2018/5/19.
//  Copyright © 2018年 Daniel. All rights reserved.
//

#import "QDFileUtil.h"
#import <CommonCrypto/CommonDigest.h>
#import <UIKit/UIKit.h>

static NSString *const kIncompleteDownloadFolderName = @"Incomplete";

@implementation QDFileUtil

+ (NSFileManager *)fileManager {
    return [NSFileManager defaultManager];
}

+ (NSString *)md5StringFormString:(NSString *)string {
    NSParameterAssert(string != nil && [string length] > 0);
    const char *value = [string UTF8String];
    unsigned char outputBuffer[CC_MD5_DIGEST_LENGTH];
    CC_MD5(value, (CC_LONG)strlen(value), outputBuffer);

    NSMutableString *outputString = [[NSMutableString alloc] initWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(NSInteger count = 0; count < CC_MD5_DIGEST_LENGTH; count++){
        [outputString appendFormat:@"%02x",outputBuffer[count]];
    }
    return outputString;
}

+ (BOOL)createFileSavePath:(NSString *)savePath {
    BOOL  result = YES;
    if (savePath != nil && savePath.length > 0) {
        NSFileManager  * fm = [NSFileManager defaultManager];
        if (![fm fileExistsAtPath:savePath]) {
            __autoreleasing NSError *error = nil;
            [fm createDirectoryAtPath:savePath
          withIntermediateDirectories:YES
                           attributes:@{NSFileProtectionKey : NSFileProtectionNone}
                                error:&error];
            if (error) {
                result = NO;
            }
        }
    } else {
        result = NO;
    }
    return result;
}


+ (NSString *)formatFormPath:(NSString *)path {
    NSArray *strArr = [path componentsSeparatedByString:@"."];
    if (strArr && strArr.count > 0) {
        NSString *suffix = strArr.lastObject;
        return suffix;
    } else {
        return nil;
    }
}

+ (NSString *)fileNameFromStringPath:(NSString *)path {
    if (!path) {
        return @"";
    }
    return path.lastPathComponent;
}

+ (NSString *)fileNameWithoutExtension:(NSString *)path {
    NSString *fileName = @"";
    NSString *temp = [path lastPathComponent];
    fileName = [temp stringByDeletingPathExtension];
    return fileName;
}


+ (BOOL)isDirectoryFromPath:(NSString *)path {
    BOOL isDirectory = YES;
    if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory]) {
        isDirectory = NO;
    }
    return isDirectory;
}

+ (BOOL)deleteFile:(NSString *)filePath {
    BOOL result = NO;
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        result = [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
    }
    return result;
}

+ (NSArray *)enumerateTmpFileArrayFromPath:(NSString *)path {

    NSMutableArray *fileList = [NSMutableArray array];
    NSDirectoryEnumerator *directoryEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:path];
    //列举目录内容，可以遍历子目录
    NSString *tempPath;
    while((tempPath = [directoryEnumerator nextObject]) != nil) {
        if ([[self formatFormPath:tempPath] isEqualToString:@"tmp"] && [tempPath containsString:@"CFNetworkDownload"]) {
            [fileList addObject:[path stringByAppendingPathComponent:tempPath]];
        }
    }
    return fileList;
}

#pragma mark - Resumable Download

+ (NSString *)incompleteDownloadTempCacheFolder {
    NSFileManager *fileManager = [NSFileManager new];
    static NSString *cacheFolder;
    if (!cacheFolder) {
        NSString *cacheDir = NSTemporaryDirectory();
        cacheFolder = [cacheDir stringByAppendingPathComponent:kIncompleteDownloadFolderName];
    }
    NSError *error = nil;
    if(![fileManager createDirectoryAtPath:cacheFolder withIntermediateDirectories:YES attributes:nil error:&error]) {
        NSLog(@"Failed to create cache directory at %@", cacheFolder);
        cacheFolder = nil;
    }
    return cacheFolder;
}

+ (NSURL *)incompleteDownloadTempPathForDownloadPath:(NSString *)downloadPath {
    NSString *tempPath = nil;
    NSString *md5URLString = [self md5StringFormString:downloadPath];
    tempPath = [[self incompleteDownloadTempCacheFolder] stringByAppendingPathComponent:md5URLString];
    return [NSURL fileURLWithPath:tempPath];
}

+ (BOOL)validateResumeData:(NSData *)data {
    if (!data || [data length] < 1) return NO;

    NSError *error;
    NSDictionary *resumeDictionary = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable format:NULL error:&error];
    if (!resumeDictionary || error) return NO;

    // Before iOS 9
#if (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED < 90000)
    NSString *localFilePath = [resumeDictionary objectForKey:@"NSURLSessionResumeInfoLocalPath"];
    if ([localFilePath length] < 1) return NO;
    return [[NSFileManager defaultManager] fileExistsAtPath:localFilePath];
#endif
    // After iOS 9 we can not actually detects if the cache file exists. This plist file has a somehow
    // complicated structue. Besides, the plist structure is different between iOS 9 and iOS 10.
    // We can only assume that the plist being successfully parsed means the resume data is valid.
    if ([[UIDevice currentDevice] systemVersion].floatValue >= 10.0 && [[UIDevice currentDevice] systemVersion].floatValue < 10.3) {
        return NO;
    }
    return YES;
}


@end
