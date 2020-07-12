#!/bin/sh

# The directory to install the scripts to
INSTALL_PATH="/usr/local/bin"

# The list of tools that this installer will install
tools=("dockup")

# Install the tool at the given directory
# $1 - The tool to install
# $2 - The directory in which to install it
function install {
    # If there is no tool by that name, do nothing
    if [[ ! -f "./$1" ]]; then
        return
    fi

    # Get this version, minor/major
    this_version="$("./$1" --version | grep 'version' | sed -r 's/^[^ ]+ version //')"
    this_major="$(echo "$this_version" | cut -d. -f1)"
    this_minor="$(echo "$this_version" | cut -d. -f2)"

    # If the tool is already installed, upgrade if this is newer and prompt the user for downgrading
    if [[ -f "$2/$1" ]]; then
        # Get the installed version, minor/major
        installed_version="$("$2/$1" --version | grep 'version ' | sed -r 's/^[^ ]+ version //')"
        installed_major="$(echo "$installed_version" | cut -d. -f1)"
        installed_minor="$(echo "$installed_version" | cut -d. -f2)"

        # If the version is the same as the installed one, don't do anything
        # If the version is greater than the installed one, install it
        # Else verify the user wants to downgrade
        if [[ "$this_version" == "$installed_version" ]]; then
            echo "$1 is up to date, nothing to do"
        elif [[ "$this_major" -ge "$installed_major" && "$this_minor" -gt "$installed_minor" ]]; then
            echo "Installing $1 version $this_version over $installed_version"
            cp "./$1" "$2/$1"

            # If it couldn't be done, error
            if [[ "$?" -ne "0" ]]; then
                echo "Error: Could not install $1"
            fi
        else
            echo "The version of $1 installed appears to be newer than the version you are trying to install."
            
            # Prompt the user
            proceed="no"
            read -p "Are you sure you want to downgrade $1 from $this_version to $installed_version? [Y/n]: " proceed

            # If they said yes, install it
            if echo "$proceed" | grep -Ei '^(Y|yes)' > /dev/null 2>&1; then
                echo "Installing $1 version $this_version over $installed_version"
                cp "./$1" "$2/$1"
            fi
        fi
    else
        echo "Installing $1 version $this_version"

        # Install the tool
        cp "./$1" "$2/$1"

        # If it couldn't be done, error
        if [[ "$?" -ne "0" ]]; then
            echo "Error: Could not install $1"
        fi
    fi
}

# If no arguments were given, install all tools
# Else install each tool specified on the command line
if [[ "$@" == "" ]]; then
    for tool in "${tools[@]}"; do
        install "$tool" "$INSTALL_PATH"
    done
else
    for tool in "${@}"; do
        if echo "$tool" | grep "${tools[@]}" > /dev/null 2>&1; then
            install "$tool" "$INSTALL_PATH"
        fi
    done
fi
