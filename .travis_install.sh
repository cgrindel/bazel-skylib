#!/bin/bash

set -eux

if [[ "${TRAVIS_OS_NAME}" == "osx" ]]; then
  OS=darwin
else
  OS=linux
fi

# -------------------------------------------------------------------------------------------------
# Helper to use the github redirect to find the latest release.
function github_latest_release_tag() {
  local PROJECT=$1
  curl \
      -s \
      -o /dev/null \
      --write-out '%{redirect_url}' \
      "https://github.com/${PROJECT}/releases/latest" \
  | sed -e 's,https://.*/releases/tag/\(.*\),\1,'
}


# -------------------------------------------------------------------------------------------------
# Helper to install bazel.
function install_bazel() {
  local VERSION="${1}"

  if [[ "${VERSION}" == "RELEASE" ]]; then
    VERSION="$(github_latest_release_tag bazelbuild/bazel)"
  fi

  # macOS and trusty images have jdk8
  if [[ "${VERSION}" == "HEAD" ]]; then
    URL="https://ci.bazel.build/view/Bazel%20bootstrap%20and%20maintenance/job/bazel/job/nightly/lastSuccessfulBuild/artifact/node=${OS}-x86_64/bazel--without-jdk-installer-${OS}-x86_64.sh"
  else
    URL="https://github.com/bazelbuild/bazel/releases/download/${VERSION}/bazel-${VERSION}-without-jdk-installer-${OS}-x86_64.sh"
  fi

  wget -O install.sh "${URL}"
  chmod +x install.sh
  ./install.sh --user
  rm -f install.sh
  bazel version
}

# -------------------------------------------------------------------------------------------------
# Helper to install buildifier.
function install_buildifier() {
  local VERSION="${1}"

  if [[ "${VERSION}" == "RELEASE" ]]; then
    VERSION="$(github_latest_release_tag bazelbuild/buildtools)"
  fi

  if [[ "${VERSION}" == "HEAD" ]]; then
    echo "buildifer head is not supported"
    exit 1
  fi

  if [[ "${OS}" == "darwin" ]]; then
    URL="https://github.com/bazelbuild/buildtools/releases/download/${VERSION}/buildifier.osx"
  else
    URL="https://github.com/bazelbuild/buildtools/releases/download/${VERSION}/buildifier"
  fi

  wget -O "${HOME}/bin/buildifier" "${URL}"
  chmod +x "${HOME}/bin/buildifier"
  buildifier --version
}

# -------------------------------------------------------------------------------------------------
# Install what is requested.
[[ -z "${BAZEL:-}" ]] || install_bazel "${BAZEL}"
[[ -z "${BUILDIFER:-}" ]] || install_buildifier "${BUILDIFER}"