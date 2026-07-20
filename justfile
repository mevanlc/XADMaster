set shell := ["bash", "-euo", "pipefail", "-c"]

project := "XADMaster.xcodeproj"
configuration := "Release"
deployment_target := "10.13"
native_derived_data := "build/macos-native"
universal_derived_data := "build/macos-universal"
universal_detector_project := "../UniversalDetector/UniversalDetector.xcodeproj"

# List available recipes.
default:
    @just --list

# Build unar and lsar for the host architecture.
cli: (_build_cli native_derived_data "")

# Build universal unar and lsar binaries for Apple Silicon and Intel Macs.
cli-universal: (_build_cli universal_derived_data "arm64 x86_64")

[private]
_build_cli derived_data architectures:
    #!/usr/bin/env bash
    set -euo pipefail

    if [[ ! -d "{{ universal_detector_project }}" ]]; then
        printf 'Missing %s\n' "{{ universal_detector_project }}" >&2
        printf 'Clone UniversalDetector beside XADMaster:\n' >&2
        printf '  git clone https://github.com/MacPaw/universal-detector.git ../UniversalDetector\n' >&2
        exit 1
    fi

    build_args=(
        -project "{{ project }}"
        -configuration "{{ configuration }}"
        -derivedDataPath "{{ derived_data }}"
        build
        CODE_SIGNING_ALLOWED=NO
        "MACOSX_DEPLOYMENT_TARGET={{ deployment_target }}"
    )

    if [[ -n "{{ architectures }}" ]]; then
        build_args+=("ARCHS={{ architectures }}" ONLY_ACTIVE_ARCH=NO)
    fi

    for scheme_name in unar lsar; do
        xcodebuild -quiet -scheme "$scheme_name" "${build_args[@]}"
    done

    products_dir="{{ derived_data }}/Build/Products/{{ configuration }}"
    printf '\nBuilt CLI tools:\n  %s/unar\n  %s/lsar\n' "$products_dir" "$products_dir"
