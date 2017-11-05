#!/usr/bin/env bash

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
#    Copyright (C) 2005-2016 Mart Frauenlob aka AllKind
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
: ${PATH:=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/bin:/usr/local/sbin}
ME=ip-array
BACKUP=
BASHCOMPDIR=
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
SYSTEMDDIR=
VERBOSE=

arr_args=( "$@" )

# ------------------------------------------------------------------------- #
# FUNCTIONS
# ------------------------------------------------------------------------- #

usage() {
printf "
USAGE: ${0##*/} [[Option] Option-argument] [...]\n
Options:
-?, -h, --help                Show this usage instructions
-b, --backup                  Create numbered backups (suffix=~)
-g, --group group_name        Set group ownership. Default: root
-n, --no-act                  Perform a dry-run
-o, --owner owner_name        Set ownership. Default: root
-v, --verbose                 Verbose output
--prefix /path                Prefix directory. Default: /usr/local
--datarootdir /path           Default: PREFIX/share
--defaultsdir /path           Default: SYSCONFDIR/ip-array
--docdir /path                Default: DATAROOTDIR/doc
--initdir /path               Default: /etc/init.d
--bindir /path                Default: PREFIX/sbin
--libdir /path                Default: PREFIX/lib
--mandir /path                Default: DATAROOTDIR/man
--sysconfdir /path            Default: PREFIX/etc
--systemddir /path            Default: /etc/systemd (set it to \`upstart',
                                       if upstart is used)
--bashcompdir /path           Retrieved with pkg-config, or as fallback:
                              /etc/bash_completion.d, or ~/.bash_completion
\n"
}

no_act() { # just print the command string
printf "%s\n" "$*"
}

create_dirs() { # create all directory components
${NOACT}command install $VERBOSE $OWNSH -d "$@"
}

install_dir() { # install multiple source files to destination
local str_perm
case "$1" in
	-m|--mode)
		str_perm="-m $2"
		shift 2
	;;
esac
${NOACT}command install $VERBOSE $BACKUP $OWNSH $str_perm "$@"
}

install_file() { # install a single file
local str_perm
case "$1" in
	-m|--mode)
		str_perm="-m $2"
		shift 2
	;;
esac
${NOACT}command install $VERBOSE $BACKUP $OWNSH $str_perm -T "$@"
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
		--bashcompdir) BASHCOMPDIR="$opt_arg" ;;
		--bindir) BINDIR="$opt_arg" ;;
		--datarootdir) DATAROOTDIR="$opt_arg" ;;
		--defaultsdir) DEFAULTSDIR="$opt_arg" ;;
		--docdir) DOCDIR="$opt_arg" ;;
		--initdir) INITDIR="$opt_arg" ;;
		--libdir) LIBDIR="$opt_arg" ;;
		--mandir) MANDIR="$opt_arg" ;;
		--prefix) PREFIX="$opt_arg" ;;
		--sysconfdir) SYSCONFDIR="$opt_arg" ;;
		--systemddir) SYSTEMDDIR="$opt_arg" ;;
		*) usage
			exit 3
	esac
	if [[ $opt_arg ]]; then shift; fi
done

# set defaults
: ${INITDIR:=/etc/init.d}
: ${PREFIX:=/usr/local}
: ${DATAROOTDIR:=${PREFIX}/share}
: ${BINDIR:=${PREFIX}/sbin}
: ${LIBDIR:=${PREFIX}/lib}
: ${SYSCONFDIR:=${PREFIX}/etc}
: ${SYSTEMDDIR:=/etc/systemd}
: ${DEFAULTSDIR:=$SYSCONFDIR/$ME}
: ${DOCDIR:=${DATAROOTDIR}/doc}
: ${MANDIR:=${DATAROOTDIR}/man}

: ${OWNER:=root}
: ${GROUP:=root}
OWNSH="--group=$GROUP --owner=$OWNER"

if [[ -z $BASHCOMPDIR ]]; then
	if command -v pkg-config &>/dev/null; then
		while :; do
			BASHCOMPDIR=$(command pkg-config --variable=completionsdir bash-completion) && break
			BASHCOMPDIR=$(command pkg-config --variable=compatdir bash-completion) && break
		done
	else
		while :; do
			[[ -e /etc/bash_completion.d ]] && BASHCOMPDIR=/etc/bash_completion.d && break
			BASHCOMPDIR='~' && break
		done
	fi

fi

# warning message on dry-run
if [[ $NOACT ]]; then
	printf "\nNO ACT MODE - NOT INSTALLING!\n\n"
fi

# check for install bin
command -v install &>/dev/null || {
	printf "Unable to find the \`install' binary in \$PATH.\n" >&2
   	exit 1
}

# warn about ownership - if not root
if ((EUID != 0)); then
	printf "Not running as root. Not changing ownership/groups.\n"
	OWNSH=
fi

# create directories
create_dirs "${BINDIR}" "${LIBDIR}/$ME" "${DATAROOTDIR}/$ME" "${DOCDIR}/$ME" "${INITDIR}"
create_dirs "${DATAROOTDIR}/${ME}/"{help.d,template_repo.d} \
	"${DOCDIR}/${ME}/"{docbook,html} \
	"${MANDIR}/"{man5,man8}
create_dirs "${DEFAULTSDIR}" "${SYSCONFDIR}/${ME}/"{save.d,stable,test}
create_dirs "${DATAROOTDIR}/${ME}/help.d/"{conf_vars,examples,ipt_args,public_functions}
create_dirs "${DATAROOTDIR}/${ME}/help.d/examples/config_like_v.0.05.74d/"{ruleblocks.d,rules.d}
create_dirs "${SYSCONFDIR}/${ME}/stable/conf.d/"{rules.d,ruleblocks.d,sysctl.d,templates.d}
create_dirs "${SYSCONFDIR}/${ME}/stable/scripts.d"
create_dirs "${SYSCONFDIR}/${ME}/stable/scripts.d/"{epilog,prolog}
create_dirs "${BASHCOMPDIR}"
[[ $SYSTEMDDIR = upstart ]] || create_dirs "${SYSTEMDDIR}/network"
[[ $SYSTEMDDIR = upstart ]] || create_dirs "${SYSTEMDDIR}/system"

# copy files
install_dir -m 0640 conf.d/*.conf "${SYSCONFDIR}/${ME}/stable/conf.d"
install_dir -m 0640 conf.d/ruleblocks.d/* "${SYSCONFDIR}/${ME}/stable/conf.d/ruleblocks.d"
install_dir -m 0640 conf.d/rules.d/* "${SYSCONFDIR}/${ME}/stable/conf.d/rules.d"
install_dir -m 0640 conf.d/sysctl.d/* "${SYSCONFDIR}/${ME}/stable/conf.d/sysctl.d"
install_dir -m 0640 conf.d/templates.d/* "${SYSCONFDIR}/${ME}/stable/conf.d/templates.d"

install_dir -m 0644 template_repo.d/* "${DATAROOTDIR}/${ME}/template_repo.d"
install_dir -m 0644 help.d/public_functions/*.txt "${DATAROOTDIR}/${ME}/help.d/public_functions"
install_dir -m 0644 help.d/ipt_args/*.txt "${DATAROOTDIR}/${ME}/help.d/ipt_args"
install_dir -m 0644 help.d/conf_vars/*.txt "${DATAROOTDIR}/${ME}/help.d/conf_vars"
install_dir -m 0644 help.d/examples/config_like_v.0.05.74d/ruleblocks.d/* "${DATAROOTDIR}/${ME}/help.d/examples/config_like_v.0.05.74d/ruleblocks.d"
install_dir -m 0644 help.d/examples/config_like_v.0.05.74d/rules.d/* "${DATAROOTDIR}/${ME}/help.d/examples/config_like_v.0.05.74d/rules.d"
install_dir -m 0644 help.d/docbook/* "${DOCDIR}/${ME}/docbook"
install_dir -m 0644 help.d/html/* "${DOCDIR}/${ME}/html"
install_dir -m 0644 help.d/man/*.5 "${MANDIR}/man5"
install_dir -m 0644 help.d/man/*.8 "${MANDIR}/man8"
install_dir -m 0640 scripts.d/prolog/* "${SYSCONFDIR}/${ME}/stable/scripts.d/prolog"
install_dir -m 0640 scripts.d/epilog/* "${SYSCONFDIR}/${ME}/stable/scripts.d/epilog"
install_dir -m 0644 "${ME}"_*_functions "${LIBDIR}/$ME"

install_file -m 0640 defaults.conf "${DEFAULTSDIR}/${ME}_defaults.conf"
install_file -m 0640 ip-array_global_defs "${LIBDIR}/${ME}/ip-array_global_defs"
install_file -m 0755 "${ME}".bin "${BINDIR}/$ME"
install_file -m 0755 "${ME}".init "${INITDIR}/$ME"
install_file -m 0755 "${ME}".init_pre_net_boot "${INITDIR}/${ME}_pre_net_boot"
[[ $SYSTEMDDIR = upstart ]] || install_file -m 0644 "${ME}".service "${SYSTEMDDIR}/system/${ME}.service"
[[ $SYSTEMDDIR = upstart ]] || install_file -m 0644 "${ME}"_pre_net_boot.service "${SYSTEMDDIR}/network/${ME}_pre_net_boot.service"

if [[ $BASHCOMPDIR = ~ ]]; then
	printf "bashcompdir is \`~', adding completion to \`%s'.\n\tRemember to manually remove it on uninstall, or re-install.\n" "~/.bash_completion"
	if ! [[ $NOACT ]]; then
		command cat ip-array_bash_completion >> ~/.bash_completion
	fi
else
	if ! [[ $NOACT ]]; then
		install_file -m 0644 ip-array_bash_completion "$BASHCOMPDIR/$ME"
	fi
fi

if [[ $SYSTEMDDIR != upstart ]]; then
	printf "Reloading systemd.\n"
	if ! [[ $NOACT ]]; then
		command systemctl daemon-reload || printf "Failed reloading systemd configuration.\n" >&2
	fi
fi

# create versions file
printf "Creating version file: \`${SYSCONFDIR}/${ME}/${ME}_version'\n"
if ! [[ $NOACT ]]; then
	(set +C; "${BINDIR}/$ME" version > "${SYSCONFDIR}/${ME}/${ME}_version")
fi

# create log file, to be re-used by uninstall.bash
printf "Creating \`./${ME}-install.log' - Will need this for uninstallation!\n"
if ! [[ $NOACT ]]; then
	(set +C; printf '#!/usr/bin/env bash\n\n' > ./${ME}-install.log) && \
	printf "# install arguments: %s\n\n" "${arr_args[*]}" >> ./${ME}-install.log && \
	for var in PREFIX BASHCOMPDIR BINDIR DATAROOTDIR DEFAULTSDIR DOCDIR \
			INITDIR LIBDIR MANDIR SYSCONFDIR SYSTEMDDIR; do
		declare -p "$var" >> ./${ME}-install.log
	done
fi

printf "${0}: installation finished.\n"
exit 0

