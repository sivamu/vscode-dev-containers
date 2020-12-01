#!/bin/bash -i
cd $(dirname "$0")

if [ -z $HOME ]; then
    HOME="/root"
fi

FAILED=()

check() {
    LABEL=$1
    shift
    echo -e "\n🧪  Testing $LABEL: $@"
    if $@; then 
        echo "🏆  Passed!"
    else
        echo "💥  $LABEL check failed."
        FAILED+=("$LABEL")
    fi
}

checkMultiple() {
    PASSED=0
    LABEL="$1"
    shift; MINIMUMPASSED=$1
    shift; EXPRESSION="$1"
    while [ "$EXPRESSION" != "" ]; do
        if $EXPRESSION; then ((PASSED++)); fi
        shift; EXPRESSION=$1
    done
    check "$LABEL" [ $PASSED -ge $MINIMUMPASSED ]
}

checkExtension() {
    checkMultiple "$1" 1 "[ -d ""$HOME/.vscode-server/extensions/$1*"" ]" "[ -d ""$HOME/.vscode-server-insiders/extensions/$1*"" ]" "[ -d ""$HOME/.vscode-test-server/extensions/$1*"" ]" "[ -d ""$HOME/.vscode-remote/extensions/$1*"" ]"
}

# Run Docker init script
/usr/local/share/docker-init.sh

# Actual tests
checkMultiple "vscode-server" 1 "[ -d ""$HOME/.vscode-server/bin"" ]" "[ -d ""$HOME/.vscode-server-insiders/bin"" ]" "[ -d ""$HOME/.vscode-test-server/bin"" ]" "[ -d ""$HOME/.vscode-remote/bin"" ]"
checkExtension "ms-azuretools.vscode-docker"
check "non-root-user" "id vscode"
check "/home/vscode" [ -d "/home/vscode" ]
check "sudo" sudo echo "sudo works."
check "git" git --version
check "command-line-tools" which top ip lsb_release
check "docker" docker ps -a
check "docker-compose" docker-compose --version

# Report result
if [ ${#FAILED[@]} -ne 0 ]; then
    echo -e "\n💥  Failed tests: ${FAILED[@]}"
    exit 1
else 
    echo -e "\n💯  All passed!"
    exit 0
fi
