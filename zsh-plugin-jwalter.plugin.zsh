#!/bin/bash

__JWALTER_SOURCE="${BASH_SOURCE[0]}"
__JWALTER_DIR="$(cd "$(dirname "${__JWALTER_SOURCE:-$0}")" &>/dev/null && pwd)"
__JWALTER_PLUGIN_DIR="${__JWALTER_DIR}/plugins"

__JWALTER_GITHUB="jeffwalter"
__JWALTER_PLUGIN_PREFIX="zsh-plugin-"

__jwalter_checkConfig() {
	if [ ! -d "${__JWALTER_PLUGIN_DIR}" ]; then
		if [ -e "${__JWALTER_PLUGIN_DIR}" ]; then
			rm -rf "${__JWALTER_PLUGIN_DIR}" &>/dev/null
		fi
		mkdir "${__JWALTER_PLUGIN_DIR}"
	fi
	if [ ! -f "${__JWALTER_PLUGIN_DIR}/.disable" ]; then
		if [ -e "${__JWALTER_PLUGIN_DIR}/.disable" ]; then
			rm -rf "${__JWALTER_PLUGIN_DIR}/.disable" &>/dev/null
		fi
		touch "${__JWALTER_PLUGIN_DIR}/.disable"
	fi
}

__jwalter_checkPluginName() {
	if [ -z "${1}" ]; then
		echo "Error: Missing plugin name" 1>&2
		return 1

	elif ! grep -qE '^[a-zA-Z0-9_-][a-zA-Z0-9_-]*$' <<<"${1}"; then
		echo "Error: Plugin name appears to be invalid" 1>&2
		return 1

	else
		return 0
	fi
}

__jwalter_remotePlugins() {
	curl -s "https://github.com/${__JWALTER_GITHUB}?page=1&tab=repositories&q=${__JWALTER_PLUGIN_PREFIX}" 2>/dev/null | awk '/<a href="\/[^"\/]+\/([^"\/]+)" itemprop="name codeRepository">/ {sub(/^.*<a href="\/[^"\/]+\//,"",$0); sub(/" itemprop=".*$/,"",$0); if ($0 !~ /-jwalter$/) {print;}}' | sed -e "s/^${__JWALTER_PLUGIN_PREFIX}//" | sort
}

__jwalter_remotePluginMetadata() {
	local PLUGIN
	PLUGIN="${1}"

	curl -s "https://raw.githubusercontent.com/${__JWALTER_GITHUB}/${__JWALTER_PLUGIN_PREFIX}${PLUGIN}/master/METADATA" 2>/dev/null
}

__jwalter_remotePluginMetadataValue() {
	local PLUGIN KEY
	PLUGIN="${1}"
	KEY="${2}"

	__jwalter_remotePluginMetadata "${PLUGIN}" | awk "/^${KEY}:/ {sub(/[^:]+:/,\"\",\$0); printf(\"%s\n\",\$0); exit 0;}"
}

__jwalter_localPlugins() {
	local REPO

	#shellcheck disable=2162
	find "${__JWALTER_PLUGIN_DIR}" -mindepth 1 -maxdepth 1 -type d -or -type l 2>/dev/null | sort | while read REPO; do
		basename "${REPO}" | sed -e "s/^${__JWALTER_PLUGIN_PREFIX}//"
	done
}

__jwalter_localPluginMetadata() {
	local PLUGIN
	PLUGIN="${1}"

	cat "${__JWALTER_PLUGIN_DIR}/${__JWALTER_PLUGIN_PREFIX}${PLUGIN}/METADATA" 2>/dev/null
}

__jwalter_localPluginMetadataValue() {
	local PLUGIN KEY
	PLUGIN="${1}"
	KEY="${2}"

	__jwalter_localPluginMetadata "${PLUGIN}" | awk "/^${KEY}:/ {sub(/[^:]+:/,\"\",\$0); printf(\"%s\n\",\$0); exit 0;}"
}

__jwalter_pluginEnabled() {
	local PLUGIN
	PLUGIN="${1}"

	if grep -qE "^${PLUGIN}$" "${__JWALTER_PLUGIN_DIR}/.disable"; then
		return 1
	else
		return 0
	fi
}

__jwalter_list_remote() {
	local PLUGIN

	echo "Available Plugins"
	echo "-----------------"

	#shellcheck disable=2162
	__jwalter_remotePlugins | while read PLUGIN; do
		printf "%-15s %9s  %s\n" "${PLUGIN}" "v$(__jwalter_remotePluginMetadataValue "${PLUGIN}" "VERSION")" "$(__jwalter_remotePluginMetadataValue "${PLUGIN}" "DESCRIPTION")"
	done
}

__jwalter_list_local() {
	local PLUGIN

	echo "Installed Plugins"
	echo "-----------------"

	#shellcheck disable=2162
	__jwalter_localPlugins | while read PLUGIN; do
		if __jwalter_pluginEnabled "${PLUGIN}"; then
			printf "%-15s* %9s  %s\n" "${PLUGIN}" "v$(__jwalter_localPluginMetadataValue "${PLUGIN}" "VERSION")" "$(__jwalter_localPluginMetadataValue "${PLUGIN}" "DESCRIPTION")"
		else
			printf "%-15s  %9s  %s\n" "${PLUGIN}" "v$(__jwalter_localPluginMetadataValue "${PLUGIN}" "VERSION")" "$(__jwalter_localPluginMetadataValue "${PLUGIN}" "DESCRIPTION")"
		fi
	done

	echo
	echo "* - Enabled"
}

__jwalter_install() {
	local PLUGIN
	PLUGIN="${1}"

	if [ -d "${__JWALTER_PLUGIN_DIR}/${__JWALTER_PLUGIN_PREFIX}${PLUGIN}" ]; then
		echo "Error: Plugin ${PLUGIN} is already installed" 1>&2
		return 0
	fi

	git clone "https://github.com/${__JWALTER_GITHUB}/${__JWALTER_PLUGIN_PREFIX}${PLUGIN}.git" "${__JWALTER_PLUGIN_DIR}/${__JWALTER_PLUGIN_PREFIX}${PLUGIN}"
	__jwalter_enable "${PLUGIN}"

	__jwalter_load "${PLUGIN}"
}

__jwalter_upgrade() {
	local PLUGIN
	PLUGIN="${1}"

	if [ ! -d "${__JWALTER_PLUGIN_DIR}/${__JWALTER_PLUGIN_PREFIX}${PLUGIN}" ]; then
		echo "Error: Plugin ${PLUGIN} is not installed" 1>&2
		return 1
	fi

	echo "Info:  Updating plugin ${PLUGIN}" 1>&2
	#shellcheck disable=2164
	(cd "${__JWALTER_PLUGIN_DIR}/${__JWALTER_PLUGIN_PREFIX}${PLUGIN}"; git pull)
	if [ "$?" = "0" ]; then
		echo "Info:  Updated plugin ${PLUGIN}" 1>&2
	else
		echo "Error: Failed to update plugin ${PLUGIN}" 1>&2
		return 1
	fi

	__jwalter_load "${PLUGIN}"
}

__jwalter_remove() {
	local PLUGIN
	PLUGIN="${1}"

	if [ ! -d "${__JWALTER_PLUGIN_DIR}/${__JWALTER_PLUGIN_PREFIX}${PLUGIN}" ]; then
		echo "Info:  Removed plugin ${PLUGIN}" 1>&2
		return 1
	fi

	echo "Info:  Removing plugin ${PLUGIN}" 1>&2
	rm -rf "${__JWALTER_PLUGIN_DIR:?}/${__JWALTER_PLUGIN_PREFIX}${PLUGIN}"
	if [ "$?" = "0" ]; then
		echo "Info:  Removed plugin ${PLUGIN}" 1>&2
	else
		echo "Error: Failed to remove plugin ${PLUGIN}" 1>&2
		return 1
	fi

	__jwalter_enable "${PLUGIN}"
}

__jwalter_enable() {
	local PLUGIN
	PLUGIN="${1}"

	echo "Info:  Enabling plugin ${PLUGIN}" 1>&2
	grep -Ev "^${PLUGIN}$" "${__JWALTER_PLUGIN_DIR}/.disable" >"${__JWALTER_PLUGIN_DIR}/.disable.tmp"
	mv "${__JWALTER_PLUGIN_DIR}/.disable.tmp" "${__JWALTER_PLUGIN_DIR}/.disable"
	echo "Info:  Enabled plugin ${PLUGIN}" 1>&2
}

__jwalter_disable() {
	local PLUGIN
	PLUGIN="${1}"

	echo "Info:  Disabling plugin ${PLUGIN}" 1>&2
	if ! grep -qE "^${PLUGIN}$" "${__JWALTER_PLUGIN_DIR}/.disable"; then
		echo "${PLUGIN}" >> "${__JWALTER_PLUGIN_DIR}/.disable"
	fi
	echo "Info:  Disabled plugin ${PLUGIN}" 1>&2
}

__jwalter_load() {
	local PLUGIN
	PLUGIN="${1}"

	if [ -f "${__JWALTER_PLUGIN_DIR}/${__JWALTER_PLUGIN_PREFIX}${PLUGIN}/${__JWALTER_PLUGIN_PREFIX}${PLUGIN}.plugin.zsh" ] && [ -r "${__JWALTER_PLUGIN_DIR}/${__JWALTER_PLUGIN_PREFIX}${PLUGIN}/${__JWALTER_PLUGIN_PREFIX}${PLUGIN}.plugin.zsh" ]; then
		if __jwalter_pluginEnabled "${PLUGIN}"; then
			#shellcheck disable=1090
			source "${__JWALTER_PLUGIN_DIR}/${__JWALTER_PLUGIN_PREFIX}${PLUGIN}/${__JWALTER_PLUGIN_PREFIX}${PLUGIN}.plugin.zsh"
		fi
		return 0
	fi

	return 1
}

__jwalter_load_all() {
	#shellcheck disable=2162
	while read PLUGIN; do
		if [ -n "${PLUGIN}" ]; then
			if ! __jwalter_load "${PLUGIN}"; then
				echo "Warn:  Failed to load plugin ${PLUGIN}" 1>&2
			fi
		fi
	done <<<"$(__jwalter_localPlugins)"
}

__jwalter_help() {
	cat <<EOF
Usage:
    jw <ACTION> [PLUGIN]

Actions:
    help                 This stuff that you're reading right now
    list-remote          Lists the remote plugins available for installation
    list                 Lists the local plugins that are currently installed
    install      PLUGIN  Installs the specified plugin
    upgrade      PLUGIN  Upgrades the specified plugin
    remove       PLUGIN  Removes the specified plugin
    enable       PLUGIN  Enables the specified plugin
    disable      PLUGIN  Disables the specified plugin

EOF
}

jw() {
	__jwalter_checkConfig

	case "${1}" in
		ls-remote|list-remote)
			__jwalter_list_remote
			;;
		ls|list|ls-local|list-local)
			__jwalter_list_local
			;;
		add|install)
			if ! __jwalter_checkPluginName "${2}"; then
				return 1
			fi
			__jwalter_install "${2}"
			;;
		update|upgrade)
			if ! __jwalter_checkPluginName "${2}"; then
				return 1
			fi
			if [ "${2}" = "all" ]; then
				#shellcheck disable=2162
				while read PLUGIN; do
					__jwalter_upgrade "${PLUGIN}"
				done <<<"$(__jwalter_localPlugins)"
			else
				__jwalter_upgrade "${2}"
			fi
			;;
		del|delete|rm|remove)
			if ! __jwalter_checkPluginName "${2}"; then
				return 1
			fi
			__jwalter_remove "${2}"
			;;
		enable)
			if ! __jwalter_checkPluginName "${2}"; then
				return 1
			fi
			__jwalter_enable "${2}"
			;;
		disable)
			if ! __jwalter_checkPluginName "${2}"; then
				return 1
			fi
			__jwalter_disable "${2}"
			;;
		-h|-help|--help|help)
			__jwalter_help
			;;
		*)
			echo "Error: Unknown action: ${1}" 1>&2
			return 1
			;;
	esac
}

__jwalter_load_all
