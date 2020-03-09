require 'dotenv'
Dotenv.load('config.env')

platform :ios, '10.2'

source "https //github.com/cocoapods/specs.git"
source "https://RastriginSergey:#{ENV['GITHUB_TOKEN']}@github.com/Vonage/PrivateCocoapodsSpecs"

CLIENT_VERSION = ENV['CLIENT_VERSION']

print "NEXMO client version is #{CLIENT_VERSION}"

target 'E2EApp' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for E2EApp
  pod 'NexmoClient', CLIENT_VERSION
  pod 'SwiftyJWT', '0.0.3'

  target 'E2EAppUITests' do
    # Pods for testing
  end

end


# target 'E2EApp' do
#   pod 'NexmoClient', CLIENT_VERSION
# end

# target 'E2EAppUITests' do
#   pod 'NexmoClient', CLIENT_VERSION
# end
