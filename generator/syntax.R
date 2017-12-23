require(dplyr)
library(jsonlite)
require(stringr)

fl = list.files("csvfolderMake","^(Chin|Eng|Span|Dutc|Ger|Rom|Othe|Fren|Jap|Sla).+.rds",full.names=T)
print(fl)

nfl = str_replace(fl,"csvfolderMake","googletags")
#nfl = str_replace(nfl,"rds","rds")

for (i in 1:length(fl)){
  if (!file.exists(nfl[i])){
    print(fl[i])
    df = readRDS(fl[i])
    
    all = data.frame()
    for (i in 1:length(df$w)){
      var = as.character(df$w[2])
      cmd = paste("/usr/bin/gcloud ml language analyze-syntax --content=\"",var,"\"",sep="")
      out = system(cmd, intern = TRUE)
      js = fromJSON(paste(out,collapse=" "))
      jsdf = flatten(js$tokens)
      jsdf$sent = js$sentences$text$content
      jsdf$sentnum = i
      all = bind_rows(all,jsdf)
    }
    print(head(all))
    saveRDS(all,nfl[i])
  }
}


