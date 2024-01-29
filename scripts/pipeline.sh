#Download all the files specified in data/filenames
for url in $(cat data/urls) #TODO
do
    bash scripts/download.sh $url data
done

# Download the contaminants fasta file, uncompress it, and
# filter to remove all small nuclear RNAs
bash scripts/download.sh https://bioinformatics.cnio.es/data/courses/decont/contaminants.fasta.gz res yes \
     "small nuclear" #TODO

# Index the contaminants file
bash scripts/index.sh res/contaminants_filtered.fasta res/contaminants_idx

# Merge the samples into a single file
for sid in $(ls data/*.fastq.gz | cut -d "-" -f1 | sed 's:data/::'| sort | uniq) #TODO
do
    bash scripts/merge_fastqs.sh data out/merged $sid
done

# TODO: run cutadapt for all merged files
mkdir -p out/trimmed
mkdir -p log/cutadapt

for sid in $(ls out/merged/*fastq.gz | cut -d "." -f1 | sed 's:out/merged/::')
do 
cutadapt -m 18 -a TGGAATTCTCGGGTGCCAAGG --discard-untrimmed \
         -o out/trimmed/${sid}.trimmed.fastq.gz out/merged/${sid}.fastq.gz > log/cutadapt/${sid}.log
done

# TODO: run STAR for all trimmed files
for fname in out/trimmed/*.fastq.gz
do
# you will need to obtain the sample ID from the filename
sid=$(echo $fname | sed 's:out/trimmed/::' | cut -d "." -f1)

mkdir -p out/star/$sid

STAR --runThreadN 4 --genomeDir res/contaminants_idx \
     --outReadsUnmapped Fastx --readFilesIn ${fname} \
     --readFilesCommand gunzip -c --outFileNamePrefix out/star/${sid}/${sid}_
done 

# TODO: create a log file containing information from cutadapt and star logs
# (this should be a single log file, and information should be *appended* to it on each run)
# - cutadapt: Reads with adapters and total basepairs
# - star: Percentages of uniquely mapped reads, reads mapped to multiple loci, and to too many loci
# tip: use grep to filter the lines you're interested in
