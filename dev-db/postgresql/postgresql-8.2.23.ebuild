# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# PostgreSQL 8.2 (diciembre de 2011, sin soporte upstream desde 2011) revivido
# para el toolchain de 2026: gcc-15 + glibc-2.43.  Derivado del ebuild original
# de Gentoo (postgresql-9.0.19.ebuild, EAPI 6), reescrito a EAPI 8 porque
# eutils/user/versionator ya no existen en el arbol.
#
# Solo se exponen las USE 'server' y 'pg_legacytimestamp'.  readline, zlib y nls
# van siempre activadas porque es lo que tenia el binario que hay en produccion
# (los mensajes del servidor salen en espanol); ssl, perl, ldap, python, tcl,
# kerberos, pam, uuid y xml se han eliminado del ebuild.

EAPI=8

inherit flag-o-matic systemd tmpfiles

DESCRIPTION="PostgreSQL RDBMS (legacy 8.2 slot, server only)"
HOMEPAGE="https://www.postgresql.org/"
SRC_URI="https://ftp.postgresql.org/pub/source/v${PV}/postgresql-${PV}.tar.bz2"

LICENSE="POSTGRESQL GPL-2"
SLOT="8.2"
KEYWORDS="amd64 x86"

IUSE="+pg_legacytimestamp +server"

# La suite de regresion de 8.2 no pasa dentro del entorno de Portage.
RESTRICT="test"

CDEPEND="
	>=app-eselect/eselect-postgresql-2.0
	acct-group/postgres
	acct-user/postgres
	sys-apps/less
	sys-libs/readline:0=
	virtual/libcrypt:=
	virtual/libintl
	virtual/zlib:=
"
DEPEND="${CDEPEND}"
BDEPEND="sys-devel/gettext"
RDEPEND="${CDEPEND}
	!dev-db/postgresql-base:${SLOT}
	!dev-db/postgresql-docs:${SLOT}
	!dev-db/postgresql-server:${SLOT}
"

src_prepare() {
	default

	# El socket unix de Gentoo esta en /run/postgresql, no en /tmp.
	sed -e "s|\(PGSOCKET_DIR[[:space:]]\+\)\"/tmp\"|\1\"${EPREFIX}/run/postgresql\"|" \
		-i src/include/pg_config_manual.h || die "no se pudo fijar PGSOCKET_DIR"
	grep -q "${EPREFIX}/run/postgresql" src/include/pg_config_manual.h \
		|| die "PGSOCKET_DIR no quedo apuntando a /run/postgresql"

	# El tarball ya trae los parsers generados (gram.c, scan.c, preproc.c...).
	# Las gramaticas de 2006 no pasan por bison-3/flex-2.6, asi que envejecemos
	# las fuentes .y/.l para que make no intente regenerarlas nunca.
	find . \( -name '*.y' -o -name '*.l' \) -exec touch -d '@1' {} + \
		|| die "no se pudo envejecer las gramaticas"
}

src_configure() {
	# --- Adaptacion del codigo de 2006 al toolchain de 2026 -----------------
	#
	# gcc-15 compila C23 por defecto: ahi 'bool', 'true' y 'false' son palabras
	# reservadas y chocan con el typedef de src/include/c.h, y las definiciones
	# de funcion al estilo K&R desaparecen.  gnu17 es el ultimo estandar que
	# acepta este codigo tal cual.
	append-cflags -std=gnu17

	# gcc-14 convirtio en errores duros varios diagnosticos que en 2006 eran
	# avisos normales.  Sin esto ni siquiera los tests de ./configure compilan,
	# con lo que configure deduciria mal media docena de capacidades del sistema.
	append-cflags $(test-flags-CC \
		-Wno-error=implicit-function-declaration \
		-Wno-error=implicit-int \
		-Wno-error=int-conversion \
		-Wno-error=incompatible-pointer-types \
		-Wno-error=return-mismatch \
		-Wno-error=declaration-missing-parameter-type \
		-Wno-error=builtin-declaration-mismatch \
		-Wno-error=format-security)

	# gcc-10 puso -fno-common por defecto; este arbol declara simbolos comunes.
	append-cflags -fcommon

	# PostgreSQL no incorporo -fwrapv a su configure hasta 8.3: sin el, gcc
	# moderno elimina comprobaciones de desbordamiento de enteros con signo.
	# -fno-strict-aliasing y -fno-aggressive-loop-optimizations son por el mismo
	# motivo (el codigo hace type punning y bucles que gcc puede "optimizar" mal).
	append-cflags -fwrapv -fno-strict-aliasing -fno-aggressive-loop-optimizations

	# El perfil 23.0 activa -D_FORTIFY_SOURCE=3, que usa tamanos de objeto
	# dinamicos y no se lleva bien con los arrays flexibles falsos (char x[1])
	# que usa el 8.2 por todas partes.  Bajamos al nivel 2, que es con el que se
	# construyo el binario que hay en produccion.
	append-cppflags -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=2

	# LTO sobre este arbol no es una apuesta razonable.
	filter-lto

	export LDFLAGS_SL="${LDFLAGS}"
	export LDFLAGS_EX="${LDFLAGS}"

	local PO="${EPREFIX%/}"

	econf \
		--prefix="${PO}/usr/$(get_libdir)/postgresql-${SLOT}" \
		--datadir="${PO}/usr/share/postgresql-${SLOT}" \
		--includedir="${PO}/usr/include/postgresql-${SLOT}" \
		--mandir="${PO}/usr/share/postgresql-${SLOT}/man" \
		--sysconfdir="${PO}/etc/postgresql-${SLOT}" \
		--with-system-tzdata="${PO}/usr/share/zoneinfo" \
		--without-docdir \
		--enable-thread-safety \
		--with-readline \
		--with-zlib \
		--without-gssapi \
		--without-krb5 \
		--without-ldap \
		--without-pam \
		--without-perl \
		--without-python \
		--without-openssl \
		--without-tcl \
		--without-libxml \
		--without-libxslt \
		--without-ossp-uuid \
		--enable-nls \
		$(use_enable !pg_legacytimestamp integer-datetimes)
}

src_compile() {
	emake
	emake -C contrib
}

src_install() {
	emake DESTDIR="${D}" install
	emake DESTDIR="${D}" install -C contrib

	dodoc README HISTORY doc/{TODO,bug.template}

	# Las paginas de manual ya vienen construidas y las instala 'make install'
	# bajo /usr/share/postgresql-${SLOT}/man para que las gestione eselect.
	if ! use server ; then
		local m
		for m in initdb ipcclean pg_controldata pg_ctl pg_resetxlog \
				postgres postmaster ; do
			rm -f "${ED}/usr/share/postgresql-${SLOT}/man/man1/${m}.1" || die
			rm -f "${ED}/usr/$(get_libdir)/postgresql-${SLOT}/bin/${m}" || die
		done
	fi
	docompress /usr/share/postgresql-${SLOT}/man/man{1,3,7}

	insinto /etc/postgresql-${SLOT}
	newins src/bin/psql/psqlrc.sample psqlrc

	dodir /etc/eselect/postgresql/slots/${SLOT}
	echo "postgres_ebuilds=\"\${postgres_ebuilds} ${PF}\"" > \
		"${ED}/etc/eselect/postgresql/slots/${SLOT}/base" || die

	find "${ED}" -name '*.a' -delete || die

	if use server ; then
		sed -e "s|@SLOT@|${SLOT}|g" -e "s|@LIBDIR@|$(get_libdir)|g" \
			"${FILESDIR}/${PN}.confd-pre_9.2" | newconfd - ${PN}-${SLOT}

		sed -e "s|@SLOT@|${SLOT}|g" -e "s|@LIBDIR@|$(get_libdir)|g" \
			"${FILESDIR}/${PN}.init-pre_9.2" | newinitd - ${PN}-${SLOT}

		sed -e "s|@SLOT@|${SLOT}|g" -e "s|@LIBDIR@|$(get_libdir)|g" \
			"${FILESDIR}/${PN}.service-pre_9.2" | \
			systemd_newunit - ${PN}-${SLOT}.service

		newbin "${FILESDIR}/${PN}-check-db-dir" ${PN}-${SLOT}-check-db-dir

		newtmpfiles "${FILESDIR}/${PN}.tmpfiles" ${PN}-${SLOT}.conf
	fi
}

pkg_postinst() {
	postgresql-config update

	use server && tmpfiles_process ${PN}-${SLOT}.conf

	elog "Si necesitas un psqlrc global, ponlo en:"
	elog "    ${EROOT}/etc/postgresql-${SLOT}/"

	if use server ; then
		elog
		elog "El socket unix por defecto es:"
		elog "    ${EROOT}/run/postgresql/"
		elog
		elog "Para crear un cluster nuevo:"
		elog "    emerge --config =${CATEGORY}/${PF}"
		elog
		if use pg_legacytimestamp ; then
			elog "Compilado con marcas de tiempo en coma flotante"
			elog "(--disable-integer-datetimes), que es el formato con el que se"
			elog "creo el cluster 8.2 existente.  NO desactives pg_legacytimestamp:"
			elog "el servidor se negaria a abrir ese cluster."
		else
			ewarn "Compilado SIN pg_legacytimestamp (--enable-integer-datetimes)."
			ewarn "Un cluster 8.2 creado con el ebuild anterior NO arrancara con"
			ewarn "este binario.  Vuelve a activar pg_legacytimestamp si es el caso."
		fi
	fi
}

pkg_prerm() {
	if use server && [[ -z ${REPLACED_BY_VERSION} ]] ; then
		ewarn "Has volcado y/o migrado el cluster ${SLOT}?"
		ewarn "    https://wiki.gentoo.org/wiki/PostgreSQL"

		ebegin "Continuando con el borrado en 10 segundos (Control-C para cancelar)"
		sleep 10
		eend 0
	fi
}

pkg_postrm() {
	postgresql-config update
}

pkg_config() {
	use server || die "USE flag 'server' not enabled. Nothing to configure."

	[[ -f "${EROOT}/etc/conf.d/postgresql-${SLOT}" ]] \
		&& source "${EROOT}/etc/conf.d/postgresql-${SLOT}"
	[[ -z "${PGDATA}" ]] && PGDATA="${EROOT}/etc/postgresql-${SLOT}/"
	[[ -z "${DATA_DIR}" ]] \
		&& DATA_DIR="${EROOT}/var/lib/postgresql/${SLOT}/data"

	# environment.bz2 puede traer un locale distinto al del sistema.
	if [[ -f "${EROOT}/etc/env.d/02locale" ]] ; then
		unset LANG LC_CTYPE LC_NUMERIC LC_TIME LC_COLLATE LC_MONETARY \
			LC_MESSAGES LC_ALL
		source "${EROOT}/etc/env.d/02locale"
		[[ -n "${LANG}" ]] && export LANG
		[[ -n "${LC_CTYPE}" ]] && export LC_CTYPE
		[[ -n "${LC_NUMERIC}" ]] && export LC_NUMERIC
		[[ -n "${LC_TIME}" ]] && export LC_TIME
		[[ -n "${LC_COLLATE}" ]] && export LC_COLLATE
		[[ -n "${LC_MONETARY}" ]] && export LC_MONETARY
		[[ -n "${LC_MESSAGES}" ]] && export LC_MESSAGES
		[[ -n "${LC_ALL}" ]] && export LC_ALL
	fi

	einfo "Las rutas y opciones de initdb se editan en:"
	einfo "    ${EROOT}/etc/conf.d/postgresql-${SLOT}"
	einfo
	einfo "PG_INITDB_OPTS vale ahora mismo:"
	einfo "    ${PG_INITDB_OPTS:-(ninguna)}"
	einfo
	einfo "Los ficheros de configuracion se instalaran en:"
	einfo "    ${PGDATA}"
	einfo
	einfo "El cluster se creara en:"
	einfo "    ${DATA_DIR}"
	einfo
	local answer correct
	while [[ "${correct}" != "true" ]] ; do
		einfo "Continuamos? (y/n)"
		read answer
		if [[ ${answer} =~ ^[Yy]([Ee][Ss])?$ ]] ; then
			correct="true"
		elif [[ ${answer} =~ ^[Nn]([Oo])?$ ]] ; then
			die "Inicializacion abortada."
		else
			echo "Respuesta no reconocida"
		fi
	done

	if [[ -n "$(ls -A "${DATA_DIR}" 2> /dev/null)" ]] ; then
		eerror "El directorio '${DATA_DIR}' no esta vacio."
		die "${DATA_DIR} no esta vacio."
	fi

	einfo "Creando el directorio de datos ..."
	if [[ ${EUID} == 0 ]] ; then
		mkdir -p "${DATA_DIR}"
		chown -Rf postgres:postgres "${DATA_DIR}"
		chmod 0700 "${DATA_DIR}"
	fi

	einfo "Inicializando la base de datos ..."
	if [[ ${EUID} == 0 ]] ; then
		su postgres -c "${EROOT}/usr/$(get_libdir)/postgresql-${SLOT}/bin/initdb -D \"${DATA_DIR}\" ${PG_INITDB_OPTS}"
	else
		"${EROOT}/usr/$(get_libdir)/postgresql-${SLOT}/bin/initdb" -U postgres \
			-D "${DATA_DIR}" ${PG_INITDB_OPTS}
	fi

	if [[ "${DATA_DIR%/}" != "${PGDATA%/}" ]] ; then
		mv "${DATA_DIR%/}"/{pg_{hba,ident},postgresql}.conf "${PGDATA}"
		ln -s "${PGDATA%/}"/{pg_{hba,ident},postgresql}.conf "${DATA_DIR%/}"
	fi

	einfo "El servidor registra los eventos por defecto en:"
	einfo "    ${DATA_DIR%/}/postmaster.log"
	einfo
	einfo "Usa ${EROOT}/etc/init.d/postgresql-${SLOT} en lugar de pg_ctl."
}
