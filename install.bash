#!/bin/bash

# ------------------------------------------------------------------------- #

  #*#   ######             #
   #    #     #           # #    #####   #####     ##     #   #
   #    #     #          #   #   #    #  #    #   #  #     # #
   #    ######   #####  #     #  #    #  #    #  #    #     #
   #    #               #######  #####   #####   ######     #
   #    #               #     #  #   #   #   #   #    #     #
  ###   #               #     #  #    #  #    #  #    #     #

# ------------------------------------------------------------------------- #
#
#    Copyright (C) 2005-2013  AllKind
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA
#
# ------------------------------------------------------------------------- #
#
#                        IP-ARRAY INSTALL SCRIPT
#
# ------------------------------------------------------------------------- #

# bash check
if [ -z "$BASH" ]; then
	echo "\`BASH' variable is not available. Not running bash?"
	exit 1
fi

# shell options
set +f -o braceexpand
umask 0027

# variables
PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/bin:/usr/local/sbin
ME=ip-array
BACKUP=
GROUP=
BINDIR=
DATAROOTDIR=
DEFAULTSDIR=
DOCDIR=
INITDIR=
LIBDIR=
MANDIR=
NOACT=
OWNER=
OWNSH=
PREFIX=
SYSCONFDIR=
VERBOSE=

# ------------------------------------------------------------------------- #
# FUNCTIONS
# ------------------------------------------------------------------------- #

usage() {
printf "
USAGE: ${0##*/} [[Option] Option-argument] [...]\n
Options:
-?, -h, --help                   Show this usage instructions.
-b, --backup                     Create numbered backups (suffix=~).
-g, --group group_name           Set group ownership. Default: root
-n, --no-act                     Perform a dry-run.
-o, --owner owner_name           Set ownership. Default: root
-v, --verbose                    Verbose output.
--prefix /path                   Prefix directory. Default: /usr/local
--datarootdir /path              Default: PREFIX/share
--defaultsdir /path              Default: /etc/defaults
--docdir /path                   Default: DATAROOTDIR/doc
--initdir /path                  Default: /etc/init.d
--libdir /path                   Default: PREFIX/lib
--mandir /path                   Default: DATAROOTDIR/man
--sysconfdir /path               Default: PREFIX/etc
\n"
}

no_act() { # just print the command string
printf "%s\n" "$*"
}

create_dirs() { # create all directory components
${NOACT}install $VERBOSE $OWNSH -d "$@"
}

install_dir() { # install multiple source files to destination
local str_perm
case "$1" in
	-m|--mode)
		str_perm="-m $2"
		shift 2
	;;
esac
${NOACT}install $VERBOSE $BACKUP $OWNSH $str_perm "$@"
}

install_file() { # install a single file
local str_perm
case "$1" in
	-m|--mode)
		str_perm="-m $2"
		shift 2
	;;
esac
${NOACT}install $VERBOSE $BACKUP $OWNSH $str_perm -T "$@"
}

# ------------------------------------------------------------------------- #
# MAIN
# ------------------------------------------------------------------------- #

# parse arguments
while (($#)); do
	option="$1" opt_arg="$2"
	shift
	case "$option" in
		"-?"|-h|--help) usage
			exit 0
		;;
		-b|--backup) BACKUP="--backup=t"
			continue
       	;;
		-g|--group) GROUP="$opt_arg" ;;
		-n|--no-act) NOACT="no_act "
			continue
       	;;
		-o|--owner) OWNER="$opt_arg" ;;
		-v|--verbose) VERBOSE="-v"
			continue
		;;
		--bindir) BINDIR="$opt_arg" ;;
		--datarootdir) DATAROOTDIR="$opt_arg" ;;
		--defaultsdir) DEFAULTSDIR="$opt_arg" ;;
		--docdir) DOCDIR="$opt_arg" ;;
		--initdir) INITDIR="$opt_arg" ;;
		--libdir) LIBDIR="$opt_arg" ;;
		--mandir) MANDIR="$opt_arg" ;;
		--prefix) PREFIX="$opt_arg" ;;
		--sysconfdir) SYSCONFDIR="$opt_arg" ;;
		*) usage
			exit 3
	esac
	if [[ $opt_arg ]]; then shift; fi
done

# set defaults
: ${INITDIR:=/etc/init.d}
: ${PREFIX:=/usr/local}
: ${DATAROOTDIR:=${PREFIX}/share}
: ${BINDIR:=${PREFIX}/bin}
: ${LIBDIR:=${PREFIX}/lib}
: ${SYSCONFDIR:=${PREFIX}/etc}
: ${DEFAULTSDIR:=${SYSCONFDIR}/${ME}}
: ${DOCDIR:=${DATAROOTDIR}/doc}
: ${MANDIR:=${DATAROOTDIR}/man}

: ${OWNER:=root}
: ${GROUP:=root}
OWNSH="--group=$GROUP --owner=$OWNER"

# warning message on dry-run
if [[ $NOACT ]]; then
	printf "\nNO ACT MODE - NOT INSTALLING!\n\n"
fi

# check for install bin
command -v install &>/dev/null || {
	printf "Unable to find the \`install' binary in \$PATH."
   	exit 1
}

# warn about ownership - if not root
if ((UID != 0)); then
	printf "Not running as root. Not changing ownership/groups.\n"
	OWNSH=
fi

# create directories
create_dirs "${BINDIR}" "${LIBDIR}/$ME" "${DATAROOTDIR}/$ME" "${DOCDIR}/$ME" "${INITDIR}"
create_dirs "${DATAROOTDIR}/${ME}/"{scripts,template_repo.d} \
	"${DATAROOTDIR}/${ME}/scripts/"{epilog,prolog} \
	"${DOCDIR}/${ME}/"{docbook,examples,html} \
	"${MANDIR}/"{man5,man8}
create_dirs "${DEFAULTSDIR}" "${SYSCONFDIR}/${ME}/"{save.d,help.d,stable,test}
create_dirs "${SYSCONFDIR}/${ME}/stable/conf.d/"{rules.d,ruleblocks.d,templates.d}
create_dirs "${SYSCONFDIR}/${ME}/stable/scripts.d/"{epilog,prolog}

# copy files
install_dir -m 0640 conf.d/*.conf "${SYSCONFDIR}/${ME}/stable/conf.d"
install_dir -m 0640 conf.d/ruleblocks.d/* "${SYSCONFDIR}/${ME}/stable/conf.d/ruleblocks.d"
install_dir -m 0640 conf.d/rules.d/* "${SYSCONFDIR}/${ME}/stable/conf.d/rules.d"
install_dir -m 0640 conf.d/templates.d/* "${SYSCONFDIR}/${ME}/stable/conf.d/templates.d"

install_dir -m 0644 template_repo.d/* "${DATAROOTDIR}/${ME}/template_repo.d"
install_dir -m 0644 help.d/public_functions/*.txt "${DATAROOTDIR}/${ME}/help.d"
install_dir -m 0644 help.d/docbook/* "${DOCDIR}/${ME}/docbook"
install_dir -m 0644 help.d/examples/* "${DOCDIR}/${ME}/examples"
install_dir -m 0644 help.d/html/* "${DOCDIR}/${ME}/html"
install_dir -m 0644 help.d/man/*.5 "${MANDIR}/man5"
install_dir -m 0644 help.d/man/*.8 "${MANDIR}/man8"
install_dir -m 0644 scripts.d/prolog/* "${DATAROOTDIR}/${ME}/scripts/prolog"
install_dir -m 0644 scripts.d/epilog/* "${DATAROOTDIR}/${ME}/scripts/epilog"
install_dir -m 0644 "${ME}"_*_functions "${LIBDIR}/$ME"

install_file -m 0640 defaults.conf "${DEFAULTSDIR}/defaults.conf"
install_file -m 0755 "${ME}".bin "${BINDIR}/$ME"
install_file -m 0755 "${ME}".init "${INITDIR}/$ME"

# create versions file
"${BINDIR}/$ME" version > "${DEFAULTSDIR}/version"

printf "Finished Install\n"
exit 0
