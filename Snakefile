"""
Structural variant caller for PacBio reads.

See also: https://github.com/EichlerLab/pacbio_variant_caller
"""
import math

#
# Define internal constants.
#
BLASR_BIN = "/net/eichler/vol5/home/mchaisso/software/blasr_1/cpp/alignment/bin/blasr"

#
# Load user variables.
#
configfile: "config.json"
TMP_DIR = config["tmp_dir"]

with open(config["input"]["reads"], "r") as fh:
    INPUT_FILES = [line for line in fh]

print(INPUT_FILES)

# Total batches is either the number of batches requested or number of input
# files (when fewer files exist than batches requested).
TOTAL_INPUT_FILES = len(INPUT_FILES)
FILES_PER_BATCH = math.ceil(float(TOTAL_INPUT_FILES) / config["alignment"]["batches"])
BATCHES = tuple(range(min((config["alignment"]["batches"], TOTAL_INPUT_FILES)))
print(BATCHES)

#
# Define rules
#

# # Create a list of BAM files for downstream analysis.
# rule collect_alignments:
#     input: expand()
#     output: "alignments.txt"
#     shell: "echo {input} > {output}"

# # Sync input reads and reference assembly to local disk, align reads, sort
# # output, and write final BAM to shared disk.
# rule align_reads:
#     input: reads=dynamic("batched_reads/{batch_id}.fofn"), reference=config["reference"]["assembly"], suffix=config["reference"]["suffix_array"], ctab=config["reference"]["ctab"]
#     output: "alignments/{batch_id}.bam"
#     params: threads="8", samtools_threads="1", samtools_memory="4G"
#     shell: "mkdir -p {TMP_DIR}; cd {TMP_DIR}; {BLASR_BIN} {input.reads} {input.reference} -out /dev/stdout -sam -sa {input.suffix} -ctab {input.ctab} -nproc {params.threads} -bestn 2 -maxAnchorsPerPosition 100 -advanceExactMatches 10 -affineAlign -affineOpen 100 -affineExtend 0 -insertion 5 -deletion 5 -extend -maxExtendDropoff 50 -clipping subread | samtools sort -@ {params.samtools_threads} -m {params.samtools_memory} -O bam -T {TMP_DIR}/{wildcards.batch_id} -o `basename {output}` -; rsync --bwlimit=20000 --remove-source-files -W `basename {output}` `pwd`/{output}"

rule all:
    input: expand("batched_reads/{batch_id}.fofn", batch_id=BATCHES)
    #input: "batched_reads"

# Divide input reads into batches for alignment.
rule assign_batches:
    output: "batched_reads/{batch_id}.fofn"
    run:
        shell("mkdir -p batched_reads")
        for files_processed in range(TOTAL_INPUT_FILES):
            batch_id = math.floor(float(files_processed) / FILES_PER_BATCH)
            if batch_id == int(wildcards.batch_id):
                current_output = open("batched_reads/%s.fofn" % batch_id, "a")
                current_output.write(INPUT_FILES[files_processed])
                current_output.close()
