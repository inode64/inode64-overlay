# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Apache Guacamole is a clientless remote desktop gateway"
HOMEPAGE="https://guacamole.apache.org/"

# Download mvn and node_modules:
# tar -xf guacamole-client-1.5.4.tar.gz (don't use mc!!)
# cd guacamole-client-1.5.4
# Require Java 11
# LC_ALL=C LANG=en-US.UTF-8 mvn dependency:go-offline -Dmaven.repo.local=.m2 -Drat.ignoreErrors=true package

# Compression process:
# cd ..
# tar --create --auto-compress --file guacamole-client-1.5.4-mvn.tar.xz guacamole-client-1.5.4/.m2
# tar --create --auto-compress --file guacamole-client-1.5.4-node_modules.tar.xz guacamole-client-1.5.4/guacamole/src/main/frontend/node_modules

KEYWORDS="~amd64 ~x86"
if [[ "${PV}" == *9999 ]] ; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/apache/guacamole-client.git"
	EGIT_BRANCH="staging/1.5.4"
else
	SRC_URI="https://mirrors.ircam.fr/pub/apache/guacamole/${PV}/source/${P}.tar.gz"
fi
SRC_URI+="
	https://www.inode64.com/dist/${PF}-node_modules.tar.xz
	https://www.inode64.com/dist/${PF}-mvn.tar.xz
	mysql? ( https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-j-8.0.33.tar.gz )
	postgres? ( https://jdbc.postgresql.org/download/postgresql-42.6.0.jar )
	"

LICENSE="Apache-2.0"
SLOT="0"
IUSE="ldap +mysql postgres radius sso test totp"
REQUIRED_USE="|| ( mysql postgres )"
BDEPEND=">=dev-java/maven-bin-3.9.6"
RDEPEND="
	ldap? ( net-nds/openldap )
	virtual/jre:11
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

src_unpack() {
	if [[ "${PV}" == *9999 ]] ; then
		git-r3_src_unpack
	else
		unpack ${P}.tar.gz
	fi

	unpack ${PF}-node_modules.tar.xz
	unpack ${PF}-mvn.tar.xz

	if use mysql; then
		unpack mysql-connector-j-8.0.33.tar.gz
	fi
}

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
	if use radius; then
		doins extensions/guacamole-auth-radius/target/guacamole-auth-radius-${MY_PV}.jar
	fi
	if use sso; then
		doins extensions/guacamole-auth-sso/target/guacamole-auth-sso-${MY_PV}.jar
	fi
	if use totp; then
		doins extensions/guacamole-auth-totp/target/guacamole-auth-totp-${MY_PV}.jar
	fi
	doins extensions/guacamole-history-recording-storage/target/guacamole-history-recording-storage-${MY_PV}.jar

	if use mysql || use postgres; then
		insinto "${GUACAMOLE_HOME}/extensions"
		doins extensions/guacamole-auth-jdbc/modules/guacamole-auth-jdbc-base/target/guacamole-auth-jdbc-base-${MY_PV}.jar
	fi

	if use mysql; then
		insinto "${GUACAMOLE_HOME}/extensions"
		doins extensions/guacamole-auth-jdbc/modules/guacamole-auth-jdbc-mysql/target/guacamole-auth-jdbc-mysql-${MY_PV}.jar
		insinto "${GUACAMOLE_HOME}/lib"
		doins "${WORKDIR}"/mysql-connector-j-8.0.33/mysql-connector-j-8.0.33.jar

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
		insinto "${GUACAMOLE_HOME}/lib"
		doins "${WORKDIR}"/postgresql-42.6.0.jar

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
	elog "Create new tomcat instance for guacamole (https://wiki.gentoo.org/wiki/Apache_Tomcat):"
	elog "  /usr/share/tomcat-8.5/gentoo/tomcat-instance-manager.bash --create --suffix guacamole --user guacamole --group guacamole"
	elog
	elog "Link the war file:"
	elog "  ln -sf /usr/share/guacamole-client/guacamole.war /var/lib/tomcat-8.5-guacamole/webapps/"
	elog
	elog "Please install www-server/apache or www-server/nginx for a proxying Guacamole and update /etc/tomcat-8.5-guacamole/server.xml see:"
	elog "  https://guacamole.apache.org/doc/gug/reverse-proxy.html"
}
