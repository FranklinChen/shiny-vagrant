library(httr)
library(xml2)
url = "http://gandalf.talkbank.org:8080/storage/actualcsv"
r <- GET(url)
h = read_html(r)
dirlistxml = xml_children(xml_children(xml_children(h)[2])[2])
dirlist = xml_text(dirlistxml)
downlist = dirlist[grepl("Biling",dirlist)]
for (f in downlist){
  download.file(paste(url,downlist[1],sep="/"), downlist[1])
}