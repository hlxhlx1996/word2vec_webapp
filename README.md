# vector visualization application
 - Description:
    This is a web application built with R to be used to visualize vector results in 128-dimensions from machine learning model word2vec. 
    The backend database is based on MongoDB with properties including the index, target, and xN representing each dimensions.
    The database is provided as a .csv file under /data.
    
 - Dependencies:
    1. R studio version 3.4.1 or higher
    2. "shiny" package
    3. "networkD3" package
    4. "mongolite" package
    5. MongoDB database of vector results
 
 - To install the libraries:
    open the R studio console, run
    
    %install.packages("shiny")
    
    %install.packages("networkD3")
    
    %install.packages("mongolite")
 
 - To run the app:
    change the dir in R studio to the parent dir of "word2vec_webapp", and run
    
    %library(shiny)
    
    %runApp("work2vec_webapp")
