require(stringr)
require(reshape2)
#options(encoding = 'UTF-8')

durdf =readRDS("../alldursec.rds")
durdf$full = paste(durdf$langgrp, durdf$langtype, durdf$corpus, durdf$file,sep="/")
durdf$full2 = str_replace(durdf$full,"[.][^ ][^ ][^ ]$","")
durdf$full2 = str_replace(durdf$full2,"[/]+","/")
durdf$dursecs=as.numeric(durdf$dursecs)
dir.create("durations")
dir.create("actualcsv")
fl = list.files("csvfolderMake","^.+.rds",full.names=T)
print(fl)

require(plyr)
ddply(durdf,~langgrp + langtype,summarise,numfiles=length(unique(corpus)))


saveDurations <- function(snddf,dname){
   snddf = snddf[!is.na(snddf$w),]
   snddf = snddf[snddf$w!="",]
   snddf$one= 1
  snddf$role2 = as.character(snddf$role)
  snddf$role2[snddf$role %in% c("Mother","Father")] = "Parent"
  if (!"Target_Child" %in% snddf$role2){
    if ("Child" %in% snddf$role2){
       snddf$role2[snddf$role2=="Child"]="Target_Child"
    }
  }
  snddf$role2[!snddf$role %in% c("Target_Child","Mother","Father")] = "Other"
  print(head(snddf))

  sumdf = aggregate(cbind(one) ~ role2 + duration + langgrp + langtype+ corpus + file, snddf, sum) 
  sumdf2 = dcast(sumdf, langgrp + langtype + corpus + file + duration ~ role2,value.var="one")
  if (!"Parent" %in% names(sumdf2)){
    sumdf2$Parent = NA
  }
  if (!"Other" %in% names(sumdf2)){
     sumdf2$Other = NA
  }
  sumdf2$input = rowSums(sumdf2[,c("Parent","Other")],na.rm=T)
  print(sumdf2)
  write.csv(sumdf2,dname)
}

durnfl = str_replace(fl,"csvfolderMake","durations")
durnfl = str_replace(durnfl,"rds","csv")
nfl = str_replace(fl,"csvfolderMake","actualcsv")
nfl = str_replace(nfl,"rds","csv")

for (i in 1:length(fl)){
  if (!file.exists(nfl[i])){
    print(paste("reading ",fl[i]))
    df = readRDS(fl[i])
    df$full = paste(df$langgrp, df$langtype, df$corpus, df$file,sep="/")
    df$full2 = str_replace(df$full,"[.][^ ][^ ][^ ]$","")
    df$full2 = str_replace(df$full2,"[/]+","/")
    flist = unique(df$full2)

    for (f in flist){
    	r = df$full2 == f
  	if (f %in% durdf$full2){
    	   df$duration[r] = durdf$dursecs[durdf$full2 == f]
    	   durdf$used[durdf$full2 == f] = TRUE
    	   print(durdf[durdf$full2 == f,])
        }
     }
     if (sum(!is.na(df$duration)) > 0){
          saveDurations(df[!is.na(df$duration),],durnfl[i])
    }
    write.csv(df,nfl[i],fileEncoding = "UTF-8",row.names = F)
    write.csv(durdf,"durtmp.csv",fileEncoding = "UTF-8",row.names = F)
  }
}
