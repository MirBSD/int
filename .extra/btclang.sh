: "${CFLAGS=-O2}"
eval "$(env DEB_BUILD_MAINT_OPTIONS='future=+all optimize=+all,-lto hardening=+all reproducible=+all' \
    dpkg-buildflags --export=sh || :)"
export LDFLAGS
exec sh mkt-int.sh clang $CPPFLAGS $CFLAGS \
    -Wall -Wextra -Wformat \
    -DMBSDINT_H_WANT_PTR_IN_SIZET -DMBSDINT_H_WANT_SIZET_IN_LONG \
    -DMBSDINT_H_WANT_INT32 -DMBSDINT_H_WANT_LRG64 -DMBSDINT_H_WANT_SAFEC
