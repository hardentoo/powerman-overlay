# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

EGIT_REPO_URI="https://github.com/clementine-player/Clementine.git"

LANGS=" af ar be bg bn br bs ca cs cy da de el en_CA en_GB eo es et eu fa fi fr ga gl he he_IL hi hr hu hy ia id is it ja ka kk ko lt lv mr ms my nb nl oc pa pl pt pt_BR ro ru si_LK sk sl sr sr@latin sv te tr tr_TR uk uz vi zh_CN zh_TW"

inherit cmake-utils flag-o-matic fdo-mime gnome2-utils virtualx
[[ ${PV} == *9999* ]] && inherit git-r3

DESCRIPTION="A modern music player and library organizer based on Amarok 1.4 and Qt4"
HOMEPAGE="http://www.clementine-player.org https://github.com/clementine-player/Clementine"
[[ ${PV} == *9999* ]] || \
SRC_URI="https://github.com/clementine-player/Clementine/archive/${PV/_}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
[[ ${PV} == *9999* ]] || \
KEYWORDS="~amd64 ~x86"
IUSE="amazoncloud box cdda +dbus debug dropbox googledrive ipod lastfm mms moodbar mtp projectm pulseaudio skydrive +qt4 qt5 test +udisks wiimote"
IUSE+="${LANGS// / linguas_}"

REQUIRED_USE="
	^^ ( qt4 qt5 )
	udisks? ( dbus )
	wiimote? ( dbus )
"

COMMON_DEPEND="
	qt4? ( >=dev-qt/qtcore-4.5:4
		>=dev-qt/qtgui-4.5:4
		>=dev-qt/qtopengl-4.5:4
		>=dev-qt/qtsql-4.5:4[sqlite]
		app-crypt/qca:2[qt4(+)]
		>=media-libs/libmygpo-qt-1.0.7[qt4]
		lastfm? ( >=media-libs/liblastfm-1[qt4] )
		dbus? ( >=dev-qt/qtdbus-4.5:4 ) )
	qt5? ( >=dev-qt/qtcore-5.1:5
		>=dev-qt/qtgui-5.1:5
		>=dev-qt/qtnetwork-5.1:5
		>=dev-qt/qtopengl-5.1:5
		>=dev-qt/qttranslations-5.1:5
		>=dev-qt/qtsql-5.1:5[sqlite]
		>=dev-qt/qtwidgets-5.1:5
		>=dev-qt/qtx11extras-5.1:5
		>=dev-qt/qtxml-5.1:5
		>=dev-qt/linguist-tools-5.1:5
		app-crypt/qca:2[qt5(+)]
		>=media-libs/libmygpo-qt-1.0.8[qt5]
		lastfm? ( >=media-libs/liblastfm-1[qt5] )
		dbus? ( >=dev-qt/qtdbus-5.1:5 ) )

	>=dev-libs/glib-2.24.1-r1
	dev-libs/libxml2
	dev-libs/protobuf:=
	>=media-libs/chromaprint-0.6
	media-libs/gstreamer:1.0
	media-libs/gst-plugins-base:1.0
	>=media-libs/taglib-1.8[mp4(+)]
	sys-libs/zlib
	dev-libs/crypto++
	virtual/glu
	virtual/opengl
	x11-libs/libX11
	cdda? ( dev-libs/libcdio )
	ipod? ( >=media-libs/libgpod-0.8.0 )
	mtp? ( >=media-libs/libmtp-1.0.0 )
	moodbar? ( sci-libs/fftw:3.0 )
	projectm? ( media-libs/glew:=
			>=media-libs/libprojectm-1.2.0 )
"
# Note: sqlite driver of dev-qt/qtsql is bundled, so no sqlite use is required; check if this can be overcome someway;
# Libprojectm-1.2 seams to work fine, so no reasons to use bundled version; check the clementine's patches:
# https://github.com/clementine-player/Clementine/tree/master/3rdparty/libprojectm/patches
# Still possibly essential but not applied yet patches are:
# 06-fix-numeric-locale.patch
# 08-stdlib.h-for-rand.patch
RDEPEND="${COMMON_DEPEND}
	dbus? ( udisks? ( sys-fs/udisks:0 ) )
	mms? ( media-plugins/gst-plugins-libmms:1.0 )
	mtp? ( gnome-base/gvfs[mtp] )
	media-plugins/gst-plugins-meta:1.0
	media-plugins/gst-plugins-soup:1.0
	media-plugins/gst-plugins-taglib:1.0
"
DEPEND="${COMMON_DEPEND}
	>=dev-libs/boost-1.39:=
	virtual/pkgconfig
	sys-devel/gettext
	qt4? ( test? ( dev-qt/qttest:4 ) )
	qt5? ( test? ( dev-qt/qttest:5 ) )
	dev-cpp/gmock
	amazoncloud? ( dev-cpp/sparsehash )
	box? ( dev-cpp/sparsehash )
	dropbox? ( dev-cpp/sparsehash )
	googledrive? ( dev-cpp/sparsehash )
	pulseaudio? ( media-sound/pulseaudio )
	skydrive? ( dev-cpp/sparsehash )
	test? ( gnome-base/gsettings-desktop-schemas )
"
DOCS=( Changelog README.md )

MY_P="${P/_}"
[[ ${PV} == *9999* ]] || \
S="${WORKDIR}/${MY_P^}"

PATCHES=(
	"${FILESDIR}"/${P}-fix-tokenizer.patch
)

# https://github.com/clementine-player/Clementine/issues/3935
RESTRICT="test"

src_unpack() {
	if use qt5; then
		EGIT_BRANCH="qt5"
	fi

	git-r3_src_unpack
}

src_prepare() {
	cmake-utils_src_prepare

	# some tests fail or hang
	sed -i \
		-e '/add_test_file(translations_test.cpp/d' \
		tests/CMakeLists.txt || die
	# If qtchooser is installed, it may break the build, because moc,rcc and uic binaries for wrong qt version may be used.
	# Setting QT_SELECT environment variable will enforce correct binaries.
	if use qt4; then
		export QT_SELECT=qt4
	elif use qt5; then
		export QT_SELECT=qt5
		ewarn "Please note that Qt5 support is still experimental."
		ewarn "If you find anything to not work with Qt5, please report a bug."
		ewarn "«Work (slowly) in progress.»© https://github.com/clementine-player/Clementine/issues/3463#issuecomment-90714420"
	fi
}

src_configure() {
	local langs x
	for x in ${LANGS}; do
		use linguas_${x} && langs+=" ${x}"
	done

	# spotify is not in portage
	local mycmakeargs=(
		-DBUILD_WERROR=OFF
		-DLINGUAS="${langs}"
		-DENABLE_AMAZON_CLOUD_DRIVE="$(usex amazoncloud)"
		-DENABLE_AUDIOCD="$(usex cdda)"
		-DENABLE_DBUS="$(usex dbus)"
		-DENABLE_DEVICEKIT="$(usex udisks)"
		-DENABLE_LIBGPOD="$(usex ipod)"
		-DENABLE_LIBLASTFM="$(usex lastfm)"
		-DENABLE_LIBMTP="$(usex mtp)"
		-DENABLE_MOODBAR="$(usex moodbar)"
		-DENABLE_GIO=ON
		-DENABLE_WIIMOTEDEV="$(usex wiimote)"
		-DENABLE_VISUALISATIONS="$(usex projectm)"
		-DENABLE_BOX="$(usex box)"
		-DENABLE_DROPBOX="$(usex dropbox)"
		-DENABLE_GOOGLE_DRIVE="$(usex googledrive)"
		-DENABLE_LIBPULSE="$(usex pulseaudio)"
		-DENABLE_SKYDRIVE="$(usex skydrive)"
		-DENABLE_SPOTIFY_BLOB=OFF
		-DENABLE_BREAKPAD=OFF  #< disable crash reporting
		-DUSE_BUILTIN_TAGLIB=OFF
		-DUSE_SYSTEM_GMOCK=ON
		-DUSE_SYSTEM_PROJECTM=ON
		-DBUNDLE_PROJECTM_PRESETS=OFF
		# force to find crypto++ see bug #548544
		-DCRYPTOPP_LIBRARIES="crypto++"
		-DCRYPTOPP_FOUND=ON
		# avoid automagically enabling of ccache (bug #611010)
		-DCCACHE_EXECUTABLE=OFF
		# see https://github.com/clementine-player/Clementine/issues/5591
		-DENABLE_VK=OFF
		)

	use !debug && append-cppflags -DQT_NO_DEBUG_OUTPUT

	cmake-utils_src_configure
}

src_test() {
	cd "${CMAKE_BUILD_DIR}" || die
	virtx emake test
}

pkg_preinst() {
	gnome2_icon_savelist
}

pkg_postinst() {
	fdo-mime_desktop_database_update
	gnome2_icon_cache_update
}

pkg_postrm() {
	fdo-mime_desktop_database_update
	gnome2_icon_cache_update
}
