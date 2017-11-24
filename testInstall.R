
testinstall <- function(somepackage,repos='https://cran.ma.imperial.ac.uk/'){
  print(paste("testing ",somepackage))
  if(!require(somepackage,character.only = TRUE)){
    install.packages(somepackage, repos)
  }
}
install.packages('shiny', repos='https://cran.rstudio.com/')
install.packages('rmarkdown', repos='http://cran.rstudio.com/')
install.packages('DT',repos='https://cran.rstudio.com/')
install.packages('devtools',repos='https://cran.ma.imperial.ac.uk/')
install.packages('shinycssloaders',repos='https://cran.ma.imperial.ac.uk/')
install.packages('ngram',repos='https://cran.ma.imperial.ac.uk/') 
install.packages('xml2',repos='https://cran.ma.imperial.ac.uk/')
install.packages('dplyr',repos='https://cran.ma.imperial.ac.uk/')
install.packages('doParallel',repos='https://cran.ma.imperial.ac.uk/')

#testinstall('shiny', repos='https://cran.rstudio.com/')
#testinstall('rmarkdown', repos='https://cran.rstudio.com/')
#testinstall('DT', repos='https://cran.rstudio.com/')
#devtools::install_github('rstudio/DT@feature/editor')
#testinstall('devtools')
#testinstall('shinycssloaders')
#testinstall('ngram')
#testinstall('xml2')
#testinstall('dplyr')
#testinstall('doParallel')

# R -e "install.packages('shiny', repos='https://cran.rstudio.com/')"
# #R -e "install.packages('RCurl',repos='https://cran.ma.imperial.ac.uk/')" 
# R -e "install.packages('rmarkdown', repos='http://cran.rstudio.com/')"
# R -e "install.packages('DT',repos='https://cran.rstudio.com/')"
# R -e "install.packages('devtools',repos='https://cran.ma.imperial.ac.uk/')" 
# R -e "install.packages('shinycssloaders',repos='https://cran.ma.imperial.ac.uk/')"
# R -e "install.packages('ngram',repos='https://cran.ma.imperial.ac.uk/')" 
# R -e "install.packages('xml2',repos='https://cran.ma.imperial.ac.uk/')" 
# R -e "install.packages('dplyr',repos='https://cran.ma.imperial.ac.uk/')" 
# R -e "install.packages('doParallel',repos='https://cran.ma.imperial.ac.uk/')" 
