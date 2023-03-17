

trail_accession=["SRR2589044","SRR2584866"]
project_dir=["/home/ubuntu"]
result_dir=["my-genome-data-bucket"]

### docker images
#curlimages/curl:7.88.1 
#staphb/samtools:1.16.1 
#mgymrek/vcfutils:latest
#ncbi/sra-tools:latest
#staphb/bcftools:latest
#biocontainers/bowtie2:v2.4.1_cv1
#biocontainers/samtools:v1.9-4-deb_cv1
#chrishah/trimmomatic-docker:0.38



rule all:
    input:
        #expand("{project_dir}/{trail_accession}_final_variants.vcf", trail_accession=trail_accession, project_dir=project_dir)
        expand("{project_dir}/{result_dir}/{trail_accession}.txt", trail_accession=trail_accession, project_dir=project_dir, result_dir=result_dir)

rule download_reference:
    output:
        "{project_dir}/ecoli_rel606.fasta.gz"
    singularity:
        "docker://curlimages/curl:7.88.1"
    shell:
        "curl ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/000/017/985/GCA_000017985.1_ASM1798v1/GCA_000017985.1_ASM1798v1_genomic.fna.gz > {project_dir}/ecoli_rel606.fasta.gz"
        
  #  docker run -t --rm -v /home/ubuntu:/home/ubuntu:rw -w /home/ubuntu ncbi/sra-tools fasterq-dump -e 2 -p GCA_000017985.1


rule unzip_ref_genome:
    input:
        "{project_dir}/ecoli_rel606.fasta.gz"
    output:
        "{project_dir}/ecoli_rel606.fasta"
    shell:
        "gunzip {input}"


rule download_trail:
    output:
        o1="{project_dir}/{trail_accession}_1.fastq",
        o2="{project_dir}/{trail_accession}_2.fastq"
    params:
        p1="{trail_accession}"
    shell:
        "docker run -t --rm -v {project_dir}:{project_dir}:rw -w {project_dir} ncbi/sra-tools fasterq-dump -e 2 -p {params.p1}" 

rule trim:
    input:
        i1="{project_dir}/{trail_accession}_1.fastq",
        i2="{project_dir}/{trail_accession}_2.fastq"
    output:
        o1="{project_dir}/{trail_accession}_1.trim.fastq",
        o2="{project_dir}/{trail_accession}_1un.trim.fastq",
        o3="{project_dir}/{trail_accession}_2.trim.fastq",
        o4="{project_dir}/{trail_accession}_2un.trim.fastq"
    shell:
        "docker run -it --rm -v {project_dir}:{project_dir} -w {project_dir} chrishah/trimmomatic-docker:0.38 trimmomatic PE -threads 4 {input.i1} {input.i2} {output.o1} {output.o2} {output.o3} {output.o4} SLIDINGWINDOW:4:20 MINLEN:25 ILLUMINACLIP:/usr/src/Trimmomatic/0.38/Trimmomatic-0.38/adapters/NexteraPE-PE.fa:2:40:15"


rule bowtie_index:
    input:
        "{project_dir}/ecoli_rel606.fasta"
    params:
        "{project_dir}/Ec606"
    output:
        "{project_dir}/Ec606.1.bt2"
    shell:
        "docker run -it --rm -v {project_dir}:{project_dir} biocontainers/bowtie2:v2.4.1_cv1 bowtie2-build {input} {params} && export BOWTIE2_INDEXES=$(pwd)"

#docker run -it --rm -v /home/ubuntu:/home/ubuntu biocontainers/bowtie2:v2.4.1_cv1 bowtie2-build /home/ubuntu/ecoli_rel606.fasta ~/Ec606


rule bowtie:
    input:
        fq1 = "{project_dir}/{trail_accession}_1.trim.fastq",
        fq2 = "{project_dir}/{trail_accession}_2.trim.fastq",
        i3 = "{project_dir}/Ec606.1.bt2"
    output:
        o1="{project_dir}/{trail_accession}.sam"
    singularity:
        "docker://biocontainers/bowtie2:v2.4.1_cv1"
    shell:
        "bowtie2 --index Ec606 --very-fast -p 1 -1 {input.fq1} -2 {input.fq2} -S {output.o1}"

#docker run -it --rm -v /home/ubuntu:/home/ubuntu -w /home/ubuntu biocontainers/bowtie2:v2.4.1_cv1 bowtie2 --index Ec606 --very-fast -p 1 -1 /home/ubuntu/SRR2589044_1.trim.fastq -2 /home/ubuntu/SRR2589044_2.trim.fastq -S /home/ubuntu/SRR2589044.sam

rule sam_to_bam:
    input:
        "{project_dir}/{trail_accession}.sam"
    output:
        "{project_dir}/sam_to_bam_{trail_accession}.bam"
    threads: 4
    singularity:
        "docker://biocontainers/samtools:v1.9-4-deb_cv1"
    shell:
        "samtools view -S -h -b {input} > {output}"

rule sort:
    input:
        "{project_dir}/sam_to_bam_{trail_accession}.bam"
    output:
        "{project_dir}/{trail_accession}_sorted.bam"
    threads: 4
    singularity:
        "docker://staphb/samtools:1.16.1"
    shell:
        "samtools sort -@ 2 -m 4G {input} -o {output}"

rule samtools_index:
    input:
        "{project_dir}/{trail_accession}_sorted.bam"
    output:
        "{project_dir}/{trail_accession}_sorted.bam.bai"
    threads: 4
    singularity:
        "docker://staphb/samtools:1.16.1"
    shell:
        "samtools index {input}"

rule mpileup:
    input:
        genome="{project_dir}/ecoli_rel606.fasta",
        bam="{project_dir}/{trail_accession}_sorted.bam",
        bai="{project_dir}/{trail_accession}_sorted.bam.bai"
    output:
        "{project_dir}/{trail_accession}_raw.bcf"
    threads: 4
    singularity:
        "docker://staphb/bcftools:latest"
    shell:
        "bcftools mpileup -O b -o {output} -f {input.genome} {input.bam}"

rule variant_calling:
    input:
        "{project_dir}/{trail_accession}_raw.bcf"
    output:
        "{project_dir}/variants_{trail_accession}.vcf"
    threads: 4
    singularity:
        "docker://staphb/bcftools:latest"
    shell:
        " bcftools call --ploidy 1 -m -v {input} > {output}"

rule final_variants:
    input:
        "{project_dir}/variants_{trail_accession}.vcf"
    output:
        "{project_dir}/{trail_accession}_final_variants.vcf"
    threads: 4
    singularity:
        "docker://mgymrek/vcfutils:latest"
    shell:
        '''
        vcfutils.pl varFilter {input} > {output}
        echo 0
        '''

rule upload_to_s3:
    input:
        "{project_dir}/{trail_accession}_final_variants.vcf"
    params:
        "s3://{result_dir}/PS1_result/"
    output:
        "{project_dir}/{result_dir}/{trail_accession}.txt"
    shell:
        "aws s3 cp {input} {params} && touch {output}"
#Generate empty txt file every time the upload succeeds to run this rule.
