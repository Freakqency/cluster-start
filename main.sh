#!/usr/bin/env bash

set -euo pipefail

check_prerequisites(){
	prereq=("jq" "wget" "tar" "find" "curl" "bash" "mktemp ")
	for cmd in "${prereq[@]}"; do
		if ! command -v $cmd &> /dev/null; then
			echo "prereq not found: $cmd"
			echo "Aborting"
			exit 1
		fi
	done
}

setup_paths() {
	BINARY_HOME="$HOME/.local/bin"
	XDG_CONFIG_HOME="$HOME/.config"
	repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
	mkdir -p "$BINARY_HOME" "$XDG_CONFIG_HOME"
}

install_bashrc() {
	touch "$HOME/.bashrc"
	if ! grep -q "HPC config bootstrap" "$HOME/.bashrc"; then
		cat "$repo_dir/configs/bashrc" >> "$HOME/.bashrc"
	fi
}

link_with_backup() {
	local source=$1
	local target=$2
	if [[ -L "$target" && "$(readlink "$target")" == "$source" ]]; then
		return 0
	fi
	if [[ -e "$target" || -L "$target" ]]; then
		mv "$target" "$target-$(date +"%Y-%m-%d-%H-%M-%S")"
	fi
	ln -s "$source" "$target"
}

link_configs() {
	find "$repo_dir/configs" -mindepth 1 -maxdepth 1 -type d | while IFS= read -r dir; do
		link_with_backup "$dir" "$XDG_CONFIG_HOME/$(basename "$dir")"
	done
}

link_scripts() {
	find "$repo_dir/scripts" -mindepth 1 -maxdepth 1 -type f -executable | while IFS= read -r script; do
		link_with_backup "$script" "$BINARY_HOME/$(basename "$script")"
	done
}

install_archive_tools() {
	binary_tmp_location="$(mktemp -d)"
	trap 'rm -rf "$binary_tmp_location"' EXIT
	# Fetch and untar external all binaries to a tmp location
	for url in $(jq -r ".tools.urls[]" "$repo_dir/manifest.json"); do
		wget -qO- "$url" | tar -xz -C "$binary_tmp_location"
	done
	# Move all executables from tmp to BINARY_HOME
	find "$binary_tmp_location" -type f -executable | while IFS= read -r bin; do
		cp "$bin" "$BINARY_HOME"
	done
}

install_special_cases() {
	# Handle special bins by directly executing the mentioned command
	jq -r '.special_cases.command[]' "$repo_dir/manifest.json" | while IFS= read -r cmd; do
		eval "$cmd"
	done
}

validate() {
	local items=$1
	local -a failures=()
	for bin in $items; do
		if ! command -v "$bin" &> /dev/null; then
			failures+=("$bin")
		fi
	done
	if ((${#failures[@]})); then
		echo "Following binary installations failed: "
		for bin in "${failures[@]}"; do 
			echo "$bin"
		done
		exit 1
	fi
}

validate_all() {
	export PATH="$HOME/.local/bin:$PATH"
	# validate the binarys are present
	validate "$(jq -r ".tools.name[]" "$repo_dir/manifest.json")"
	# validate special tools where installed
	validate "$(jq -r '.special_cases.name[]' "$repo_dir/manifest.json")"
	# validate local scripts where installed properly
	validate "$(find "$repo_dir/scripts" -mindepth 1 -maxdepth 1 -type f -executable -printf "%f\n")"
	echo "Setup completed successfully! 🎉🎉🎉"
	echo 'Run source $HOME/.bashrc'
}

main() {
	check_prerequisites 
	setup_paths
	install_bashrc
	link_configs
	link_scripts
	install_archive_tools
	install_special_cases
	validate_all
}

main "$@"

