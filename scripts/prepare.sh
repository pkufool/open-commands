#!/usr/bin/env bash

set -eou pipefail

stage=1
stop_stage=10

CN_dir=CN
EN_dir=EN

. scripts/parse_options.sh || exit 1

log() {
  # This function is from espnet
  local fname=${BASH_SOURCE[1]##*/}
  echo -e "$(date '+%Y-%m-%d %H:%M:%S') (${fname}:${BASH_LINENO[0]}:${FUNCNAME[1]}) $*"
}

if [ $stage -le 1 ] && [ $stop_stage -ge 1 ]; then
  log "Stage 1: Download CN commands from modelscope."
  if [ ! -e ${CN_dir}/.cn_speech_commands.done ]; then 
    wget -v "https://www.modelscope.cn/api/v1/datasets/pkufool/open-commands/repo?Revision=master&FilePath=cn_speech_commands.tar.gz" -O ${CN_dir}/cn_speech_commands.tar.gz
    log "untar cn_speech_commands.tar.gz"
    pushd ${CN_dir}
    tar zxf cn_speech_commands.tar.gz
    touch .cn_speech_commands.done
    popd
  else
    log "cn_speech_commands.tar.gz exits, skipping."
  fi
fi

if [ $stage -le 2 ] && [ $stop_stage -ge 2 ]; then
  log "Stage 2: Download CN commands from github."
  if [ ! -e ${CN_dir}/.cn_speech_commands.done ]; then 
    wget -v https://github.com/pkufool/open-commands/releases/download/original_data/cn_speech_commands.tar.gz -O ${CN_dir}/cn_speech_commands.tar.gz
    log "untar cn_speech_commands.tar.gz"
    pushd ${CN_dir}
    tar zxf cn_speech_commands.tar.gz
    touch .cn_speech_commands.done
    popd
  else
    log "cn_speech_commands.tar.gz exits, skipping."
  fi
fi

if [ $stage -le 3 ] && [ $stop_stage -ge 3 ]; then
  log "Stage 3: Download EN commands from modelscope."
  if [ ! -e ${EN_dir}/.fluent_speech_commands.done ]; then 
    wget -v "https://www.modelscope.cn/api/v1/datasets/pkufool/open-commands/repo?Revision=master&FilePath=fluent_speech_commands.zip" -O ${EN_dir}/fluent_speech_commands.zip
    log "unzip fluent_speech_commands.zip"
    pushd ${EN_dir}
    unzip -q fluent_speech_commands.zip
    touch .fluent_speech_commands.done
    popd
  else
    log "fluent_speech_commands.zip exits, skipping."
  fi
fi

if [ $stage -le 4 ] && [ $stop_stage -ge 4 ]; then
  log "Stage 4: Download EN commands from github."
  if [ ! -e ${EN_dir}/.fluent_speech_commands.done ]; then 
    wget -v https://github.com/pkufool/open-commands/releases/download/original_data/fluent_speech_commands.zip -O ${EN_dir}/fluent_speech_commands.zip
    log "unzip fluent_speech_commands.zip"
    pushd ${EN_dir}
    unzip -q fluent_speech_commands.zip
    touch .fluent_speech_commands.done
    popd
  else
    log "fluent_speech_commands.zip exits, skipping."
  fi
fi

if [ $stage -le 5 ] && [ $stop_stage -ge 5 ]; then
  log "Stage 5: Prepare and compute feature for CN commands."
  for part in small large; do
    if [ ! -e ${CN_dir}/.${part}.done ]; then
        python scripts/prepare_dataset_from_kaldi_dir.py \
          --kaldi-dir ${CN_dir}/${part} \
          --dataset cn_speech_commands \
          --partition ${part} \
          --num-jobs 5 \
          --perturb-speed 1
        touch ${CN_dir}/.${part}.done
    else
      log "Manifest ${part} of CN commands already exits, skipping."
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
        --perturb-speed 1
      touch ${EN_dir}/.${part}.done
    else
      log "Manifest ${part} of EN commands already exits, skipping."
    fi
  done
fi
