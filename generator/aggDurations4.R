require(ggplot2)
require(stringr)
require(plyr)
require(dplyr)

flist = list.files("workfiles/durations","^[^_]+_[^_]+_.+.csv",full.names=T)
print(flist)

alldf = data.frame()
alldfutt = data.frame()
for (fl in flist){
  print(fl)
  df = read.csv(fl,stringsAsFactors=F)
  df$corpus = as.character(df$corpus)
#  print(head(df))
   if (str_detect(fl,"Word")){
      alldf = bind_rows(alldf,df)
   }else{
      alldfutt = bind_rows(alldfutt,df)
   }
}
write.csv(alldf,"alldfword.csv")
write.csv(alldfutt,"alldfutt.csv")

alldf = alldf[alldf$duration > 600,]
alldf = alldf[!is.na(alldf$Target_Child),]
alldf = alldf[alldf$Target_Child > 10, ]
alldf = alldf[!is.na(alldf$input) ,]
alldf = alldf[alldf$input > 10 ,]
alldf$minfull =alldf$duration/60
alldf$min = alldf$minfull * alldf$input/(alldf$input + alldf$Target_Child)

alldf$corfile = paste(alldf$corpus,alldf$file,"/")
alldf$typecorfile = paste(alldf$langtype,alldf$corpus,alldf$file,"/")
filelangtype = ddply(alldf,~langgrp + langtype,summarise,numfiles=length(unique(corfile)))
filelanggrp = ddply(alldf,~langgrp ,summarise,numfiles=length(unique(typecorfile)))

sumdf = aggregate(cbind(input,duration,min) ~ langgrp + langtype,alldf, sum)
sumdf = sumdf[order(sumdf$langgrp,sumdf$langtype),]
sumdf$rate = sumdf$input/sumdf$min
sumdf$numfile = filelangtype$numfiles
print(sumdf)

sumdf2 = aggregate(cbind(input,duration,min) ~ langgrp,alldf, sum)
sumdf2$rate = round(sumdf2$input/sumdf2$min,3)
sumdf3 = sumdf[sumdf$langgrp %in% c("EastAsian","Other","Romance","Scandinavian","Slavic"),]
sumdf3$langgrp = NULL
names(sumdf3)[1]<-"langgrp"
sumdf2$numfile = filelanggrp$numfiles
sumdf4 = rbind(sumdf3,sumdf2)
sumdf4 = sumdf4[!sumdf4$langgrp %in% c("EastAsian","Other","Romance","Scandinavian","Slavic","Frogs"),]
sumdf4 = sumdf4[order(sumdf4$langgrp),]
sumdf4$duration = NULL
sumdf4$min = round(sumdf4$min)
print(sumdf4)

alldfutt = alldfutt[alldfutt$duration > 600,]
alldfutt = alldfutt[!is.na(alldfutt$Target_Child),]
alldfutt = alldfutt[alldfutt$Target_Child > 10, ]
alldfutt = alldfutt[!is.na(alldfutt$input) ,]
alldfutt = alldfutt[alldfutt$input > 10 ,]
alldfutt$min =alldfutt$duration/60

sumdfutt = aggregate(cbind(input,duration,min) ~ langgrp + langtype,alldfutt, sum)
sumdfutt = sumdfutt[order(sumdfutt$langgrp,sumdfutt$langtype),]
sumdfutt$rate = sumdfutt$input/sumdfutt$min
print(sumdfutt)

sumdfutt2 = aggregate(cbind(input,duration,min) ~ langgrp,alldfutt, sum)
sumdfutt2$rate = sumdfutt2$input/sumdfutt2$min
sumdfutt3 = sumdfutt[sumdfutt$langgrp %in% c("EastAsian","Other","Romance","Scandinavian","Slavic"),]
sumdfutt3$langgrp = NULL
names(sumdfutt3)[1]<-"langgrp"
sumdfutt4 = rbind(sumdfutt3,sumdfutt2)
sumdfutt4 = sumdfutt4[!sumdfutt4$langgrp %in% c("EastAsian","Other","Romance","Scandinavian","Slavic","Frogs"),]
sumdfutt4 = sumdfutt4[order(sumdfutt4$langgrp),]
sumdfutt4$duration = NULL
sumdfutt4$min = round(sumdfutt4$min)
sumdfutt4$rate = round(sumdfutt4$rate,3)
print(sumdfutt4)

both = merge(sumdfutt4,sumdf4, by="langgrp")
names(both)<-c("lang","numutt","minutt","uttpermin","numwords","minwords","wordsmin","numfiles")
both$minutt = round(both$minutt,2)
both$minwords = round(both$minwords,2)
both$wordsmin = round(both$wordsmin,2)
#print(both)
write.csv(both,"both.csv")
print("overall means")
colMeans(both[2:7])

engna = subset(alldf, langgrp == "Eng-NA")
engna$rate = engna$input/engna$min
ggplot(engna,aes(x=agemonth,y=rate))+geom_point(aes(x=agemonth,y=rate,colour=langtype))+stat_smooth(method="lm",mapping=aes(x=agemonth,y=rate))+ylab("Words per minute")
ggsave("storage/plotna.png")

enguk = subset(alldf, langgrp == "Eng-UK")
enguk$rate = enguk$input/enguk$min
ggplot(enguk,aes(x=agemonth,y=rate))+geom_point(aes(x=agemonth,y=rate,colour=langtype))+stat_smooth(method="lm",mapping=aes(x=agemonth,y=rate))+ylab("Words per minute")
ggsave("storage/plotuk.png")

both$X=NULL
both$min=both$minutt
both$minutt=NULL
both$minwords=NULL
both$lang[both$lang=="DutchAfrikaans"]="Dutch"
both$lang[both$lang=="Clinical-MOR"]="Clin-MOR"
both$lang[both$lang=="Portuguese"]="Portug"
names(both)[3] <- "uttmin"
print(both)