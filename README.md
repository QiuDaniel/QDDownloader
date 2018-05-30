# QDDownloader
Downloader depend on AFNetworking

## Installation

### CocoaPods

The preferred installation method is with [CocoaPods](http://cocoapods.org). Add the following to your Podfile:
```ruby
pod 'QDDownloader', '~> 0.1.2'
```
## Usage

### Creating an Download Task
```objective-c
NSUInteger taskId = [[QDDownloadManager manager] downloadWithUrl:downloadUrl progress:^(int64_t completedUnitCount, int64_t totalUnitCount) {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"prgress:%f", completedUnitCount / 1.0 / totalUnitCount);
    });
} didFinished:^(QDDidFinishedStatus status, NSString *filePath) {
    if (status == QDDidFinishedStatusSuceess) {
        NSLog(@"download success");
    } else {
        NSLog(@"download fail");
    }
}];
```
### Cancel Downloading Task
```objective-c
[[QDDownloadManager manager] cancelTask:taskId];
```
## License

QDDownloader is released under the MIT license. See [LICENSE](https://github.com/QiuDaniel/QDDownloader/blob/master/LICENSE) for details.

