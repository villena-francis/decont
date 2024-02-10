# This script should index the genome file specified in the first argument ($1),
# creating the index in a directory specified by the second argument ($2).

fname=$1
dir=$2

mkdir -p res/contaminants_idx

# The STAR command is provided for you. You should replace the parts surrounded
# by "<>" and uncomment it.

STAR --runThreadN 4 --runMode genomeGenerate --genomeDir $2 \
     --genomeFastaFiles $1 --genomeSAindexNbases 9
