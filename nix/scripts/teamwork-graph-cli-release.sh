#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF' >&2
Usage:
  teamwork-graph-cli-release.sh parse-manifest MANIFEST_JSON
  teamwork-graph-cli-release.sh parse-checksums RELEASE_CANDIDATE_JSON SHA256SUMS
  teamwork-graph-cli-release.sh verify-checksum EXPECTED_SHA256 ACTUAL_SHA256
EOF
  exit 2
}

parse_manifest() {
  local manifest_file="$1"

  jq -e '
    def reject($message): error("Teamwork Graph CLI manifest: " + $message);
    def require($condition; $message): if $condition then . else reject($message) end;

    . as $manifest
    | require($manifest | type == "object"; "root must be an object")
    | require($manifest.channel == "stable"; "channel must be stable")
    | require(
        $manifest.version
        | type == "string" and test("^[0-9]+\\.[0-9]+\\.[0-9]+$");
        "version must be strict SemVer"
      )
    | $manifest.version as $version
    | "twg-darwin-arm64-v\($version)" as $file_name
    | "https://teamwork-graph.atlassian.com/cli/\($file_name)" as $artifact_url
    | "https://teamwork-graph.atlassian.com/cli/SHA256SUMS-v\($version)" as $checksums_url
    | require(
        $manifest.assets | type == "object" and has("darwin-arm64");
        "darwin-arm64 asset is required"
      )
    | require(
        $manifest.assets["darwin-arm64"].url == $artifact_url;
        "darwin-arm64 asset URL must use the official origin and filename"
      )
    | require(
        $manifest.checksumsUrl == $checksums_url;
        "checksums URL must use the official origin and filename"
      )
    | {
        version: $version,
        fileName: $file_name,
        url: $artifact_url,
        checksumsUrl: $checksums_url
      }
  ' "$manifest_file"
}

parse_checksums() {
  local release_candidate_file="$1"
  local checksums_file="$2"

  jq -e -n \
    --slurpfile candidates "$release_candidate_file" \
    --rawfile checksums "$checksums_file" '
      def reject($message): error("Teamwork Graph CLI checksums: " + $message);
      def require($condition; $message): if $condition then . else reject($message) end;

      require($candidates | length == 1; "release candidate must contain one object")
      | $candidates[0] as $candidate
      | require($candidate | type == "object"; "release candidate must be an object")
      | [
          $checksums
          | split("\n")[]
          | try capture("^(?<sha256>[0-9a-f]{64})  (?<fileName>[^[:space:]]+)$") catch empty
          | select(.fileName == $candidate.fileName)
        ] as $matches
      | require($matches | length == 1; "target artifact must have exactly one checksum")
      | $candidate + { sha256: $matches[0].sha256 }
    '
}

verify_checksum() {
  local expected_sha256="$1"
  local actual_sha256="$2"
  local sha256_pattern='^[0-9a-f]{64}$'

  if [[ ! $expected_sha256 =~ $sha256_pattern ]]; then
    printf 'Teamwork Graph CLI checksum: published SHA-256 has an invalid format\n' >&2
    exit 1
  fi

  if [[ ! $actual_sha256 =~ $sha256_pattern ]]; then
    printf 'Teamwork Graph CLI checksum: downloaded SHA-256 has an invalid format\n' >&2
    exit 1
  fi

  if [[ $expected_sha256 != "$actual_sha256" ]]; then
    printf 'Teamwork Graph CLI checksum: downloaded artifact does not match the published SHA-256\n' >&2
    exit 1
  fi
}

case "${1:-}" in
parse-manifest)
  [[ $# -eq 2 ]] || usage
  parse_manifest "$2"
  ;;
parse-checksums)
  [[ $# -eq 3 ]] || usage
  parse_checksums "$2" "$3"
  ;;
verify-checksum)
  [[ $# -eq 3 ]] || usage
  verify_checksum "$2" "$3"
  ;;
*)
  usage
  ;;
esac
