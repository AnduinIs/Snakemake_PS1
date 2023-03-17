# Instruction manual



## 1. Preparation
##### Get administrator access and pre-downloads

* The first step is to upload the provided `snakefile` and `singularity.py` onto your s3 bucket. 
* The you should open your AWS EC2 instance and __*install the required software*__.
```ruby

sudo su &&\
snap install snakemake &&\            #download snakemake
snap install docker  && \             #download docker
snap install aws-cli --classic   && \ #download aws-cli
```
* You should also configure your instance and make sure you can download and upload files from or onto your s3 bucket
****
##### Update the singularity version
* Due to the version issue of using `singularity` in `snakemake`, you should replace the original `singularity.py` file with the modified version provided by us. We found the solution for this issue from [bilke](https://github.com/bilke/snakemake/commit/704e38a44e2e5e54af6af66090e0140b0d2ad075#diff-80031b2d8f48ac13272fca9b904be01b585b2e2764fe88d8e932790d241016bfR176-R185). __*Run the following code*__ and solve this problem.
```ruby
aws s3 cp s3://Your-bucket-name/singularity.py /lib/python3/dist-packages/snakemake/deployment
```
****
##### Configure your environment variables
* Because we have omitted the download and import of the configuration file, you will need to change the environment variables in the snakemake script we provided. <br />
* __*You should first download it from your s3 bucket.*__

```ruby
aws s3 cp s3://Your-bucker-name/Snakemake_group1.smk . 
```

* *__Then you should change the environment variables listed at the beginning of `Snakemake_group1.smk` based on your instance.__*

```ruby
trail_accession=["SRR2589044","SRR2584866"]
project_dir=["/home/ubuntu"]
result_dir=["my-genome-data-bucket"]
```

    * The above is the settings for our use, you can change the accession number to other samples from Lenski's experiment. The `result_dir` refers to your `s3 bucket` name.*

## 2. Running the snakefile
* Using the following code to run your `snakefile`.
```ruby
snakemake --cores -s Snakemake_group1.smk --rerun-incomplete --latency-wait 120 --use-singularity
```

* You can see some `.txt` files are generated if your final results have been successfully uploaded onto your `s3 bucket`. *
* __ I wish you success ba.__ -Love from China*

## 3. Results

![DAG workflow](https://github.com/AnduinIs/Snakemake_PS1/blob/main/dag(1).svg) 

