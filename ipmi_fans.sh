#!/bin/bash

POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
    case $1 in
        -d | --idrac)
            IDRAC="$2"
            shift 2
            ;;
        -s | --speed)
            SPEED="$2"
            shift 2
            ;;
        -h | --help)
            "This script sets fan speeds on Dell PowerEdge iDrac over IPMI"
            exit 2
            ;;
        -* | --*)
            echo "Unknown option $1"
            exit 1
            ;;
        *)
            POSITIONAL_ARGS+=("$1")
            shift
            ;;
    esac
done

set -- "${POSITIONAL_ARGS[@]}"

install_packages () {
    local PACKAGE="ipmitool"

    if [[ "$OSTYPE" == "linux-gnu" ]]; then
        if [ -f /etc/redhat-release ]; then
            if ! rpm -qa | grep "${PACKAGE}" > /dev/null; then
                dnf install "${PACKAGE}" -y || exit 1
            fi
        elif [ -f /etc/debian_version ]; then
            if ! dpkg -l | grep "${PACKAGE}" > /dev/null; then
                apt-get install "${PACKAGE}" -y || exit 1
            fi
        fi
    elif [[ "$OSTYPE" == "darwin" ]]; then
        if ! bew list | grep "${PACKAGE}" > /dev/null; then
            brew install "${PACKAGE}" -y || exit 1
        fi
    else
        echo -n "Unkown OS"
        exit 1
    fi
}

get_ip () {
    case $IDRAC in
        r510) 
            IP_ADDRESS="192.168.165.48"
            ;;
        r710)
            IP_ADDRESS="192.168.165.49"
            ;;
        *)
            echo -n "unknown IDRAC"
            exit 1
            ;;
    esac 
}

convert_speed () {
    HEX_SPEED=$(printf '%x\n' ${SPEED})
}

run_command () {
    ipmitool -I lanplus -H "${IP_ADDRESS}" -U root -P calvin raw 0x30 0x30 0x01 0x00 > /dev/null || exit 1
    echo "Dell r510 fan control set to manual"

    ipmitool -I lanplus -H "${IP_ADDRESS}" -U root -P calvin raw 0x30 0x30 0x02 0xff 0x"${HEX_SPEED}" &> /dev/null
    echo "Fan speed on IDRAC ${IDRAC} set to ${SPEED}%"
}

main () {
    install_packages
    get_ip
    convert_speed
    run_command
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi