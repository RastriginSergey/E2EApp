platform :ios, '10.2'

source "https://RastriginSergey:#{ENV['token']}@github.com/Vonage/PrivateCocoapodsSpecs"

CLIENT_VERSION = ENV['CLIENT_VERSION']

print "NEXMO client version is #{CLIENT_VERSION}"

target 'E2EApp' do
  pod 'NexmoClient', CLIENT_VERSION
end

target 'E2EAppUITests' do
  pod 'NexmoClient', CLIENT_VERSION
end
