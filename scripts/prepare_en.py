# keep here just for reference

import csv
import sys

keywords = set()
with open("EN/small/commands.txt", "r") as f:
    for line in f:
        keywords.add(line.strip())

# test set
with open(
    "EN/fluent_speech_commands_dataset/data/test_data.csv", newline=""
) as f, open("EN/small/text", "w") as fo1, open("EN/small/segments", "w") as fo2, open(
    "EN/small/wav.scp", "w"
) as fo3, open(
    "EN/large/text", "w"
) as fo4, open(
    "EN/large/segments", "w"
) as fo5, open(
    "EN/large/wav.scp", "w"
) as fo6:
    reader = csv.reader(f, delimiter=",")
    for row in reader:
        if row[0] == "":
            continue
        assert len(row) == 7, row
        idx = f"{row[2]}-{row[1].split('/')[-1][0:-4]}"
        text = (
            row[3]
            .replace("’", "'")
            .replace(",", "")
            .replace(".", "")
            .replace("?", "")
            .strip()
            .upper()
        )
        wav = f"EN/fluent_speech_commands_dataset/{row[1]}"
        if text in keywords:
            fo1.write(f"{idx}\t{text}\n")
            fo2.write(f"{idx}\t{idx}\t0\t-1\n")
            fo3.write(f"{idx}\t{wav}\n")
        fo4.write(f"{idx}\t{text}\n")
        fo5.write(f"{idx}\t{idx}\t0\t-1\n")
        fo6.write(f"{idx}\t{wav}\n")

# train & valid set
for part in ("train", "valid"):
    with open(
        f"EN/fluent_speech_commands_dataset/data/{part}_data.csv", newline=""
    ) as f, open(f"EN/{part}/text", "w") as fo1, open(
        f"EN/{part}/segments", "w"
    ) as fo2, open(
        f"EN/{part}/wav.scp", "w"
    ) as fo3:
        reader = csv.reader(f, delimiter=",")
        for row in reader:
            if row[0] == "":
                continue
            assert len(row) == 7, row
            idx = f"{row[2]}-{row[1].split('/')[-1][0:-4]}"
            text = (
                row[3]
                .replace("’", "'")
                .replace(",", "")
                .replace(".", "")
                .replace("?", "")
                .strip()
                .upper()
            )
            wav = f"EN/fluent_speech_commands_dataset/{row[1]}"
            fo1.write(f"{idx}\t{text}\n")
            fo2.write(f"{idx}\t{idx}\t0\t-1\n")
            fo3.write(f"{idx}\t{wav}\n")
