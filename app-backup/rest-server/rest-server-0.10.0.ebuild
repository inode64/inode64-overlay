# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit bash-completion-r1 go-module

DESCRIPTION="High-performance HTTP server that implements restic's REST backend API"
HOMEPAGE="https://github.com/restic/rest-server"

EGO_SUM=(
	"github.com/beorn7/perks v0.0.0-20160804104726-4c0e84591b9a"
	"github.com/beorn7/perks v0.0.0-20160804104726-4c0e84591b9a/go.mod"
	"github.com/golang/protobuf v1.0.0"
	"github.com/golang/protobuf v1.0.0/go.mod"
	"github.com/gorilla/handlers v1.3.0"
	"github.com/gorilla/handlers v1.3.0/go.mod"
	"github.com/inconshreveable/mousetrap v1.0.0"
	"github.com/inconshreveable/mousetrap v1.0.0/go.mod"
	"github.com/matttproud/golang_protobuf_extensions v1.0.0"
	"github.com/matttproud/golang_protobuf_extensions v1.0.0/go.mod"
	"github.com/miolini/datacounter v0.0.0-20171104152933-fd4e42a1d5e0"
	"github.com/miolini/datacounter v0.0.0-20171104152933-fd4e42a1d5e0/go.mod"
	"github.com/prometheus/client_golang v0.8.0"
	"github.com/prometheus/client_golang v0.8.0/go.mod"
	"github.com/prometheus/client_model v0.0.0-20171117100541-99fa1f4be8e5"
	"github.com/prometheus/client_model v0.0.0-20171117100541-99fa1f4be8e5/go.mod"
	"github.com/prometheus/common v0.0.0-20180110214958-89604d197083"
	"github.com/prometheus/common v0.0.0-20180110214958-89604d197083/go.mod"
	"github.com/prometheus/procfs v0.0.0-20180212145926-282c8707aa21"
	"github.com/prometheus/procfs v0.0.0-20180212145926-282c8707aa21/go.mod"
	"github.com/spf13/cobra v0.0.1"
	"github.com/spf13/cobra v0.0.1/go.mod"
	"github.com/spf13/pflag v1.0.0"
	"github.com/spf13/pflag v1.0.0/go.mod"
	"goji.io v2.0.2+incompatible"
	"goji.io v2.0.2+incompatible/go.mod"
	"golang.org/x/crypto v0.0.0-20180214000028-650f4a345ab4"
	"golang.org/x/crypto v0.0.0-20180214000028-650f4a345ab4/go.mod"
	"golang.org/x/sync v0.0.0-20200317015054-43a5402ce75a"
	"golang.org/x/sync v0.0.0-20200317015054-43a5402ce75a/go.mod"
)

go-module_set_globals

SRC_URI="https://github.com/restic/rest-server/archive/v${PV}.tar.gz -> ${P}.tar.gz
	${EGO_SUM_SRC_URI}"

LICENSE="BSD-2"
SLOT="0"
KEYWORDS="amd64 ~arm ~arm64 ~ppc64 ~x86"
IUSE=""

RDEPEND="virtual/httpd-basic"
DEPEND="${RDEPEND}"

src_compile() {
	local mygoargs=(
		-v
		-work
		-x
		-tags release
		-ldflags "-X main.version=${PV}"
		-asmflags "-trimpath=${S}"
		-gcflags "-trimpath=${S}"
	)

	CGO_ENABLED=0 go build "${mygoargs[@]}" -o rest-server ./cmd/rest-server || die
}

src_install() {
	dobin rest-server

	dodoc *.md
}
