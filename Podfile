platform :ios, '15.0'
use_frameworks! :linkage => :static

target 'RainbowKingdom' do
  pod 'RealmSwift', '~> 20.0'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
      # 禁用代码签名以避免沙盒权限问题
      config.build_settings['CODE_SIGN_IDENTITY'] = ''
      config.build_settings['CODE_SIGNING_REQUIRED'] = 'NO'
    end
  end
end