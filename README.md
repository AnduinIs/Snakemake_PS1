# Learning experience
=

## 1\首先你打开s3: singluarity.py,snakefie,上传到S3


## 2\然后打开instance：获得管理员权限，下载依赖文件和环境：singularity，docker，aws-cli

```
sudo su &&\
snap install snakemake &&\            #下载snakemake
snap install docker  && \             #下载docker
snap install aws-cli --classic   && \ #下载aws-cli
```



[python developer](https://github.com/bilke/snakemake/commit/704e38a44e2e5e54af6af66090e0140b0d2ad075#diff-80031b2d8f48ac13272fca9b904be01b585b2e2764fe88d8e932790d241016bfR176-R185)






## 3\然后跟着我做两部，第一部：把py文件复制到根目录，执行下列代码可以实现

```
aws s3 cp s3://my-genome-data-bucket/singularity.py /lib/python3/dist-packages/snakemake/deployment
```
## 4\第二部，第二部复制smk脚本到instance上

```
aws s3 cp /home/ubuntu/Snakemake_group1.smk s3://{your/own/path/storing}
```

## 5\根据你的工作环境配置snakemake前面部分的环境变量，你可以通过下面的代码进行进入编辑

```
nano Snakemake_group1.smk
```

配置环境变量：accession 和 project——dir来适应不同的user的工作环境。 例如在本次实验中使用的环境变量有
```
trail_accession=["SRR2589044","SRR2584866"]
project_dir=["/home/ubuntu"]
result_dir=["my-genome-data-bucket"]
```

## 6\配置好就可以跑了

```
snakemake --cores 4 -s Snakemake_group1.smk --rerun-incomplete --latency-wait 120 --use-singularity
```


`<hello world>`

Our group first discussed about the functions we need to run in the snakemake script. We want to reproduce the whole process by which starts with downloading the sample sequence and reference sequence. Then TrimmomaticPE function is used to remove low quality sequences. Next, use bowtie2 to align the reads to the reference genome, generating sam files. After that, convert the sam file to bam file in a bid to decrease the file size for future analysis. The whole flow chart of our workflow has been uploaded to the group page as dag.svg file. 

1.Downloading
The first step is the downloading step, where we found to use the sra-tools function to download the sample trials by setting the accession numbers as the parameters. It will download both forward and reverse fastq files based on the provided accession numbers. However, we encountered unwanted problems when using this docker image of sra-tools. One sample (SRR2584863) cannot be completely downloaded through this function, which will generate ‘file imcomplete’ error when being trimmed. It may due to this sra-tool downloads the .fastq file instead of .fastq.gz file. In this case, we simply reduce the accession numbers used as two accession numbers can also prove the reproductivity of our script.

2.Trim
In the trim step, docker images from staphb and biocontainers were first choices while no manual instruction can be found in their homepage. As a result, we turned to another docker image named chrishah/trimmomatic-docker:0.38, where relatively instruction can be found including how to refer the adapter file in the shell code. We also encountered some strange permission related issues which can be solved by signing in as root.

3.Bowtie2
In order to run bowtie2 in one snakemake script, we have to make sure the index will be built before the bowtie2 rule. We managed to do that by specifying one of the inputs in the bowtie2 rule as Ec606.1.bt2 which is also defined as one output of index building rule and will be generated automatically after index building. Through building this input & output connection, the bowtie2 index will be built before running bowtie2. In this case, the input and output are both not presented in the shell directive, while it can still restrict the running order of the two rules.

4.sam to bam & sort
The sam files generated after bowtie2 are not sorted, which have to be compressed into bam files before sorting. It seems that these two steps have been giving us problems that are difficult to solve. The bam files generated by the docker images we tried seems to be broken and returns white errors during sorting, which may point to the previous converting step. We finally determined that the docker image for samtools may contain problems after successfully running the problematic steps with locally installed samtools.

5.Upload vcf files to s3 bucket
The variants calling steps were normal when using docker images. Therefore, we can obtain the results we want in our local storage of the EC2 instance. Based on the function ‘aws s3 cp’ function, we can upload our results to s3 bucket. However, in order to use an output as the final input of the rule all, we need to generate something can be detected by snakemake when uploading our results. We managed to let our script create an empty txt file when performing the uploading process by using ‘touch’ function. So that, one txt file will be created every time after successfully uploading the vcf file, which can be used as a trick to run the uploading rule.
