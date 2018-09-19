library(shiny)

ui <- shinyUI(fluidPage(

  sidebarPanel(

      actionButton("add_btn", "Add Textbox"),
      actionButton("rm_btn", "Remove Textbox"),
	extOutput("out"),
      textOutput("counter"),
	uiOutput("textbox_ui")
      
    )
))

server <- shinyServer(function(input, output, session) {

  # Track the number of input boxes to render
  counter <- reactiveValues(n = 0)

  observeEvent(input$add_btn, {counter$n <- counter$n + 1})
  observeEvent(input$rm_btn, {
    if (counter$n > 0) counter$n <- counter$n - 1
  })

  output$counter <- renderPrint(print(counter$n))

  textboxes <- reactive({

    n <- counter$n

    if (n > 0) {
      lapply(seq_len(n), function(i) {
        inputId <- paste0("textin", i)
        textInput(inputId = inputId,
                  label = paste0("Textbox", i), value = "Hello World!"),
	  output$out <- renderText(input$inputId)
      })
    }

 
  })

  output$textbox_ui <- renderUI({ textboxes() })
})

shinyApp(ui, server)