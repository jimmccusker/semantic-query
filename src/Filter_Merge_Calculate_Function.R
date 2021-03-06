# Purpose: The script will perform the following:
# 1) Read in the content from two different csv file that provide the following information:
#   -- Ground truth datasets that are relevant to specific query fragments.
#   -- Query results returned by SOLR for specific query fragments.
# 2) Filter the unwated query results based on the dataset IDs listed in the ground truth file. 
#   -- This removes any dataset IDs that are not in the correct format but exist in the CN-Sandbox2.
# 3) Merge the resulting datasets after being filtered and any additional relevant datsets that are in the ground truth file.
# 4) Calculate the precision and recall value based on the number of relevant datasets retrieved, the total number of relevant datasets, and number of irrelevant datasets retrieved.=

# Definitions:
# 1) Definition of Recall: A/(A+B), where A = # of relevant retrieved and B = # of relevant records NOT retrieved
# 2) Definition of Precision: A/(A+C), where A = # of relevant retrieved and C = # of irrelevant records retrieved

# Note:
# 1) The output of function is set up to be written and append to the following file: '~/dataone/gitcheckout/semantic-query/results/Prec_Recall_Results.txt'

filter_merge_calculate_function <- function(gtFileLocation, outputFileLocation){
  
  # Example: 
  ## This example needs to be commented out during the full automatic test ##
  #gtFileLocation <- '~/dataone/gitcheckout/semantic-query/lib/ground_truth/ground_truth_test.csv'
  
  groundTruthDF <- read.csv(gtFileLocation, header = T, sep = ",", stringsAsFactors = F)

  # Example: 
  ## This example needs to be commented out during the full automatic test ##
  #outputFileLocation <- '~/dataone/gitcheckout/semantic-query/results/Resultset_Summary_2015-10-20 16:12:16_.csv'
  
  queryResultDF <- read.csv(outputFileLocation, header = T, sep = ",", stringsAsFactors = F)
  
  #filtered_result <- merge(groundTruthDF, queryResultDF, by='Dataset_ID')
  
  queryResultDF$Check <- "query"
  groundTruthDF$Check <- "ground_truth"
  
  df <- merge(queryResultDF,groundTruthDF,by="Dataset_ID",all=TRUE)
  filtered_merged_result <-  df[complete.cases(df[,c("q1","q2","q3","q4","q5","q6","q7","q8","q9","q10")]),]
  
  filtered_merged_result[is.na(filtered_merged_result)] <- 0
  
  
  querycolumns <- c("q1","q2","q3","q4","q5","q6","q7","q8","q9","q10")
  
  #This variable will need to be adjusted as we finalize the definition of the values for SOLR_Index_Type
  solrtypecolumns <- c("full_text","metacat_ui")
  
  # Initialize an output data frame with the proper columns
  RP_Result <- data.frame(Test_Corpus_ID = character(0), Query_ID = character(0), SOLR_Index_Type = character(0), Run_ID = character(0), Ontology_Set_ID = character(0), Precision = character(0), Recall = character(0),
                          stringsAsFactors = FALSE)
  
  line_counter <- 1
  total_number_of_rows <- nrow(filtered_merged_result) #To determine how many rows are in the filtered_merged_result data frame
  #print(total_number_of_rows)
  
  for (n in querycolumns) {
    
    #n <- "q1"
   
    #Count the total number of Relevant dataset for a specific query from the ground truth
    queryOfInterest <- which( colnames(filtered_merged_result) == n )
    counter <- table(filtered_merged_result[queryOfInterest])
    totalRelevantRecords <- counter[names(counter)==1]

    for (j in solrtypecolumns) {
      
      Relevant_Retrieved_Counter <- 0
      IRRelevant_Retrieved_Counter <- 0
      Relevant_NotRetrieved_Counter <- 0
      counter <- 1
    
      for (i in 1:nrow(filtered_merged_result)) {
      
        if((filtered_merged_result[i,"SOLR_Index_Type"]) == j || (filtered_merged_result[i,"SOLR_Index_Type"]) == 0)
        {
          
          if (counter == 1)
          {
            test_corpus_id <- gtFileLocation
            run_id <- filtered_merged_result[i,"Run_ID"]
            ontology_set_id <- filtered_merged_result[i,"Ontology_Set_ID"]
          }
          
          #Count the number of Relevant and Retrieved dataset for a specific query (e.g. q1)
          if((filtered_merged_result[i,"Query_ID"]) == n && (filtered_merged_result[i,n]) == 1)
          { 
            #print(filtered_merged_result[i,"Dataset_ID"])
            Relevant_Retrieved_Counter <- Relevant_Retrieved_Counter + 1
          }
      
          #Count the number of IRRelevant and Retrieved dataset for a specific query (e.g. q1)
          if((filtered_merged_result[i,"Query_ID"]) == n && (filtered_merged_result[i,n]) == 0)
          {  
            #print(filtered_merged_result[i,"Dataset_ID"])
            IRRelevant_Retrieved_Counter <- IRRelevant_Retrieved_Counter + 1
          }
      
          #Count the number of Relevant and NOT Retrieved dataset for a specific query (e.g. q1)
          if((filtered_merged_result[i,"Query_ID"]) == 0 && (filtered_merged_result[i,n]) == 1)
          {  
            #print(filtered_merged_result[i,"Dataset_ID"])
            Relevant_NotRetrieved_Counter <- Relevant_NotRetrieved_Counter + 1
          }
        }
      
      }
    
      #print("The query is:")
      #print(n)
      #print("The SOLR index type is:")
      #print(j)
      #print("This is the total relevant records")
      #print(totalRelevantRecords)
      #print("The total number of relevant and retrieved datasets is:")
      #print(Relevant_Retrieved_Counter)
      #print("The total number of irrelevant and retrieved dataset is:")
      #print(IRRelevant_Retrieved_Counter)
      #print("The total number of relevant and NOT retrieved dataset is:")
      #print(Relevant_NotRetrieved_Counter)
    
      if(length(totalRelevantRecords) == 0) {
        #print("There are no relevant dataset for this query from the ground truth")
        Recall <- "Not Applicable"
        Precision <- "Not Applicable"
      } else if ((Relevant_Retrieved_Counter == 0) && (IRRelevant_Retrieved_Counter == 0)) {
        Recall <- (Relevant_Retrieved_Counter / totalRelevantRecords)*100
        Precision <- "Not Applicable"
      } else {
        Recall <- (Relevant_Retrieved_Counter / totalRelevantRecords)*100
        Precision <- (Relevant_Retrieved_Counter / (Relevant_Retrieved_Counter + IRRelevant_Retrieved_Counter))*100
      }
      
      #print("Recall for this query is: ")
      #print(Recall)
      #print("Precision for this query is: ")
      #print(Precision)
    
      if (line_counter == '1'){

        test <- data.frame(test_corpus_id, n, j, run_id, ontology_set_id, as.character(Precision), as.character(Recall))
        colnames(test) <- c("Test_Corpus_ID", "Query_ID", "SOLR_Index_Type", "Run_ID", "Ontology_Set_ID", "Precision", "Recall")
        test2 <- rbind(test, RP_Result)
      } else {
        test <- data.frame(test_corpus_id, n, j, run_id, ontology_set_id, as.character(Precision), as.character(Recall))
        colnames(test) <- c("Test_Corpus_ID", "Query_ID", "SOLR_Index_Type", "Run_ID", "Ontology_Set_ID", "Precision", "Recall")
        test2 <- rbind(test, test2)
      }
  
      line_counter <- line_counter + 1
      counter <- counter + 1
    }
  }

  # Write out the results as a Tab Delimited Text File file, so append could be used
  write.table(test2, "~/dataone/gitcheckout/semantic-query/results/Prec_Recall_Results.txt", append = T, sep = " ", row.names=F)
  
  finaloutputFileLocation = "~/dataone/gitcheckout/semantic-query/results/Prec_Recall_Results.txt"

  return()
  
}
