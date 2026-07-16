# _ffmpeg-static-deps.sh — build static codec libraries when apt ships shared-only.
# Sourced from ffmpeg-install.sh.

ffmpeg_source_static_deps_prefix() {
    printf '%s\n' "${FFMPEG_STATIC_DEPS_PREFIX:-/usr/local/ffmpeg-static-deps}"
}

ffmpeg_source_dep_build_jobs() {
    local j="${FFMPEG_MAKE_JOBS:-1}"
    (( j >= 1 )) || j=1
    printf '%s\n' "${j}"
}

ffmpeg_source_static_dep_profile_wants() {
    local p=""
    for p in "$@"; do
        [[ "${SOURCE_PROFILE}" == "${p}" ]] && return 0
    done
    return 1
}

ffmpeg_source_static_deps_prepend_pkg_config() {
    local prefix="" pc=""
    prefix="$(ffmpeg_source_static_deps_prefix)"
    [[ -d "${prefix}/lib/pkgconfig" ]] || return 0
    for pc in "${prefix}/lib/pkgconfig" "${prefix}/lib/x86_64-linux-gnu/pkgconfig"; do
        [[ -d "${pc}" ]] || continue
        case ":${PKG_CONFIG_PATH:-}:" in
            *:"${pc}":*) continue ;;
        esac
        PKG_CONFIG_PATH="${pc}${PKG_CONFIG_PATH:+:${PKG_CONFIG_PATH}}"
    done
    export PKG_CONFIG_PATH
}

ffmpeg_source_static_dep_ok_in_prefix() {
    local spec="$1"

    ffmpeg_source_static_deps_prepend_pkg_config
    ffmpeg_pkg_config_satisfied "${spec}" || return 1
    ffmpeg_source_pkg_static_usable "${spec}"
}

ffmpeg_source_static_dep_ok_anywhere() {
    local spec="$1"

    ffmpeg_source_ensure_pkg_config_path
    if ffmpeg_pkg_config_satisfied "${spec}" && ffmpeg_source_pkg_static_usable "${spec}"; then
        return 0
    fi
    ffmpeg_source_static_dep_ok_in_prefix "${spec}"
}

ffmpeg_source_install_static_build_tools() {
    local -a tools=(
        cmake git meson ninja-build
        autoconf automake libtool
        libnuma-dev
    )
    local -a extras=(
        libxml2-dev libpng-dev libfftw3-dev libmpg123-dev
        libfreetype-dev libfontconfig-dev libfribidi-dev libharfbuzz-dev
    )

    log_step "Installing tools to compile static codec libraries..."
    apt_install_packages "${tools[@]}"
    apt_install_optional_packages "${extras[@]}"
}

ffmpeg_source_git_clone_to() {
    local dest="$1" url="$2" ref="$3"

    need_cmd git
    mkdir -p "$(dirname "${dest}")"
    if [[ -n "${ref}" ]]; then
        git clone --depth 1 --branch "${ref}" "${url}" "${dest}"
    else
        git clone --depth 1 "${url}" "${dest}"
    fi
}

ffmpeg_source_build_static_x265() {
    local prefix="" jobs="" build_root="" src="" cmake_dir="" old_pwd=""

    prefix="$(ffmpeg_source_static_deps_prefix)"
    jobs="$(ffmpeg_source_dep_build_jobs)"
    build_root="$(mktemp -d "${TEMP_CATALOG}/x265-build.XXXXXX")"
    src="${build_root}/x265"
    cmake_dir="${src}/build/linux"
    old_pwd="$(pwd)"

    log_step "Building static x265 into ${prefix}..."
    ffmpeg_source_git_clone_to "${src}" "https://bitbucket.org/multicoreware/x265_git.git" "4.1"
    mkdir -p "${cmake_dir}"
    (
        cd "${cmake_dir}"
        cmake -G "Unix Makefiles" "${src}/source" \
            -DCMAKE_INSTALL_PREFIX="${prefix}" \
            -DENABLE_SHARED=OFF \
            -DENABLE_CLI=OFF \
            -DENABLE_PIC=ON \
            -DCMAKE_BUILD_TYPE=Release
        cmake --build . -- -j"${jobs}"
        cmake --install .
    ) || {
        cd "${old_pwd}" || true
        rm -rf "${build_root}"
        return 1
    }
    cd "${old_pwd}" || true
    rm -rf "${build_root}"
    ffmpeg_source_static_deps_prepend_pkg_config
    log_note "Static x265 installed under ${prefix}."
}

ffmpeg_source_build_static_dav1d() {
    local prefix="" jobs="" build_root="" src="" old_pwd=""

    prefix="$(ffmpeg_source_static_deps_prefix)"
    jobs="$(ffmpeg_source_dep_build_jobs)"
    build_root="$(mktemp -d "${TEMP_CATALOG}/dav1d-build.XXXXXX")"
    src="${build_root}/dav1d"
    old_pwd="$(pwd)"

    log_step "Building static dav1d into ${prefix}..."
    ffmpeg_source_git_clone_to "${src}" "https://code.videolan.org/videolan/dav1d.git" "1.5.1"
    (
        cd "${src}"
        meson setup build \
            --prefix="${prefix}" \
            --libdir=lib \
            --default-library=static \
            --buildtype=release \
            -Denable_tools=false \
            -Denable_tests=false
        meson compile -C build -j"${jobs}"
        meson install -C build
    ) || {
        cd "${old_pwd}" || true
        rm -rf "${build_root}"
        return 1
    }
    cd "${old_pwd}" || true
    rm -rf "${build_root}"
    ffmpeg_source_static_deps_prepend_pkg_config
    log_note "Static dav1d installed under ${prefix}."
}

ffmpeg_source_build_static_vpx() {
    local prefix="" jobs="" build_root="" src="" old_pwd=""

    prefix="$(ffmpeg_source_static_deps_prefix)"
    jobs="$(ffmpeg_source_dep_build_jobs)"
    build_root="$(mktemp -d "${TEMP_CATALOG}/vpx-build.XXXXXX")"
    src="${build_root}/libvpx"
    old_pwd="$(pwd)"

    log_step "Building static libvpx into ${prefix}..."
    ffmpeg_source_git_clone_to "${src}" "https://chromium.googlesource.com/webm/libvpx" "v1.14.1"
    (
        cd "${src}"
        ./configure --prefix="${prefix}" \
            --disable-shared --enable-static --enable-pic \
            --disable-unit-tests --disable-examples \
            --enable-vp8 --enable-vp9 \
            --libdir="${prefix}/lib"
        make -j"${jobs}"
        make install
    ) || {
        cd "${old_pwd}" || true
        rm -rf "${build_root}"
        return 1
    }
    cd "${old_pwd}" || true
    rm -rf "${build_root}"
    ffmpeg_source_static_deps_prepend_pkg_config
    log_note "Static libvpx installed under ${prefix}."
}

ffmpeg_source_build_static_aom() {
    local prefix="" jobs="" build_root="" src="" build="" old_pwd=""

    prefix="$(ffmpeg_source_static_deps_prefix)"
    jobs="$(ffmpeg_source_dep_build_jobs)"
    build_root="$(mktemp -d "${TEMP_CATALOG}/aom-build.XXXXXX")"
    src="${build_root}/aom"
    build="${build_root}/build"
    old_pwd="$(pwd)"

    log_step "Building static libaom into ${prefix} (this can take a while)..."
    ffmpeg_source_git_clone_to "${src}" "https://aomedia.googlesource.com/aom" "v3.12.0"
    (
        cmake -G "Unix Makefiles" -S "${src}" -B "${build}" \
            -DCMAKE_INSTALL_PREFIX="${prefix}" \
            -DENABLE_SHARED=OFF \
            -DENABLE_STATIC=ON \
            -DENABLE_TESTS=OFF \
            -DENABLE_DOCS=OFF \
            -DENABLE_EXAMPLES=OFF \
            -DCMAKE_BUILD_TYPE=Release
        cmake --build "${build}" -- -j"${jobs}"
        cmake --install "${build}"
    ) || {
        cd "${old_pwd}" || true
        rm -rf "${build_root}"
        return 1
    }
    cd "${old_pwd}" || true
    rm -rf "${build_root}"
    ffmpeg_source_static_deps_prepend_pkg_config
    log_note "Static libaom installed under ${prefix}."
}

ffmpeg_source_build_static_libass() {
    local prefix="" jobs="" build_root="" src="" old_pwd=""

    prefix="$(ffmpeg_source_static_deps_prefix)"
    jobs="$(ffmpeg_source_dep_build_jobs)"
    build_root="$(mktemp -d "${TEMP_CATALOG}/libass-build.XXXXXX")"
    src="${build_root}/libass"
    old_pwd="$(pwd)"

    log_step "Building static libass into ${prefix}..."
    ffmpeg_source_git_clone_to "${src}" "https://github.com/libass/libass.git" "0.17.3"
    (
        cd "${src}"
        ./autogen.sh
        ./configure --prefix="${prefix}" --enable-static --disable-shared
        make -j"${jobs}"
        make install
    ) || {
        cd "${old_pwd}" || true
        rm -rf "${build_root}"
        return 1
    }
    cd "${old_pwd}" || true
    rm -rf "${build_root}"
    ffmpeg_source_static_deps_prepend_pkg_config
    log_note "Static libass installed under ${prefix}."
}

ffmpeg_source_build_static_svtav1() {
    local prefix="" jobs="" build_root="" src="" old_pwd=""

    prefix="$(ffmpeg_source_static_deps_prefix)"
    jobs="$(ffmpeg_source_dep_build_jobs)"
    build_root="$(mktemp -d "${TEMP_CATALOG}/svt-av1-build.XXXXXX")"
    src="${build_root}/SVT-AV1"
    old_pwd="$(pwd)"

    log_step "Building static SVT-AV1 into ${prefix}..."
    ffmpeg_source_git_clone_to "${src}" "https://gitlab.com/AOMediaCodec/SVT-AV1.git" "v2.3.0"
    (
        cd "${src}"
        mkdir -p build && cd build
        cmake .. \
            -DCMAKE_INSTALL_PREFIX="${prefix}" \
            -DBUILD_SHARED_LIBS=OFF \
            -DCOMPILE_C_ONLY=ON
        make -j"${jobs}"
        make install
    ) || {
        cd "${old_pwd}" || true
        rm -rf "${build_root}"
        return 1
    }
    cd "${old_pwd}" || true
    rm -rf "${build_root}"
    ffmpeg_source_static_deps_prepend_pkg_config
    log_note "Static SVT-AV1 installed under ${prefix}."
}

ffmpeg_source_build_static_fdk_aac() {
    local prefix="" jobs="" build_root="" src="" old_pwd=""

    prefix="$(ffmpeg_source_static_deps_prefix)"
    jobs="$(ffmpeg_source_dep_build_jobs)"
    build_root="$(mktemp -d "${TEMP_CATALOG}/fdk-aac-build.XXXXXX")"
    src="${build_root}/fdk-aac"
    old_pwd="$(pwd)"

    log_step "Building static fdk-aac into ${prefix}..."
    ffmpeg_source_git_clone_to "${src}" "https://github.com/mstorsjo/fdk-aac.git" "v2.0.3"
    (
        cd "${src}"
        autoreconf -fiv
        ./configure --prefix="${prefix}" --enable-static --disable-shared
        make -j"${jobs}"
        make install
    ) || {
        cd "${old_pwd}" || true
        rm -rf "${build_root}"
        return 1
    }
    cd "${old_pwd}" || true
    rm -rf "${build_root}"
    ffmpeg_source_static_deps_prepend_pkg_config
    log_note "Static fdk-aac installed under ${prefix}."
}

ffmpeg_source_build_static_bluray() {
    local prefix="" jobs="" build_root="" src="" old_pwd=""

    prefix="$(ffmpeg_source_static_deps_prefix)"
    jobs="$(ffmpeg_source_dep_build_jobs)"
    build_root="$(mktemp -d "${TEMP_CATALOG}/bluray-build.XXXXXX")"
    src="${build_root}/libbluray"
    old_pwd="$(pwd)"

    log_step "Building static libbluray into ${prefix}..."
    ffmpeg_source_git_clone_to "${src}" "https://code.videolan.org/videolan/libbluray.git" "1.3.4"
    (
        cd "${src}"
        ./bootstrap
        ./configure --prefix="${prefix}" \
            --enable-static --disable-shared \
            --disable-docs --disable-bdjava-jar \
            --without-x11 --without-graphics
        make -j"${jobs}"
        make install
    ) || {
        cd "${old_pwd}" || true
        rm -rf "${build_root}"
        return 1
    }
    cd "${old_pwd}" || true
    rm -rf "${build_root}"
    ffmpeg_source_static_deps_prepend_pkg_config
    log_note "Static libbluray installed under ${prefix}."
}

ffmpeg_source_build_static_chromaprint() {
    local prefix="" jobs="" build_root="" src="" build="" old_pwd=""

    prefix="$(ffmpeg_source_static_deps_prefix)"
    jobs="$(ffmpeg_source_dep_build_jobs)"
    build_root="$(mktemp -d "${TEMP_CATALOG}/chromaprint-build.XXXXXX")"
    src="${build_root}/chromaprint"
    build="${build_root}/build"
    old_pwd="$(pwd)"

    log_step "Building static chromaprint into ${prefix}..."
    ffmpeg_source_git_clone_to "${src}" "https://github.com/acoustid/chromaprint.git" "v1.5.1"
    (
        cmake -G "Unix Makefiles" -S "${src}" -B "${build}" \
            -DCMAKE_INSTALL_PREFIX="${prefix}" \
            -DBUILD_SHARED_LIBS=OFF \
            -DCMAKE_BUILD_TYPE=Release
        cmake --build "${build}" -- -j"${jobs}"
        cmake --install "${build}"
    ) || {
        cd "${old_pwd}" || true
        rm -rf "${build_root}"
        return 1
    }
    cd "${old_pwd}" || true
    rm -rf "${build_root}"
    ffmpeg_source_static_deps_prepend_pkg_config
    log_note "Static chromaprint installed under ${prefix}."
}

ffmpeg_source_build_static_gme() {
    local prefix="" jobs="" build_root="" src="" old_pwd=""

    prefix="$(ffmpeg_source_static_deps_prefix)"
    jobs="$(ffmpeg_source_dep_build_jobs)"
    build_root="$(mktemp -d "${TEMP_CATALOG}/gme-build.XXXXXX")"
    src="${build_root}/libgme"
    old_pwd="$(pwd)"

    log_step "Building static libgme into ${prefix}..."
    ffmpeg_source_git_clone_to "${src}" "https://bitbucket.org/mpyne/game-music-emu.git" "0.6.3"
    (
        cd "${src}"
        ./autogen.sh
        ./configure --prefix="${prefix}" --enable-static --disable-shared
        make -j"${jobs}"
        make install
    ) || {
        cd "${old_pwd}" || true
        rm -rf "${build_root}"
        return 1
    }
    cd "${old_pwd}" || true
    rm -rf "${build_root}"
    ffmpeg_source_static_deps_prepend_pkg_config
    log_note "Static libgme installed under ${prefix}."
}

ffmpeg_source_build_static_openmpt() {
    local prefix="" jobs="" build_root="" src="" build="" old_pwd=""

    prefix="$(ffmpeg_source_static_deps_prefix)"
    jobs="$(ffmpeg_source_dep_build_jobs)"
    build_root="$(mktemp -d "${TEMP_CATALOG}/openmpt-build.XXXXXX")"
    src="${build_root}/libopenmpt"
    build="${build_root}/build"
    old_pwd="$(pwd)"

    log_step "Building static libopenmpt into ${prefix}..."
    ffmpeg_source_git_clone_to "${src}" "https://github.com/OpenMPT/openmpt.git" "libopenmpt-0.7.11"
    (
        cmake -G "Unix Makefiles" -S "${src}" -B "${build}" \
            -DCMAKE_INSTALL_PREFIX="${prefix}" \
            -DBUILD_SHARED_LIBS=OFF \
            -DCMAKE_BUILD_TYPE=Release
        cmake --build "${build}" -- -j"${jobs}"
        cmake --install "${build}"
    ) || {
        cd "${old_pwd}" || true
        rm -rf "${build_root}"
        return 1
    }
    cd "${old_pwd}" || true
    rm -rf "${build_root}"
    ffmpeg_source_static_deps_prepend_pkg_config
    log_note "Static libopenmpt installed under ${prefix}."
}

ffmpeg_source_build_static_vidstab() {
    local prefix="" jobs="" build_root="" src="" build="" old_pwd=""

    prefix="$(ffmpeg_source_static_deps_prefix)"
    jobs="$(ffmpeg_source_dep_build_jobs)"
    build_root="$(mktemp -d "${TEMP_CATALOG}/vidstab-build.XXXXXX")"
    src="${build_root}/vid.stab"
    build="${build_root}/build"
    old_pwd="$(pwd)"

    log_step "Building static vidstab into ${prefix}..."
    ffmpeg_source_git_clone_to "${src}" "https://github.com/georgmartius/vid.stab.git" "v1.1.1"
    (
        cmake -G "Unix Makefiles" -S "${src}" -B "${build}" \
            -DCMAKE_INSTALL_PREFIX="${prefix}" \
            -DBUILD_SHARED_LIBS=OFF \
            -DCMAKE_BUILD_TYPE=Release
        cmake --build "${build}" -- -j"${jobs}"
        cmake --install "${build}"
    ) || {
        cd "${old_pwd}" || true
        rm -rf "${build_root}"
        return 1
    }
    cd "${old_pwd}" || true
    rm -rf "${build_root}"
    ffmpeg_source_static_deps_prepend_pkg_config
    log_note "Static vidstab installed under ${prefix}."
}

ffmpeg_source_build_static_shine() {
    local prefix="" jobs="" build_root="" src="" old_pwd=""

    prefix="$(ffmpeg_source_static_deps_prefix)"
    jobs="$(ffmpeg_source_dep_build_jobs)"
    build_root="$(mktemp -d "${TEMP_CATALOG}/shine-build.XXXXXX")"
    src="${build_root}/shine"
    old_pwd="$(pwd)"

    log_step "Building static shine into ${prefix}..."
    ffmpeg_source_git_clone_to "${src}" "https://github.com/savonet/shine.git" "3.1.1"
    (
        cd "${src}"
        ./bootstrap
        ./configure --prefix="${prefix}" --enable-static --disable-shared
        make -j"${jobs}"
        make install
    ) || {
        cd "${old_pwd}" || true
        rm -rf "${build_root}"
        return 1
    }
    cd "${old_pwd}" || true
    rm -rf "${build_root}"
    ffmpeg_source_static_deps_prepend_pkg_config
    log_note "Static shine installed under ${prefix}."
}

ffmpeg_source_build_static_sdl2() {
    local prefix="" jobs="" build_root="" src="" build="" old_pwd=""

    prefix="$(ffmpeg_source_static_deps_prefix)"
    jobs="$(ffmpeg_source_dep_build_jobs)"
    build_root="$(mktemp -d "${TEMP_CATALOG}/sdl2-build.XXXXXX")"
    src="${build_root}/SDL"
    build="${build_root}/build"
    old_pwd="$(pwd)"

    log_step "Building static SDL2 into ${prefix} (needed for ffplay)..."
    ffmpeg_source_git_clone_to "${src}" "https://github.com/libsdl-org/SDL.git" "release-2.30.9"
    (
        cmake -G "Unix Makefiles" -S "${src}" -B "${build}" \
            -DCMAKE_INSTALL_PREFIX="${prefix}" \
            -DSDL_SHARED=OFF \
            -DSDL_STATIC=ON \
            -DSDL_TEST=OFF \
            -DCMAKE_BUILD_TYPE=Release
        cmake --build "${build}" -- -j"${jobs}"
        cmake --install "${build}"
    ) || {
        cd "${old_pwd}" || true
        rm -rf "${build_root}"
        return 1
    }
    cd "${old_pwd}" || true
    rm -rf "${build_root}"
    ffmpeg_source_static_deps_prepend_pkg_config
    log_note "Static SDL2 installed under ${prefix}."
}

ffmpeg_source_build_static_openjpeg() {
    local prefix="" jobs="" build_root="" src="" build="" old_pwd=""

    prefix="$(ffmpeg_source_static_deps_prefix)"
    jobs="$(ffmpeg_source_dep_build_jobs)"
    build_root="$(mktemp -d "${TEMP_CATALOG}/openjpeg-build.XXXXXX")"
    src="${build_root}/openjpeg"
    build="${build_root}/build"
    old_pwd="$(pwd)"

    log_step "Building static openjpeg into ${prefix}..."
    ffmpeg_source_git_clone_to "${src}" "https://github.com/uclouvain/openjpeg.git" "v2.5.2"
    (
        cmake -G "Unix Makefiles" -S "${src}" -B "${build}" \
            -DCMAKE_INSTALL_PREFIX="${prefix}" \
            -DBUILD_SHARED_LIBS=OFF \
            -DCMAKE_BUILD_TYPE=Release
        cmake --build "${build}" -- -j"${jobs}"
        cmake --install "${build}"
    ) || {
        cd "${old_pwd}" || true
        rm -rf "${build_root}"
        return 1
    }
    cd "${old_pwd}" || true
    rm -rf "${build_root}"
    ffmpeg_source_static_deps_prepend_pkg_config
    log_note "Static openjpeg installed under ${prefix}."
}

ffmpeg_source_ensure_static_dep() {
    local spec="$1" builder="$2"

    if ffmpeg_source_static_dep_ok_anywhere "${spec}"; then
        return 0
    fi
    if (( FFMPEG_SOURCE_BUILD_STATIC_DEPS == 0 )); then
        log_note "${spec%% *} not available as static library; set FFMPEG_SOURCE_BUILD_STATIC_DEPS=1 to build from source."
        return 1
    fi
    "${builder}" || {
        log_note "${spec%% *} source build failed; codec will be skipped at configure."
        return 1
    }
    ffmpeg_source_static_dep_ok_in_prefix "${spec}"
}

ffmpeg_source_ensure_fdk_aac_available() {
    if ffmpeg_source_static_build; then
        if ffmpeg_source_static_dep_ok_anywhere fdk-aac; then
            FFMPEG_SOURCE_HAS_FDK_AAC=1
            return 0
        fi
    elif pkg-config --exists fdk-aac 2>/dev/null; then
        FFMPEG_SOURCE_HAS_FDK_AAC=1
        return 0
    fi
    if apt_cache_has_package libfdk-aac-dev; then
        apt_install_packages libfdk-aac-dev
        if ffmpeg_source_static_build; then
            ffmpeg_source_static_dep_ok_anywhere fdk-aac || true
        fi
        if pkg-config --exists fdk-aac 2>/dev/null \
            || ffmpeg_source_static_dep_ok_in_prefix fdk-aac 2>/dev/null; then
            FFMPEG_SOURCE_HAS_FDK_AAC=1
            return 0
        fi
    fi
    log_step "libfdk-aac-dev not usable — building fdk-aac from source..."
    ffmpeg_source_install_static_build_tools
    ffmpeg_source_build_static_fdk_aac || return 1
    FFMPEG_SOURCE_HAS_FDK_AAC=1
}

ffmpeg_source_install_static_deps_for_profile() {
    ffmpeg_source_static_build || return 0
    (( FFMPEG_SOURCE_BUILD_STATIC_DEPS == 0 )) && return 0

    local prefix=""
    prefix="$(ffmpeg_source_static_deps_prefix)"
    mkdir -p "${prefix}"

    log_step "Ensuring static codec libraries for profile ${SOURCE_PROFILE} (prefix ${prefix})..."
    ffmpeg_source_install_static_build_tools

    if ffmpeg_source_static_dep_profile_wants min common max gpu nvidia; then
        ffmpeg_source_ensure_static_dep sdl2 ffmpeg_source_build_static_sdl2 || true
    fi

    if ffmpeg_source_static_dep_profile_wants common max gpu nvidia jellyfin; then
        ffmpeg_source_ensure_static_dep x265 ffmpeg_source_build_static_x265 || true
        ffmpeg_source_ensure_static_dep dav1d ffmpeg_source_build_static_dav1d || true
        ffmpeg_source_ensure_static_dep vpx ffmpeg_source_build_static_vpx || true
        ffmpeg_source_ensure_static_dep aom ffmpeg_source_build_static_aom || true
        ffmpeg_source_ensure_static_dep libass ffmpeg_source_build_static_libass || true
        ffmpeg_source_ensure_static_dep 'SvtAv1Enc >= 0.9.0' ffmpeg_source_build_static_svtav1 || true
    fi

    if ffmpeg_source_static_dep_profile_wants max gpu nvidia jellyfin; then
        ffmpeg_source_ensure_static_dep 'libopenjp2 >= 2.1.0' ffmpeg_source_build_static_openjpeg || true
        ffmpeg_source_ensure_static_dep libbluray ffmpeg_source_build_static_bluray || true
        ffmpeg_source_ensure_static_dep chromaprint ffmpeg_source_build_static_chromaprint || true
        ffmpeg_source_ensure_static_dep libgme ffmpeg_source_build_static_gme || true
        ffmpeg_source_ensure_static_dep 'libopenmpt >= 0.2.6557' ffmpeg_source_build_static_openmpt || true
        ffmpeg_source_ensure_static_dep 'vidstab >= 0.98' ffmpeg_source_build_static_vidstab || true
        ffmpeg_source_ensure_static_dep shine ffmpeg_source_build_static_shine || true
    fi

    if ffmpeg_source_static_dep_profile_wants max && (( FFMPEG_SOURCE_WITH_FDK_AAC == 1 )); then
        ffmpeg_source_ensure_static_dep fdk-aac ffmpeg_source_build_static_fdk_aac || true
    fi

    ffmpeg_source_static_deps_prepend_pkg_config
    log_note "Static dependency prefix: ${prefix} (PKG_CONFIG_PATH updated)."
}
