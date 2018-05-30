//
//  DownloadViewCell.h
//  Example
//
//  Created by Daniel on 2018/5/21.
//  Copyright © 2018年 Daniel. All rights reserved.
//

#import <UIKit/UIKit.h>

UIKIT_EXTERN NSString *const DownloadViewCellIdentifier;

@class DownloadModel;

@interface DownloadViewCell : UITableViewCell

@property (nonatomic, strong) DownloadModel *model;

@end
