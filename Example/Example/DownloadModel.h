//
//  DownloadModel.h
//  Example
//
//  Created by Daniel on 2018/5/21.
//  Copyright © 2018年 Daniel. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DownloadModel : NSObject

@property (nonatomic, assign) NSUInteger taskId;
@property (nonatomic, assign, getter=isDownloading) BOOL downloading;
@property (nonatomic, copy) NSString *downloadUrl;
@property (nonatomic, copy) NSString *destPath;
@property (nonatomic, assign) NSInteger tag;


- (BOOL)isDownloaded;
@end
