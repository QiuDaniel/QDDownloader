//
//  DownloadViewCell.m
//  Example
//
//  Created by Daniel on 2018/5/21.
//  Copyright © 2018年 Daniel. All rights reserved.
//

#import "DownloadViewCell.h"
#import "DownloadModel.h"
#import <QDDownloader/QDDownloadManager.h>

NSString *const DownloadViewCellIdentifier = @"DownloadViewCell";

@interface DownloadViewCell ()

@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UIButton *downloadBtn;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;

@end

@implementation DownloadViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
}

#pragma mark - ResponseEvent

- (IBAction)downloadBtnClicked:(UIButton *)sender {
    if (self.model.isDownloaded) {
        return;
    }
    if (self.model.isDownloading) {
        [[QDDownloadManager manager] cancelTask:self.model.taskId];
        return;
    }
    [self.downloadBtn setTitle:@"取消" forState:UIControlStateNormal];
    NSUInteger taskId = [[QDDownloadManager manager] downloadWithUrl:self.model.downloadUrl progress:^(int64_t completedUnitCount, int64_t totalUnitCount) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.progressView.progress = completedUnitCount / 1.0 / totalUnitCount;
            NSLog(@"prgress:%f", completedUnitCount / 1.0 / totalUnitCount);
        });
    } didFinished:^(QDDidFinishedStatus status, NSString *filePath) {
        if (status == QDDidFinishedStatusSuceess) {
            [self.downloadBtn setTitle:@"已下载" forState:UIControlStateNormal];
        } else {
            NSLog(@"下载失败");
            self.progressView.progress = 0;
            [self.downloadBtn setTitle:@"重试" forState:UIControlStateNormal];
        }
    }];
    self.model.taskId = taskId;
}

#pragma mark - Private

- (NSString *)getNameFromUrl:(NSString *)url {
    return url.lastPathComponent;
}

#pragma mark - Setter

- (void)setModel:(DownloadModel *)model {
    _model = model;
    NSString *downloadBtnName = @"下载";
    if (self.model.isDownloaded) {
        downloadBtnName = @"已下载";
        self.progressView.progress = 1.0;
    } else {
        if ([[QDDownloadManager manager] taskDownloading:model.taskId]) {
            downloadBtnName = @"下载中";
            _model.downloading = YES;
        }
    }
    [self.downloadBtn setTitle:downloadBtnName forState:UIControlStateNormal];
    self.nameLabel.text = [self getNameFromUrl:model.downloadUrl];

}


@end
