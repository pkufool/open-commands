#!/usr/bin/env bash

set -eou pipefail

stage=1
stop_stage=10

mirror=modelscope

CN_dir=CN
EN_dir=EN

. scripts/parse_options.sh || exit 1

log() {
  # This function is from espnet
  local fname=${BASH_SOURCE[1]##*/}
  echo -e "$(date '+%Y-%m-%d %H:%M:%S') (${fname}:${BASH_LINENO[0]}:${FUNCNAME[1]}) $*"
}


if [ $stage -le 1 ] && [ $stop_stage -ge 1 ]; then
  log "Stage 1: Download CN commands."
  if [ ! -e ${CN_dir}/.cn_speech_commands.done ]; then 
    if [ $mirror -eq "modelscope" ]; then
      log "Downloading from modelscope."
      wget -v "https://www.modelscope.cn/api/v1/datasets/pkufool/open-commands/repo?Revision=master&FilePath=cn_speech_commands.tar.bz" -O ${CN_dir}/cn_speech_commands.tar.bz
      wget -v "https://www.modelscope.cn/api/v1/datasets/pkufool/open-commands/repo?Revision=master&FilePath=nihaowenwen.tar.bz" -O ${CN_dir}/nihaowenwen.tar.bz
      wget -v "https://www.modelscope.cn/api/v1/datasets/pkufool/open-commands/repo?Revision=master&FilePath=xiaoyun.tar.bz" -O ${CN_dir}/xiaoyun.tar.bz
    elif [ $mirror -eq "github" ]; then
      log "Downloading from github."
      wget -v https://github.com/pkufool/open-commands/releases/download/original_data/cn_speech_commands.tar.bz -O ${CN_dir}/cn_speech_commands.tar.bz
      wget -v https://github.com/pkufool/open-commands/releases/download/original_data/nihaowenwen.tar.bz -O ${CN_dir}/nihaowenwen.tar.bz
      wget -v https://github.com/pkufool/open-commands/releases/download/original_data/xiaoyun.tar.bz -O ${CN_dir}/xiaoyun.tar.bz
    else
      log "Mirror : $mirror not support."
      exit -1
    fi
    log "Extracting CN commands."
    pushd ${CN_dir}
    tar xf cn_speech_commands.tar.bz
    tar xf nihaowenwen.tar.bz
    tar xf xiaoyun.tar.bz
    touch .cn_speech_commands.done
    popd
  else
    log "CN commands exits, skipping."
  fi
fi

if [ $stage -le 2 ] && [ $stop_stage -ge 2 ]; then
  log "Stage 2: Download EN commands."
  if [ ! -e ${EN_dir}/.fluent_speech_commands.done ]; then 
    if [ $mirror -eq "modelscope" ]; then
      log "Downloading from modelscope."
      wget -v "https://www.modelscope.cn/api/v1/datasets/pkufool/open-commands/repo?Revision=master&FilePath=fluent_speech_commands.zip" -O ${EN_dir}/fluent_speech_commands.zip
    elif [ $mirror -eq "github" ]; then
      log "Downloading from github."
      wget -v https://github.com/pkufool/open-commands/releases/download/original_data/fluent_speech_commands.zip -O ${EN_dir}/fluent_speech_commands.zip
    else
      log "Mirror : $mirror not support."
      exit -1
    fi
    log "unzip fluent_speech_commands.zip"
    pushd ${EN_dir}
    unzip -q fluent_speech_commands.zip
    touch .fluent_speech_commands.done
    popd
  else
    log "fluent_speech_commands.zip exits, skipping."
  fi
fi

if [ $stage -le 3 ] && [ $stop_stage -ge 3 ]; then
  log "Stage 3: Prepare and compute feature for CN commands."
  for part in small large; do
    if [ ! -e ${CN_dir}/.${part}.done ]; then
        python scripts/prepare_dataset_from_kaldi_dir.py \
          --kaldi-dir ${CN_dir}/${part} \
          --dataset cn_speech_commands \
          --partition ${part} \
          --num-jobs 5 \
          --perturb-speed 0
        touch ${CN_dir}/.${part}.done
    else
      log "Manifest ${part} of CN commands already exits, skipping."
    fi
  done
fi


if [ $stage -le 4 ] && [ $stop_stage -ge 4 ]; then
  log "Stage 4: Prepare and compute feature for nihaowenwen."
  for part in test dev train; do
    if [ ! -e ${CN_dir}/nihaowenwen/.${part}.done ]; then
      cat ${CN_dir}/nihaowenwen/utt_ids.${part} | awk '{print $1"\t你好问问"}' > ${CN_dir}/nihaowenwen/${part}/text
      cat ${CN_dir}/nihaowenwen/utt_ids.${part} | awk '{print $1"\tCN/nihaowenwen/wavs/"$1".wav"}' > ${CN_dir}/nihaowenwen/${part}/wav.scp
      cat ${CN_dir}/nihaowenwen/utt_ids.${part} | awk '{print $1"\t"$1"\t0\t-1"}' > ${CN_dir}/nihaowenwen/${part}/segments

      python scripts/prepare_dataset_from_kaldi_dir.py \
        --kaldi-dir ${CN_dir}/nihaowenwen/${part} \
        --dataset nihaowenwen \
        --partition ${part} \
        --num-jobs 5 \
        --perturb-speed 0
        touch ${CN_dir}/nihaowenwen/.${part}.done
    else
      log "Manifest ${part} of nihaowenwen already exits, skipping."
    fi
  done
fi

if [ $stage -le 5 ] && [ $stop_stage -ge 5 ]; then
  log "Stage 5: Prepare and compute feature for xiaoyun."
  for part in clean noisy; do
    if [ ! -e ${CN_dir}/xiaoyun/.${part}.done ]; then
      cat ${CN_dir}/xiaoyun/utt_id.${part} | awk '{print $1"\t小云小云"}' > ${CN_dir}/xiaoyun/${part}/text
      cat ${CN_dir}/xiaoyun/utt_id.${part} | awk '{print $1"\tCN/xiaoyun/wavs/"$1".wav"}' > ${CN_dir}/xiaoyun/${part}/wav.scp
      cat ${CN_dir}/xiaoyun/utt_id.${part} | awk '{print $1"\t"$1"\t0\t-1"}' > ${CN_dir}/xiaoyun/${part}/segments

      python scripts/prepare_dataset_from_kaldi_dir.py \
        --kaldi-dir ${CN_dir}/xiaoyun/${part} \
        --dataset xiaoyun \
        --partition ${part} \
        --num-jobs 1 \
        --perturb-speed 0
        touch ${CN_dir}/xiaoyun/.${part}.done
    else
      log "Manifest ${part} of xiaoyun already exits, skipping."
    fi
  done
fi

if [ $stage -le 6 ] && [ $stop_stage -ge 6 ]; then
  log "Stage 6: Prepare and compute feature for EN commands."
  for part in small large valid train; do
    if [ ! -e ${EN_dir}/.${part}.done ]; then
      python scripts/prepare_dataset_from_kaldi_dir.py \
        --kaldi-dir ${EN_dir}/${part} \
        --dataset fluent_speech_commands \
        --partition ${part} \
        --num-jobs 5 \
        --perturb-speed 0
      touch ${EN_dir}/.${part}.done
    else
      log "Manifest ${part} of EN commands already exits, skipping."
    fi
  done
fi
