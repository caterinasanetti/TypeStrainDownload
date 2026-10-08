# typestrain-available

Pinned lists of NCBI type-strain genome assemblies (Bacteria + Archaea), used by the shotgun
workflow of [rcc-nf-orchestrator](https://gitlab.kuleuven.be/raeslab/pipelines-and-packages/rcc-orchestrator/rcc-nf-orchestrator)
to build its skani type-strain database.

## Why a pinned list

NCBI's type-material set changes continuously (new genomes, suppressed assemblies, reclassified
species), so querying it at runtime gives a different database every time. Each list here freezes
the exact versioned accessions (`GCA_/GCF_xxxxxxxxx.N`). The sequence behind an accession.version
never changes, so the same list always produces the same database.

## Files

| File | Content |
|------|---------|
| `typestrain_available_<date>.tsv` | One row per type-strain assembly. Header lines starting with `#` record the `datasets` version, generation time and query. |
| `make_typestrain_available.sh` | Regenerates a list from NCBI. |

Columns: `accession`, `organism_name`, `taxid`, `strain`, `assembly_level`, `assembly_name`,
`release_date`, `type_material`.

| List | `datasets` | Assemblies | Query |
|------|-----------|-----------:|-------|
| `typestrain_available_2026-10-08.tsv` | 18.35.0 | 61,661 (30,413 GCF + 31,248 GCA) | `datasets summary genome taxon {bacteria,archaea} --from-type --exclude-atypical` |

GenBank (GCA) and RefSeq (GCF) copies of the same assembly are both kept. NCBI also lists SeqCode
type genomes (e.g. `... (SeqCode)`), which are often MAGs.

## Using a list in the pipeline

Point `typestrain_available` at the raw URL of a **tag**, never a branch, so the list can't
change under you:

```bash
nextflow run raeslab/rccorchestrator --workflow shotgun \
    --typestrain_available https://<host>/<group>/typestrain-available/<tag>/typestrain_available_2026-10-08.tsv \
    ...
```

The pipeline builds the skani database once into `<db_cache_dir>/skani_<list file name>/` and
reuses it on later runs. A new list file name means a new database.

## Making a new list

```bash
docker run --rm -v "$PWD":/work -w /work staphb/ncbi-datasets:18.35.0 \
    bash make_typestrain_available.sh typestrain_available_$(date +%Y-%m-%d).tsv
git add typestrain_available_*.tsv && git commit -m "Add type-strain list $(date +%Y-%m-%d)"
git tag $(date +%Y-%m-%d) && git push --tags
```

Keep old lists in the repo so earlier results stay reproducible.
