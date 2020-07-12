#!/bin/sh

# The directory to install the scripts to
INSTALL_PATH="/usr/local/bin"

MAN_DIR=""

# Determine where man pages are located on this system
if [[ -d /usr/local/share/man ]]; then
    MAN_DIR="/usr/local/share/man"
elif [[ -d /usr/local/man ]]; then
    MAN_DIR="/usr/local/man"
elif [[ -d /usr/share/man ]]; then
    MAN_DIR="/usr/share/man"
elif [[ -d /usr/man ]]; then
    MAN_DIR="/usr/man"
fi

# The list of tools that this installer will install
tools=("dockup")

# Install the tool at the given directory
# $1 - The tool to install
# $2 - The directory in which to install it
function install_tool {
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
        elif [[ "$this_major" -ge "$installed_major" && "$this_minor" -ge "$installed_minor" ]]; then
            echo "Installing utility $1 version $this_version"

            # Install the tool
            install -g 0 -o 0 -m 0555 "./$1" "$2"

            # Install the man page if possible
            if [[ ! -z "$MAN_DIR" && -f "./man/$1.1" ]]; then
                echo "Installing man page for $1"
                install -g 0 -o 0 -m 0644 "./man/$1.1" "$MAN_DIR/man1"

                # If it already exists, remove it
                if [[ -f "$MAN_DIR/man1/$1.1.gz" ]]; then
                    rm -f "$MAN_DIR/man1/$1.1.gz"
                fi

                # Gzip it
                gzip "$MAN_DIR/man1/$1.1"
            fi

            # If it couldn't be done, error
            if [[ "$?" -ne "0" ]]; then
                echo "Error: Could not install $1"
            fi
        else
            echo "The version of $1 installed appears to be newer than the version you are trying to install."
            
            # Prompt the user
            proceed="no"
            read -p "Are you sure you want to downgrade $1 from $installed_version to $this_version? [Y/n]: " proceed

            # If they said yes, install it
            if echo "$proceed" | grep -Ei '^(Y|yes)' > /dev/null 2>&1; then
                echo "Installing utility $1 version"

                # Install the tool
                install -g 0 -o 0 -m 0555 "./$1" "$2"
            
                # Install the man page if possible
                if [[ ! -z "$MAN_DIR" && -f "./man/$1.1" ]]; then
                    echo "Installing man page for $1"
                    install -g 0 -o 0 -m 0644 "./man/$1.1" "$MAN_DIR/man1/"

                    # If it already exists, remove it
                    if [[ -f "$MAN_DIR/man1/$1.1.gz" ]]; then
                        rm -f "$MAN_DIR/man1/$1.1.gz"
                    fi

                    # Gzip it
                    gzip "$MAN_DIR/man1/$1.1"
                fi
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
        install_tool "$tool" "$INSTALL_PATH"
    done
else
    for tool in "${@}"; do
        if echo "$tool" | grep "${tools[@]}" > /dev/null 2>&1; then
            install_tool "$tool" "$INSTALL_PATH"
        fi
    done
fi
