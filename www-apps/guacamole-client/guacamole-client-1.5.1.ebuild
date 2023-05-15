# Copyright 1999-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Guacamole is a clientless remote desktop gateway"
HOMEPAGE="https://guacamole.apache.org/"

# Download mvn:
# cd guacamole-client-1.5.1
# Require Java 8 for maven
# LC_ALL=C LANG=en-US.UTF-8 mvn dependency:go-offline -Dmaven.repo.local=.m2 -Drat.ignoreErrors=true
#
# Download node_modules:
# cd guacamole-client-1.5.1/guacamole/src/main/frontend
# npm install --audit false --color false --foreground-scripts --progress false --verbose --ignore-scripts
#
# Compression process
# cd guacamole-client-1.5.1/..
# tar --create --auto-compress --file guacamole-client-1.5.1-mvn.tar.xz guacamole-client-1.5.1/.m2
# tar --create --auto-compress --file guacamole-client-1.5.1-node_modules.tar.xz guacamole-client-1.5.1/guacamole/src/main/frontend/node_modules

if [[ "${PV}" == *9999 ]] ; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/apache/incubator-guacamole-client.git"
else
	KEYWORDS="~amd64 ~x86"
	SRC_URI="https://mirrors.ircam.fr/pub/apache/guacamole/${PV}/source/${P}.tar.gz
		https://inode64.com/dist/${P}-node_modules.tar.xz
		https://inode64.com/dist/${P}-mvn.tar.xz"
fi

LICENSE="MIT"
SLOT="0"
IUSE="ldap +mysql postgres test"
REQUIRED_USE="|| ( mysql postgres )"
BDEPEND="dev-java/maven-bin"
RDEPEND="
	ldap? ( net-nds/openldap )
	virtual/jre:1.8
	www-servers/tomcat:8.5
	"
RESTRICT="!test? ( test )"

PATCHES=(
	"${FILESDIR}"/npm_offline.diff
)

MY_PN="guacamole"
MY_PV="$(ver_cut 1-3)"
GUACAMOLE_HOME="/etc/${MY_PN}"
CLASSPATH="${GUACAMOLE_HOME}/lib"

src_compile() {
	export LC_ALL=C
	export LANG=en-US.UTF-8

	local myconf=(
		-Dmaven.repo.local="${S}/.m2"
		-Drat.ignoreErrors=true
	)

	if ! use test; then
		myconf+=(
			-DskipTests=true
	    )
	fi

	mvn package ${myconf[@]} || die
}

src_install() {
	insinto "${GUACAMOLE_HOME}/extensions"
	#doins extensions/guacamole-auth-duo/target/guacamole-auth-duo-${MY_PV}.jar
	doins extensions/guacamole-auth-header/target/guacamole-auth-header-${MY_PV}.jar
	doins extensions/guacamole-auth-json/target/guacamole-auth-json-${MY_PV}.jar
	doins extensions/guacamole-auth-quickconnect/target/guacamole-auth-quickconnect-${MY_PV}.jar
	#doins extensions/guacamole-auth-radius/target/guacamole-auth-radius-${MY_PV}.jar
	#doins extensions/guacamole-auth-sso/target/guacamole-auth-sso-${MY_PV}.jar
	#doins extensions/guacamole-auth-totp/target/guacamole-auth-totp-${MY_PV}.jar
	#doins extensions/guacamole-history-recording-storage/target/guacamole-history-recording-storage-${MY_PV}.jar

	if use mysql || use postgres; then
		insinto "${GUACAMOLE_HOME}/extensions"
		doins extensions/guacamole-auth-jdbc/modules/guacamole-auth-jdbc-base/target/guacamole-auth-jdbc-base-${MY_PV}.jar
	fi

	if use mysql; then
		insinto "${GUACAMOLE_HOME}/extensions"
		doins extensions/guacamole-auth-jdbc/modules/guacamole-auth-jdbc-mysql/target/guacamole-auth-jdbc-mysql-${MY_PV}.jar

		insinto "/usr/share/${PN}/schema/mysql"
		find "${S}/extensions/${MY_PN}-auth-jdbc/modules/${MY_PN}-auth-jdbc-mysql/schema/" -name '*.sql' -exec doins '{}' +

		elog "Please add a mysql database and a user and load the sql files in /usr/share/${PN}/schema/ into it."
		elog "If this is an update, then you will need to apply the appropriate update script in the location above."
		elog "You will also need to adjust the DB properties in ${GUACAMOLE_HOME}/guacamole.properties!"
		elog "The default user and it's password is \"guacadmin\"."
		elog "-"
	fi

	if use postgres; then
		insinto "${GUACAMOLE_HOME}/extensions"
		doins extensions/guacamole-auth-jdbc/modules/guacamole-auth-jdbc-postgresql/target/guacamole-auth-jdbc-postgresql-${MY_PV}.jar

		insinto "/usr/share/${PN}/schema/postgres"
		find "${S}/extensions/${MY_PN}-auth-jdbc/modules/${MY_PN}-auth-jdbc-postgresql/schema/" -name '*.sql' -exec doins '{}' +

		elog "Please add a postgresql database and a user and load the sql files in /usr/share/${PN}/schema/ into it."
		elog "If this is an update, then you will need to apply the appropriate update script in the location above."
		elog "You will also need to adjust the DB properties in ${GUACAMOLE_HOME}/guacamole.properties!"
		elog "The default user and it's password is \"guacadmin\"."
		elog "-"
	fi

	if use ldap; then
		insinto "${GUACAMOLE_HOME}/extensions"
		doins extensions/guacamole-auth-ldap/target/guacamole-auth-ldap-${MY_PV}.jar

		insinto "/usr/share/${PN}/schema"
		doins "${S}/extensions/${MY_PN}-auth-ldap/schema/guacConfigGroup.ldif" "${S}/extensions/${MY_PN}-auth-ldap/schema/guacConfigGroup.schema"

		elog "You will need to add and load the .schema file in /usr/share/${PN}/schema/ to your ldap server."
		elog "You will also need to adjust the DB properties in ${GUACAMOLE_HOME}/guacamole.properties!"
		elog "There is also an example .lidf file for creating the users."
		elog "-"
	fi

	insinto "${GUACAMOLE_HOME}"
	doins "${FILESDIR}"/guacamole.properties
	doins "${S}/${MY_PN}/doc/example/user-mapping.xml"
	doins "${S}/${MY_PN}/src/main/resources/logback.xml"
	keepdir ${CLASSPATH}

	echo "GUACAMOLE_HOME=${GUACAMOLE_HOME}" >98guacamole
	doenvd 98guacamole

	insinto "/usr/share/${PN}"
	newins "${S}/${MY_PN}/target/${MY_PN}-${MY_PV}.war" "${MY_PN}.war"

	elog "Guacamole split in two components, please install net-mis/guacamole-server in a computer when you need a Guacamole proxy"
	elog
	elog "If it is an update, please make sure to delete the old webapp in /var/lib/tomcat-8.5/webapps/ first!"
	elog "To deploy guacamole with tomcat, you will need to link the war file and create the configuration!"
	elog "ln -sf /var/lib/${MY_PN}/${MY_PN}.war /var/lib/tomcat-8.5/webapps/"
	elog "You will also need to adjust the configuration in ${GUACAMOLE_HOME}/${MY_PN}.properties"
	elog "With systemd make sure that the var GUACAMOLE_HOME is set to ${GUACAMOLE_HOME}. for example via /etc/conf/tomcat."
	elog "See https://guacamole.apache.org/doc/gug/configuring-guacamole.html for a basic setup"
	elog "or https://guacamole.apache.org/doc/gug/jdbc-auth.html for a database for authentication and host definitions."
	elog
	elog "Please install www-server/apache or www-server/nginx for a proxying Guacamole see: https://guacamole.apache.org/doc/gug/proxying-guacamole.html"
}
