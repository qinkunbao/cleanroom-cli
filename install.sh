#!/bin/sh

set -e

if [ -t 1 ]; then
  is_tty() {
    true
  }
else
  is_tty() {
    false
  }
fi

cleanroomcli_dir="$HOME/.cleanroomcli"
release_dir="/xlabfs/shared/teaclave-release"

command_exists() {
  command -v "$@" >/dev/null 2>&1
}


# Adapted from code and information by Anton Kochkov (@XVilka)
# Source: https://gist.github.com/XVilka/8346728
supports_truecolor() {
  case "$COLORTERM" in
  truecolor|24bit) return 0 ;;
  esac

  case "$TERM" in
  iterm           |\
  tmux-truecolor  |\
  linux-truecolor |\
  xterm-truecolor |\
  screen-truecolor) return 0 ;;
  esac

  return 1
}


setup_color() {
  # Only use colors if connected to a terminal
  if ! is_tty; then
    FMT_RAINBOW=""
    FMT_RED=""
    FMT_GREEN=""
    FMT_YELLOW=""
    FMT_BLUE=""
    FMT_BOLD=""
    FMT_RESET=""
    return
  fi

  if supports_truecolor; then
    FMT_RAINBOW="
      $(printf '\033[38;2;255;0;0m')
      $(printf '\033[38;2;255;97;0m')
      $(printf '\033[38;2;247;255;0m')
      $(printf '\033[38;2;0;255;30m')
      $(printf '\033[38;2;77;0;255m')
      $(printf '\033[38;2;168;0;255m')
      $(printf '\033[38;2;245;0;172m')
    "
  else
    FMT_RAINBOW="
      $(printf '\033[38;5;196m')
      $(printf '\033[38;5;202m')
      $(printf '\033[38;5;226m')
      $(printf '\033[38;5;082m')
      $(printf '\033[38;5;021m')
      $(printf '\033[38;5;093m')
      $(printf '\033[38;5;163m')
    "
  fi

  FMT_RED=$(printf '\033[31m')
  FMT_GREEN=$(printf '\033[32m')
  FMT_YELLOW=$(printf '\033[33m')
  FMT_BLUE=$(printf '\033[34m')
  FMT_BOLD=$(printf '\033[1m')
  FMT_RESET=$(printf '\033[0m')
}

download_cleanroomcli() {
    echo "${FMT_GREEN}Downloading P4cleanroom CLI...${FMT_RESET}"
    mkdir -p "$cleanroomcli_dir"

    current_dir="$PWD"
    if [ ! -d "$release_dir" ]; then
        echo "Cannot find cleanroom directory:${FMT_YELLOW}$release_dir ${FMT_RESET}..."
        exit 0
    fi

    release_tar_path=$(ls -t $release_dir/cleanroomcli_*.tgz | head -1)
    cd "$cleanroomcli_dir"
    cp "$release_tar_path" "$cleanroomcli_dir" && tar xf "$release_tar_path"

    if [ -d "$cleanroomcli_dir/conf" ]; then
        rm -rf "$cleanroomcli_dir/conf"
    fi
    cp -r cleanroomcli_*/conf "$cleanroomcli_dir" 

    if [! -d "$cleanroomcli_dir/data-owner" ]; then
        cp -r cleanroomcli_*/data-owner "$cleanroomcli_dir" 
    fi

    if [ -d "$cleanroomcli_dir/data-owner-manager" ]; then
        rm -rf "$cleanroomcli_dir/data-owner-manager"
    fi
    cp -r cleanroomcli_*/data-owner-manager "$cleanroomcli_dir" 

    if [ -d "$cleanroomcli_dir/sdk" ]; then
        rm -rf "$cleanroomcli_dir/sdk"
    fi
    cp -r cleanroomcli_*/sdk "$cleanroomcli_dir" 
    rm -f cleanroomcli_*.tgz

    cd "$current_dir"

}

setup_cleanroomcli() {
    echo "${FMT_GREEN}Setting up P4cleanroom CLI environments...${FMT_RESET}"
    echo "alias p4cleanroom=$cleanroomcli_dir/data-owner/cleanroom.py" >> ~/.bashrc
    echo "alias p4cleanroom-manager=$cleanroomcli_dir/data-owner-manager/user-manager.py" >> ~/.bashrc
    echo "alias p4cleanroom=\"$cleanroomcli_dir/data-owner/cleanroom.py\"" >> ~/.zshrc
    echo "alias p4cleanroom-manager=\"$cleanroomcli_dir/data-owner-manager/user-manager.py\"" >> ~/.zshrc
    
    if command_exists bash; then
      bash -c "source ~/.bashrc"
    fi

    if command_exists zsh; then
      zsh -c "source ~/.zshrc"
    fi
}


print_success() {
    echo "${FMT_GREEN}Setup P4cleanroom CLI successfully...${FMT_RESET}"
}

main() {
  setup_color
  
  if ! command_exists python3; then
    echo "${FMT_YELLOW}Python3 is not installed.${FMT_RESET} Please install python3 first."
    exit 1
  fi

  if ! command_exists pip3; then
    echo "${FMT_YELLOW}pip3 is not installed.${FMT_RESET} Please install pip3 first."
    exit 1
  fi
  
  if ! command_exists tar; then
    echo "${FMT_YELLOW}tar is not installed.${FMT_RESET} Please install tar first."
    exit 1
  fi
  pip3 install -q cryptography --upgrade cryptography
  pip3 install -q toml cryptography pyOpenSSL tabulate argcomplete
  download_cleanroomcli
  setup_cleanroomcli
  print_success

}


main "$@"
