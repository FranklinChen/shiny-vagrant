require(stringr)

fl = list.files("csvfolderMake","^.+.rds",full.names=T)
print(fl)

#args = commandArgs(trailingOnly=TRUE)
#fi = "storage/csvcorpora/Eng-UK_Utterance.rds"
#if (length(args)==1){
#  fi = args[1]
#}

nfl = str_replace(fl,"csvfolderMake","actualcsv")
nfl = str_replace(nfl,"rds","csv")

for (i in 1:length(fl)){
  if (!file.exists(nfl[i])){
    print(fl[i])
    df = readRDS(fl[i])
    write.csv(df,nfl[i])
  }
}
