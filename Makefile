# Created by: Mateusz Piotrowski <0mp@FreeBSD.org>
# $FreeBSD: head/sysutils/nix/Makefile 550026 2020-09-25 12:54:38Z 0mp $

PORTNAME=	nix
DISTVERSION=	2.19.2
CATEGORIES=	sysutils

MAINTAINER=	0mp@FreeBSD.org
COMMENT=	Purely functional package manager

LICENSE=	LGPL21
LICENSE_FILE=	${WRKSRC}/COPYING

BUILD_DEPENDS=	${LOCALBASE}/share/aclocal/ax_cxx_compile_stdcxx.m4:devel/autoconf-archive \
		bash:shells/bash \
		gsed:textproc/gsed \
		mdbook:textproc/mdbook \
		mdbook-linkcheck:textproc/mdbook-linkcheck \
		gnustat:sysutils/coreutils \
		grealpath:sysutils/coreutils \
		jq:textproc/jq \
		libarchive>=3.1.2:archivers/libarchive \
		googletest>0:devel/googletest \
		${LOCALBASE}/include/rapidcheck/gtest.h:devel/rapidcheck \
		nlohmann-json>=3.9.1_2:devel/nlohmann-json
LIB_DEPENDS=	libaws-cpp-sdk-core.so:devel/aws-sdk-cpp \
		libaws-crt-cpp.so:devel/aws-crt-cpp \
		libboost_context.so:devel/boost-libs \
		libbrotlienc.so:archivers/brotli \
		libcurl.so:ftp/curl \
		libeditline.so:devel/editline \
		libgc.so:devel/boehm-gc \
		liblowdown.so:textproc/lowdown \
		libsodium.so:security/libsodium
TEST_DEPENDS=	dot:graphics/graphviz \
		git:devel/git \
		gxargs:misc/findutils \
		hg:devel/mercurial

USES=		autoreconf bison compiler:c++20-lang gmake localbase pkgconfig \
		sqlite:3 ssl
USE_GITHUB=	yes
GH_ACCOUNT=	NixOS
GH_TAGNAME=	50f8f1c
USE_LDCONFIG=	yes
USE_RC_SUBR=	nix-daemon

HAS_CONFIGURE=		yes
# Workaround for bashisms in the configure script.
CONFIGURE_SHELL=	${_BASH}
CONFIGURE_ARGS=		--disable-seccomp-sandboxing \
			--enable-gc \
			--with-system=x86_64-freebsd14
CONFIGURE_ENV=		OPENSSL_CFLAGS="-I ${OPENSSLINC}" \
			OPENSSL_LIBS="-L ${OPENSSLLIB}"
# Workaround for:
#   /usr/bin/ld: error: undefined symbol: SHA512_Update
MAKE_ARGS=		libutil_ALLOW_UNDEFINED=yes
# XXX: Tests require the port to be installed on the system. It is not enough
# to have the port staged.
TEST_ARGS=		nix_tests="${_PASSING_TESTS}"
TEST_TARGET=		installcheck

# grealpath and gnustat are needed for tests.
BINARY_ALIAS=	realpath=grealpath stat=gnustat sed=gsed

SUB_FILES=	pkg-message

GROUPS=		nixbld

OPTIONS_DEFINE=	DOCS

_BASH=		${LOCALBASE}/bin/bash
_STRIP_TARGETS=	bin/nix bin/nix-build bin/nix-channel bin/nix-collect-garbage \
		bin/nix-copy-closure bin/nix-daemon bin/nix-env \
		bin/nix-instantiate bin/nix-prefetch-url bin/nix-store \
		lib/libnixexpr.so lib/libnixmain.so lib/libnixstore.so \
		lib/libnixutil.so
# Regenerate the list of all tests with:
# make patch && make -f $(make -V WRKSRC)/tests/local.mk -V nix_tests
_ALL_TESTS=	init.sh hash.sh lang.sh add.sh simple.sh dependencies.sh gc.sh \
		gc-concurrent.sh gc-auto.sh referrers.sh user-envs.sh \
		logging.sh nix-build.sh misc.sh fixed.sh gc-runtime.sh \
		check-refs.sh filter-source.sh remote-store.sh export.sh \
		export-graph.sh timeout.sh secure-drv-outputs.sh nix-channel.sh \
		multiple-outputs.sh import-derivation.sh fetchurl.sh \
		optimise-store.sh binary-cache.sh nix-profile.sh repair.sh \
		dump-db.sh case-hack.sh check-reqs.sh pass-as-file.sh \
		tarball.sh restricted.sh placeholders.sh nix-shell.sh \
		linux-sandbox.sh build-dry.sh build-remote.sh nar-access.sh \
		structured-attrs.sh fetchGit.sh fetchMercurial.sh signing.sh \
		run.sh brotli.sh pure-eval.sh check.sh plugins.sh search.sh \
		nix-copy-ssh.sh post-hook.sh function-trace.sh
# Remove problematic tests from the list:
# - restricted.sh is hanging and never finishes.
_PASSING_TESTS=	${_ALL_TESTS:Nrestricted.sh}

post-install:
	@${MKDIR} ${STAGEDIR}${DATADIR}
	${INSTALL_SCRIPT} ${FILESDIR}/add-nixbld-users ${STAGEDIR}${DATADIR}

	@${RM} ${STAGEDIR}${PREFIX}/libexec/nix/build-remote
	@${RLN} ${STAGEDIR}${PREFIX}/bin/nix ${STAGEDIR}${PREFIX}/libexec/nix/build-remote

	@cd ${STAGEDIR}${PREFIX} && ${STRIP_CMD} ${_STRIP_TARGETS}

pre-test:
	${MKDIR} /tmp/nix-test

	${REINPLACE_CMD} -e 's| xargs | gxargs |g' ${WRKSRC}/tests/push-to-store.sh
	${REINPLACE_CMD} -e 's| touch | ${TOUCH} |g' ${WRKSRC}/tests/timeout.nix
	${REINPLACE_CMD} -e 's| touch | ${TOUCH} |g' ${WRKSRC}/tests/check-reqs.nix
	${REINPLACE_CMD} -e 's| touch | ${TOUCH} |g' ${WRKSRC}/tests/nar-access.nix
	${REINPLACE_CMD} -e 's| touch | ${TOUCH} |g' ${WRKSRC}/tests/pass-as-file.sh
	${REINPLACE_CMD} -e 's| date | ${LOCALBASE}/bin/gdate |g' ${WRKSRC}/tests/check.nix

	${REINPLACE_CMD} -e 's| wc -l)| /usr/bin/grep -c .)|g' ${WRKSRC}/tests/gc-auto.sh
	${REINPLACE_CMD} -e 's| tar c tarball)| tar -cf - tarball)|' ${WRKSRC}/tests/tarball.sh
	${REINPLACE_CMD} -e 's|^grep |/usr/bin/grep |' ${WRKSRC}/tests/check.sh

post-test:
	${RM} -r /tmp/nix-test

.include <bsd.port.mk>
