library(mongolite)
library(shiny)
library(networkD3)

# Connect mongodb database
db <- mongo(collection = "fashion_short", db = "word2vec", 
			url = "mongodb://localhost", verbose = TRUE)
db_Lists <- mongo(collection = "Lists", db = "word2vec", 
      url = "mongodb://localhost", verbose = TRUE)
db_Nodes <- mongo(collection = "Nodes", db = "word2vec", 
      url = "mongodb://localhost", verbose = TRUE)

getCount <- function(){
	count <- db$count('{}')
	return (count)
}

# Load query data
loadData <- function(qry, field){
	df <- db$find(qry, field)
	return (df)
}

# Update distance between two vectors
updateData <- function(qry, field){
	db$update(qry, field, multiple=TRUE)
}

# Sort data and put into seperate collections 'Lists' and 'Nodes'
sortData <- function(number, index){
	df <- db$find('{}','{"similarity": -1, "target": 1, "_id": 0}', 
			sort='{"similarity": 1}', limit=number+1)
	# set source index
	field <- paste0('{"$set" : {"source": ', index,'}}')
	db$update('{}', field, multiple=TRUE)

	return (df)
}

getSimpleNodes <- function(number){
	df <- db$find('{}','{"target": 1, "_id": 0}', sort='{"similarity": 1}',
			limit=number+1)
	return (df)
}

getForceNodes <- function(number){
	df <- db$find('{}','{"index": 1, "_id": 0}', sort='{"similarity": 1}',
			limit=number)
	return (df)
}
getForceSource <- function(number){
	df <- db$find('{}','{"source": 1, "_id": 0}', sort='{"similarity": 1}',
			limit=number)
	return (df)
}
getWeight <- function(number){
	df <- db$find('{}','{"similarity": 1, "_id": 0}', sort='{"similarity": 1}',
			limit=number)
	return (df)
}

getResult <- function(word, multiple, ob){
		i <- 0
		count <- getCount()
		target_qry <- paste0('{"target" : "', word,'"}')

		while (i < count) {
			product <- 0
			temp_qry <- paste0('{"index" : ', i,'}')
			for (j in 1:128) {
				index <- paste0('x', j)
				field <- paste0('{"_id" : 0, "', index,'" : 1}')
				
				targetx <- loadData(target_qry, field)
				tempx <- loadData(temp_qry, field)
				temp_product <- (targetx-tempx)^2
				product <- (product + temp_product)
			}
			result <- product*multiple
			update_field <- paste0('{"$set" : {"similarity": ', result,'}}')
			updateData(temp_qry, update_field)
			i <- i+1
		}
		# Sort similarity and return # of records required and update source index
		target_index <- db$find(target_qry,'{"index": 1, "_id": 0}')
		df <- sortData(ob, target_index)

  		# get source index
  		target_qry <- paste0('{"target" : "', word,'"}')

  		Src <- getForceSource(ob)
  		# get target indices
    	Target <- getForceNodes(ob)
    	# get weight
    	Weight <- getWeight(ob)

		# define click script
		clickScript <- 'alert("You clicked " + d.name);'

		# create data frame
    	Links <- data.frame(Src, Target, Weight)
    	
    	# put data into seperate collections
    	db_Lists$insert(Links)
    	return (df)
}
shinyServer(function(input, output) {
	# Track the number of input boxes to render
  	counter <- reactiveValues(n = 0)

  	observeEvent(input$add, {
  		counter$n <- counter$n + 1
  	})
  	observeEvent(input$remove, {
    	if (counter$n > 0) 
    		counter$n <- counter$n - 1
  	})

  	output$counter <- renderPrint(print(counter$n))

  	textboxes <- reactive({
	    n <- counter$n
    	if (n > 0) {
      		lapply(seq_len(n), function(i) {
        		textInput(inputId = paste0("textin", i),
                  	label = paste0("Textbox", i), value = "fawn")
      		})
    	}

  	})
	output$textbox_ui <- renderUI({ textboxes() })

	# generate query results
	qryResults <- reactive({
		# truncate the collection first
		db_Lists$remove('{}')
		n <- counter$n
		ob <- input$obs
		mult <- input$mul 
		if (n == 1){
			df <- getResult(input$textin1, mult, ob)
		}
		else if (n ==2){
			df <- getResult(input$textin1, mult, ob)
			df <- getResult(input$textin2, mult, ob)
		}
		else{
			df <- getResult(input$textin1, mult, ob)
			df <- getResult(input$textin2, mult, ob)
			df <- getResult(input$textin3, mult, ob)
		}
		return(df)
	})

	output$table <- renderDataTable({qryResults()})
	output$simple <- renderSimpleNetwork({
    	src <- input$textin1
    	target <- getSimpleNodes(input$obs)
    	networkData <- data.frame(src, target)
    	simpleNetwork(networkData, linkDistance=100, charge=-150, fontSize=16, 
    		opacity=input$opacity, zoom=TRUE)
  	})
  	output$force <- renderForceNetwork({
    	# query for data into a data frame

  		src <- db_Lists$find('{}','{"source": 1, "_id": 0}')
  		Target <- db_Lists$find('{}','{"index": 1, "_id": 0}')
  		weight <- db_Lists$find('{}','{"similarity": 1, "_id": 0}')
  		id <- db_Nodes$find('{}', '{"id": 1, "_id": 0}')
  		name <- db_Nodes$find('{}', '{"name": 1, "_id": 0}')
  		nodeSize <- db_Nodes$find('{}', '{"size": 1, "_id": 0}')
    	# get group
    	count <- getCount()
    	group <- c(1:count)
    	
    	Lists <- data.frame(src, Target, weight)
    	Nodes <- data.frame(id, name, group)
 		clickScript <- 'alert("You clicked: " + d.name);'
    	forceNetwork(Links = Lists, Nodes = Nodes, Source = "source",
                Target = "index", Value = "similarity", NodeID = "name", 
                Group = "group",
				linkDistance = JS("function(d){return (d.value*10)}"),
				opacityNoHover = input$wordDisplay,
				opacity = input$opacity,
				zoom = TRUE,
				clickAction = clickScript
		)
  	})
})