#require(openxlsx)
library(stringr)
require(xml2)
require(dplyr)
require(ngram)
library(doParallel)

options(encoding = 'UTF-8')
csvfolder = "csvfolderMake"

args <- commandArgs(TRUE)
mode <- as.integer(args[1])
if (is.na(mode)){
  mode=0
}
nc = 1
if (Sys.getenv("RSTUDIO")!="1"){
  nc = as.integer(detectCores()/2)
}else{
  setwd("/media/big/chang/rscripts/shiny-vagrant/generator/workfiles")
  mode = -1
}
cl <- makeCluster(nc,outfile="",type = "FORK")
registerDoParallel(cl)

print("mode")
print(mode)

#setwd("~/big/rscripts/corpus/childes/workfiles")
#write("start",file="myfile",append=FALSE)

readFileLoop <- function(fname){
  fdf=NULL
 # for (i in 1:100) {
    tryCatch({
      fdf = readRDS(fname)
      if (length(fdf) > 0){
        return(fdf)
      }
    }, error=function(e){cat("ERROR :",fname,conditionMessage(e), "\n")})
 # }
  if (fdf == NULL){
    print(paste("NOTFOUND ",fname))
  }else{
    print(paste("FOUND ",fname))
  }
  return(NULL)
}
#readFileLoop("csvfolderMake/Eng-UK_Forrester_Word.csv")

listFilesSortSize <- function(csvfolder,filere,fn = T, rec = T){
  flist = list.files(path = csvfolder, filere, full.names = fn, recursive = rec)
  details = file.info(flist)
  details2=details[order(-details$size),]
  return(rownames(details2))
}

safeSave <- function(df,namerds,namecsv){
  tryCatch({
    saveRDS(df,namerds)
    print(paste("safesave rds",namerds))
  }, warning = function(w) {
    print(paste("warning rds",w))
  }, error = function(e) {
    print(paste("error rds",e))
  })
#  if (!is.null(namecsv)){
#    tryCatch({
#      write.csv(df,namecsv,fileEncoding = "UTF-8",row.names = F)
#      print(paste("safesave csv",namerds))
#    }, warning = function(w) {
#      print(paste("warning csv",w))
#    }, error = function(e) {
#      print(paste("error csv",e))
#    })
#  }
}

mergePartMain <- function(table,parttable){
  table$origline = 1:length(table$who)
  table=merge(table,parttable,by.x="who",by.y="id",all.x=T,sort=F)
  table=table[order(table$origline),]
  row.names(table)<-1:length(table[,1])
  return(table)
}

parstr = '<Participants>
  <participant id="ET1" name="Teacher_Dorothy" role="Teacher" language="eng"/>
<participant id="KIE" name="Kiera" role="Child" language="eng" age="P5Y8M" education="K2"/>
<participant id="SAN" name="Sandra" role="Child" language="eng" age="P5Y5M" education="K2"/>
<participant id="STA" name="Stacey" role="Child" language="eng" age="P6Y2M" education="K2"/>
<participant id="KRI" name="Krista" role="Child" language="eng" education="K2"/>
<participant id="CT1" name="Hua_Wen_Laoshi" role="Teacher" language="zho"/>
<participant id="IVA" name="Ivan" role="Child" language="eng" age="P6Y2M" education="K2"/>
<participant id="JAM" name="James" role="Child" language="eng" age="P5Y5M" education="K2"/>
<participant id="CM1" name="Unidentified" role="Child" language="eng" education="K2"/>
<participant id="ALA" name="Alan_Lai" role="Child" language="eng" age="P6Y4M" education="K2"/>
<participant id="LEA" name="Lea" role="Child" language="eng" education="K2"/>
<participant id="MEL" name="Melvin" role="Child" language="eng" age="P5Y10M" education="K2"/>
<participant id="TIF" name="Tiffany" role="Child" language="eng" age="P5Y6M" education="K2"/>
<participant id="LUC" name="Lucas" role="Child" language="eng" education="K2"/>
<participant id="LEW" name="Lewis" role="Child" language="eng" age="P5Y9M" education="K2"/>
<participant id="MAR" name="Martin" role="Child" language="eng" age="P6Y4M" education="K2"/>
<participant id="AUG" name="Augustine_Zhang" role="Child" language="eng" age="P5Y9M" education="K2"/>
<participant id="EDD" name="Eddie" role="Child" language="eng" education="K2"/>
<participant id="DIA" name="Claudia" role="Child" language="eng" education="K2"/>
<participant id="TAL" name="Tai_Lin" role="Child" language="eng" age="P5Y3M" education="K2"/>
<participant id="CM2" name="Unidentified" role="Child" language="eng" education="K2"/>
<participant id="DRA" name="Kendra" role="Child" language="eng" age="P6Y0M" education="K2"/>
<participant id="EDW" name="Edward" role="Child" language="eng" education="K2"/>
<participant id="JAR" name="Jared" role="Child" language="eng" age="P5Y8M" education="K2"/>
<participant id="CAL" name="Calista" role="Child" language="eng" age="P5Y7M" education="K2"/>
<participant id="TIT" name="Titus" role="Child" language="eng" age="P5Y7M" education="K2"/>
<participant id="CF1" name="Unidentified" role="Child" language="eng" education="K2"/>
<participant id="CF2" name="Unidentified" role="Child" language="eng" education="K2"/>
<participant id="AUN" name="Aunty_Carmen" role="Teacher" language="eng" education="K2"/>
</Participants>'

processParticipants <- function(one){
  partdf = data.frame()
  partset = xml_children(one)
  for (p in partset){
    df = data.frame(t(xml_attrs(p)),stringsAsFactors=F)
    rownames(df)=NULL
    #   print(df)
    partdf = bind_rows(partdf, df)
  }
#  partdf$age[1]="P12"
#  partdf$age[2]="P5Y5M29D"
  
  if ("age" %in% names(partdf) && sum(!is.na(partdf$age)) > 0){
#    print(partdf)
    rr = !is.na(partdf$age)
    ymd = data.frame(str_split_fixed(partdf$age,"[A-Z]",5))
    ymd$X1=NULL
    ymd$X5=NULL
    names(ymd) = c("Y","M","D")
    ymd$Y = as.integer(as.character(ymd$Y))
    ymd$M = as.integer(as.character(ymd$M))
    ymd$D = as.integer(as.character(ymd$D))
    
    partdf = cbind(partdf,ymd)

    partdf$agemonth = partdf$Y * 12
    mon = !is.na(partdf$M)
    partdf$agemonth[mon] = partdf$agemonth[mon] + partdf$M[mon]
    ye = !is.na(partdf$Y)
    partdf$agemonth[ye & !mon] =  partdf$agemonth[ye & !mon] + 6 # if missing, put age in middle of year
    day = !is.na(partdf$D)
    partdf$agemonth[day] = partdf$agemonth[day] + partdf$D[day]/31
 
    # partdf$Y = as.character(partdf$Y)
    # partdf$M = as.character(partdf$M)
    # partdf$D = as.character(partdf$D)
    ages = which(!is.na(partdf$age))
    if (length(ages) == 1){
      partdf$agemonth = partdf$agemonth[ages]
      partdf$Y = partdf$Y[ages]
      partdf$M = partdf$M[ages]
      partdf$D = partdf$D[ages]
    }
  }
  return(partdf)
}
#processParticipants(read_xml(parstr))

addtodf <- function(wwdf,cname,val,verbose=FALSE){
  if (cname %in% names(wwdf)){
    wwdf[cname] = paste(wwdf[cname],val,sep=";")
  }else{
    wwdf[cname] = val
  }
  if (verbose){
    print(paste("addtodf",cname,val))
    print(wwdf)
  }
  return(wwdf)
}

addattr <- function(wdf,nodename, node,verbose=FALSE){
  nodeattr = xml_attrs(node)
  if (length(nodeattr) > 0){
    attnames = names(nodeattr)
    if (nodename != ""){
      attnames = paste(nodename,attnames,sep="_")
    }
    for (ii in 1:length(attnames)){
      onecol = attnames[ii]
      wdf = addtodf(wdf,onecol,nodeattr[ii],verbose)
    }
    if (verbose){
      print("addattr")
      print(nodeattr)
      print(wdf)
    }
  }
  return(wdf)
}

processXML <- function(wdf, node, lab = "", verbose=FALSE){
  
  if (class(node) == "xml_node"){
    nodename = xml_name(node)
    orignodename = nodename
    if (lab != ""){
      nodename = paste(lab,nodename,sep="_")
    }
    nodecont = xml_contents(node)
    #     print("nodename")
    #    print(nodename)
    if (length(nodecont)>0 && xml_type(nodecont[[1]]) == "text"){
      txt  = xml_text(nodecont[1])
      if (length(txt) > 0  && nchar(txt)> 0){
        wdf = addtodf(wdf,nodename,txt,verbose)
      }
    }else{
      lab = orignodename
      #      print(paste("lab",lab))
    }
    wdf = addattr(wdf,nodename, node,verbose)
  }
  children = xml_children(node)
  if (length(children) > 0){
    for (i in 1:length(children)){
      wdf= processXML(wdf, children[[i]],lab, verbose)
    }
  }
  if(verbose){
    print("procXML")
    print(node)
    print(wdf)
  }
  
  return(wdf)
}
# processXML(data.frame(line=1),node,lab="",verbose=T)
#node=read_xml('<a type="extension" flavor="trn"></a>')


processXMLFileList <- function(fulfile, csvfolder, verbose = FALSE, force=FALSE,label="") {
  # print("STARTXML")
  newfile = fulfile
  newfile = str_replace(newfile, "data-xml", csvfolder)
  newfile = str_replace(newfile, "[.]xml$", ".rds")
#  print(force)
  if (!file.exists(newfile) | force) {
    if (verbose){
      print(fulfile)
    }
    if (file.exists(fulfile) && str_detect(fulfile, "xml")) {
      file <- read_xml(fulfile)
      print(paste("read file",fulfile,label))
      dir.create(dirname(newfile),
                 recursive = T,
                 showWarnings = F)
      wholefilelines = xml_children(file)
      file = NULL
      alldf = data.frame()
      filelinenum = 1
      if (verbose) {
        print(tail(wholefilelines))
      }
      while (filelinenum <= length(wholefilelines)) {
        linenodeset = wholefilelines[filelinenum]
        nodetype = xml_name(linenodeset)
        #   print(linenodeset)
        
        if (nodetype == "u") {
          if (verbose) {
            print("u")
            print(linenodeset)
          }
          nodeattr = xml_attrs(linenodeset)[[1]]
          attnames = names(nodeattr)
          wdf = data.frame(xmlline = filelinenum)
          for (ii in 1:length(attnames)) {
            onecol = attnames[ii]
            wdf = addtodf(wdf, onecol, nodeattr[ii])
          }
          resetwdf = wdf
          uchildren = xml_children(linenodeset)
          if (length(uchildren) > 0) {
            for (i in 1:length(uchildren)) {
              childnode = uchildren[[i]]
              groupchild = NULL
              unodename = xml_name(childnode)
              if ((unodename == "g" ||
                   unodename == "w") && length(resetwdf) != length(wdf)) {
                alldf = bind_rows(alldf, wdf)
                wdf = resetwdf
              }
              if (unodename == "g") {
                groupchild = xml_children(childnode)
                for (gc in 1:length(groupchild)) {
                  wdf = processXML(wdf,
                                   groupchild[[gc]],
                                   lab = "",
                                   verbose = verbose)
                }
              }
              wdf = processXML(wdf,
                               childnode,
                               lab = "",
                               verbose = verbose)
            }
#            print("bindrows")
#            print(wdf)
            alldf = bind_rows(alldf, wdf)
          }
          uchildren = NULL
          wdf = NULL
          resetwdf = NULL
        }
        if (nodetype == "Participants") {
          partdf = processParticipants(linenodeset)
#          print(partdf)
        }
        filelinenum = filelinenum + 1
      }
      
#      print("finished reading xml file")
#       print("alldf")
#      print(alldf)
      if (length(alldf) > 0 && "uID" %in% names(alldf)) {
        # add word position to data frame
        alldf2 = alldf %>% group_by(uID) %>% mutate(word_posn = row_number())
        alldf$word_posn = alldf2$word_posn
      }
#      print(partdf)
      
      if ("id" %in% names(partdf)){
        alldf3 = data.frame(who = partdf$id,uID = "u-1", w = "",t_type = "p",word_posn = 1)
#        print(alldf3)
#        print(length(alldf))
#        print(length(unique(partdf$id)))
#        print(length(unique(alldf$who)))
        if ("who" %in% names(alldf) && length(unique(alldf$who)) < length(unique(partdf$id))) {
          print("bind prev")
 #         print(head(alldf))
#          print("new")
          alldf = bind_rows(alldf, alldf3)
        } 
        if (length(alldf) <= 0){
          print(paste("EMPTY ", newfile))
          alldf = alldf3
          print(head(alldf))
        }
      }
      
      fnameparts = str_split_fixed(fulfile, "/", 5)
      alldf$langgrp = fnameparts[2]
      alldf$langtype = fnameparts[3]
      if (str_detect(".xml", fnameparts[4])) {
        alldf$corpus = ""
        alldf$file = fnameparts[4]
      } else{
        alldf$corpus = fnameparts[4]
        alldf$file = fnameparts[5]
      }
      onefilelines = mergePartMain(alldf, partdf)
      names(onefilelines) <- str_replace_all(names(onefilelines), "-", "_")
      print(paste("saving ", newfile))
#      print(onefilelines)
      if (sum(onefilelines$uID=="u-1") > 0) {
        start = min(which(onefilelines$uID=="u-1"))-2
        if (start < 1){
          start = 1
        }
        print(onefilelines[start:length(onefilelines),])
      }else{
        if (verbose){
          print(head(onefilelines))
        }
      }
      safeSave(onefilelines,newfile,NULL)      
      alldf = NULL
      partdf = NULL
      wdf = NULL
      lenone = length(onefilelines)
      onefilelines = NULL
      gc()
      return(1)
    }
  }else{
      return(1)
  }
  return(0)
}
#processXMLFileList("data-xml/Chinese/Mandarin/Xinjiang/2012.09/ENNI/sdfyxb10.xml",csvfolder,verbose=T,force=TRUE)
#processXMLFileList("data-xml/Biling/Singapore/e3d5b.xml",csvfolder,verbose=F,force=TRUE)
#processXMLFileList("data-xml/Slavic/Slovenian/Zagar/group2/01pop.xml",csvfolder,verbose=TRUE,force=TRUE)



createCSVfromXML <- function(csvfolder){
  dir.create(csvfolder,showWarnings = F)
  #  flist = list.files(path = "data-xml",".+?xml", full.names = T, recursive = T)
  flist = listFilesSortSize("data-xml",".+?xml")
  print(paste("\n\n@@ create CSV from XML numfiles=",length(flist)))
#  flist = flist[1:14]
#  print(flist)
  funclist = c('bind_rows','addattr','addtodf','mergePartMain','processParticipants','processXML','processXMLFileList','readFileLoop')
#  for (i in 1:length(flist)){
  foundFiles <- foreach(i=1:length(flist),.export=funclist,.packages=c("stringr","xml2")) %dopar% { 
    processXMLFileList(flist[i],csvfolder,verbose=F,label=paste(i,length(flist)))
  }
  print(paste("found=",sum(foundFiles)))
}
#processXMLFileList("data-xml/German/Rigol/Pauline/000623.xml",csvfolder,verbose=T)

if (mode == 1 || mode == 0){
  system.time(createCSVfromXML(csvfolder))
}
print("done createCSVfromXML XML -> rds")

shiftLessInterestingLeft <- function(df){
  print("shift columns")
  lgp = which(names(df)=="langgrp")
  dcol = which(names(df)=="role")
  if ("D" %in% names(df)){
    dcol = which(names(df)=="D")
  }
  if ("agemonth" %in% names(df)){
    dcol = which(names(df)=="agemonth")
  }
  corpusinfo = df[,lgp:dcol]
  df2 = df[,-c(lgp:dcol)]
  if ("w" %in% names(df2)){
    df2$w = NULL
  }
  if ("rownum" %in% names(df2)){
    df2$rownum = NULL
  }
  if ("uID" %in% names(df2)){
    df2$uID = NULL
  }
  if ("xmlnum" %in% names(df2)){
    df2$xmlnum = NULL
  }
  if ("who" %in% names(df2)){
    df2$who = NULL
  }
  if ("t_type" %in% names(df2)){
    df2$t_type = NULL
  }
  if ("word_posn" %in% names(df2)){
    df2$word_posn = NULL
  }
#  percna = apply(is.na(df2),2,sum)/length(df2$who)
#  percna2 = percna[percna > 0.5]
  uniquelen = rev(sort(sapply(apply(df2,2,unique),length)))
#  uniquelen2 = uniquelen[-c(which(names(uniquelen) %in% c("rownum","w","uID","xmlnum")))]
  logunique = log(uniquelen)
  lastset = names(logunique[logunique < mean(logunique)*2])
  firstset = names(logunique[logunique >= mean(logunique)*2])
  allname = names(df)
  notordered = setdiff(allname,c(firstset,lastset))
#  endcol = c(union(names(percna2),names(uniquelen2)))
#  allcol = names(df)
  allcol = c(firstset,notordered,lastset)
  if ("xmlline" %in% allcol){
    allcol = setdiff(allcol,c("xmlline"))
    allcol = c(allcol,"xmlline")
  }
  if ("t_type" %in% allcol){
    allcol = setdiff(allcol,c("t_type"))
    allcol = c("t_type",allcol)
  }
  if ("w" %in% allcol){
    allcol = setdiff(allcol,c("w"))
    allcol = c("w",allcol)
  }
  if ("who" %in% allcol){
    allcol = setdiff(allcol,c("who"))
    allcol = c("who",allcol)
  }
  if ("uID" %in% allcol){
    allcol = setdiff(allcol,c("uID"))
    allcol = c("uID",allcol)
  }
  
  newdf = df[,allcol]
  return(newdf)
}
#df = readRDS("csvfolderMake/Biling_Amsterdam_Annick_Word.rds")
#head(shiftLessInterestingLeft(df))

combineCSVFiles <- function(csvfolder,foldname){
  dir.create("actualcsv",showWarnings = F)
  newfname = str_replace_all(foldname,"_","-")
  newfname = str_replace_all(newfname,"/","_")
  newfnamerds = paste(csvfolder,"/",newfname,"_Word.rds",sep="")
  newfnamecsv = paste("actualcsv/",newfname,"_Word.csv",sep="")
  if (!file.exists(newfnamerds)){
    fold = foldname
    print(paste("starting combineCSVFiles ",newfname))
    flist2 = list.files(path = paste(csvfolder,fold,sep="/"),".+?[.]rds", full.names = T, recursive = T)
#    print(head(flist2))
    allcorpus=data.frame()
    for (i in 1:length(flist2)){
      fdf = readFileLoop(flist2[i])
      fdf$X=NULL
      fdf$origline=NULL
      if (fdf$file[1] == ""){
        fdf$file=fdf$corpus
        fdf$corpus = ""
#        print(head(fdf))
      }
      allcorpus= bind_rows(allcorpus,fdf)
    }
    if ("xmlline" %in% allcorpus){
      allcorpus$xmlnum = allcorpus$xmlline
      allcorpus$xmlline = NULL
    }
    allcorpus$rownum = 1:length(allcorpus$who)
#    print(head(allcorpus))
    print(paste("writing combineCSVFiles ",newfnamerds))
    allcorpus = shiftLessInterestingLeft(allcorpus)
    safeSave(allcorpus,newfnamerds,newfnamecsv)      
    allcorpus = NULL
    fdf = NULL
    gc()
    return(1)
  }else{
    return(1)
  }
  return(0)
}

#combineCSVFiles(csvfolder,"EastAsian/Korean/Jiwon")
#df = readRDS("workfiles/csvfolderMake/Biling/SilvaCorvalan/eng/10.rds")
#unique(df$mor_type)
#df = readRDS("csvfolderMake/EastAsian_Indonesian_Jakarta_Word.rds")

combineFileCorpora <- function(csvfolder){
  print(paste("\n\n@@ combine csv into folder csv ",csvfolder))
  flist = list.files(path = csvfolder, ".+?rds", full.names = T, recursive = T) 
 # print(flist)
  fparts = str_split_fixed(as.character(flist),"/",5)
  fparts = fparts[fparts[,3] != "",]
  fparts[str_detect(fparts[,4],".rds"),4] = ""
  foldname = as.character(unique(paste(fparts[,2],fparts[,3],fparts[,4],sep="/")))
  foldname = str_replace(foldname,"[/]$","")
#  print(foldname)
#  for (i in 1:length(foldname)){
  funclist = c('combineCSVFiles','readFileLoop','shiftLessInterestingLeft')
  x <- foreach(i=1:length(foldname),.export=funclist,.packages=c("stringr","dplyr")) %dopar% { 
    combineCSVFiles(csvfolder,foldname[i])
  }
}
if (mode == 2 || mode == 0){
  system.time(combineFileCorpora(csvfolder))
}
print("finished combineFileCorpora Word")

pasteCol <- function(v) {
  return(paste0(v,collapse=" "))
}

#alluttdf = readFileLoop("csvfolderMake/Clinical-MOR_EllisWeismer_30ec_Word.rds")
word2sent <- function(alluttdf){
  #  print("word2sent")
  alluttdf$lnum = NULL
  alluttdf$word_posn = NULL
#  print(head(alluttdf))
  lgnum = which(names(alluttdf)=="langgrp")
  dcol = which(names(alluttdf)=="role")
  if ("D" %in% names(alluttdf)){
    dcol = which(names(alluttdf)=="D")
  }
  if ("agemonth" %in% names(alluttdf)){
    dcol = which(names(alluttdf)=="agemonth")
  }
  alluttdf[is.na(alluttdf)]=""
  alluttdf[] <- lapply(alluttdf, as.character)
  originalorder = names(alluttdf)
  grpcol = c("uID","who",names(alluttdf)[lgnum:dcol])
  # print(grpcol)
  dots <- lapply(grpcol, as.symbol)
  newdf = alluttdf %>% group_by_(.dots=grpcol) %>% summarise_if(is.character,pasteCol)
  # print(head(alluttdf))
  # print(originalorder)
  #  print(names(alluttdf))
  newdf$numuID = newdf$uID
  newdf$numuID = as.integer(str_replace(newdf$numuID,"u",""))
  newdf =newdf[order(newdf$file,newdf$numuID),c(originalorder,"numuID")]
  #  print("ss")
  if ("w" %in% names(newdf)){
    newdf$w = str_trim(newdf$w)
    newdf$w = str_replace(newdf$w,"\\s+"," ")
    newdf$utt_len = sapply(strsplit(newdf$w, "\\s+"), length)
  }
  if ("t_type" %in% names(newdf)){
    newdf$t_type = str_trim(newdf$t_type)
  }
  #  print("word2sent")
  #  print(head(alluttdf))
  return(newdf)
}

writeUtteranceCorpora <- function(fname,force=FALSE){
  uttfname = str_replace(fname,"_Word","_Utterance")
  uttfnamecsv = str_replace(uttfname,".rds",".csv")
  uttfnamecsv = str_replace(uttfnamecsv,csvfolder,"actualcsv")
  if (!file.exists(uttfname) | force){
    print(paste("reading writeUtteranceCorpora ",fname))
    fdf = readFileLoop(fname)
    if ("w" %in% names(fdf)){
      uttfdf = word2sent(fdf)
      uttfdf$rownum = 1:length(uttfdf$who)
      safeSave(uttfdf,uttfname,uttfnamecsv)      
      print(paste("writing writeUtteranceCorpora ",uttfname))
      uttfdf=NULL
      gc()
      return(1)
    }else{
      return(0)
    }
  }else{
    return(1)
  }
  return(0)
}
#writeUtteranceCorpora("csvfolderMake/Clinical-MOR_EllisWeismer_30ec_Word.rds",force=TRUE)

createUtteranceCorpora <- function(csvfolder){
  flist = listFilesSortSize(csvfolder,".+?_.+?_Word.rds", fn = T, rec = F)
  print(paste("\n\n@@ change Word To Utterance",length(flist)))
  funclist = c('writeUtteranceCorpora','word2sent','pasteCol','readFileLoop')
  foundFiles <- foreach(i=1:length(flist),.export=funclist,.packages=c("stringr","dplyr")) %dopar% { 
    writeUtteranceCorpora(flist[i])
  }
  print(paste("finished=",sum(foundFiles)))
}
if (mode == 3 || mode == 0){
  system.time(createUtteranceCorpora(csvfolder))
}
#utt = read.csv("whole9utt/Biling_Amsterdam_Annick_Utterance.csv")
print("finished createUtteranceCorpora")

combineLangCorpora <- function(csvfolder,name,type){
  newfname = paste(csvfolder,"/",name,"_",type,sep="")
  newfnamecsv = str_replace(newfname,".rds",".csv")
  newfnamecsv = str_replace(newfnamecsv,csvfolder,"actualcsv")
  
  if (!file.exists(newfname)){
    print(paste("starting combineLangCorpora ",newfname))
    searchname = paste(name,"_[^_]+_",type,sep="")
    flist2 = list.files(path = csvfolder,searchname, full.names = T, recursive = F)
    if (length(flist2) > 0){
      allcorpus=data.frame()
      for (j in 1:length(flist2)){
   #     print(paste("reading ",flist2[j]))
        fdf = readFileLoop(flist2[j])
        allcorpus= bind_rows(allcorpus,fdf)
      }
      allcorpus$rownum = 1:length(allcorpus$who)
      safeSave(allcorpus,newfname,newfnamecsv)    
      print(paste("made combineLangCorpora ",newfname))
      allcorpus = NULL
      fdf = NULL
      gc()
    }else{
      print(paste("no files found combineLangCorpora ",searchname))
    }
  }else{
    print(paste("found combineLangCorpora ",newfname))
  }
}

createLangCorpora <- function(csvfolder, langgrp=FALSE){
  if (langgrp){
    print(paste("\n\n@@create Lang Group Corpora"))
    flist = listFilesSortSize(csvfolder,"[^_]+?_[^_]+?_[^_]+?_Word.rds", fn = T, rec = F)
  }else{
    print(paste("\n\n@@create Lang Corpora"))
    flist = listFilesSortSize(csvfolder,"[^_]+?_[^_]+?_Word.rds", fn = T, rec = F)
  }
#  flist = list.files(path = csvfolder,paste(".+?_",type,sep=""), full.names = T, recursive = F)
  fparts= basename(flist)
 # fparts = str_split_fixed(flist,"/",2)
  fparts2 = str_split_fixed(fparts,"_",4)
  if (langgrp){
    fparts3 = unique(fparts2[,1])
  }else{
    fparts3 = unique(paste(fparts2[,1],fparts2[,2],sep="_"))
  }
  fparts3 = fparts3[!str_detect(fparts3,".rds")]
#  print(fparts3)
  fdf = data.frame(file = fparts3, type = "Word.rds",stringsAsFactors=F)
  fdf2 = data.frame(file = fparts3, type = "Utterance.rds",stringsAsFactors=F)
  fdf3 = rbind(fdf,fdf2,stringsAsFactors=F)
#  for (i in 1:length(fdf3$file)){
  funclist = c('combineLangCorpora','readFileLoop')
  x <- foreach(i=1:length(fdf3$file),.export=funclist,.packages=c("stringr","dplyr")) %dopar% { 
    combineLangCorpora(csvfolder,fdf3$file[i],fdf3$type[i])
  }
}
if (mode == 4 || mode == 0){
  system.time(createLangCorpora(csvfolder))
    gc()
}
print("finished createLangCorpora")

if (mode == 5 || mode == 0){
     createLangCorpora(csvfolder,langgrp = TRUE)
     system(paste("rm -f ",csvfolder,"/*_ALL_*",sep=""))
     gc()
}
print("finished createLangCorpora")

######################################################

makeDirList <- function(){
  if (!file.exists("filesData-XML.rds")){
    print("\n\n@@ makeDirList")
    flist = list.files(csvfolder,".+?_Word.rds", full.names = T, recursive = F)
    #  flist = list.files(path = csvfolder,paste(".+?_",type,sep=""), full.names = T, recursive = F)
    fparts= basename(flist)
    # fparts = str_split_fixed(flist,"/",2)
    fparts2 = str_split_fixed(fparts,"_",4)
    fparts2[fparts2[,4]=="Word.rds",4]=""
    fparts2[fparts2[,3]=="Word.rds",3]=""
    fparts2[fparts2[,2]=="Word.rds",2]=""
    #   print(head(dd))
    print(fparts2)
    saveRDS(fparts2, file = "filesData-XML.rds")
  }
}
if (mode == 6 || mode == 0){
  makeDirList()
}
print("finished makeDirList")

################################

summarizeOne <- function(f){
  parts = str_split_fixed(f,"[_/]",5)
  cdf = data.frame(lg=parts[2],langtype=parts[3],corpus=parts[4],
                   numWords = NA, numUtt = NA, wordsPerUtt=NA, mored=0, minAge=NA, maxAge = NA,
                   percTarChild=NA,percParent=NA,percOthers=NA)
  #  worddf = read.csv(f,stringsAsFactors = F)
  #  print(f)
  worddf =  readFileLoop(f)
  if (length(worddf$w)>0){
    #    length(worddf$w)
    worddf$w = str_trim(worddf$w)
    worddf = worddf[worddf$w != "",]
    worddf = worddf[!is.na(worddf$w),]
    if ("mor_type" %in% names(worddf)){
      cdf$mored=round(sum(!is.na(worddf$mor_type))/length(worddf$mor_type),3)
    }
    #   length(worddf$w)
    if (length(worddf$w) > 1){
      fhead = str_replace(f,"Word.rds","")
      f2 = paste(fhead,"Utterance.rds",sep="")
      #     print(f2)
      uttdf =  readFileLoop(f2)
      #  uttdf = read.csv(,stringsAsFactors = F)
      if (length(uttdf$w) > 1 && !str_detect(fhead,"untranscribe")){
        # length(uttdf$w)
        uttdf$w = str_trim(uttdf$w)
        uttdf = uttdf[uttdf$w != "",]
        uttdf = uttdf[!is.na(uttdf$w),]
        #length(uttdf$w)
        uttdf$wordlength = sapply(strsplit(uttdf$w, "\\s+"), length)
        
        cdf$numWords = length(worddf$w)
        cdf$numUtt = length(uttdf$w)
        cdf$wordsPerUtt = mean(uttdf$wordlength,na.rm=T)
        
        if ("Y" %in% names(uttdf)){
          #print(uttdf$Y)
          uttdf$Y=as.numeric(uttdf$Y)
          uttdf$agemonths = uttdf$Y*12
          if ("M" %in% names(uttdf)){
            uttdf$M = as.numeric(uttdf$M)
            uttdf$agemonths = rowSums(uttdf[,c("agemonths","M")],na.rm=T)
          }
          uttdf$agemonths=as.numeric(uttdf$agemonths)
        #  print(head(uttdf[,c("Y","agemonths","M","w")]))
          cdf$minAge = min(uttdf$agemonths,na.rm = T)
          cdf$maxAge = max(uttdf$agemonths,na.rm = T)
        }
        #    print(unique(uttdf$role))
        
        uttdf$role2 = "Others"
        uttdf$role2[uttdf$role %in% c("Father","Mother")] = "Parent"
        uttdf$role2[uttdf$role %in% c("Target_Child")] = "Target_Child"
        
        if (!("Target_Child" %in% unique(uttdf$role))){
          uttdf$role2[uttdf$role %in% c("Child")] = "Target_Child"
        }
        
        counts = data.frame(xtabs(~ role2,uttdf)/length(uttdf$w))
        if ("Target_Child" %in% uttdf$role2){
          cdf$percTarChild = counts$Freq[counts$role2=="Target_Child"]
        }
        if ("Parent" %in% uttdf$role2){
          cdf$percParent = counts$Freq[counts$role2=="Parent"]
        }
        if ("Others" %in% uttdf$role2){
          cdf$percOthers = counts$Freq[counts$role2=="Others"]
        }
        
        print(cdf)
        #       cordf = rbind(cordf,cdf)
      }
    }
    
  }else{
    print(paste("Empty file",f))
  }
  return(cdf)
}
#summarizeOne("csvfolderMake/Chinese_Mandarin_ZhouNarratives_Word.rds")

summarizeCorpora <- function(csvfolder){
  print("\n\n@@ summarize Corpora")
  if (!file.exists("summaryChildes.rds")){
    flist = list.files(path = csvfolder,pattern = "[^_]+_[^_]+_[^_]+_Word.rds", full.names = T, recursive = T)
    cordf2 = data.frame()
    funclist = c('summarizeOne','readFileLoop')
    #   for (i in 1:length(flist)){
    cordf <- foreach(i=1:length(flist),.export=funclist,.packages=c("stringr","dplyr")) %dopar% { 
      cdf = summarizeOne(flist[i])
      #      cordf2 = rbind(cordf2,cdf)
      cdf
    }
    cordf2 = do.call("rbind",cordf)
    # print(tail(cordf2))
    cordf2 = cordf2[order(cordf2$lg,cordf2$langtype,cordf2$corpus),]
    saveRDS(cordf2,"summaryChildes.rds")
    cordf2=NULL
    gc()
  }
}
if (mode == 7 || mode == 0){
  summarizeCorpora(csvfolder)
}
print("finished summarizeCorpora")

#### NGRAMS

computeNgrams <- function(f,csvdir,ngramdir){
  if (!str_detect(f,"untranscribe")){
    udf = readFileLoop(f)
   # print(head(udf))
    if ("w" %in% names(udf)){
      udf = udf[udf$w!="",]
      udf = udf[!is.na(udf$w),]
      if (length(udf$w) > 10){
        udf$t_type = str_trim(udf$t_type)
        #        print(unique(udf$t_type))
        udf = udf[udf$t_type %in% c("p","e","q"),]
        udf$punct = "#ooo"
        udf$punct[udf$t_type == "p"] = "#ppp"
        udf$punct[udf$t_type == "e"] = "#eee"
        udf$punct[udf$t_type == "q"] = "#qqq"
        udf$w=str_trim(udf$w)
        udf$utt = paste(udf$punct,udf$w,udf$punct)
        udf$wordlen = sapply(strsplit(udf$w, "\\s+"), length)
        
        #    print("wordlen")
        ngramfile = str_replace(f,csvdir,ngramdir)
        #    print(head(ngramfile))
        
        for (g in 1:4){
          ngramfile2 = str_replace(ngramfile,"Utterance",paste("",g,sep=""))
     #     print(ngramfile2)
          if (!file.exists(ngramfile2)){
            #      print(g)
            udf2 = subset(udf,wordlen >= g)
            if(length(udf2$utt) > 2){
              ng <- ngram (udf2$utt , n =g)
              ngdf = get.phrasetable ( ng )
              ngdf$rank = 1:length(ngdf$freq)
              ngdf$logrank = log( ngdf$rank )
              ngdf$logfreq = log( ngdf$freq )
              ngdf$ngrams=as.character(ngdf$ngrams)
              ngdf$punct = ifelse(str_detect( ngdf$ngrams, "[#](eee|ppp|qqq)" ),1,0)
              print(paste("writing ",ngramfile2))
              saveRDS(ngdf, ngramfile2)
              ng=NULL
              ngdf=NULL
              gc()
              #        head(ngdf)
            }
          }
        }
        #    print("done")
      }
    }
    udf=NULL
    gc()
  }
}
#computeNgrams("csvcorpora/Scandinavian_Norwegian_Simonsen_Utterance.csv",csvdir,ngramdir)

computeNgramsAll <- function(csvdir, ngramdir){
  print("\n\n@@ make Ngrams")
  dir.create(ngramdir)
  flist = list.files(path = csvdir,pattern = "[^_]+_[^_]+_[^_]+_Utterance.rds", full.names = T, recursive = T )
  funclist = c('computeNgrams','readFileLoop','ngram','get.phrasetable')
  #   for (i in 1:length(flist)){
  x <- foreach(i=1:length(flist),.export=funclist,.packages=c("stringr")) %dopar% { 
    computeNgrams(flist[i],csvdir,ngramdir)
  }
}
  
  
if (mode == 8 || mode == 0){
  computeNgramsAll(csvfolder, "ngramdir")
}
print("finished computeNgramsAll")

stopCluster(cl)
print("done")

