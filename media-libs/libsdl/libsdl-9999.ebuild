# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=4
inherit cmake-utils eutils flag-o-matic mercurial multilib toolchain-funcs

DESCRIPTION="Simple Direct Media Layer"
HOMEPAGE="http://www.libsdl.org"
EHG_REPO_URI="http://hg.libsdl.org/SDL"

LICENSE="ZLIB"
SLOT="2"
KEYWORDS="~amd64"

#FIXME: Add "test".
# SDL 1.2 ebuilds prohibited unsafe CFLAGS unless "custom-flags" was enabled.
# This appears to have been overly judicious, as the query "How does one build
# an optimized SDL library?" at
# http://osdl.sourceforge.net/main/documentation/rendering/SDL-optimizing.html
# suggests. SDL supports at least a modicum of extreme optimization. If users
# enable unsafe CFLAGS, SDL breaking is the least of their concerns.
IUSE="
+audio +video joystick threads static-libs
3dnow altivec mmx sse sse2
alsa fusionsound nas oss pulseaudio
X xcursor xinerama xinput xrandr xrender xscreensaver xv
aqua directfb gles opengl tslib 
"

#FIXME: Replace "gles" deps with "virtual/opengles" after hitting Portage.
RDEPEND="
	X? (
		x11-libs/libX11
		x11-libs/libXext
		x11-libs/libXt
	)
	nas? (
		media-libs/nas
		x11-libs/libX11
		x11-libs/libXext
		x11-libs/libXt
	)
	xcursor?  ( x11-libs/libXcursor )
	xinerama? ( x11-libs/libXinerama )
	xinput?   ( x11-libs/libXi )
	xrandr?   ( x11-libs/libXrandr )
	xrender?  ( x11-libs/libXrender )
	xv?       (	x11-libs/libXv )
	xscreensaver? ( x11-libs/libXScrnSaver )
	alsa? ( media-libs/alsa-lib )
	fusionsound? ( >=media-libs/FusionSound-1.1.1 )
	pulseaudio? ( >=media-sound/pulseaudio-0.9 )
	directfb? ( >=dev-libs/DirectFB-1.0.0 )
	gles? ( || ( media-libs/mesa[gles2] media-libs/mesa[gles] ) )
	opengl? ( virtual/opengl )
	tslib? ( x11-libs/tslib )
"
DEPEND="${RDEPEND}
	virtual/pkgconfig
	X?   ( x11-proto/xextproto x11-proto/xproto )
	nas? ( x11-proto/xextproto x11-proto/xproto )
	xinerama? ( x11-proto/xineramaproto )
	xinput?   ( x11-proto/inputproto )
	xrandr?   ( x11-proto/randrproto )
	xrender?  ( x11-proto/renderproto )
	xv?       ( x11-proto/videoproto )
	xscreensaver? ( x11-proto/scrnsaverproto )
"

CMAKE_MIN_VERSION=2.6  # ...if "CMakeLists.txt" can be believed.

src_unpack() {
	[[ -d "${EHG_STORE_DIR}/${PN}" ]] ||
		einfo 'Cloning may take up to several minutes on slow connections.'
	mercurial_src_unpack
}

src_prepare() {
	epatch     "${FILESDIR}/${PV}-sdl2-config.in.patch"
  	epatch -p1 "${FILESDIR}/${PV}-cmake_20120827.patch"
}

src_configure() {
	# DirectFB can link against SDL, triggering a dependency loop. Link against
	# DirectFB only if it isn't broken. (See issue #61592.)
	local use_enable_directfb="-DVIDEO_DIRECTFB=ON"
	if use directfb; then
		echo 'int main(){}' > directfb-test.c
		$(tc-getCC) directfb-test.c -ldirectfb 2>/dev/null \
			&& use_enable_directfb="-DVIDEO_DIRECTFB=OFF" \
			|| ewarn "Disabling DirectFB, since \"libdirectfb.so\" is broken."
		rm directfb-test.c
	fi

	#FIXME: "CMakeLists" supports Xvm rather than Xv and doesn't support XRender
	#at all. Probably bugs. Report.

	# Required by cmake-utils_src_configure().
	mycmakeargs=(
		# Avoid hard-coding RPATH entries into dynamically linked SDL libraries.
		-DRPATH=NO
		# Disable obsolete and/or inapplicable libraries.
		-DARTS=NO
		-DESD=NO
		${use_enable_directfb}
		$(cmake-utils_use_enable audio    SDL_AUDIO)
		$(cmake-utils_use_enable video    SDL_VIDEO)
		$(cmake-utils_use_enable joystick SDL_JOYSTICK)
		$(cmake-utils_use_enable threads  SDL_THREADS)
		$(cmake-utils_use_enable static-libs SDL_STATIC)
		$(cmake-utils_use_enable 3dnow)
		$(cmake-utils_use_enable altivec)
		$(cmake-utils_use_enable mmx)
		$(cmake-utils_use_enable sse)
		$(cmake-utils_use_enable sse SSEMATH)
		$(cmake-utils_use_enable sse2)
		$(cmake-utils_use_enable alsa)
		$(cmake-utils_use_enable fusionsound)
		$(cmake-utils_use_enable nas)
		$(cmake-utils_use_enable oss)
		$(cmake-utils_use_enable pulseaudio)
		$(cmake-utils_use_enable tslib INPUT_TSLIB)
		$(cmake-utils_use_enable X            VIDEO_X11)
		$(cmake-utils_use_enable xcursor      VIDEO_X11_XCURSOR)
		$(cmake-utils_use_enable xinerama     VIDEO_X11_XINERAMA)
		$(cmake-utils_use_enable xinput       VIDEO_X11_XINPUT)
		$(cmake-utils_use_enable xrandr       VIDEO_X11_XRANDR)
		$(cmake-utils_use_enable xscreensaver VIDEO_X11_XSCRNSAVER)
		$(cmake-utils_use_enable aqua   VIDEO_COCOA)
		$(cmake-utils_use_enable gles   VIDEO_OPENGLES)
		$(cmake-utils_use_enable opengl VIDEO_OPENGL)
	)

	cmake-utils_src_configure
}

src_install() {
	# cmake-utils_src_install() installs all docs, except...
	cmake-utils_src_install
	dodoc WhatsNew
}
