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
echo "📥 Injecting Podfile for flutter build ios"

cat > ios/Podfile <<EOF
platform :ios, '13.0'
use_frameworks! :linkage => :static

ENV['COCOAPODS_DISABLE_STATS'] = 'true'

project 'Runner', {
  'Debug' => :debug,
  'Profile' => :release,
  'Release' => :release,
}

def flutter_root
  generated_xcode_build_settings_path = File.expand_path(File.join('..', 'Flutter', 'Generated.xcconfig'), __FILE__)
  unless File.exist?(generated_xcode_build_settings_path)
    raise "\#{generated_xcode_build_settings_path} must exist. Run flutter pub get first."
  end

  File.foreach(generated_xcode_build_settings_path) do |line|
    matches = line.match(/FLUTTER_ROOT=(.*)/)
    return matches[1].strip if matches
  end

  raise "FLUTTER_ROOT not found in Generated.xcconfig"
end

require File.expand_path(File.join('packages', 'flutter_tools', 'bin', 'podhelper'), flutter_root)

flutter_ios_podfile_setup

target 'Runner' do
  use_frameworks!
  use_modular_headers!
  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
end
EOF


echo "✅ Podfile generated successfully"
