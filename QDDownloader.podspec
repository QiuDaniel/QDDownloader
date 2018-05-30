Pod::Spec.new do |s|
  s.name         = "QDDownloader"
  s.version      = "0.1.2"
  s.summary      = "Downloader depend on AFNetworking."

  s.homepage     = "https://github.com/QiuDaniel/QDDownloader"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { "qiudan" => "qiudan-098@163.com" }
  s.source       = { :git => "https://github.com/QiuDaniel/QDDownloader.git", :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'
  s.requires_arc = true

  s.source_files  = "QDDownloader/*.{h,m}", "QDDownloader/Core/*.{h,m}"
  s.dependency "AFNetworking"
  s.dependency "SSZipArchive"

end
