#!/usr/bin/env bash
#SBATCH -o /home/%u/slurm_logs/slurm-%A_%a.out
#SBATCH -e /home/%u/slurm_logs/slurm-%A_%a.out
#SBATCH -N 1	  # nodes requested
#SBATCH -n 1	  # tasks requested
#SBATCH --gres=gpu:0  # use 1 GPU
#SBATCH --mem=32GB  # memory in Mb
#SBATCH --cpus-per-task=12  # number of cpus to use - there are 32 on each node.

set -e # fail fast

# Activate Conda
source /home/${USER}/miniconda3/bin/activate ParlAI

export CURRENT_TIME=$(date "+%Y_%m_%d_%H%M%S")

# Env variables
export STUDENT_ID=${USER}
export CLUSTER_HOME="/home/${STUDENT_ID}"
export EXP_NAME="wikiplots_jul_2020"
export EXP_ID="${EXP_NAME}_${CURRENT_TIME}"

declare -a ScratchPathArray=(/disk/scratch_big/ /disk/scratch1/ /disk/scratch2/ /disk/scratch/ /disk/scratch_fast/)

# Iterate the string array using for loop
for i in "${ScratchPathArray[@]}"; do
  echo ${i}
  if [ -d ${i} ]; then
    export SCRATCH_HOME="${i}/${STUDENT_ID}"
    mkdir -p ${SCRATCH_HOME}
    if [ -w ${SCRATCH_HOME} ]; then
      break
    fi
  fi
done

echo ${SCRATCH_HOME}

export SERIAL_DIR="${SCRATCH_HOME}/${EXP_ID}"
mkdir -p ${SERIAL_DIR}

export EXP_ROOT="${CLUSTER_HOME}/git/WikiPlots/"

cd "${EXP_ROOT}"

echo "Wikiplots Extract Task========"

python wikiPlots.py "${HOME}/wiki/enwiki-20200701-pages-extracted/" "${SERIAL_DIR}/${EXP_NAME}.jsonl"

echo "============"
echo "Task finished"

export HEAD_EXP_DIR="${CLUSTER_HOME}/runs/${EXP_ID}"
mkdir -p "${HEAD_EXP_DIR}"
rsync -avuzhP "${SERIAL_DIR}/" "${HEAD_EXP_DIR}/" # Copy output onto headnode

rm -rf "${SERIAL_DIR}"

echo "============"
echo "results synced"