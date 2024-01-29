# This script should download the file specified in the first argument ($1),
# place it in the directory specified in the second argument ($2),

wget -nc -P $2 $1

# and *optionally*:
# - uncompress the downloaded file with gunzip if the third
#   argument ($3) contains the word "yes"

if [ "$3" == "yes" ]
then 
    gunzip -fk "$2/$(basename $1)"
fi 

# - filter the sequences based on a word contained in their header lines:
#   sequences containing the specified word in their header should be **excluded**
#
# Example of the desired filtering:
#
#   > this is my sequence
#   CACTATGGGAGGACATTATAC
#   > this is my second sequence
#   CACTATGGGAGGGAGAGGAGA
#   > this is another sequence
#   CCAGGATTTACAGACTTTAAA
#
#   If $4 == "another" only the **first two sequence** should be output

if [ "$4" == "small nuclear" ]
then
    seqkit grep -n -p "$4" -v -r "$2/contaminants.fasta" > "$2/contaminants_filtered.fasta"
fi 
