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
#    Copyright (C) 2005-2018 Mart Frauenlob aka AllKind
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
#                        IP-ARRAY UNINSTALL SCRIPT
#
# ------------------------------------------------------------------------- #

# ------------------------------------------------------------------------- #
# FUNCTIONS
# ------------------------------------------------------------------------- #

usage() {
printf "
USAGE: ${0##*/} [Option] [...]\n
Options:
-?, -h, --help                Show this usage instructions
-n, --no-act                  Perform a dry-run
-v, --verbose                 Verbose output
\n"
}

no_act() { # just print the command string
	printf "%s\n" "$*"
}

rem_dir() {
	${NOACT}command rm $VERBOSE -rf "$1"
}

rem_file() {
	${NOACT}command rm $VERBOSE -f "$1"
}

rem_empty_dir() {
# all done in a sub-shell, as we change shell options
(
	shopt -s nullglob
	shopt -s dotglob
	set +f
	# Check for empty files using arrays
	chk_files=(${1}/*)
	if (( ${#chk_files[*]} )); then
		if [[ $VERBOSE ]]; then
			printf "Directory \`%s' is not empty. Skipping it.\n" "$1"
		fi
	else
		${NOACT}command rmdir $VERBOSE "$1"
	fi
)
}

# ------------------------------------------------------------------------- #
# MAIN
# ------------------------------------------------------------------------- #

ME="ip-array"
: ${PATH:=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/bin:/usr/local/sbin}

# parse arguments
unset NOACT VERBOSE
while (($#)); do
	case "$1" in
		"-?"|-h|--help) usage
			exit 0
		;;
		-n|--no-act) NOACT="no_act "
		;;
		-v|--verbose) VERBOSE="-v"
		;;
		*) usage
			exit 3
	esac
	shift
done

# install.bash created ${ME}-install.log, need the declarations from it
. ./${ME}-install.log || {
	printf "Cannot find ./${ME}-install.log. Aborting.\n" >&2
	exit 1
}

# check if the variable are defined
for f in LIBDIR DATAROOTDIR DOCDIR SYSCONFDIR \
	BINDIR DEFAULTSDIR BASHCOMPDIR MANDIR INITDIR
do
	if [[ -z ${!f} ]]; then
		printf "Need variable \`%s'. Aborting.\n" "$f" >&2
		exit 1
	fi
done
[[ $SYSTEMDDIR ]] || SYSTEMDDIR="upstart"

# check for needed programs
for f in rm rmdir; do
	command -v $f &>/dev/null || {
		printf "Unable to find the \`$f' program in \$PATH.\n" >&2
		exit 1
	}
done

# warn about ownership - if not root
if ((EUID != 0)); then
	printf "Warning: Not running as root.\n"
fi

if [[ $NOACT ]]; then
	printf "\nNO ACT MODE - NOT UNINSTALLING!\n\n"
else
	printf "Starting uninstall\n"
fi

# start deletion
for f in LIBDIR DOCDIR DATAROOTDIR SYSCONFDIR; do
	rem_dir "${!f}/$ME"
done

for f in BINDIR DEFAULTSDIR; do
	rem_file "${!f}/$ME"
done
rem_file "${INITDIR}/$ME"
rem_file "${INITDIR}/${ME}_pre_net_boot"

if [[ $BASHCOMPDIR = \~ ]]; then
	printf "bashcompdir is \`~'.\n\tRemember to manually remove completion from: \`%s'.\n" "~/.bash_completion"
else
	rem_file "${BASHCOMPDIR}/$ME"
fi

for f in "${MANDIR}"/man5/${ME}*.5 "${MANDIR}"/man8/${ME}*.8; do
	rem_file "$f"
done

for f in 5 8; do
	rem_empty_dir "${MANDIR}/man${f}"
done
rem_empty_dir "${MANDIR}"

for f in BINDIR LIBDIR DOCDIR DEFAULTSDIR SYSCONFDIR BASHCOMPDIR INITDIR DATAROOTDIR
do
	rem_empty_dir "${!f}"
done

if [[ $SYSTEMDDIR != upstart ]]; then
	rem_file "${SYSTEMDDIR}/${ME}.service"
	rem_file "${SYSTEMDDIR}/${ME}_pre_net_boot.service"
	rem_empty_dir "$SYSTEMDDIR"
	printf "Reloading systemd.\n"
	if ! [[ $NOACT ]]; then
		command systemctl daemon-reload || printf "Failed reloading systemd configuration.\n" >&2
	fi
fi

if [[ $PREFIX ]]; then
	rem_empty_dir "$PREFIX"
fi
printf "Finished uninstall\n"

