## It is difficult to output unicode excel files for different platforms (e.g. mac, pc).
## So in order to create these files, childes2csv outputs unicode csv files.
## Then you need to run this script in R on your platform to create
## platform-specific excel files where different languages are readable.
## This program also shows you how to remove columns that you do not need.
## It then saves the data frame in xlsx excel file.
## you can test it with the Chinese_Cantonese_HKU_Utterance.csv file

testinstall <- function(somepackage,repos='https://cran.ma.imperial.ac.uk/'){
  if(!require(somepackage,character.only = TRUE)){
    install.packages(somepackage)
  }else{
    print(paste("packages",somepackage,"is installed"))
  }
}
testinstall('openxlsx') # install library if it is not already available
require(openxlsx) # we need this library to use write.xlsx

setwd("~/Desktop") # this should be set to the folder with the csv file

# change the file name to the name of your csv file
corpusdf = read.csv("Chinese_Cantonese_HKU_Utterance.csv")
print(head(corpusdf))
# the file has many columns that we don't need, so we can remove some
namecol = names(corpusdf)
print(namecol)
# above is the full list of columns.  We now select only those columns that we want below
namecol2 = namecol[c(2,3,4,6,34,35,36,37,39,43,44,45)]
smallercorpusdf = corpusdf[,namecol2] # this is the smaller corpus dataframe
# save as xlsx 
write.xlsx(smallercorpusdf,"cantonese.xlsx")

