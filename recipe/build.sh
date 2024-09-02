#! /bin/bash

set -e

if [ $(uname) = Darwin ] ; then
    # This needs to be kept the same as what was used to build Cairo, which is
    # apparently this:
    export MACOSX_DEPLOYMENT_TARGET=10.9
fi

# We're using the meson build system as opposed to 'pip install .' because it provides
# the pkg-config files for `pycairo`. These are used by downstream packages (notably
# `pygobject`) that also use the meson build system in order to locate `pycairo`.
# Without them, `pycairo` will not be found and might be built as an in-tree subproject
# which is obviously undesirable.

# get meson to find pkg-config when cross compiling
export PKG_CONFIG=$BUILD_PREFIX/bin/pkg-config

# meson options
meson_config_args=(
  --prefix="$PREFIX"
  --wrap-mode=nofallback
  --backend=ninja
  -Dlibdir=lib
  -D python="$PYTHON"
)

if [[ "$CONDA_BUILD_CROSS_COMPILATION" == "1" ]]; then
    meson_config_args+=(
        -D tests=false
    )
fi

# configure build using meson
meson setup builddir ${MESON_ARGS} "${meson_config_args[@]}"

meson compile -v -C builddir -j ${CPU_COUNT}
meson test -C builddir --print-errorlogs --timeout-multiplier 10 --num-processes ${CPU_COUNT}
meson install -C builddir
