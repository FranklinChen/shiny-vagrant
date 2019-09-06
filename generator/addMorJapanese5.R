#require(stringr)

addMorJapanese <- function(jdf){
  
  jdf$uID=as.character(jdf$uID)
  jdf$mor = ""  # create a new column for results
  for (i in 27102:length(jdf$a)){
    onea = jdf$a[i]    # column from one row
    # print(onea)
    if (!is.na(onea) && str_detect(onea,"[a-z]")){  # if not empty then split
      print(i)
      filelines = jdf$uID==jdf$uID[i] & jdf$corpus == jdf$corpus[i] & jdf$file == jdf$file[i]
      oneutt = jdf[filelines, 1:3]
      oneutt$w=as.character(oneutt$w)
      oneutt$w[is.na(oneutt$w)]="NA####"
      morkan = str_split(onea,";")[[1]]
      morkan[1] = str_replace_all(morkan[1],"([A-z]) (tag[|])","\\1 \\2=")
      morparts = str_split(morkan[1]," ")[[1]]
      lmor = length(morparts) - 1  # number of parts
      ulen = length(oneutt$w)
      if (ulen == lmor){
        oneutt$mor = as.character(morparts[1:lmor])
        jdf$mor[filelines] = as.character(oneutt$mor)
      }else{
        if (lmor > 1){
          tempdf = data.frame(mor=as.character(morparts[1:lmor]))
          tempdf$form = str_match(tempdf$mor,"[^|]+[|]([A-z][^&=-]*)")[,2]
          tempdf$form = str_replace(tempdf$form,"[+].+","")
          tempdf$form[is.na(tempdf$form)] = "########"
          
          tbA = adist(substr(tempdf$form,1,1), substr(oneutt$w,1,1))
          tbB = adist(substr(tempdf$form,1,2), substr(oneutt$w,1,2))
          tbC = adist(substr(tempdf$form,1,3), substr(oneutt$w,1,3))
          tb = adist(tempdf$form,oneutt$w)+tbA+tbB+tbC
          minpos = apply(tb,1,which.min)
          dif = minpos[2:(length(minpos))]-minpos[1:(length(minpos)-1)]
          
          d = which(dif <= 0)+1
          for (dd in d){
            if (dd < length(minpos)){
              mpm = minpos[dd-1]+1
              mpa = minpos[dd+1]-1
              if (mpa - mpm < 1){
                if (mpm <= ulen){
                  minpos[dd]  = mpm
                }
              }else{
                tb2 = tb[,(minpos[dd-1]+1):(minpos[dd+1]-1)]
                minpos2 = apply(tb2,1,which.min)
                newp = minpos2[dd]+minpos[dd-1]-1
                if (newp <= ulen){
                  minpos[dd] = newp
                }
              }
            }
          }
          
          tempdf$mor = as.character(tempdf$mor)
          oneutt$mor = ""
          k = 1
          for (m in 1:length(minpos)){
            mm = minpos[m]
            oneutt$mor[mm] = paste(oneutt$mor[mm],as.character(tempdf$mor[k]))
            k = k+1
          }
          jdf$mor[filelines] = as.character(oneutt$mor) # set mor column to morparts
        }
      }
    }
  }
}

#jdforig <- read.csv("~/Desktop/Japanese_Miyata_Tai_Word_2019-09-05.csv")

