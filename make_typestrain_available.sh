#!/usr/bin/env bash
#
# Build the pinned list of available NCBI type-strain genome assemblies (Bacteria + Archaea).
#
# NCBI type-material listings change over time, so the rcc-nf-orchestrator pipeline never
# queries them at runtime: it downloads exactly the versioned accessions listed in the output.
# Run this script only when you deliberately want to refresh the database, commit and tag the
# new list, and point the pipeline's params.typestrain_available at its tagged raw URL.
#
# Requires the NCBI `datasets` and `dataformat` CLIs, e.g.:
#   docker run --rm -v "$PWD":/work -w /work staphb/ncbi-datasets:18.35.0 \
#       bash make_typestrain_available.sh typestrain_available_$(date +%Y-%m-%d).tsv
#
set -euo pipefail

OUT="${1:?Usage: make_typestrain_available.sh <output.tsv>}"
FIELDS="accession,organism-name,organism-tax-id,organism-infraspecific-strain,assminfo-level,assminfo-name,assminfo-release-date,type_material-display_text"
TMP="$(mktemp)"
trap 'rm -f "${TMP}"' EXIT

for taxon in bacteria archaea; do
    datasets summary genome taxon "${taxon}" \
        --from-type \
        --exclude-atypical \
        --as-json-lines \
    | dataformat tsv genome --fields "${FIELDS}" --elide-header >> "${TMP}"
done

{
    echo "# datasets_version: $(datasets --version | awk '{print $NF}')"
    echo "# generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "# query: datasets summary genome taxon {bacteria,archaea} --from-type --exclude-atypical"
    printf "accession\torganism_name\ttaxid\tstrain\tassembly_level\tassembly_name\trelease_date\ttype_material\n"
    LC_ALL=C sort -u -t $'\t' -k1,1 "${TMP}"
} > "${OUT}"

echo "Wrote $(grep -vc '^#' "${OUT}") lines (incl. header) to ${OUT}" >&2
