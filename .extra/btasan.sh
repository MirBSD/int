ASAN_OPTIONS=check_initialization_order=true:detect_stack_use_after_return=true:detect_invalid_pointer_pairs=2:dump_instruction_bytes=true:color=never:strict_string_checks=true:exitcode=251
export ASAN_OPTIONS
: "${CC=cc}${CFLAGS=-O2}"
eval "$(env DEB_BUILD_MAINT_OPTIONS='future=+all qa=+all,-canary optimize=+all,-lto hardening=+all reproducible=+all' \
    dpkg-buildflags --export=sh || :)"
export LDFLAGS
exec sh mkt-int.sh $CC $CPPFLAGS $CFLAGS \
    -Wall -Wextra -Wformat -Werror=format-security -Og -fstack-protector-strong \
    -fsanitize=address -fno-omit-frame-pointer -fno-common -fsanitize=pointer-compare \
    -fsanitize=pointer-subtract -fsanitize=undefined -fsanitize=shift -fsanitize=shift-exponent \
    -fsanitize=shift-base -fsanitize=integer-divide-by-zero -fsanitize=unreachable \
    -fsanitize=vla-bound -fsanitize=null -fsanitize=signed-integer-overflow -fsanitize=bounds \
    -fsanitize=bounds-strict -fsanitize=alignment -fsanitize=object-size -fsanitize=nonnull-attribute \
    -fsanitize=returns-nonnull-attribute -fsanitize=bool -fsanitize=enum -fsanitize=vptr \
    -fsanitize=pointer-overflow -fsanitize=builtin -fsanitize-address-use-after-scope \
    -fstack-clash-protection \
    -DMBSDINT_H_WANT_PTR_IN_SIZET -DMBSDINT_H_WANT_SIZET_IN_LONG \
    -DMBSDINT_H_WANT_INT32 -DMBSDINT_H_WANT_LRG64 -DMBSDINT_H_WANT_SAFEC
