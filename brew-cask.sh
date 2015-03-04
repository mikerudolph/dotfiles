# Install native apps
#
export HOMEBREW_CASK_OPTS="--appdir=/Applications --caskroom=/etc/Caskroom"

brew install caskroom/cask/brew-cask
brew tap caskroom/versions

# daily
brew cask install alfred
brew cask install divvy
brew cask install dropbox
brew cask install caffeine
brew cask install evernote
brew cask install fantastical

# dev
brew cask install iterm2
brew cask install sublime-text3
brew cask install imagealpha
brew cask install imageoptim
brew cask install dash
brew cask install sourcetree
brew cask install virtualbox

brew cask install hipchat
brew cask install slack

# fun
brew cask install limechat
brew cask install spotify

# browsers
brew cask install google-chrome
brew cask install google-chrome-canary
brew cask install firefox-nightly --force
brew cask install webkit-nightly --force
brew cask install chromium --force

# less often
brew cask install disk-inventory-x
brew cask install vlc
