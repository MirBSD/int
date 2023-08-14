set -ex
apt-get update
apt-get install -y bc build-essential
: "${CC=cc}${CFLAGS=-O2}"
eval "$(env DEB_BUILD_MAINT_OPTIONS='\''future=+all qa=+all,-canary optimize=+all,-lto hardening=+all reproducible=+all'\'' dpkg-buildflags --export=sh || :)"
export LDFLAGS
exec sh mkt-int.sh $CC $CPPFLAGS $CFLAGS -Wall -Wextra
