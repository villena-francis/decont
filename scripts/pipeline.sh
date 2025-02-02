echo -e "\e[34m##############################################\e[0m"
echo -e "\e[34m##### Starting decontamination pipeline ######\n\e[0m"

#Download all the files specified in data/filenames
echo -e "\e[34m\nDownloading data files...\n\e[0m"

for url in $(cat data/urls) #TODO
do
    bash scripts/download.sh $url data
done

# Download the contaminants fasta file, uncompress it, and
# filter to remove all small nuclear RNAs
echo -e "\e[34m\nDownloading the contaminants file...\n\e[0m"
bash scripts/download.sh https://bioinformatics.cnio.es/data/courses/decont/contaminants.fasta.gz res yes \
     "small nuclear" "snRNA" #TODO

# Index the contaminants file
echo -e "\e[34m\nRuning STAR index...\n\e[0m"
bash scripts/index.sh res/contaminants_filtered.fasta res/contaminants_idx
echo " "

# Merge the samples into a single file
for sid in $(ls data/*.fastq.gz | cut -d "-" -f1 | sed 's:data/::'| sort | uniq) #TODO
do
    echo -e "\e[34m\nMerging sample $sid files...\e[0m"
    bash scripts/merge_fastqs.sh data out/merged $sid
    echo -e "\e[34mDone\e[0m"
done

# TODO: run cutadapt for all merged files
mkdir -p out/trimmed
mkdir -p log/cutadapt

echo -e "\e[34m\n\nRuning cutadapt...\e[0m"
for sid in $(ls out/merged/*fastq.gz | cut -d "." -f1 | sed 's:out/merged/::')
do
echo -e "\e[34m\nTrimming sample $sid\e[0m"
cutadapt -m 18 -a TGGAATTCTCGGGTGCCAAGG --discard-untrimmed \
         -o out/trimmed/${sid}.trimmed.fastq.gz out/merged/${sid}.fastq.gz > log/cutadapt/${sid}.log
done

# TODO: run STAR for all trimmed files
echo -e "\e[34m\n\nRuning STAR aligment...\e[0m"
for fname in out/trimmed/*.fastq.gz
do
# you will need to obtain the sample ID from the filename
sid=$(echo $fname | sed 's:out/trimmed/::' | cut -d "." -f1)

mkdir -p out/star/$sid

echo -e "\e[34m\nDecontaminating sample $sid\e[0m"
STAR --runThreadN 4 --genomeDir res/contaminants_idx \
     --outReadsUnmapped Fastx --readFilesIn ${fname} \
     --readFilesCommand gunzip -c --outFileNamePrefix out/star/${sid}/${sid}_
done 

# TODO: create a log file containing information from cutadapt and star logs
# (this should be a single log file, and information should be *appended* to it on each run)
# - cutadapt: Reads with adapters and total basepairs
# - star: Percentages of uniquely mapped reads, reads mapped to multiple loci, and to too many loci
# tip: use grep to filter the lines you're interested in

echo -e "\e[34m\n\nGenerating log with information from cutadapt and star logs...\e[0m"
for sid in $(ls data/*.fastq.gz | cut -d "-" -f1 | sed 's:data/::' | sort | uniq)
do
    {
        echo "SAMPLE: $sid"
        echo " "
        
        echo "CUTADAPT: "
        grep -hi -e "Reads with adapters" log/cutadapt/$sid.log \
                 -e "total basepairs" log/cutadapt/$sid.log 
        echo " "
        
        echo "STAR: "
        grep -hi -e "Uniquely mapped reads %" out/star/$sid/${sid}_Log.final.out \
                 -e "% of reads mapped to multiple loci" out/star/$sid/${sid}_Log.final.out \
                 -e "% of reads mapped to too many loci" out/star/$sid/${sid}_Log.final.out 
        echo " "
    } >> log/pipeline.log
done
echo -e "\e[34mDone\n\e[0m"

echo -e "\e[34m\n##### Decontamination pipeline completed #####\e[0m"
echo -e "\e[34m##############################################\e[0m"