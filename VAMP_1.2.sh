#!/bin/bash
set -e
set -o pipefail

echo ""
echo ""
echo "	___      ___    ____         ___   ___         ________   "  
echo "	\  \    /  /   /    \       /   \ /   \       /  __   /   "
echo "	 \  \  /  /   /  /\  \     /  /  /  /  \     /  /_/  /    "
echo "	  \  \/  /   /  ____  \   /  /\    / \  \   /  _____/     "
echo "	   \____/   /__/    \__\ /__/  \__/   \__\ /__/           "
echo ""

echo ""
echo -ne "	\033[1mV\033[22mersatile\r"
sleep 0.5
echo -ne "	\033[1mV\033[22mersatile \033[1mA\033[22mpproach\r"
sleep 0.5
echo -ne "	\033[1mV\033[22mersatile \033[1mA\033[22mpproach for \033[1mM\033[22metabarcoding\r"
sleep 0.5
echo -ne "	\033[1mV\033[22mersatile \033[1mA\033[22mpproach for \033[1mM\033[22metabarcoding \033[1mP\033[22mipelines\r"
sleep 0.5
echo -ne "\n"
sleep 0.5
echo ""
echo "Your one stop shop for any metabarcoding needs!"
sleep 1
echo ""

#read -p "Do you want to clean up the directory first? (y/n): " clean
		
if [[ $clean == "y" ]]; then
	rm -r 1_demux
	rm -r 2_demux
	rm *.fasta
	rm *.stat
	rm -r fwd_dada
	rm -r rev_dada
	rm *.R
else
	echo "OK, lets get started."
fi

# Asks if you want to do both RDP and BLAST or just BLAST alone, then uses the $pipeline variable later in "if: then" functions to decide whether or not to run RDP

until [[ $pipeline == "1" || $pipeline == "2" ]]
do
	echo ""
	echo "What pipeline do you want to use? (Type the number)
	
1 - Run both RDP and BLAST
2 - Run just BLAST"
	echo ""
	read -p "Pipeline: " pipeline
	echo ""	
done	

# Asks if you've put your two files in the directory, and will keep asking the question unless the answer is y.

until [[ $answer == "y" ]]
do
	echo ""
	echo -e "Are your \033[1mtwo\033[22m sequence files (ending in .fq.gz) in the current directory?" 
	echo ""
	read -p "(y/n):" answer
	echo ""	
done

echo "Ok, got them"


# Looks for files ending in _1.fq.gz and _2.fq.gz, and sets those filenames as the two variables fwdfile and revfile, which then autofill into the cutadapt command.

fwdfile=$(find *_1.fq.gz)
revfile=$(find *_2.fq.gz)

# Asks the user to pick the primers they used for PCR, and then copies the .fasta file with the primer and tag sequences into the current directory.
# Depending on what primers are chosen, the amplicon length needed for the trunc option is decided and copied into the dada script.

until [[ $tags == "0" || $tags == "1" || $tags == "2" || $tags == "3" || $tags == "4" || $tags == "5" ]]
do
	echo ""
	echo "What tagged primers are you using? (Type the number)
	
0 - rbcl diatomes (3f 2r)
1 - Kelly 12S
2 - Gwen COI (ZF5 & ZR5)
3 - Core COI
4 - 16S
5 - Plant ITS" 
	echo ""
	read -p "Number: " tags
	echo ""	
done

if [[ $tags == "0" ]]; then
	current_directory=$(pwd)
	cp /data03/area52_files/primers/rbcl_wobbly_fwd.fasta $current_directory
	cp /data03/area52_files/primers/rbcl_wobbly_rev.fasta $current_directory
	forwardtag="rbcl_wobbly_fwd.fasta"
	reversetag="rbcl_wobbly_rev.fasta"
	fwdlength=200
	revlength=170
	smallnum=$(( fwdlength - 5 ))
	bignum=$(( fwdlength + 5 ))
fi

if [[ $tags == "1" ]]; then
	current_directory=$(pwd)
	cp /data03/area52_files/primers/fwd_12S_Kelly.fasta $current_directory
	cp /data03/area52_files/primers/rev_12S_Kelly.fasta $current_directory
	forwardtag="fwd_12S_Kelly.fasta"
	reversetag="rev_12S_Kelly.fasta"
	fwdlength=108
	revlength=108
	smallnum=$(( fwdlength - 5 ))
	bignum=$(( fwdlength + 5 ))
fi

if [[ $tags == "2" ]]; then
	current_directory=$(pwd)
	cp /data03/area52_files/primers/fwd_COI_Gwen_ZF5.fasta $current_directory
	cp /data03/area52_files/primers/rev_COI_Gwen_ZR5.fasta $current_directory
	forwardtag="fwd_COI_Gwen_ZF5.fasta"
	reversetag="rev_COI_Gwen_ZR5.fasta"
	fwdlength=112
	revlength=118
	smallnum=152
	bignum=162
fi

if [[ $tags == "3" ]]; then
	current_directory=$(pwd)
	cp /data03/area52_files/primers/Core_COI_fwd.fasta $current_directory
	cp /data03/area52_files/primers/Core_COI_rev.fasta $current_directory
	forwardtag="Core_COI_fwd.fasta"
	reversetag="Core_COI_rev.fasta"
	fwdlength=218
	revlength=218
	smallnum=303
	bignum=323
fi

if [[ $tags == "4" ]]; then
	current_directory=$(pwd)
	cp /data03/area52_files/primers/16S_fwd_primers.fasta $current_directory
	cp /data03/area52_files/primers/16S_rev_primers.fasta $current_directory
	forwardtag="16S_fwd_primers.fasta"
	reversetag="16S_rev_primers.fasta"
	fwdlength=218
	revlength=218
	smallnum=303
	bignum=323
fi

if [[ $tags == "5" ]]; then
	current_directory=$(pwd)
	cp /data03/area52_files/primers/ITS_fwd.fasta $current_directory
	cp /data03/area52_files/primers/ITS_rev.fasta $current_directory
	forwardtag="ITS_fwd.fasta"
	reversetag="ITS_rev.fasta"
	fwdlength=223
	revlength=221
	smallnum=320
	bignum=360
fi
# Asks how many single base errors you will allow in the primers.

until [[ $err == "1" || $err == "2" || $err == "3" ]]
do
	echo ""
	echo "How many nucleotide errors are you allowing in your tagged primers? (1, 2 or 3)" 
	echo ""
	read -p "Number: " err
	echo ""	
done

# Decides the error rate to give to cutadapt depending on which primers you chose and the error rate

fwdprimerlength=$(awk 'NR==2 { gsub(/[^[:alpha:]]/, "", $0); print length }' $forwardtag)
fwdnumb=$(echo "scale=2; $err / $fwdprimerlength" | bc)
fwderrr=$(echo "scale=2; $fwdnumb + 0.01" | bc)
fwdproperr=0$fwderrr

revprimerlength=$(awk 'NR==2 { gsub(/[^[:alpha:]]/, "", $0); print length }' $reversetag)
revnumb=$(echo "scale=2; $err / $revprimerlength" | bc)
reverrr=$(echo "scale=2; $revnumb + 0.01" | bc)
revproperr=0$reverrr


# Looks for files ending in _forward.txt and _reverse.txt, and sets those filenames as the two variables fwdindex and revindex, which then autofill into the cutadapt command.


until [[ $ansr == "y" ]]
do
	echo ""
	echo -e "Are your \033[1mtwo\033[22m index files (make sure they end in _forward.txt and _reverse.txt) in the current directory?
	
	MAKE SURE THE BLANKS/NEGATIVE CONTROLS CONTAIN THE WORD BLANK/THERE CAN BE NO EMPTY LINES IN THE FILES - ALSO ENSURE ALL DEPENDENCIES ARE INSTALLED
	" 
	echo ""
	read -p "(y/n):" ansr
	echo ""	
done



fwdindex=$(find *_forward.txt)
revindex=$(find *_reverse.txt)


# Entering the RDP database to use. 
# If a number >5 is listed it will loop back to the question until a number between 1 and 5 is entered.

if [[ $pipeline == "1" ]]; then
	until [[ $database == "0" || $database == "1" || $database == "2" || $database == "3" || $database == "4" || $database == "5" || $database == "6" || $database == "7" ]]
	do
		echo ""
		echo "What database are you using? (Type the number)
	
0 - Diatoms
1 - 12S fish
2 - 12S vertebrates
3 - 16S
4 - COI
5 - UK 12S
6 - Plant ITS
7 - Plant rbcl" 
		echo ""
		read -p "Number: " database
		echo ""	
	done

    if [[ $database == "0" ]]; then
		directory="diatoms_RbcL/mydata_trained"
		Fwd_abundance_table="Fwd_diatom_abundance_table.R"
		Rev_abundance_table="Rev_diatom_abundance_table.R"
	elif [[ $database == "1" ]]; then
		directory="12S_fish"
		Fwd_abundance_table="Fwd_abundance_table.R"
		Rev_abundance_table="Rev_abundance_table.R"
	elif [[ $database == "2" ]]; then
		directory="12S_vertebrates"
		Fwd_abundance_table="Fwd_abundance_table.R"
		Rev_abundance_table="Rev_abundance_table.R"
	elif [[ $database == "3" ]]; then
		directory="16srrna"
		Fwd_abundance_table="Fwd_abundance_table.R"
		Rev_abundance_table="Rev_abundance_table.R"
	elif [[ $database == "4" ]]; then
		directory="COI_terriporter/mydata_trained"
		Fwd_abundance_table="Fwd_abundance_table.R"
		Rev_abundance_table="Rev_abundance_table.R"
	elif [[ $database == "5" ]]; then
		directory="uk_12s/training_files"
		Fwd_abundance_table="Fwd_abundance_table.R"
		Rev_abundance_table="Rev_abundance_table.R"
	elif [[ $database == "6" ]]; then
		directory="Plant_ITS/PLANiTSv032920_v1.1"
		Fwd_abundance_table="Fwd_ITS_abundance_table.R"
		Rev_abundance_table="Rev_ITS_abundance_table.R"
	elif [[ $database == "7" ]]; then
		directory="RBCL/mydata_trained"
		Fwd_abundance_table="Fwd_ITS_abundance_table.R" # check these work
		Rev_abundance_table="Rev_ITS_abundance_table.R"
	fi
fi


# Ask how many cores you want to run the cutadapt, and the variable $core_cutadapt is copied into the blast command.
echo ""
echo -e "How many cores do you want to run cutadapt with?" 
echo ""
read -p "Number:" core_cutadapt
echo ""	


# Ask how many cores you want to run the blast, and the variable $numcore is copied into the blast command.
echo ""
echo -e "How many cores do you want to run the BLAST with?" 
echo ""
read -p "Number:" numcore
echo ""	

# Asks what the minimum number of reads you want are, and makes the variable $reads which autofills the later R script that will remove read counts under this number later.
echo ""
read -p "What do you want your minimum number of reads to be " count

if [[ $count == "0" || $count == "1" ]]; then
	reads="0"	
elif [[ $count == "2" ]]; then
	reads="1"
else
	highnumb=$(( $count - 1 ))
	reads="1:$highnumb"
fi

# Bit of text before running cutadapt

echo ""
echo "Easy peasy. Now go make a coffee and VAMP will take it from here"
echo ""
echo "FYI the error rate is $fwdproperr"
echo ""

## Running for the forward reads ##

mkdir 1_demux

cutadapt -j $core_cutadapt -e $fwdproperr --no-indels -g file:$forwardtag -G file:$reversetag -o 1_demux/{name1}-{name2}_R1_001.fastq.gz -p 1_demux/{name1}-{name2}_R2_001.fastq.gz $fwdfile $revfile --minimum-length 100 > fwd_orient.cutadapt.stat

echo ""
#echo "Unzipping files... JC says no need... It casused a crash..."
echo ""

#gunzip 1_demux/*.fastq.gz

mkdir 1_demux/true_hits

echo ""
echo -ne "Now..\r"
sleep 2
echo -ne "Now..Let's fire up dada!\r"
echo -ne "\n"
sleep 1
echo ""

cp $fwdindex 1_demux/

cd 1_demux

#this replaces the old mmv command but requires a longer F_sample_index_file_forward.txt file.
while read old_name new_name; do
  mv "$old_name" "$new_name"
done < $fwdindex

cd true_hits

cd ..

cd ..

mkdir fwd_dada

touch dada_1.R

echo -e "# dada2 pipeline Rscript #

library(\"dada2\")

directory = getwd()
setwd(file.path(directory,\"fwd_dada\"))			# Where you want the output files to save
path <- file.path(directory,\"1_demux/true_hits\")	 		# Where the fastq.gz demuxd files are located

fnFs <- sort(list.files(path, pattern=\"_1.fastq.gz\", full.names = TRUE)) 	   # list forward files 
fnRs <- sort(list.files(path,pattern=\"_2.fastq.gz\", full.names = TRUE)) 	   # list reverse files
sample.names <- sapply(strsplit(basename(fnFs), \"_\"), \`[\`, 1)

# Quality good both ways (checked with FastQC), will truncate F at $length, reverse at $length 

# Place filtered files in filtered/ subdirectory
filtFs <- file.path(path, \"filtered\", paste0(sample.names, \"_F_filt.fastq.gz\"))
filtRs <- file.path(path, \"filtered\", paste0(sample.names, \"_R_filt.fastq.gz\"))
names(filtFs) <- sample.names
names(filtRs) <- sample.names

out <- filterAndTrim(fnFs, filtFs, fnRs, filtRs, truncLen=c($fwdlength,$revlength), minLen=70, maxN=0, maxEE=c(2,2), truncQ=2, rm.phix=TRUE, compress=TRUE, multithread=TRUE)

exists <- file.exists(filtFs) & file.exists(filtRs)
filtFs <- filtFs[exists]
filtRs <- filtRs[exists]

sink(\"filterAndTrim.txt\")
head(out,20)
sink()

sink(\"leanrErrors.txt\")
errF <- learnErrors(filtFs, multithread=TRUE)
errR <- learnErrors(filtRs, multithread=TRUE)
sink()

make.monotone.decreasing <- function(v) sapply(seq_along(v), function(i) max(v[i:length(v)])) # enforce monotonicity in error estimates for Novaseq data
errF.md <- t(apply(getErrors(errF), 1, make.monotone.decreasing))
dimnames(errF.md) <- dimnames(errF\$err_out)
errR.md <- t(apply(getErrors(errR), 1, make.monotone.decreasing))
dimnames(errR.md) <- dimnames(errR\$err_out)

save.image(\"dada2.RData\")

errF\$err_out <- errF.md
pdf(\"errFmd.pdf\")
plotErrors(errF, nominalQ=TRUE)
dev.off()

errR\$err_out <- errR.md
pdf(\"errRmd.pdf\")
plotErrors(errR, nominalQ=TRUE)
dev.off()

sink(\"dadaFs.txt\")
dadaFs <- dada(filtFs, err=errF, multithread=TRUE, pool=TRUE)
sink()
sink(\"dadaRs.txt\")
dadaRs <- dada(filtRs, err=errR, multithread=TRUE, pool=TRUE)
sink()

save.image(\"dada2.RData\")

mergers <- mergePairs(dadaFs, filtFs, dadaRs, filtRs, minOverlap = 40, verbose=TRUE)
# Inspect the merger data.frame from the first sample
sink(\"head_mergers.txt\")
head(mergers[[1]])
sink()

save.image(\"dada2.RData\")

seqtab <- makeSequenceTable(mergers)		# Make ASV table

write.csv(table(nchar(getSequences(seqtab))), \"seq_lengths.csv\")
seqtab2 <- seqtab[,nchar(colnames(seqtab)) %in% $smallnum:$bignum] # lengths set as $smallnum-$bignum bp
write.csv(table(nchar(getSequences(seqtab2))), \"seq_lengths_filt.csv\")
write.csv(seqtab2, \"seqtab2.csv\")

save.image(\"dada2.RData\")

sink(\"chim_rem.txt\")
seqtab.nochim <- removeBimeraDenovo(seqtab2, method=\"consensus\", multithread=TRUE, verbose=TRUE)
dim(seqtab.nochim)
sum(seqtab.nochim)/sum(seqtab2)
sink()

save.image(\"dada2.RData\")

getN <- function(x) sum(getUniques(x))
track <- cbind(out, sapply(dadaFs, getN), sapply(dadaRs, getN), sapply(mergers, getN), rowSums(seqtab.nochim))

colnames(track) <- c(\"input\", \"filtered\", \"denoisedF\", \"denoisedR\", \"merged\", \"nonchim\")
rownames(track) <- sample.names
head(track)
write.csv(track, \"track_fwd_orient.csv\")
save.image(\"dada2.RData\")

uniquesToFasta(seqtab.nochim, \"ASVs_1.fasta\", ids=colnames(seqtab.nochim))
save.image(\"dada2.RData\")
saveRDS(seqtab.nochim, \"seqtab_nochim.rds\")" >> dada_1.R

Rscript dada_1.R

if [[ $pipeline == "1" ]]; then
	echo ""
	echo "Next up is the RDP"
	sleep 2
	echo -ne "RDPeeing....\r"
	sleep 2
	echo -ne "RDPeeing....This make take a sec....\r"
	sleep 1
	echo -ne "\n"
	echo ""

	java -Xmx20g -jar /data03/area52_files/RDP/rdp_classifier_213/dist/classifier.jar classify -t /data03/area52_files/RDP/DBs/$directory/rRNAClassifier.properties -o fwd_dada/RDP_classified_fwd.txt fwd_dada/ASVs_1.fasta

	echo ""
	echo "And now let's make the forward table!"
	echo ""


# Copy the tablemaking scripts into fwd_dada

	cd fwd_dada

	fwddada_directory=$(pwd)

	cp /data03/area52_files/Rscripts/$Fwd_abundance_table $fwddada_directory

	Rscript $Fwd_abundance_table

	cd ..
fi

## Running for the reverse reads ##

echo ""
echo "Go Maith, now let's do it all again but in reverse"
echo ""


mkdir 2_demux

cutadapt -j $core_cutadapt -e $revproperr --no-indels -G file:$forwardtag -g file:$reversetag -o 2_demux/{name1}-{name2}_R1_001.fastq.gz -p 2_demux/{name1}-{name2}_R2_001.fastq.gz $fwdfile $revfile --minimum-length 100 > rev_orient.cutadapt.stat

echo ""
echo "Unzipping...."
echo ""

#gunzip 2_demux/*.fastq.gz

mkdir 2_demux/true_hits


echo ""
echo "Let's get dada going again.."
echo ""
sleep 1

cp $revindex 2_demux/

cd 2_demux

#this replaces the old mmv command but requires a longer R_sample_index_file_forward.txt file.
while read old_name new_name; do
  mv "$old_name" "$new_name"
done < $revindex

cd true_hits

cd ..

cd ..

mkdir rev_dada

touch dada_2.R

echo -e "# dada2 pipeline #

library(\"dada2\")

directory = getwd()
setwd(file.path(directory,\"rev_dada\"))			# Where you want the output files to save
path <- file.path(directory,\"2_demux/true_hits\") # Where the fastq.gz demuxd files are located

## This first part can be run in terminal real time to observe the quality plots before proceeding ##

fnFs <- sort(list.files(path, pattern=\"_1.fastq.gz\", full.names = TRUE)) 	   # list forward files 
fnRs <- sort(list.files(path,pattern=\"_2.fastq.gz\", full.names = TRUE)) 	   # list reverse files
sample.names <- sapply(strsplit(basename(fnFs), \"_\"), \`[\`, 1)


# Place filtered files in filtered/ subdirectory
filtFs <- file.path(path, \"filtered\", paste0(sample.names, \"_F_filt.fastq.gz\"))
filtRs <- file.path(path, \"filtered\", paste0(sample.names, \"_R_filt.fastq.gz\"))
names(filtFs) <- sample.names
names(filtRs) <- sample.names

out <- filterAndTrim(fnFs, filtFs, fnRs, filtRs, truncLen=c($revlength,$fwdlength), minLen=70, maxN=0, maxEE=c(2,2), truncQ=2, rm.phix=TRUE, compress=TRUE, multithread=TRUE)

exists <- file.exists(filtFs) & file.exists(filtRs)
filtFs <- filtFs[exists]
filtRs <- filtRs[exists]


sink(\"filterAndTrim.txt\")
head(out,20)
sink()

sink(\"leanrErrors.txt\")
errF <- learnErrors(filtFs, multithread=TRUE)
errR <- learnErrors(filtRs, multithread=TRUE)
sink()

make.monotone.decreasing <- function(v) sapply(seq_along(v), function(i) max(v[i:length(v)])) # enforce monotonicity in error estimates for Novaseq data
errF.md <- t(apply(getErrors(errF), 1, make.monotone.decreasing))
dimnames(errF.md) <- dimnames(errF\$err_out)
errR.md <- t(apply(getErrors(errR), 1, make.monotone.decreasing))
dimnames(errR.md) <- dimnames(errR\$err_out)

save.image(\"dada2.RData\")

errF\$err_out <- errF.md
pdf(\"errFmd.pdf\")
plotErrors(errF, nominalQ=TRUE)
dev.off()

errR\$err_out <- errR.md
pdf(\"errRmd.pdf\")
plotErrors(errR, nominalQ=TRUE)
dev.off()

sink(\"dadaFs.txt\")
dadaFs <- dada(filtFs, err=errF, multithread=TRUE, pool=TRUE)
sink()
sink(\"dadaRs.txt\")
dadaRs <- dada(filtRs, err=errR, multithread=TRUE, pool=TRUE)
sink()

save.image(\"dada2.RData\")

mergers <- mergePairs(dadaFs, filtFs, dadaRs, filtRs, minOverlap = 40, verbose=TRUE)
# Inspect the merger data.frame from the first sample
sink(\"head_mergers.txt\")
head(mergers[[1]])
sink()

save.image(\"dada2.RData\")

seqtab <- makeSequenceTable(mergers)		# Make ASV table

write.csv(table(nchar(getSequences(seqtab))), \"seq_lengths.csv\")
seqtab2 <- seqtab[,nchar(colnames(seqtab)) %in% $smallnum:$bignum] # lengths set as 106 bp
write.csv(table(nchar(getSequences(seqtab2))), \"seq_lengths_filt.csv\")
write.csv(seqtab2, \"seqtab2.csv\")

save.image(\"dada2.RData\")

sink(\"chim_rem.txt\")
seqtab.nochim <- removeBimeraDenovo(seqtab2, method=\"consensus\", multithread=TRUE, verbose=TRUE)
dim(seqtab.nochim)
sum(seqtab.nochim)/sum(seqtab2)
sink()

save.image(\"dada2.RData\")

getN <- function(x) sum(getUniques(x))
track <- cbind(out, sapply(dadaFs, getN), sapply(dadaRs, getN), sapply(mergers, getN), rowSums(seqtab.nochim))

colnames(track) <- c(\"input\", \"filtered\", \"denoisedF\", \"denoisedR\", \"merged\", \"nonchim\")
rownames(track) <- sample.names
head(track)
write.csv(track, \"track_rev_orient.csv\")
save.image(\"dada2.RData\")

library(\"Biostrings\")
asvs <- colnames(seqtab.nochim)
asvs <- DNAStringSet(asvs)
asvs <- reverseComplement(asvs)
asvs <- as.data.frame(asvs)
seqtab.nochim2 <- seqtab.nochim
colnames(seqtab.nochim2) <- asvs\$x

uniquesToFasta(seqtab.nochim2, \"ASVs_2.fasta\", ids=colnames(seqtab.nochim2))
save.image(\"dada2.RData\")
saveRDS(seqtab.nochim2, \"seqtab_nochim2.rds\")" >> dada_2.R

Rscript dada_2.R

if [[ $pipeline == "1" ]]; then
	echo ""
	echo -ne "RDPeeing....\r"
	sleep 2
	echo -ne "RDPeeing....again....\r"
	sleep 1
	echo -ne "\n"
	echo ""

	java -Xmx20g -jar /data03/area52_files/RDP/rdp_classifier_213/dist/classifier.jar classify -t /data03/area52_files/RDP/DBs/$directory/rRNAClassifier.properties -o rev_dada/RDP_classified_rev.txt rev_dada/ASVs_2.fasta

	echo ""
	echo "Aaaand finally, let's make your reverse table!"
	echo ""
 
	cd rev_dada

	# Copy the tablemaking scripts into rev_dada

	revdada_directory=$(pwd)

	cp /data03/area52_files/Rscripts/$Rev_abundance_table $revdada_directory

	Rscript $Rev_abundance_table

	cd ..
fi

### BLASTING ###

# FORWARD #

# If RDP included, this step takes out the ASVs and puts them in a fasta format for blasting, otherwise just blasts the ASVs as they came out of DADA.

mkdir Finished_tables

cd fwd_dada

if [[ $pipeline == "1" ]]; then
	ASVfwdblast="ASV_fwd_for_blast.fasta"
	echo ""
	echo "Now lets BLAST those ASVs to make sure RDP isn't lying.."
	sleep 1
	echo ""

	echo "Pulling out forward ASVs"
	echo ""

	## command for comma separated csv, 'NR!=1' skips the first line (the header), gsub swaps any " for nothing, 
	## print ">"$1 prints the first column with an ">" added in front, and "\n" means move the second column
	## to a new line.

	awk -F "," 'NR!=1 {gsub(/"/, ""); print ">"$1, "\n"$2}' Fwd_abundance_table.csv > ASV_fwd_for_blast.fasta


elif [[ $pipeline == "2" ]]; then
	ASVfwdblast="ASVs_1.fasta"

fi

spinner=( "BLASTing ASVs  ACGTACGT" "BLASTing ASVs  -CGTACGT" "BLASTing ASVs  A-GTACGT" "BLASTing ASVs  AC-TACGT" "BLASTing ASVs  ACG-ACGT" "BLASTing ASVs  ACGT-CGT" "BLASTing ASVs  ACGTA-GT" "BLASTing ASVs  ACGTAC-T" "BLASTing ASVs  ACGTACG-")

copy(){
	spin &
	pid=$!

/data01/nt_2024/./blastn -query $ASVfwdblast -db /data01/nt_2024/nt -num_threads $numcore -max_target_seqs 10 -outfmt "6 qseqid stitle pident length evalue" -out ASV_fwd_blast_results.txt

	## Print top hit of each result only.

	sort -k1,1 -u ASV_fwd_blast_results.txt > ASV_fwd_blast_top_hit.csv

	kill $pid
	echo ""
}

spin(){
	while [ 1 ]
	do
		for i in "${spinner[@]}"
		do
			echo -ne "\r$i"
			sleep 0.2
		done
	done
}

copy
echo ""



## Merge the blast results with the RDP results

if [[ $pipeline == "1" ]]; then

	echo "Combining BLAST results to RDP results"
	echo ""

	cp /data03/area52_files/Rscripts/Fwd_combine_blast.R $fwddada_directory

#### THIS IS WHERE TO ADD THE NEW R SCRIPTS

	Rscript Fwd_combine_blast.R

# Move the table to the Finished_tables folder

	mv Fwd_combined_results.csv ../

	cd ..

	mv Fwd_combined_results.csv Finished_tables/
fi

if [[ $pipeline == "2" ]]; then

	echo "Combining BLAST results to sample table"
	echo ""

	cp /data03/area52_files/Rscripts/Fwd_Blastonly_combo.R $fwddada_directory

	Rscript Fwd_Blastonly_combo.R

# Move the table to the Finished_tables folder

	mv Fwd_Blast_results.csv ../

	cd ..

	mv Fwd_Blast_results.csv Finished_tables/
fi


# REVERSE #

cd rev_dada

if [[ $pipeline == "1" ]]; then
	ASVrevblast="ASV_rev_for_blast.fasta"
	echo ""
	echo "Pulling out reverse ASVs"
	echo ""

	awk -F "," 'NR!=1 {gsub(/"/, ""); print ">"$1, "\n"$2}' Rev_abundance_table.csv > ASV_rev_for_blast.fasta

elif [[ $pipeline == "2" ]]; then
	ASVrevblast="ASVs_2.fasta"

fi

echo "Blasting ASVs"
echo ""

/data01/nt_2024/./blastn -query $ASVrevblast -db /data01/nt_2024/nt -num_threads $numcore -max_target_seqs 10 -outfmt "6 qseqid stitle pident length evalue" -out ASV_rev_blast_results.txt



## Print top hit of each result only.

sort -k1,1 -u ASV_rev_blast_results.txt > ASV_rev_blast_top_hit.csv

## Merge the blast results with the RDP results

if [[ $pipeline == "1" ]]; then

	echo "Combining BLAST results to RDP results"
	echo ""

	cp /data03/area52_files/Rscripts/Rev_combine_blast.R $revdada_directory

	Rscript Rev_combine_blast.R

# Move the table to the Finished_tables folder

	mv Rev_combined_results.csv ../

	cd ..

	mv Rev_combined_results.csv Finished_tables/

fi

if [[ $pipeline == "2" ]]; then

	echo "Combining BLAST results to sample table"
	echo ""

	cp /data03/area52_files/Rscripts/Rev_Blastonly_combo.R $revdada_directory

	Rscript Rev_Blastonly_combo.R

# Move the table to the Finished_tables folder

	mv Rev_Blast_results.csv ../

	cd ..

	mv Rev_Blast_results.csv Finished_tables/

fi


## Clean up all the extra files

mkdir TicFuc_bits

mv 1_demux TicFuc_bits/
mv 2_demux TicFuc_bits/
mv dada_1.R TicFuc_bits/
mv dada_2.R TicFuc_bits/
mv $forwardtag TicFuc_bits/
mv $reversetag TicFuc_bits/
mv fwd_dada TicFuc_bits/
mv rev_dada TicFuc_bits/
mv fwd_orient.cutadapt.stat TicFuc_bits/
mv rev_orient.cutadapt.stat TicFuc_bits/

echo ""
echo "Voila!"
sleep 2
echo ""
echo "Your results are in the folder called Finished_tables."
sleep 3
echo ""
echo "FYI the error rate you used was $fwdproperr"

# Print the minimum read count
echo "The minimum read count you selected for BLASTn was: $count"

echo ""          
echo -ne "              \\\/////        
             / _  _ \         
           (| (.)(.) |)       
   .-----.OOOo--()--oOOO.----.
   |                         |
   |     \033[1mCONGRATULATIONS\033[22m     |
   |   \033[1mYOU ARE OFFICIALLY\033[22m    |
   |        \033[1mA VAMP\033[22m         |
   |          user           |
   '------.oooO--------------'
          (   )   Oooo.       
           \ (    (   )        
            \_)    ) /        
                  (_/"
echo -ne "\n"
echo ""
echo ""  
sleep 1


