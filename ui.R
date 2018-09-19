library(shiny)
library(networkD3)

# Define UI for dataset viewer application
fluidPage(
  
  # Application title
  titlePanel("Word2Vec Application"),
  
  # User can select a dataset(Not available), enter a query word,
  # and specify the number of observations to view. Note that
  # changes made to the caption in the textInput control are
  # updated in the output area immediately as you type
  sidebarLayout(
    sidebarPanel(
      actionButton("add", "Add Word"),
      actionButton("remove", "Remove Word"),
      tags$h5("Max Input: 3"),
      textOutput("counter"),
      uiOutput("textbox_ui"),
      numericInput("obs", "Number of observations to view:", 10),
      sliderInput("mul", "Width", 100, min = 1,
                max = 1000, step = 100),
      sliderInput("opacity", "Opacity", 0.6, min = 0.1,
                max = 1, step = .1),
      sliderInput("wordDisplay", "Opacity of Word", 0, min = 0.1,
                max = 1, step = .1)
    ),
    
    mainPanel(
	    tabsetPanel(
		   # tabPanel("All", img(src='tsne.png', width=900, height=900)),
		    tabPanel("Table", dataTableOutput(outputId = "table")),
		    tabPanel("Simple Network", simpleNetworkOutput("simple")),
        tabPanel("Force Network", forceNetworkOutput("force"))
	    )
    )
  )
)