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
  --buildtype=release
  --backend=ninja
  -Dlibdir=lib
  -D python="$PYTHON"
)

# configure build using meson
meson setup builddir ${MESON_ARGS} "${meson_config_args[@]}"

ninja -v -C builddir -j ${CPU_COUNT}
ninja -C builddir test
ninja -C builddir install

# meson installs to the wrong location for PyPy, so move the files manually
PYTHON_IMPL=$($PYTHON -c "import platform; print(platform.python_implementation())")
if [ "$PYTHON_IMPL" = "PyPy" ]; then
    INSTALL_PLATLIB=$($PYTHON -c "import sysconfig; print(sysconfig.get_path('platlib'))")
    cd $PREFIX/lib/pypy*/site-packages
    mv *.egg-info $INSTALL_PLATLIB
    mv cairo $INSTALL_PLATLIB
fi
