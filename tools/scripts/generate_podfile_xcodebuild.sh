#!/bin/bash

set -euo pipefail
trap 'echo "❌ Failed to generate Podfile at line $LINENO"; exit 1' ERR

echo "📥 Parsing environment from \$CM_ENV"
while IFS='=' read -r key value; do
  key=$(echo "$key" | xargs)
  value=$(echo "$value" | sed -e 's/^"//' -e 's/"$//' | xargs)
  if [[ -n "$key" ]]; then
    export "$key=$value"
  fi
done < "$CM_ENV"

echo "✅ PROFILE_UUID=$PROFILE_UUID"
echo "✅ PROFILE_NAME=$PROFILE_NAME"
echo "✅ APPLE_TEAM_ID=$APPLE_TEAM_ID"
echo "✅ BUNDLE_ID=$BUNDLE_ID"

#!/bin/bash
echo "📥 Injecting Podfile for xcodebuild archive"

cat > ios/Podfile <<EOF
platform :ios, '13.0'
use_frameworks! :linkage => :static

ENV['COCOAPODS_DISABLE_STATS'] = 'true'

project 'Runner', {
  'Debug' => :debug,
  'Profile' => :release,
  'Release' => :release,
}

require File.expand_path(File.join('packages', 'flutter_tools', 'bin', 'podhelper'), File.expand_path('../Flutter', __FILE__))

flutter_ios_podfile_setup

target 'Runner' do
  use_frameworks!
  use_modular_headers!
  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
end

post_install do |installer|
  puts "✅ Configuring code signing for xcodebuild"

  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
      config.build_settings['ENABLE_BITCODE'] = 'NO'
      config.build_settings['ONLY_ACTIVE_ARCH'] = 'YES'

      if target.name == 'Runner'
        config.build_settings['CODE_SIGN_STYLE'] = 'Manual'
        config.build_settings['DEVELOPMENT_TEAM'] = '\${APPLE_TEAM_ID}'
        config.build_settings['PROVISIONING_PROFILE_SPECIFIER'] = '\${PROFILE_NAME}'
      else
        config.build_settings.delete('CODE_SIGN_STYLE')
        config.build_settings.delete('DEVELOPMENT_TEAM')
        config.build_settings.delete('PROVISIONING_PROFILE_SPECIFIER')
      end
    end
  end
end
EOF
echo "✅ Podfile generated successfully"
rm -rf ios/Pods ios/Podfile.lock
cd ios && pod install && cd ..



