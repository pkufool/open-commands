# keep here just for reference

keywords = set()
with open("CN/cn_speech_commands/manifest/text", "r") as f1, open(
    "CN/small/commands.txt", "r"
) as f2, open("CN/small/text", "w") as fo1, open("CN/small/segments", "w") as fo2, open(
    "CN/small/wav.scp", "w"
) as fo3, open(
    "CN/large/text", "w"
) as fo4, open(
    "CN/large/segments", "w"
) as fo5, open(
    "CN/large/wav.scp", "w"
) as fo6:
    for line in f2:
        keywords.add(line.strip())
    for line in f1:
        tok = line.strip().split("\t")
        if tok[1] in keywords:
            fo1.write(line)
            fo2.write(f"{tok[0]}\t{tok[0]}\t0\t-1\n")
            fo3.write(f"{tok[0]}\tCN/cn_speech_commands/wavs/{tok[0]}.wav\n")
        fo4.write(line)
        fo5.write(f"{tok[0]}\t{tok[0]}\t0\t-1\n")
        fo6.write(f"{tok[0]}\tCN/cn_speech_commands/wavs/{tok[0]}.wav\n")
