#!/usr/bin/env zsh

#
set -e

#
#
#

log() {
  local timestamp
  local level
  local message
  local colour

  timestamp=$(date "+%Y-%m-%d %T")
  level=$(echo "${1}" | tr "[:lower:] [:upper:]")
  message="${2}"
  colour="\e[96m"

  case "${level}" in
    OK | SUCCESS | DONE )
      colour="\e[92m" ;;
    ERROR | FAILED | FATAL )
      colour="\e[91m" ;;
    WARNING )
      colour="\e[93m" ;;
  esac

  echo -e "${timestamp} ${colour}${level}:\e[0m ${message}"
}

abort() {
  log fatal "$@"
  exit 1
}

#
#
#

#
function install-files {
  local from to copy=(
    #
    ".curlrc"       "${HOME}/.curlrc"
    ".dockerignore" "${HOME}/.dockerignore"
    ".editorconfig" "${HOME}/.editorconfig"
    ".gitconfig"    "${HOME}/.gitconfig"
    ".gitignore"    "${HOME}/.gitignore"
    ".inputrc"      "${HOME}/.inputrc"
    ".nvmrc"        "${HOME}/.nvmrc"
    ".screenrc"     "${HOME}/.screenrc"
    ".tmux.conf"    "${HOME}/.tmux.conf"
    ".wgetrc"       "${HOME}/.wgetrc"
    ".zfunctions"   "${HOME}/.zfunctions"
    ".zprofile"     "${HOME}/.zprofile"
    ".zshrc"        "${HOME}/.zshrc"
    #
    ".gnupg"        "${HOME}/.gnupg"
    ".ssh"          "${HOME}/.ssh"
    ".vscode"       "${HOME}/.vscode"
  )

  local mkdir=(
    "${HOME}/go/{bin,pkg,src}"
    "${HOME}/bin"    
    "${HOME}/Projects"    
  )

  local touch=(
    "${HOME}/.hushlogin"
  )

  local path mask recurse chmod=(
    "${HOME}/.gnupg"   700 1
    "${HOME}/.gnupg/*" 600 1
  )

  local path owner group recurse chown=(
    "${HOME}/.gnupg" "$(whoami)" "$(id -gn)" 1
  )

  for from to recurse in $copy; do
    rsync -avz --progress "$(pwd)/${from}" "${to}"
  done

  for path in $mkdir; do
    mkdir -p "${path}"
  done

  for path in $touch; do
    touch "${path}"
  done

  for path mask recurse in $chmod; do
    if [[ "${recurse}" -eq 1 ]]; then
      chmod -R "${mask}" "${path}"
    else
      chmod "${mask}" "${path}"
    fi
  done

  for path owner group recurse in $chown; do
    if [[ "${recurse}" -eq 1 ]]; then
      chown -R "${owner}:${group}" "${path}"
    else
      chown "${owner}:${group}" "${path}"
    fi
  done

  #
  chflags hidden "${HOME}/bin"
}

#
function install-command-line-tools {
  if ! [[ -e "/Library/Developer/CommandLineTools/usr/bin/git" ]]; then
    CLI_TOOLS_PLACEHOLDER="/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress"
    sudo touch "$CLI_TOOLS_PLACEHOLDER"

    CLI_TOOLS_LABEL=$(softwareupdate -l | grep -B 1 -E 'Command Line Tools' | awk -F'*' '/^ *\\*/ {print $2}' | sed -e 's/^ *Label: //' -e 's/^ *//' | sort -V | tail -n1 | sed 's/ *$//')
    if [[ -n "$CLI_TOOLS_LABEL" ]]; then
      sudo softwareupdate -i "$CLI_TOOLS_LABEL"
      sudo rm -f "$CLI_TOOLS_PLACEHOLDER"
      sudo xcode-select --switch /Library/Developer/CommandLineTools
    fi
  fi
}

#
function install-shell {
  if [[ ! -d "${HOME}/.oh-my-zsh" ]]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc

    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${HOME}/.oh-my-zsh/custom/themes/powerlevel10k"
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "${HOME}/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
    git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "${HOME}/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"

    for font in ( "MesloLGS NF Regular" "MesloLGS NF Bold" "MesloLGS NF Italic" "MesloLGS NF Bold Italic" ); do
      curl -fsSL -o "${HOME}/Library/Fonts/$font.ttf" "https://github.com/romkatv/powerlevel10k-media/raw/master/${font// /%20}ttf"
    done
  fi
}

#
function install-homebrew {
  exists_but_not_writable() {
    [[ -e "$1" ]] && ! [[ -r "$1" && -w "$1" && -x "$1" ]]
  }

  user_only_chmod() {
    [[ -d "$1" ]] && [[ "$(stat -f "%A" "$1")" != 75[0145] ]]
  }

  file_not_owned() {
    [[ "$(stat -f "%u" "$1")" != "$(id -u)" ]]
  }

  file_not_grpowned() {
    [[ " $(id -G "$USER") " != *" $(stat -f "%g" "$1") "* ]]
  }

  local HOMEBREW_PREFIX="/opt/homebrew"
  local HOMEBREW_REPOSITORY="${HOMEBREW_PREFIX}"
  local HOMEBREW_CORE="${HOMEBREW_PREFIX}/Library/Taps/homebrew/homebrew-core"
  local HOMEBREW_CACHE="${HOME}/Library/Caches/Homebrew"
  
  if [[ -e "${HOMEBREW_PREFIX}/bin/brew" ]]; then
    return 0
  fi

  install-command-line-tools

  local directories=(
    bin etc include lib sbin share opt var
    Frameworks
    etc/bash_completion.d lib/pkgconfig
    share/aclocal share/doc share/info share/locale share/man
    share/man/man1 share/man/man2 share/man/man3 share/man/man4
    share/man/man5 share/man/man6 share/man/man7 share/man/man8
    var/log var/homebrew var/homebrew/linked
    bin/brew
  )

  group_chmods=()
  for dir in "${directories[@]}"; do
    if exists_but_not_writable "${HOMEBREW_PREFIX}/${dir}"; then
      group_chmods+=("${HOMEBREW_PREFIX}/${dir}")
    fi
  done

  directories=(
    share/zsh share/zsh/site-functions
  )

  zsh_dirs=()
  for dir in "${directories[@]}"; do
    zsh_dirs+=("${HOMEBREW_PREFIX}/${dir}")
  done

  directories=(
    bin etc include lib sbin share var opt
    share/zsh share/zsh/site-functions
    var/homebrew var/homebrew/linked
    Cellar Caskroom Frameworks
  )
  
  mkdirs=()
  for dir in "${directories[@]}"; do
    if ! [[ -d "${HOMEBREW_PREFIX}/${dir}" ]]; then
      mkdirs+=("${HOMEBREW_PREFIX}/${dir}")
    fi
  done

  user_chmods=()
  mkdirs_user_only=()
  if [[ "${#zsh_dirs[@]}" -gt 0 ]]; then
    for dir in "${zsh_dirs[@]}"; do
      if [[ ! -d "${dir}" ]]; then
        mkdirs_user_only+=("${dir}")
      elif user_only_chmod "${dir}"; then
        user_chmods+=("${dir}")
      fi
    done
  fi

  chmods=()
  if [[ "${#group_chmods[@]}" -gt 0 ]]; then
    chmods+=("${group_chmods[@]}")
  fi
  if [[ "${#user_chmods[@]}" -gt 0 ]]; then
    chmods+=("${user_chmods[@]}")
  fi

  chowns=()
  chgrps=()
  if [[ "${#chmods[@]}" -gt 0 ]]; then
    for dir in "${chmods[@]}"; do
      if file_not_owned "${dir}"; then
        chowns+=("${dir}")
      fi
      if file_not_grpowned "${dir}"; then
        chgrps+=("${dir}")
      fi
    done
  fi

  if [[ -d "${HOMEBREW_PREFIX}" ]]; then
    if [[ "${#chmods[@]}" -gt 0 ]]; then
      sudo chmod u+rwx "${chmods[@]}"
    fi
    if [[ "${#group_chmods[@]}" -gt 0 ]]; then
      sudo chmod g+rwx "${group_chmods[@]}"
    fi
    if [[ "${#user_chmods[@]}" -gt 0 ]]; then
      sudo chmod g-w,o-w "${user_chmods[@]}"
    fi
    if [[ "${#chowns[@]}" -gt 0 ]]; then
      sudo chown "$USER" "${chowns[@]}"
    fi
    if [[ "${#chgrps[@]}" -gt 0 ]]; then
      sudo chgrp admin "${chgrps[@]}"
    fi
  else
    sudo mkdir -p "${HOMEBREW_PREFIX}"
    sudo chown "$USER:admin" "${HOMEBREW_PREFIX}"
  fi

  if [[ "${#mkdirs[@]}" -gt 0 ]]; then
    sudo mkdir -p "${mkdirs[@]}"
    sudo chmod u=rwx,g=rwx "${mkdirs[@]}"
    if [[ "${#mkdirs_user_only[@]}" -gt 0 ]]; then
      sudo chmod g-w,o-w "${mkdirs_user_only[@]}"
    fi
    sudo chown "$USER" "${mkdirs[@]}"
    sudo chgrp admin "${mkdirs[@]}"
  fi

  if ! [[ -d "${HOMEBREW_REPOSITORY}" ]]; then
    sudo mkdir -p "${HOMEBREW_REPOSITORY}"
  fi
  sudo chown -R "$USER:admin" "${HOMEBREW_REPOSITORY}"

  if ! [[ -d "${HOMEBREW_CACHE}" ]]; then
    if [[ -z "${HOMEBREW_ON_LINUX-}" ]]; then
      sudo mkdir -p "${HOMEBREW_CACHE}"
    else
      mkdir -p "${HOMEBREW_CACHE}"
    fi
  fi
  if exists_but_not_writable "${HOMEBREW_CACHE}"; then
    sudo chmod g+rwx "${HOMEBREW_CACHE}"
  fi
  if file_not_owned "${HOMEBREW_CACHE}"; then
    sudo chown -R "$USER" "${HOMEBREW_CACHE}"
  fi
  if file_not_grpowned "${HOMEBREW_CACHE}"; then
    sudo chgrp -R admin "${HOMEBREW_CACHE}"
  fi
  if [[ -d "${HOMEBREW_CACHE}" ]]; then
    touch "${HOMEBREW_CACHE}/.cleaned"
  fi

  (
    cd "${HOMEBREW_REPOSITORY}" >/dev/null || return

    git init -q

    git config remote.origin.url https://github.com/Homebrew/brew
    git config remote.origin.fetch +refs/heads/*:refs/remotes/origin/*

    git config core.autocrlf false

    git fetch --force origin
    git fetch --force --tags origin

    git reset --hard origin/master

    if [[ "${HOMEBREW_REPOSITORY}" != "${HOMEBREW_PREFIX}" ]]; then
      ln -sf "${HOMEBREW_REPOSITORY}/bin/brew" "${HOMEBREW_PREFIX}/bin/brew"
    fi

    if [[ ! -d "${HOMEBREW_CORE}" ]]; then
      (
        mkdir -p "${HOMEBREW_CORE}"

        cd "${HOMEBREW_CORE}" >/dev/null || return

        git init -q

        git config remote.origin.url https://github.com/Homebrew/homebrew-core
        git config remote.origin.fetch +refs/heads/*:refs/remotes/origin/*

        git config core.autocrlf false

        git fetch --force origin refs/heads/master:refs/remotes/origin/master

        git remote set-head origin --auto >/dev/null

        git reset --hard origin/master

        cd "${HOMEBREW_REPOSITORY}" >/dev/null || return
      ) || exit 1

      "${HOMEBREW_PREFIX}/bin/brew" update --force --quiet
      "${HOMEBREW_PREFIX}/bin/brew" analytics off --quiet
    fi
  ) || exit 1
}

#
function install-packages {
  #
  local tap=(
    "homebrew/core"
    "homebrew/cask"
    "homebrew/cask-fonts"
    "homebrew/services"
  )

  #
  local brew=(
    #
    "ansible"
    "aria2"
    "bazel"
    "composer"
    "displayplacer"
    "ffmpeg"
    "git-secret"
    "gnupg"
    "go"
    "llvm"
    "mas"
    "php"
    "protobuf"
    "pyenv"
    "tree"
    "vagrant"
    "wget"
    #
    "ncurses"
    "pinentry-mac"
    "pinentry"
    "readline"
    "rtmpdump"
    "sqlite3"
    "xz"
    "zlib"
    #
    "bash"
    "curl"
    "git"
    "openssl"
    "zsh"
  )

  #
  local cask=(
    #
    "font-fira-code"
    #
    "adobe-creative-cloud"
    "jetbrains-toolbox"
    "tableplus"
    "parallels"
    #
    "dropbox"
    "spotify"
    "tunnelbear"
    #
    "adoptopenjdk"
    "appcleaner"
    "discord"
    "docker"
    "firefox"
    "google-chrome"
    "iina"
    "iterm2"
    "messenger"
    "notion"
    "postman"
    "telegram"
    "the-unarchiver"
    "transmission"
    "visual-studio-code"
    "vnc-server"
    "vnc-viewer"
    "zoom"
  )

  #
  local mas=(
    # Keynote
    "409183694"  
    # Pages
    "409201541"  
    # Numbers
    "409203825"  
    # Xcode
    "497799835"  
    # GarageBand
    "682658836"  
    # 1Password 7
    "1333542190" 
    # Magnet
    "441258766"  
    # Amphetamine
    "937984704"  
    # ColorSnapper 2
    "969418666"  
  )

  #
  local pip=(
    "pip"
    "yt-dlp"
  )

  #
  local npm=(
    "yarn"
  )

  #
  local composer=(
    "friendsofphp/php-cs-fixer"
  )

  #
  local go=(
    "google.golang.org/protobuf/cmd/protoc-gen-go@v1.26"
    "google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.1"
  )

  for t in $tap; do
    brew tap $t
  done

  brew update
  brew upgrade

  for b in $brew; do
    brew reinstall $b
  done

  for c in $cask; do
    brew reinstall --cask $c
  done

  brew cleanup

  authenticate-mas

  for m in $mas; do
    mas install $m
  done

  for p in $pip; do
    python -m pip install --upgrade $p
  done

  install-node

  for n in $npm; do
    npm install -g $n
  done

  for c in $composer; do
    composer global require $c
  done

  for g in $go; do
    go install $g
  done

  install-shell
  install-node
}

#
function authenticate-mas {
  if ! mas account >/dev/null; then
    log warning "Please sign in to the Mac App Store with your Apple ID before continuing."

    osascript -e 'tell app "App Store"' -e 'activate' -e 'end'

    until mas account >/dev/null; do
      sleep 1
    done
  fi

  return 0
}

#
function install-node {
  local nvm_version="v0.38.0"

  git clone https://github.com/nvm-sh/nvm.git ${HOME}/.nvm
  git --git-dir ${HOME}/.nvm/.git checkout "${nvm_version}"

  nvm install
}

#
function configure-packages {
  local python_version="3.9.6"

  pyenv install "${python_version}"
  pyenv global "${python_version}"

  configure-vagrant
  configure-gpg

  defaults write com.google.Chrome DisablePrintPreview -bool true
  defaults write com.google.Chrome PMPrintingExpandedStateForPrint2 -bool true

  defaults write org.m0k.transmission UseIncompleteDownloadFolder -bool true
  defaults write org.m0k.transmission IncompleteDownloadFolder -string "${HOME}/Documents/Torrents"
  defaults write org.m0k.transmission DownloadLocationConstant -bool true
  defaults write org.m0k.transmission DownloadAsk -bool false
  defaults write org.m0k.transmission MagnetOpenAsk -bool false
  defaults write org.m0k.transmission WarningDonate -bool false
  defaults write org.m0k.transmission WarningLegal -bool false
  defaults write org.m0k.transmission BlocklistNew -bool true
  defaults write org.m0k.transmission BlocklistURL -string "https://mirror.codebucket.de/transmission/blocklist.p2p.gz"
  defaults write org.m0k.transmission BlocklistAutoUpdate -bool true
  defaults write org.m0k.transmission RandomPort -bool true
}

#
function configure-vagrant {
  vagrant plugin install vagrant-parallels
}

#
function configure-gpg {
  unset SSH_AGENT_PID
  if [ "${gnupg_SSH_AUTH_SOCK_by:-0}" -ne $$ ]; then
    export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
  fi
  export GPG_TTY=$(tty)
  gpg-connect-agent updatestartuptty /bye >/dev/null

  #
  gpg --import < .gpg
}

#
function configure-system {
  configure-terminal

  # Disable startup chime
  sudo nvram SystemAudioVolume=" "

  # Enable tap to click
  defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
  defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
  defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

  # Enable force feedback and haptics
  defaults write NSGlobalDomain com.apple.trackpad.forceClick -bool true
  defaults write com.apple.AppleMultitouchTrackpad ForceSuppressed -bool false
  defaults write com.apple.AppleMultitouchTrackpad ActuateDetents -bool true
  # Enable silent click
  defaults write com.apple.AppleMultitouchTrackpad ActuationStrength -int 0
  # Haptic feedback strength
  defaults write com.apple.AppleMultitouchTrackpad FirstClickThreshold -int 1
  defaults write com.apple.AppleMultitouchTrackpad SecondClickThreshold -int 1

  # Disable automatic input correction
  defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
  defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
  defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
  defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
  defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

  # Expand save panels and dialogs
  defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
  defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true

  # Expand print panels and dialogs
  defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
  defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

  # Disable saving new documents to cloud
  defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

  # Enable instant dialogs
  defaults write NSGlobalDomain NSWindowResizeTime -float 0.001
  # Disable window animations
  defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false

  # Enable full keyboard access for all controls
  defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

  # Configure languages, units and locale
  defaults write NSGlobalDomain AppleLanguages -array "en"
  defaults write NSGlobalDomain AppleLocale -string "en_GB@currency=GBP"
  defaults write NSGlobalDomain AppleMeasurementUnits -string "Centimeters"
  defaults write NSGlobalDomain AppleMetricUnits -bool true

  # Enable subpixel font rendering
  defaults write NSGlobalDomain AppleFontSmoothing -int 2

  # Quit the print queue when finished
  defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true

  # Improve Bluetooth 
  defaults write com.apple.BluetoothAudioAgent "Apple Bitpool Min (editable)" -int 40

  # Set timezone
  sudo systemsetup -settimezone "Europe/London" > /dev/null

  # Enable automatic restart on failure
  sudo pmset -a autorestart 1

  # Save screenshots to desktop
  defaults write com.apple.screencapture location -string "${HOME}/Desktop"
  # Save screenshots as PNG files
  defaults write com.apple.screencapture type -string "png"
  # Remove shadows from screenshots
  defaults write com.apple.screencapture disable-shadow -bool true

  # Enable HiDPI mode
  sudo defaults write /Library/Preferences/com.apple.windowserver DisplayResolutionEnabled -bool true

  # Use /Applications as default directory
  defaults write com.apple.finder NewWindowTarget -string "PfLo"
  defaults write com.apple.finder NewWindowTargetPath -string "file:///Applications/"
  # Use current directory as default search scope
  defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
  # Expand info panes by default
  defaults write com.apple.finder FXInfoPanesExpanded -dict General -bool true OpenWith -bool true Privileges -bool true
  # Disable Finder window animations
  defaults write com.apple.finder DisableAllAnimations -bool true
  # Enable folders on top when sorting by name
  defaults write com.apple.finder _FXSortFoldersFirst -bool true

  # Prevent writing .DS_Store files to network shares and USB storage
  defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
  defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

  # Skip verification of disk images
  defaults write com.apple.frameworks.diskimages skip-verify -bool true
  defaults write com.apple.frameworks.diskimages skip-verify-locked -bool true
  defaults write com.apple.frameworks.diskimages skip-verify-remote -bool true

  # Clear the dock
  defaults write com.apple.dock persistent-apps -array
  # Disable application launch animations
  defaults write com.apple.dock launchanim -bool false
  defaults write com.apple.dock expose-animation-duration -float 0.1
  # Disable recents in dock
  defaults write com.apple.dock show-recents -bool false

  # Disable dashboard
  defaults write com.apple.Dashboard mcx-disabled -boolean true

  # Enable using all network interfaces for AirDrop
  defaults write com.apple.NetworkBrowser BrowseAllInterfaces -bool true

  # Prevent indexing of external volumes
  sudo defaults write /.Spotlight-V100/VolumeConfiguration Exclusions -array "/Volumes"
  killall mds > /dev/null 2>&1
  sudo mdutil -i on / > /dev/null
  sudo mdutil -E / > /dev/null

  # Disable Quick Look animations
  defaults write -g QLPanelAnimationDuration -float 0

  # Disable automatic opening of Photos
  defaults -currentHost write com.apple.ImageCapture disableHotPlug -bool true

  # Disable automatic opening of safe downloads
  defaults write com.apple.Safari AutoOpenSafeDownloads -bool false
  # Disable sidebar in top sites page
  defaults write com.apple.Safari ShowSidebarInTopSites -bool false
  # Enable internal debug menu
  defaults write com.apple.Safari IncludeInternalDebugMenu -bool true
  # Remove extra links from bookmarks bar
  defaults write com.apple.Safari ProxiesInBookmarksBar "()"
  # Enable developer menu
  defaults write com.apple.Safari IncludeDevelopMenu -bool true
  # Enable inspector in all webviews
  defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
  # Disable local file restrictions
  defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true
  # Enable developer extras globally
  defaults write NSGlobalDomain WebKitDeveloperExtras -bool true
  # Disable automatic spelling correction
  defaults write com.apple.Safari WebAutomaticSpellingCorrectionEnabled -bool false

  # Prevent offering new disks for backup
  defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

  # Disable animations in mail
  defaults write com.apple.mail DisableReplyAnimations -bool true
  defaults write com.apple.mail DisableSendAnimations -bool true

  # Sort Activity Monitor by CPU Usage
  defaults write com.apple.ActivityMonitor OpenMainWindow -bool true
  defaults write com.apple.ActivityMonitor ShowCategory -int 0
  defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
  defaults write com.apple.ActivityMonitor SortDirection -int 0

  # Edit plain text by default in TextEdit
  defaults write com.apple.TextEdit RichText -int 0
  defaults write com.apple.TextEdit PlainTextEncoding -int 4
  defaults write com.apple.TextEdit PlainTextEncodingForWrite -int 4

  # Enable advanced image options for Disk Utility
  defaults write com.apple.DiskUtility advanced-image-options -bool true

  # Automatically start playing media on open
  defaults write com.apple.QuickTimePlayerX MGPlayMovieOnOpen -bool true

  # Configure display resolution and position
  displayplacer "id:2AA9593B-3FF0-6D4C-3D19-FC1626C9B248 res:2560x1440 hz:60 color_depth:7 scaling:on origin:(0,0) degree:0" "id:2AA9593B-3FF0-6D4C-0857-D6964E3302DB res:2560x1440 hz:60 color_depth:7 scaling:on origin:(2560,0) degree:0"
}

#
function configure-terminal {
  local k t v settings=(
    '"Normal Font"'                                 string '"MesloLGS-NF-Regular '13'"'
    '"Terminal Type"'                               string '"xterm-256color"'
    '"Horizontal Spacing"'                          real   1
    '"Vertical Spacing"'                            real   1
    '"Minimum Contrast"'                            real   0
    '"Use Bold Font"'                               bool   1
    '"Use Bright Bold"'                             bool   1
    '"Use Italic Font"'                             bool   1
    '"ASCII Anti Aliased"'                          bool   1
    '"Non-ASCII Anti Aliased"'                      bool   1
    '"Use Non-ASCII Font"'                          bool   0
    '"Ambiguous Double Width"'                      bool   0
    '"Draw Powerline Glyphs"'                       bool   1
    '"Only The Default BG Color Uses Transparency"' bool   1
  )

  for k t v in $settings; do
    /usr/libexec/PlistBuddy -c "Set :\"New Bookmarks\":0:$k $v" ${HOME}/Library/Preferences/com.googlecode.iterm2.plist 2>/dev/null && continue
    /usr/libexec/PlistBuddy -c "Add :\"New Bookmarks\":0:$k $t $v" ${HOME}/Library/Preferences/com.googlecode.iterm2.plist
  done

  defaults write com.googlecode.iterm2 PromptOnQuit -bool false
}

#
#
#

if [ -z "${ZSH_VERSION:-}" ]; then
  abort "Zsh is required to interpret this script."
fi

ARCH="$(uname -p)"
OS="$(uname -s)"

if [[ "$OS" != "Darwin" ]]; then
  abort "This script is only supported on MacOS."
fi

if [[ "$ARCH" != "arm" ]]; then
  abort "This script is only supported on Apple M1."
fi

if sudo -v && sudo -n -l mkdir &>/dev/null; [ "$?" -eq 1 ]; then
  abort "Sudo access is required to execute this script."
fi

install-files
install-homebrew
install-packages
configure-packages
configure-system

if ! /usr/bin/sudo -n -v 2>/dev/null; then
  trap '/usr/bin/sudo -k' EXIT
fi