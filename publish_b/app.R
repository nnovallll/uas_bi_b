# Install required packages if not already installed
# install.packages(c("shiny", "shinydashboard", "DT", "ggplot2", "plotly"))

# Load required libraries
library(shiny)
library(shinydashboard)
library(DT)
library(ggplot2)
library(plotly)

# Define data
ad_placement_data <- data.frame(
  Day = 1:10,
  Left_Sidebar = c(2.5, 2.7, 2.8, 2.6, 3.0, 2.4, 2.9, 2.5, 2.6, 2.7),
  Center_Page = c(3.8, 3.5, 4.0, 3.7, 3.9, 3.6, 4.1, 3.4, 3.8, 3.9),
  Right_Sidebar = c(3.1, 2.9, 3.0, 3.2, 3.3, 2.8, 3.4, 3.1, 3.2, 3.5)
)

# Define UI
ui <- dashboardPage(
  dashboardHeader(title = "Ad Placement Data"),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Data Example", tabName = "data_tab"),
      menuItem("Input Your Data", tabName = "preview_custom_data_tab"),
      menuItem("Data Analysis", tabName = "analyze_tab")
    )
  ),
  dashboardBody(
    tabItems(
      tabItem(
        tabName = "data_tab",
        fluidPage(
          fluidRow(
            box(
              title = "Ad Placement Data Dashboard",
              "This Shiny dashboard showcases data related to Ad Placement. In the 'Data Example' tab, you can view the default Ad Placement Data. Navigate to the 'Input Your Data' tab to input custom data and observe its performance. The table displays the data, and the line chart visualizes the ad placement performance over days.",
              width = 12
            ),
            box(
              title = "Ad Placement Data Example (Default)",
              DTOutput("table"),
              plotlyOutput("line_chart_data")
            )
          )
        )
      ),
      tabItem(
        tabName = "preview_custom_data_tab",
        fluidPage(
          fluidRow(
            box(
              title = "Information/Note",
              "The error will gone after you input your custom data.",
              width = 12
            ),
            box(
              title = "Performa Iklan - Custom Data",
              DTOutput("custom_data_table"),
              plotlyOutput("line_chart_custom_data")
            ),
            box(
              title = "Input",
              numericInput("day_input", "Enter Day:", min = 1, max = 100, value = 1),
              numericInput("left_sidebar_rkt", "Left Sidebar RKT:", value = 0),
              numericInput("center_page_rkt", "Center Page RKT:", value = 0),
              numericInput("right_sidebar_rkt", "Right Sidebar RKT:", value = 0),
              actionButton("add_data_btn", "Add Data"),
              actionButton("reset_data_btn", "Reset Data")
            )
          )
        )
      ),
      tabItem(
        tabName = "analyze_tab",
        fluidPage(
          fluidRow(
            box(
              title = "Interpretation of ANOVA Results",
              "When the p-value from the ANOVA results shows a value above alpha (0.05), it can be concluded that there is no difference in the ads for ZoomRunners placed in three different locations on the website: the left sidebar, the center (within the content), and the right sidebar. If the ANOVA results show a value below alpha (0.05), it can be concluded that there is at least one pair of differences in the ads for ZoomRunners placed in three different locations on the website: the left sidebar, the center (within the content), and the right sidebar.",
              width = 12
            )
          ),
          fluidRow(
            box(
              title = "Data Example Analysis",
              verbatimTextOutput("data_example_summary"),
              width = 6
            ),
            box(
              title = "Custom Data Analysis",
              verbatimTextOutput("custom_data_summary"),
              width = 6
            )
          ),
          fluidRow(
            box(
              title = "Analysis Options - Data Example",
              selectInput("data_example_analysis_type", "Choose Analysis Type:", 
                          choices = c("Summary Statistics", "ANOVA", "Other Analysis"), 
                          selected = "Summary Statistics"),
              width = 6
            ),
            box(
              title = "Analysis Options - Custom Data",
              selectInput("custom_data_analysis_type", "Choose Analysis Type:", 
                          choices = c("Summary Statistics", "ANOVA", "Other Analysis"), 
                          selected = "Summary Statistics"),
              width = 6
            )
          )
        )
      )
    )
  )
)

# Define server
server <- function(input, output, session) {
  
  output$table <- renderDT({
    datatable(ad_placement_data, options = list(dom = 't', paging = FALSE))
  })
  
  output$line_chart_data <- renderPlotly({
    ggplotly(
      ggplot(ad_placement_data, aes(x = Day)) +
        geom_line(aes(y = Left_Sidebar, color = "Left Sidebar"), size = 1.5) +
        geom_line(aes(y = Center_Page, color = "Center Page"), size = 1.5) +
        geom_line(aes(y = Right_Sidebar, color = "Right Sidebar"), size = 1.5) +
        labs(title = "Ad Placement Performance - Data",
             x = "Day",
             y = "Ad Placement Template") +
        theme_minimal()
    )
  })
  
  custom_data <- reactiveVal(data.frame(Day = integer(), Left_Sidebar = numeric(), Center_Page = numeric(), Right_Sidebar = numeric()))
  
  observeEvent(input$add_data_btn, {
    new_data <- data.frame(
      Day = input$day_input,
      Left_Sidebar = input$left_sidebar_rkt,
      Center_Page = input$center_page_rkt,
      Right_Sidebar = input$right_sidebar_rkt
    )
    custom_data(rbind(custom_data(), new_data))
  })
  
  observeEvent(input$reset_data_btn, {
    custom_data(data.frame(Day = integer(), Left_Sidebar = numeric(), Center_Page = numeric(), Right_Sidebar = numeric()))
  })
  
  output$line_chart_custom_data <- renderPlotly({
    ggplotly(
      ggplot(custom_data(), aes(x = Day)) +
        geom_line(aes(y = Left_Sidebar, color = "Left Sidebar"), size = 1.5) +
        geom_line(aes(y = Center_Page, color = "Center Page"), size = 1.5) +
        geom_line(aes(y = Right_Sidebar, color = "Right Sidebar"), size = 1.5) +
        labs(title = "Ad Placement Performance - Custom Data",
             x = "Day",
             y = "Ad Placement Template") +
        theme_minimal()
    )
  })
  
  output$custom_data_table <- renderDT({
    datatable(custom_data(), options = list(dom = 't', paging = FALSE))
  })
  
  # Data frame for ANOVA analysis
  anova_data <- reactive({
    ad_place <- c(rep("Left Sidebar", length(ad_placement_data$Left_Sidebar)),
                  rep("Center Page", length(ad_placement_data$Center_Page)),
                  rep("Right Sidebar", length(ad_placement_data$Right_Sidebar)))
    rkt <- c(ad_placement_data$Left_Sidebar, ad_placement_data$Center_Page, ad_placement_data$Right_Sidebar)
    data.frame(Ad_Place = ad_place, RKT = rkt)
  })
  
  # Custom Data ANOVA
  output$custom_data_summary <- renderPrint({
    if (!is.null(custom_data()$Day) && length(unique(custom_data()$Day)) >= 3) {
      # Perform ANOVA on custom_data()
      anova_result <- tryCatch({
        model <- aov(Left_Sidebar + Center_Page + Right_Sidebar ~ Day, data = custom_data())
        summary(model)
      }, error = function(e) {
        NULL
      })
      
      if (is.null(anova_result)) {
        cat("Error occurred during ANOVA analysis.\n")
      } else {
        print(anova_result)
      }
    } else {
      cat("Error: ANOVA analysis requires at least three unique days in custom data.\n")
    }
  })
  
  output$custom_data_summary <- renderPrint({
    if (input$custom_data_analysis_type == "Summary Statistics") {
      # Perform summary statistics on custom_data()
      summary_stats <- summary(custom_data())
      print(summary_stats)
    } else if (input$custom_data_analysis_type == "ANOVA") {
      # Perform ANOVA on custom_data()
      anova_result <- tryCatch({
        model <- aov(Left_Sidebar + Center_Page + Right_Sidebar ~ Day, data = custom_data())
        summary(model)
      }, error = function(e) {
        NULL
      })
      
      if (is.null(anova_result)) {
        cat("Error occurred during ANOVA analysis.\n")
      } else {
        print(anova_result)
      }
    } else {
      # If the selected analysis type is not implemented yet
      cat("Selected analysis type not implemented yet.\n")
    }
  })
  
  output$data_example_summary <- renderPrint({
    if (input$data_example_analysis_type == "Summary Statistics") {
      # Perform summary statistics on ad_placement_data
      summary_stats <- summary(ad_placement_data)
      print(summary_stats)
    } else if (input$data_example_analysis_type == "ANOVA") {
      # Perform ANOVA on ad_placement_data
      # Perform ANOVA on anova_data
      anova_result <- tryCatch({
        model <- aov(RKT ~ Ad_Place, data = anova_data())
        summary(model)
      }, error = function(e) {
        NULL
      })
      
      if (is.null(anova_result)) {
        cat("Error occurred during ANOVA analysis.\n")
      } else {
        print(anova_result)
      }
    } else {
      # If the selected analysis type is not implemented yet
      cat("Selected analysis type not implemented yet.\n")
    }
  })
}

# Run the Shiny app
shinyApp(ui, server)
