require(dplyr)
library(jsonlite)
require(stringr)
require(stringi)

#df= readRDS("~/big/rscripts/shiny-vagrant/generator/workfiles/googletags/Eng-NA_Bloom70_Gia_Word.rds")
#head(df)
# var = "jʌwʌblublublujujæwæ wæjawe"
# var = stri_enc_toascii(var)
# cmd = enc2utf8(paste("~/google-cloud-sdk/bin/gcloud  ml language analyze-syntax --content=\"",var,"\"",sep=""))
# print(cmd)
# out = system(cmd, intern = TRUE)
#df = readRDS("workfiles/googletags/Eng-NA_Bates_Free28_Word.rds")  

fl = list.files("csvfolderMake","^(Eng).+?_.+?_.+?_Utterance.rds",full.names=T)
print(fl)

nfl = str_replace(fl,"csvfolderMake","googletags")
nfl = str_replace(nfl,"Utterance","WordGT")

for (i in 1:length(fl)){
  if (!file.exists(nfl[i])){
    print(fl[i])
    outfile = nfl[i]
    print(outfile)
    df = readRDS(fl[i])
    
    all = data.frame()
 #   saveRDS(all,file=outfile)
    for (j in 1:length(df$w)){
        var = stri_enc_toascii(as.character(df$w[j]))
        if (str_length(var) > 3){
           cmd = enc2utf8(paste("gcloud ml language analyze-syntax --content=\"",var,"\"",sep=""))
           print(cmd)
          out = NULL
          out = tryCatch({
            system(cmd, intern = TRUE)
         }, warning = function(w) {
              print(paste("warning ",w))
            out = NULL
          }, error = function(e) {
              print(paste("error ",e))
            out = NULL
          }, finally = {
              print("done")
            out = NULL
          })
           if (length(out) > 0){
             js = fromJSON(paste(out,collapse=" "))
             jsdf = flatten(js$tokens)
             jsdf$sent = js$sentences$text$content
             jsdf$sentnum = j
             all = bind_rows(all,jsdf)
           }
  
      
      }
    }
    print(head(all))
    saveRDS(all,file=outfile)
  }
}
