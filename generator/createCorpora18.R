#require(openxlsx)
library(stringr)
require(xml2)
require(dplyr)
require(ngram)
options(encoding = 'UTF-8')
csvfolder = "csvfolderMake"

library(doParallel)
nc = detectCores()
cl <- makeCluster(nc-1,outfile="",type = "FORK")
registerDoParallel(cl)

args <- commandArgs(TRUE)
mode <- as.integer(args[1])
if (is.na(mode)){
  mode=0
}
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

mergePartMain <- function(table,parttable){
  table$origline = 1:length(table$who)
  table=merge(table,parttable,by.x="who",by.y="id",all.x=T,sort=F)
  table=table[order(table$origline),]
  row.names(table)<-1:length(table[,1])
  return(table)
}

processParticipants <- function(one){
  partdf = data.frame()
  partset = xml_children(one)
  for (p in partset){
    df = data.frame(t(xml_attrs(p)),stringsAsFactors=F)
    rownames(df)=NULL
    #   print(df)
    partdf = bind_rows(partdf, df)
  }
  
  if ("age" %in% names(partdf) && sum(!is.na(partdf$age)) > 0){
#    print(partdf)
    partage = partdf$age[!is.na(partdf$age)]
    # if (sum(partage) > 1){
    #   print("## too many ages")
    #   print(partdf)
    #   partage = partdf$age[partdf$role == "Target_Child"]
    # }
    agenum = as.integer(as.character(str_split(partage,"[A-Z]")[[1]]))
    partdf$agemonth = agenum[2] * 12
    if (!is.na(agenum[3])){
      partdf$agemonth = agenum[2] * 12 + agenum[3]
      if (!is.na(agenum[4])){
        partdf$agemonth = agenum[2] * 12 + agenum[3] + agenum[4]/31
      }
    }else{
      print("age month 6")
#      print(partdf)
      partdf$agemonth = agenum[2] * 12 + 6 # if missing, put age in middle of year
    } 
    partdf$Y = as.character(agenum[2])
    partdf$M = as.character(agenum[3])
    partdf$D = as.character(agenum[4])
  }
  return(partdf)
}

addtodf <- function(wwdf,cname,val,verbose=FALSE){
  if (verbose){
    print(paste("adddf",cname,val))
  }
  if (cname %in% names(wwdf)){
    wwdf[cname] = paste(wwdf[cname],val,sep=";")
  }else{
    wwdf[cname] = val
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
    if (verbose){
      print(nodeattr)
    }
    for (ii in 1:length(attnames)){
      onecol = attnames[ii]
      wdf = addtodf(wdf,onecol,nodeattr[ii],verbose)
    }
  }
  return(wdf)
}

processXML <- function(wdf, node, lab = "", verbose=FALSE){
  if(verbose){
    print("procXML")
    print(node)
  }
  
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
  return(wdf)
}
# processXML(data.frame(line=1),node,lab="",verbose=T)
#node=read_xml('<a type="extension" flavor="trn"></a>')


processXMLFileList <- function(fulfile, csvfolder, verbose = FALSE, force=FALSE,label="") {
  # print("STARTXML")
  newfile = fulfile
  newfile = str_replace(newfile, "data-xml", csvfolder)
  newfile = str_replace(newfile, "[.]xml$", ".rds")
  if (!file.exists(newfile) || force) {
#    print(fulfile)
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
            alldf = bind_rows(alldf, wdf)
          }
          uchildren = NULL
          wdf = NULL
          resetwdf = NULL
        }
        if (nodetype == "Participants") {
          partdf = processParticipants(linenodeset)
        }
        filelinenum = filelinenum + 1
      }
#      print("finished reading xml file")
      #     print("alldf")
  #    print(head(alldf))
      if (length(alldf) > 0 && "uID" %in% names(alldf)) {
        alldf2 = alldf %>% group_by(uID) %>% mutate(word_posn = row_number())
        alldf$word_posn = alldf2$word_posn
      }
 #     print(partdf)
      
      if ("id" %in% names(partdf)){
        alldf3 = data.frame(who = partdf$id,uID = "u-1", w = "",t_type = "p",word_posn = 1)
        if (length(alldf) > 0 && length(alldf[, 1]) < length(partdf$id)) {
          print("bind prev")
          print(head(alldf))
          print("new")
          alldf = bind_rows(alldf, alldf3)
          print(head(alldf))
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
      #      print(head(onefilelines))
      saveRDS(onefilelines, newfile)
      alldf = NULL
      partdf = NULL
      wdf = NULL
      lenone = length(onefilelines)
      onefilelines = NULL
      gc()
      return(lenone)
    }
  }
  return("exists")
}
#processXMLFileList("data-xml/Chinese/Mandarin/Xinjiang/2012.09/ENNI/sdfyxb10.xml",csvfolder,verbose=T,force=TRUE)


createCSVfromXML <- function(csvfolder){
  print("\n\n@@ create CSV from XML")
  dir.create(csvfolder,showWarnings = F)
  #  flist = list.files(path = "data-xml",".+?xml", full.names = T, recursive = T)
  flist = listFilesSortSize("data-xml",".+?xml")
#  flist = flist[1:14]
#  print(flist)
  funclist = c('bind_rows','addattr','addtodf','mergePartMain','processParticipants','processXML','processXMLFileList','readFileLoop')
#  for (i in 1:length(flist)){
  x <- foreach(i=1:length(flist),.export=funclist,.packages=c("stringr","xml2")) %dopar% { 
    processXMLFileList(flist[i],csvfolder,verbose=F,label=paste(i,length(flist)))
  }
#  print(x)
 # print(length(x))
  print("finished csvfoldermake")
}
#processXMLFileList("data-xml/German/Rigol/Pauline/000623.xml",csvfolder,verbose=T)

if (mode == 1 || mode == 0){
  system.time(createCSVfromXML(csvfolder))
}

shiftLessInterestingLeft <- function(df){
  lgp = which(names(df)=="langgrp")-1
  df2 = df[,1:lgp]
  percna = apply(is.na(df2),2,sum)/length(df2$who)
  percna2 = percna[percna > 0.5]
  uniquelen = lapply(apply(df2,2,unique),length)
  uniquelen2 = uniquelen[uniquelen < 4]
  
  endcol = c(union(names(percna2),names(uniquelen2)))
  allcol = names(df)
  if ("xmlline" %in% allcol){
    endcol = setdiff(endcol,c("xmlline"))
    allcol = setdiff(allcol,c("xmlline"))
    allcol = c(allcol,"xmlline")
  }
  if ("t_type" %in% allcol){
    endcol = setdiff(endcol,c("t_type"))
    allcol = setdiff(allcol,c("t_type"))
    allcol = c("t_type",allcol)
  }
  if ("w" %in% allcol){
    endcol = setdiff(endcol,c("w"))
    allcol = setdiff(allcol,c("w"))
    allcol = c("w",allcol)
  }
  if ("who" %in% allcol){
    endcol = setdiff(endcol,c("who"))
    allcol = setdiff(allcol,c("who"))
    allcol = c("who",allcol)
  }
  
  firstcol = setdiff(allcol,endcol)
  newlab = as.character(c(firstcol,endcol))
  newdf = df[,newlab]
  return(newdf)
}
#df = readRDS("csvfolderMake/Biling_Amsterdam_Annick_Word.rds")
#head(shiftLessInterestingLeft(df))

combineCSVFiles <- function(csvfolder,foldname){
  print(paste("combineCSVFiles ",csvfolder," ",foldname))
  newfname = str_replace_all(foldname,"_","-")
  newfname = str_replace_all(newfname,"/","_")
  newfname = paste(csvfolder,"/",newfname,"_Word.rds",sep="")
  if (!file.exists(newfname)){
    fold = foldname
    fold = str_replace(fold,"/ALL","")
 #   print(newfname)
    flist2 = list.files(path = paste(csvfolder,fold,sep="/"),".+?[.]rds", full.names = T, recursive = T)
    print(flist2)
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
    allcorpus$xmlnum = allcorpus$xmlline
    allcorpus$rownum = 1:length(allcorpus$who)
    allcorpus$xmlline = NULL
#    if (max(xtabs( ~ uID,allcorpus)) == 1){
#      newfname = str_replace(newfname,"_Word","_Utt")
#    }
    print(head(allcorpus))
    print(paste("writing ",newfname))
    allcorpus = shiftLessInterestingLeft(allcorpus)
    saveRDS(allcorpus,newfname)
    allcorpus = NULL
    fdf = NULL
    gc()
  }
}
#combineCSVFiles(csvfolder,"Biling/Amsterdam/Annick")
#df = readRDS("workfiles/csvfolderMake/Biling/SilvaCorvalan/eng/10.rds")
#unique(df$mor_type)

combineFileCorpora <- function(csvfolder){
  print(paste("\n\n@@ combine csv into folder csv ",csvfolder))
  flist = list.files(path = csvfolder, ".+?rds", full.names = T, recursive = T)
 # print(flist)
  fparts = str_split_fixed(as.character(flist),"/",5)
  fparts = fparts[fparts[,3] != "",]
  fparts[str_detect(fparts[,4],".rds"),4] = "ALL"
  foldname = as.character(unique(paste(fparts[,2],fparts[,3],fparts[,4],sep="/")))
  print(foldname)
#  for (i in 1:length(foldname)){
  funclist = c('combineCSVFiles','readFileLoop','shiftLessInterestingLeft')
  x <- foreach(i=1:length(foldname),.export=funclist,.packages=c("stringr","dplyr")) %dopar% { 
    combineCSVFiles(csvfolder,foldname[i])
  }
 # print(length(x))
  print("finished combineFileCorpora")
}
if (mode == 2 || mode == 0){
  system.time(combineFileCorpora(csvfolder))
}

pasteCol <- function(v) {
  return(paste0(v,collapse=" "))
}

word2sent <- function(alluttdf){
  #  print("word2sent")
  alluttdf$lnum = NULL
#  print(head(alluttdf))
  lgnum = which(names(alluttdf)=="langgrp")
  dcol = which(names(alluttdf)=="role")
  if ("D" %in% names(alluttdf)){
    dcol = which(names(alluttdf)=="D")
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

writeUtteranceCorpora <- function(fname){
  uttfname = str_replace(fname,"_Word","_Utterance")
  if (!file.exists(uttfname)){
#    print(paste("reading",fname))
    fdf = readFileLoop(fname)
    #    uttfname = str_replace(uttfname,"whole9","whole9utt")
    uttfdf = word2sent(fdf)
    print(paste("writing",uttfname))
    uttfdf$rownum = 1:length(uttfdf$who)
    saveRDS(uttfdf,uttfname)
    uttfdf=NULL
    gc()
    return(uttfname)
  }
  return(paste("exists",uttfname))
}

createUtteranceCorpora <- function(csvfolder){
  print("\n\n@@ change Word To Utterance")
 # flist = list.files(path = csvfolder,".+?_.+?_.+?_Word.csv", full.names = T, recursive = F)
  flist = listFilesSortSize(csvfolder,".+?_.+?_.+?_Word.rds", fn = T, rec = F)
  funclist = c('writeUtteranceCorpora','word2sent','pasteCol','readFileLoop')
  x <- foreach(i=1:length(flist),.export=funclist,.packages=c("stringr","dplyr")) %dopar% { 
#  for (i in 1:length(flist)){
    writeUtteranceCorpora(flist[i])
  }
 # print(length(x))
  print("finished createUtteranceCorpora")
}
if (mode == 3 || mode == 0){
  system.time(createUtteranceCorpora(csvfolder))
}
#utt = read.csv("whole9utt/Biling_Amsterdam_Annick_Utterance.csv")

combineLangCorpora <- function(csvfolder,name,type){
  newfname = paste(csvfolder,"/",name,"_",type,sep="")
  if (!file.exists(newfname)){
#    print(name)
#    print(type)
    searchname = paste(name,"_[^_]+_",type,sep="")
    flist2 = list.files(path = csvfolder,searchname, full.names = T, recursive = F)
    if (length(flist2) > 0){
      allcorpus=data.frame()
      for (j in 1:length(flist2)){
   #     print(paste("reading ",flist2[j]))
        fdf = readFileLoop(flist2[j])
        allcorpus= bind_rows(allcorpus,fdf)
      }
      #        print(unique(allcorpus$corpus))
      print(paste("writing",newfname))
      allcorpus$rownum = 1:length(allcorpus$who)
      saveRDS(allcorpus,newfname)
      allcorpus = NULL
      fdf = NULL
      gc()
    }else{
      print(paste("no files found ",searchname))
    }
  }else{
    print(paste("found ",newfname))
  }
}

createLangCorpora <- function(csvfolder, langgrp=FALSE){
  if (langgrp){
    print(paste("\n\n@@create Lang Group Corpora"))
  }else{
    print(paste("\n\n@@create Lang Corpora"))
  }
  flist = listFilesSortSize(csvfolder,".+?_Word.rds", fn = T, rec = F)
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
#  print(length(x))
  print("finished createLangCorpora")
}
if (mode == 4 || mode == 0){
  system.time(createLangCorpora(csvfolder))
    gc()
}
if (mode == 5 || mode == 0){
     createLangCorpora(csvfolder,langgrp = TRUE)
     system(paste("rm -f ",csvfolder,"/*_ALL_*",sep=""))
     gc()
}

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
    ##    flist = list.files(path = "data-xml", full.names = F, recursive = T)
##    dd = str_split_fixed(flist,"/",4)
##    shortlines = dd[,4] == ""
##    dd[shortlines,4]=dd[shortlines,3]
##    dd[shortlines,3]="ALL"
    # dd= dd[,1:3]
    #   print(head(dd))
    print(fparts2)
    saveRDS(fparts2, file = "filesData-XML.rds")
  }
  print("finished makeDirList")
}
if (mode == 6 || mode == 0){
  makeDirList()
}
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
  print("finished summarizeCorpora")
}
if (mode == 7 || mode == 0){
  summarizeCorpora(csvfolder)
}
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
 # print(length(x))
  print("finished computeNgramsAll")
}
  
  
if (mode == 8 || mode == 0){
  computeNgramsAll(csvfolder, "ngramdir")
}

print("done")
