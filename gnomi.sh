#!/bin/bash
set -e

script_version="0.1"
script_name="gnomi"

function usage ()
{
    echo "Usage :  $0 [options]

    Options:
    -h|help       Display this message
    -v|version    Display script version
    -p|programs   Set a .csv file to install programs from
    -d|dotfiles   Set a repository to install dotfiles from"
}

#-----------------------------------------------------------------------
#  Handle command line arguments
#-----------------------------------------------------------------------

while getopts ":p:d:h:v" opt; do
  case ${opt} in

    h) usage; exit 0 ;;
    v) echo "$0 $script_version"; exit 0 ;;
    d) dotfiles=${OPTARG} && git ls-remote "$dotfiles" || exit 1 ;;
    p) prgrmsfile=${OPTARGS} ;;
    ?) echo -e "\nOption does not exist : ($OPTARG)\n"; usage && exit 1 ;;

  esac
done

[ -z "$dotfilesrepo" ] && dotfilesrepo="https://github.com/vagos/.dotfiles.git"
[ -z "$prgrmsfile"   ] && prgrmsfile="https://raw.githubusercontent.com/vagos/gnomi/main/programs.csv"
aurhelper="yay"

#-----------------------------------------------------------------------
#  Utility functions
#-----------------------------------------------------------------------

installpkg() { pacman --noconfirm --needed -S "$1" &> /dev/null; }

error() { printf "%s\n" "$1" >&2; exit 1; }

welcome() 
{
  clear
  printf "Welcome!\n"
  printf "This is the %s installer script!\nEnjoy the installation!\n\n-Vagos Lamprou\n\n\n" "$script_name"
}

basicinstall()
{
  echo "Installing the bare basics first..."
  for pkg in curl base-devel git zsh; do
    echo "Installing $pkg"
    installpkg $pkg
  done
}

refreshkeyrings()
{
  echo "Refreshing Arch Keyring"
  installpkg archlinux-keyring
  pacman -Syy
}

gitinstall()
{
   error "Not implemented."
}

aurhelperinstall()
{
  sudo -u "$name" "$aurhelper" -S --noconfirm "$1" 
  pacman -Qqm | grep -q "^$1$" && error "Failed to intall AUR package: $1"
}

pipinstall()
{
  [ -x "$(command -v "pip")" ] || installpkg "python-pip" 
  yes | pip install "$1"
}

manualinstall()
{
  sudo -u "$name" mkdir -p "$srcdir"
  sudo -u "$name" git clone --depth 1 "https://aur.archlinux.org/$1.git" "$srcdir/$1"
  cd "$srcdir/$1"

  sudo -u "$name" -D "$srcdir/$1" makepkg --noconfirm -si || return 1
}

installprograms() # Install all the programs located in the programs file
{
  ( [ -f "$prgrmsfile" ] &&  sed "/^#/d" < "$prgrmsfile" > /tmp/programs.csv ) || curl -sL "$prgrmsfile" | sed "/^#/d" > /tmp/programs.csv
  nprgrms=$(wc -l < /tmp/programs.csv) # number of programs to install

  while IFS=, read -r tag program comment; do
    n=$((n+1))

    echo Installing: "$program": "$comment" "($n of $nprgrms)"

    case "$tag" in 
      "P") pipinstall "$program" ;;
      *) aurhelperinstall "$program"   ;;
    esac

  done < /tmp/programs.csv
}

installdotfiles() # Install dotfiles with stow
{
  echo "Installing dotfiles..."
  [ -z "$3" ] && branch="main"
  dtdir="/home/$name/.dotfiles"
  sudo -u "$name" git clone -b "$branch" --recurse-submodules "$1" "$dtdir" 
  cd "$dtdir" || error "Couldn't change to dotfiles directory"

  for dir in */; do
    printf "Installing dotfiles for %s\n" "${dir%/}"
    stow "${dir%/}"
  done
}

getuserandpass()
{
  read -rp "Please enter your username: " name
  while ! echo "$name" | grep -q "^[a-z_][a-z0-9_-]*$"; do 
    read -rp "Please enter a (valid) username: " name
  done

  clear
}

changeperms()
{
  echo "$* #gnomi" >> /etc/sudoers
}

usersetup()
{
  echo "Seting up user $name"

  useradd -m -g wheel -s /bin/zsh "$name" 
  mkdir -p /home/"$name"

  chown "$name":wheel /home/"$name"

  export srcdir="/home/$name/.local/src" 
  mkdir -p "$srcdir" 
  chown -R "$name":wheel "$(dirname "$srcdir")"
}

extrainstalls()
{
  cd /home/"$name" || error "Couldn't change to home directory"

  # Install vim plugins
  nvim +'PlugInstall --sync' +qa 

  # Create home folders
  for dir in bin wrk etc var; do 
    mkdir -p /home/"$name"/$dir
  done

  # Enable ssh
  systemctl start sshd.service
  systemctl enable sshd.service
}

#-----------------------------------------------------------------------
#  Main installation
#-----------------------------------------------------------------------

welcome 

getuserandpass || error "Installation cancelled."

refreshkeyrings

basicinstall

adduser || error "Couldn't add username and/or password."

# Allow user to run sudo without password.
changeperms "%wheel ALL=(ALL) NOPASSWD: ALL"

echo "Installing the AUR helper..."
manualinstall "yay-bin" || error "Failed to install AUR helper."

installprograms

installdotfiles "$dotfilesrepo"

extrainstalls

echo "All done!"
