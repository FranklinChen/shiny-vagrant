require(stringr)
require(reshape2)
#options(encoding = 'UTF-8')

durdf =read.csv("~/alldurations2.csv")
durdf$full = paste(durdf$X1, durdf$X2, durdf$X3, durdf$X4,sep="/")
durdf$full2 = str_replace(durdf$full,"[.][^ ][^ ][^ ]$","")
durdf$full2 = str_replace(durdf$full2,"[/]+","/")
durdf$duration=as.numeric(durdf$duration)
dir.create("durations")

dir.create("actualcsv")
fl = list.files("csvfolderMake","^.+.rds",full.names=T)

mediadf = read.csv("media.csv",stringsAsFactors=F)
print(head(mediadf))

saveDurations <- function(snddf,dname){
  print(dname)
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
#  print(head(snddf))
   snddf$agemonth = as.numeric(snddf$agemonth)
   snddf$agemonth = round(snddf$agemonth,3)

 print(head(snddf))
  sumdf = aggregate(cbind(one) ~ role2 + duration + langgrp + langtype+ corpus + file + agemonth, snddf, sum) 
 print("sumdf")
print(head(sumdf))
sumdf2 = dcast(sumdf, langgrp + langtype + corpus + file + agemonth + duration ~ role2,value.var="one")
 print(head(sumdf2))
if (!"Parent" %in% names(sumdf2)){
    sumdf2$Parent = NA
  }
  if (!"Other" %in% names(sumdf2)){
     sumdf2$Other = NA
  }
  sumdf2$input = rowSums(sumdf2[,c("Parent","Other")],na.rm=T)
  sumdf2$agemonth[sumdf2$agemonth == -100]=NA
#  print(sumdf2)
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
    	   df$duration[r] = durdf$duration[durdf$full2 == f]
    	   durdf$used[durdf$full2 == f] = TRUE
#    	   print(durdf[durdf$full2 == f,])

	   agemonth = "-100"
	   rdf = df[r,]
	   if ("Target_Child" %in% rdf$role && "agemonth" %in% names(rdf)){
	       agemonth = rdf$agemonth[rdf$role == "Target_Child"]
  	   }
	   df$agemonth[r] = agemonth
	
#	   print(f)
	   mat = str_detect(mediadf$file,f)
	   if (any(mat)){
	     mdf = mediadf[mat,]
#	     print(mdf)
	     df$mediafile[r] = mdf$mediafile
	     df$mediacode[r] = mdf$mcode
	   }
        }
     }
     sdf = df[!is.na(df$duration),]
     if (length(sdf$duration) > 0){
     	print(head(sdf))
          saveDurations(sdf,durnfl[i])
    }
    df$full = NULL
    df$full2 = NULL
    write.csv(df,nfl[i],fileEncoding = "UTF-8",row.names = F)
    write.csv(durdf,"durtmp.csv",fileEncoding = "UTF-8",row.names = F)
  }
}
