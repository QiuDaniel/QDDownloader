//
//  QDGCDUtils.h
//  QDDownloader
//
//  Created by Daniel on 2018/5/19.
//  Copyright © 2018年 Daniel. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QDGCDUtils : NSObject

void dispatch_main_async_safe(dispatch_block_t block);
void dispatch_main_sync_safe(dispatch_block_t block);
void dispatch_after_duration(double duration, dispatch_block_t block);
void dispatch_global_async(dispatch_block_t block);

@end
