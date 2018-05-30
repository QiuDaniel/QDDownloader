//
//  QDFileUtil.h
//  QDDownloader
//
//  Created by Daniel on 2018/5/19.
//  Copyright © 2018年 Daniel. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QDFileUtil : NSObject

+ (NSFileManager *)fileManager;
+ (NSString *)md5StringFormString:(NSString *)string;
+ (BOOL)createFileSavePath:(NSString *)savePath;
+ (NSString *)formatFormPath:(NSString *)path;
+ (NSString *)fileNameFromStringPath:(NSString *)path;
+ (NSString *)fileNameWithoutExtension:(NSString *)path;
+ (BOOL)isDirectoryFromPath:(NSString *)path;
+ (BOOL)deleteFile:(NSString *)filePath;
+ (NSArray *)enumerateTmpFileArrayFromPath:(NSString *)path;

+ (NSString *)incompleteDownloadTempCacheFolder;
+ (NSURL *)incompleteDownloadTempPathForDownloadPath:(NSString *)downloadPath;
+ (BOOL)validateResumeData:(NSData *)data;

@end
