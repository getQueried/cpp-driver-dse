#!/bin/bash

function check_command {
  command=$1
  package=$2
  if ! type "$command" > /dev/null 2>&1; then
    echo "Missing command '$command', run: apt-get install $package"
    exit 1
  fi
}

function header_version {
  read -d ''  version_script << 'EOF'
  BEGIN { major="?"; minor="?"; patch="?" }
  /DSE_VERSION_MAJOR/ { major=$3 }
  /DSE_VERSION_MINOR/ { minor=$3 }
  /DSE_VERSION_PATCH/ { patch=$3 }
  /DSE_VERSION_SUFFIX/ { suffix=$3; gsub(/"/, "", suffix) }
  END { 
    if (length(suffix) > 0)
      printf "%s.%s.%s~%s", major, minor, patch, suffix
    else
      printf "%s.%s.%s", major, minor, patch 
  }
EOF
  version=$(grep '#define[ \t]\+DSE_VERSION_\(MAJOR\|MINOR\|PATCH\|SUFFIX\)' $1 | awk "$version_script")
  if [[ ! $version =~ ^[0-9]+\.[0-9]+\.[0-9]+(~[a-zA-Z0-9_\-]+)?$ ]]; then
    echo "Unable to extract version from $1"
    exit 1
  fi
  echo "$version"
}

check_command "dch" "debhelper"
check_command "lsb_release" "lsb-release"

version=$(header_version "../include/dse.h")
release=1
dist=$(lsb_release -s -c)
base="dse-cpp-driver-$version"
archive="$base.tar.gz"
files="CMakeLists.txt include src cmake cpp-driver/include cpp-driver/src cpp-driver/cmake cpp-driver/cassconfig.hpp.in"

echo "Building version $version"

libuv_version=$(dpkg -s libuv | grep 'Version' | awk '{ print $2 }')

if [[ -e $libuv_version ]]; then
  echo "'libuv' required, but not installed"
  exit 1
fi

echo "Using libuv version $libuv_version"

if [[ -d build ]]; then
  read -p "Build directory exists, remove? [y|n] " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf build
  fi
fi
mkdir -p "build/$base"

echo "Copying files"
mkdir -p "build/$base/cpp-driver"
for file in $files; do
  cp -r  "../$file" "build/$base/$file"
done
cp -r debian "build/$base"

pushd "build/$base"
echo "Updating changlog"
dch -m -v "$version-$release" -D $dist "Version $version"
echo "Building package:"
nprocs=$(grep -e '^processor' -c /proc/cpuinfo)
DEB_BUILD_OPTIONS="parallel=$nprocs" debuild -i -b -uc -us
popd
