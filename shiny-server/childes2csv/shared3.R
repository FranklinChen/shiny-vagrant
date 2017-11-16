require(dplyr)
require(xml2)
require(stringr)

#gstorage = "storage/csvcorpora/"
gstorage = "../storage/actualcsv/"
values <- reactiveValues()
values$text = ""
values$table = NULL
values$parttable = NULL
values$longcol = c()
values$fulltable = NULL
values$csvfile=""
values$maxsize = 1000000000000

readFileDir <- function(lgrp,lg,corp){
  dd <- readRDS("storage/filesData-XML.rds")
  ignore = "-----"
  langgroup = unique(dd[,1])
  langgroup = langgroup[langgroup != ""]
  langlist = unique(dd[dd[,1]==lgrp ,2])
  langlist = c(ignore,langlist)
  corpuslist = unique(dd[dd[,1]==lgrp & dd[,2]==lg,3])
  corpuslist = corpuslist[corpuslist != ""]
  corpuslist = c(ignore,corpuslist)
  
  
  updateSelectInput(session, "langGroup", label="Language Group:",choices = langgroup,selected=lgrp)
  updateSelectInput(session, "lang", label="Language:",choices = langlist,selected=lg)
  updateSelectInput(session, "corpus", label="Corpora:",choices = corpuslist,selected=corp)
  return(dd)
}
#dd <- readFileDir()


output$parttable <- DT::renderDataTable(DT::datatable({
  values$parttable
},options = list(searching = FALSE,paging = FALSE,autoWidth = TRUE)))

output$table <- DT::renderDataTable(DT::datatable(values$table,fillContainer=TRUE
                      ,options = list(searching = FALSE,autoWidth = TRUE,processing = TRUE,
                      columnDefs = list(list(width = '300px', targets = values$longcol)))
))

pasteSpace <- function(v) {
  return(paste0(v,collapse=" "))
}

word2sent <- function(alluttdf){
  if (!is.null(alluttdf)){
    #  print("word2sent")
    alluttdf$lnum = NULL
    lgnum = which(names(alluttdf)=="langgrp")
    dcol = which(names(alluttdf)=="D")
    alluttdf[is.na(alluttdf)]=""
    alluttdf[] <- lapply(alluttdf, as.character)
    originalorder = names(alluttdf)
    grpcol = c("unum","uID","who",names(alluttdf)[lgnum:dcol])
 #   print(grpcol)
    dots <- lapply(grpcol, as.symbol)
    alluttdf = alluttdf %>% group_by_(.dots=grpcol) %>% summarise_if(is.character,pasteSpace)
 #   print(head(alluttdf))
    # print(originalorder)
    #  print(names(alluttdf))
    alluttdf =alluttdf[order(alluttdf$file,alluttdf$unum),originalorder]
    #  print("ss")
    if ("w" %in% names(alluttdf)){
      alluttdf$w = str_trim(alluttdf$w)
      alluttdf$w = str_replace(alluttdf$w,"\\s+"," ")
      alluttdf$wordlen = sapply(strsplit(alluttdf$w, "\\s+"), length)
    }
    if ("t_" %in% names(alluttdf)){
      alluttdf$t_ = str_trim(alluttdf$t_)
    }
    #  print("word2sent")
    #  print(head(alluttdf))
  }
  return(alluttdf)
}

adjustTableCol <- function(){
  print("adjust")
  if (nrow(values$table) > 4){ # set column lengths
  #  print("adjust col")
    collength = data.frame(apply(apply(values$table,1,nchar),1,max))
    if ("rowunit" %in% input && input$rowunit == "Utterance"){
      values$longcol = union(which(names(values$table)=="w"),which(collength > 40))
      # values$text = paste(values$longcol)
    }else{ # word
      values$longcol = which(collength > 10)
    }
  }
}


observeEvent(input$langGroup,  ignoreInit=T,{
      print(paste("langgroup",input$langGroup))
  langlist = unique(dd[dd[,1]==input$langGroup,2])
  langlist = langlist[langlist != ""]
  len = length(langlist)
  if (values$updateFilter){
    langlist = c(ignore,langlist)
  }
  defval = langlist[1]
  if (defval == ignore && len > 1){
    defval = langlist[2]
  }
  updateSelectInput(session, "lang", label=paste("Languages (",len,"):"),
                    choices = langlist,selected=defval)
})

observeEvent(input$lang, ignoreInit=T,{
    prevCorp = input$corpus
  updateLangSelect()
  if (input$corpus == prevCorp){
    searchForCorpusFile()
  }
})

updateLangSelect <- function(){
  print(input$langGroup)
  if (input$lang != ""){
    corpuslist = unique(dd[dd[,1]==input$langGroup & dd[,2]==input$lang,3])
    corpuslist = corpuslist[corpuslist != ""]
    corpuslist = c(ignore,corpuslist)
    len = length(corpuslist)
    defval = corpuslist[1]
    if (defval == ignore && len > 1){
      defval = corpuslist[2]
    }
    updateSelectInput(session, "corpus", label=paste("Corpora (",len,"):"),
                      choices = corpuslist,selected=defval)
    
 #   values$csvfile = ""
    
#    if (length(corpuslist) < 1){
#      fpath = paste(top,input$langGroup,input$lang,sep="/")
#      filelist = list.files(path = fpath,pattern="[^.]+?.xml",full.names = F, recursive = T)
#      updateSelectInput(session, "xmlfileList", label=paste("File (",len,"):"),
#                        choices = filelist)
#    }
  }
}



searchForCorpusFile <- function(){
  isolate({
  type = ".csv"
  if (input$lang == ignore){
    csvfile <-  paste(gstorage,input$langGroup,"_",input$rowunit,type,sep="")
  }else{
    if (input$corpus == ignore){
      csvfile <-  paste(gstorage,input$langGroup,"_",input$lang,"_",input$rowunit,type,sep="")
    }else{
      csvfile <-  paste(gstorage,input$langGroup,"_",input$lang,"_",input$corpus,"_",input$rowunit,type,sep="") 
    }
  }
  values$text1 = csvfile
  print(paste("search",csvfile))
  
  if (file.exists(csvfile) ){
    print(paste("read csvfile",csvfile))
#    csvfile ="storage/csvcorpora/Biling_Amsterdam_Annick_Utterance.rds"
    print(values$maxsize)
    
    values$fulltable <- read.csv(csvfile,nrows=values$maxsize)
#    values$fulltable <- readRDS(csvfile)
#    if (length(values$fulltable$w) > values$maxsize){
#      values$fulltable=values$fulltable[1:values$maxsize,]
#    }
    values$table <- values$fulltable
    adjustTableCol()
    values$csvfile = csvfile
    print(length(values$table))
    print("done")
#    values$table$file = factor(values$table$file)
#    values$table$lang = factor(values$table$lang)
#    values$table$corpus = factor(values$table$corpus)
  }
  })
}

createPartTable <- function(){
  print("part")
  F = which(names(values$table)=="file")+1
  Y= which(names(values$table)=="Y")-1
  if (length(Y) > 0 && length(F) > 0){
    partdf =  values$table[,F:Y]
    values$parttable = partdf[!duplicated(partdf$role),]
  }
  print("part done")
}



updateCorpusSelect <- function(){
  #     curl = paste(url,input$langGroup,input$lang,input$corpus,sep="/")
  #     if (input$corpus == ignore){
  #       xmllist = unique(dd[dd[,1]==input$langGroup & dd[,2]==input$lang,4])
  #        xmllist = xmllist[xmllist != ""]
  #       fpath = paste(top,input$langGroup,input$lang,sep="/")
  #      }else{
  xmllist = unique(dd[dd[,1]==input$langGroup & dd[,2]==input$lang & dd[,3]==input$corpus,4])
  xmllist = xmllist[xmllist != ""]
  #        fpath = paste(top,input$langGroup,input$lang,input$corpus,sep="/")
  #     }
  #     filelist = list.files(path = fpath,pattern=".+?.xml",full.names = F, recursive = T)
  
  #  print(fpath)
  len = length(xmllist)
  values$csvfile = ""
  #   print(filelist)
  if (len > 0){
    updateSelectInput(session, "xmlfileList", label=paste("File (",len,"):"),
                      choices = xmllist)
  }
}




updateSelectorTable <- function(){
  #  if ("recodeUI" %in% values){
  if (nrow(values$table)>2){
    dv = input$dv
    if (!"ONE" %in% names(values$table) ){
      values$table$ONE = 1
      if (dv == ignore)
      dv = "ONE"
    }
    cho = c(ignore,names( values$table))
    source1=input$source1
    updateSelectInput(session, "source1", choices = cho,selected=source1)
    updateSelectInput(session, "dv", choices = cho,selected=dv)
    col1 = input$col1
    updateSelectInput(session, "col1", choices = cho,selected=col1)
    col2 = input$col2
    updateSelectInput(session, "col2", choices = cho,selected=col2)
    col3 = input$col3
    updateSelectInput(session, "col3", choices = cho,selected=col3)
    grp1 = input$grp1
    updateSelectInput(session, "grp1", choices = cho,selected=grp1)
    grp2 = input$grp2
    updateSelectInput(session, "grp2", choices = cho,selected=grp2)
    grp3 = input$grp3
    updateSelectInput(session, "grp3", choices = cho,selected=grp3)
    
  }
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
    agenum = as.integer(as.character(str_split(partdf$age[!is.na(partdf$age)],"[A-Z]")[[1]]))
    partdf$Y = as.character(agenum[2])
    partdf$M = as.character(agenum[3])
    partdf$D = as.character(agenum[4])
  }
  return(partdf)
}


output$downloadDataLangGroup <- downloadHandler(
  filename = function() { 
    paste(input$langGroup,"_",input$rowunit,".csv",sep="")
  },
  content <- function(file) {
    geturl = paste(gstorage,input$langGroup,"_",input$rowunit,".csv",sep="")
#    wholecsv <- readRDS(geturl)
    print("finished reading corpus")
    print(geturl)
    file.copy(geturl,file)
    #download.file(geturl, destfile=file, method="auto")
 #   write.csv.utf8.BOM(wholecsv, file)
 #   write.csv(wholecsv, file, fileEncoding = "UTF-8",quote=T,row.names = F)
  }
  ,contentType = "text/csv"
)

output$downloadDataLang <- downloadHandler(
  filename = function() { 
    paste(input$langGroup,"_",input$lang,"_",input$rowunit,".csv",sep="")
  },
  content <- function(file) {
    geturl = paste(gstorage,input$langGroup,"_",input$lang,"_",input$rowunit,".csv",sep="")
#    wholecsv <- readRDS(geturl)
        print(geturl)
    file.copy(geturl,file)
#    write.csv.utf8.BOM(wholecsv, file)
 #   write.csv(wholecsv, file, fileEncoding = "UTF-8",quote=T,row.names = F)
    
    #        download.file(geturl, destfile=file, method="auto")
  }
  ,contentType = "text/csv"
)

output$downloadDataCorp <- downloadHandler(
  filename = function() { 
    paste(input$langGroup,"_",input$lang,"_",input$corpus,"_",input$rowunit,".csv",sep="")
  },
  content <- function(file) {
    geturl = paste(gstorage,input$langGroup,"_",input$lang,"_",input$corpus,"_",input$rowunit,".csv",sep="")
#    wholecsv <- readRDS(geturl)
  #  print("read wholecsv")
       print(geturl)
    #    file.copy(geturl,file)
#    write.csv.utf8.BOM(wholecsv, file)
    #print(geturl)
    file.copy(geturl,file)
    #  download.file(geturl, destfile=file, method="auto")
#    write.csv(wholecsv, file, fileEncoding = "UTF-8",quote=T,row.names = F)
    
  }
  ,contentType = "text/csv"
)

output$downloadData <- downloadHandler(
  filename = function() { 
    values$downloadtext
  },
  content <- function(file) {
    write.csv(values$alldata, file =file,fileEncoding = "UTF-8",quote=T)
  }
  ,contentType = "text/csv"
)