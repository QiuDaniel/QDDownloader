//
//  ViewController.m
//  Example
//
//  Created by Daniel on 2018/5/21.
//  Copyright © 2018年 Daniel. All rights reserved.
//

#import "ViewController.h"
#import "DownloadViewCell.h"
#import "DownloadModel.h"

#define kDefaultDownloadUrlZip   (@"https://github.com/QiuDaniel/QDDownloader/archive/master.zip")
#define kDefaultErrorUrl (@"http://download.oracle.com/otn-pub/java/jdk/8u111-b14-demos/jdk-8u111-windows-x64-demos.zip")
#define kDefaultDownloadUrlOther (@"http://dlsw.baidu.com/sw-search-sp/soft/9d/25765/sogou_mac_32c_V3.2.0.1437101586.dmg")

@interface ViewController () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *dataArray;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    for (NSInteger i = 0; i < 3; i++) {
        DownloadModel *model = [[DownloadModel alloc] init];
        if ( i == 0) {
            model.downloadUrl = kDefaultDownloadUrlZip;
        } else if ( i == 1) {
            model.downloadUrl = kDefaultDownloadUrlOther;
        } else if (i == 2) {
            model.downloadUrl = kDefaultErrorUrl;
        }

        [self.dataArray addObject:model];
    }
    [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    DownloadViewCell *cell = [tableView dequeueReusableCellWithIdentifier:DownloadViewCellIdentifier forIndexPath:indexPath];
    cell.model = self.dataArray[indexPath.row];
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 70;
}

#pragma mark - Getter

- (NSMutableArray *)dataArray {
    if (!_dataArray) {
        _dataArray = [NSMutableArray array];
    }
    return _dataArray;
}


@end
