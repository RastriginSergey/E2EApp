require 'dotenv'
Dotenv.load('config.env')

platform :ios, '10.2'

CLIENT_VERSION = ENV['CLIENT_VERSION']

print "NEXMO client version is #{CLIENT_VERSION}"

target 'E2EApp' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for E2EApp
  pod 'NexmoClient', CLIENT_VERSION, :source => "https://RastriginSergey:#{ENV['GITHUB_TOKEN']}@github.com/Vonage/PrivateCocoapodsSpecs"
  pod 'SwiftyJWT', '0.0.3'

  target 'E2EAppUITests' do
    # Pods for testing
  end

end
