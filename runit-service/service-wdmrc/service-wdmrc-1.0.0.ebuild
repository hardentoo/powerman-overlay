# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

DESCRIPTION="Service for net-fs/wdmrc"
HOMEPAGE="http://powerman.name/RTFM/runit.html"
SRC_URI="http://powerman.name/download/Gentoo/${P}.tgz"

LICENSE="public-domain"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

DEPEND=""
RDEPEND="
	runit-service/setupservices
	net-fs/wdmrc
	"

src_install() {
	cp -a * "${D}"
}

pkg_postinst() {
	chown log:root /var/log/wdmrc
	chmod 2750 /var/log/wdmrc
	chown log:root /var/log/wdmrc/all
	chmod 2755 /var/log/wdmrc/all
	chown log:root /var/log/wdmrc/*/{lock,state,newstate,current} 2>/dev/null
}
