: "${CC=cc}${CXX=c++}${CFLAGS=-O2}${CXXFLAGS=-O2}"
eval "$(env DEB_BUILD_MAINT_OPTIONS='future=+all qa=+all,-canary optimize=+all,-lto hardening=+all reproducible=+all' \
    dpkg-buildflags --export=sh || :)"
export LDFLAGS
sh mkt-int.sh $CC $CPPFLAGS $CFLAGS \
    -Wall -Wextra \
    -DMBSDINT_H_WANT_PTR_IN_SIZET -DMBSDINT_H_WANT_SIZET_IN_LONG \
    -DMBSDINT_H_WANT_INT32 -DMBSDINT_H_WANT_LRG64 -DMBSDINT_H_WANT_SAFEC
exec sh mkt-int.sh -cxx $CXX $CPPFLAGS $CXXFLAGS \
    -Wall -Wextra \
    -DMBSDINT_H_WANT_PTR_IN_SIZET -DMBSDINT_H_WANT_SIZET_IN_LONG \
    -DMBSDINT_H_WANT_INT32 -DMBSDINT_H_WANT_LRG64 -DMBSDINT_H_WANT_SAFEC
