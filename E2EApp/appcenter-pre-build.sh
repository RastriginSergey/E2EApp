pip install pyjwt
pip install requests
pip install pygments

sudo gem install cocoapods

podVersion=`pod --version`

if [ ! $podVersion ]; then
    echo ERROR: Failed to install Cocoapods
    exit 1
fi

echo "Cocoapods version is:" $podVersion

pod install
