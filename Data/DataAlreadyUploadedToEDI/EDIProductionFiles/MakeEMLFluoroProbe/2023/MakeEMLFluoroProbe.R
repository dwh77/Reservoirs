##MakeEMLFluoroProbe
##Author: Mary Lofton
##Date: 03JAN24

#good sites for step-by-step instructions
#https://ediorg.github.io/EMLassemblyline/articles/overview.html
#https://github.com/EDIorg/EMLassemblyline/blob/master/documentation/instructions.md
#and links therein

# Install devtools
install.packages("devtools")

# Load devtools
library(devtools)

# Install and load EMLassemblyline
install_github("EDIorg/EMLassemblyline")
library(EMLassemblyline)

#Step 0: Create new dataset and do visual QAQC

#' Run the visual inspection script, which is located in Reservoirs -> Data -> DataNotYetUploadedToEDI -> Raw_fluoroprobe -> FluoroProbe_inspection_2014-2023.Rmd
#' This script will both create plots for you to manually inspect the data 
#' and create a collated dataset of historic and current year's data
#' 
#' Look through the plots; if additional QAQC needs to be done, record that in the
#' maintenance log, located in Reservoirs -> Data -> DataNotYetUploadedToEDI -> Raw_fluoroprobe -> Maintenance_Log_FluoroProbe.csv
#' 
#' Trigger a run of the automatic workflow to make sure your current year's data 
#' get updated following any revisions you've made to the maintenance log
#' This is in Actions in the CareyLabVT/Reservoirs repo
#' It also runs every day automatically, so alternatively you can just wait 24 h

#Step 1: Create a directory for your dataset
#in this case, our directory is Reservoirs/Data/DataAlreadyUploadedToEDI/EDIProductionFiles/MakeEMLFluoroProbe/2023

#Step 2: Move your dataset to the directory.

#' Also move your qaqc script, which is located in Reservoirs -> Scripts -> L1_generation_scripts -> fluoroprobe_qaqc.R
#' Also move your maintenance log, which is located in Reservoirs -> Data -> DataNotYetUploadedToEDI -> Raw_fluoroprobe -> Maintenance_Log_FluoroProbe.csv
#' Also move your visual inspection script, which is located in Reservoirs -> Data -> DataNotYetUploadedToEDI -> Raw_fluoroprobe -> FluoroProbe_inspection_2014-2023.Rmd
#' Also make sure you have a site_descriptions.csv file in there which is up to date
#' So you should be publishing five files in total: data, qaqc script, maintenance
#' log, visual inspection script, site description file

#Step 3: Create an intellectual rights license
#ours is CCBY

#Step 4: Identify the types of data in your dataset
#need to update which options are supported...not sure what else is
#possible besides "table"

#Step 5: Import the core metadata templates

#THIS IS ONLY NECESSARY FOR A BRAND NEW DATASET!!!!
#if you are just updating a previous dataset, PLEASE save yourself time
#by copy-pasting the metadata files from the previous year's folder 
#(in this case, 2022) into the current year's folder and editing them
#as needed. DON'T CAUSE YOURSELF MORE WORK BY BUILDING FROM SCRATCH!!

#IF you are just appending a new year of data, skip steps 5-12 and instead
#DOUBLE-CHECK all the imported metadata files and edit them as needed

#for our application, we will need to generate all types of metadata
#files except for taxonomic coverage, as we have both continuous and
#categorical variables and want to report our geographic location

# View documentation for these functions
?template_core_metadata
?template_table_attributes
?template_categorical_variables #don't run this till later
?template_geographic_coverage

# Import templates for our dataset licensed under CCBY.

#for the FluoroProbe dataset, you will have the following files:
#'the dataset (csv)
#'the site descriptions file (csv)
#'the maintenance log (csv)
#'the qaqc script (R)
#'the visualization script (R)
template_core_metadata(path = "C:/Users/Mary Lofton/Documents/Github/Reservoirs/Data/DataAlreadyUploadedToEDI/EDIProductionFiles/MakeEMLFluoroProbe/2019",
                       license = "CCBY",
                       file.type = ".txt",
                       write.file = TRUE)

template_table_attributes(path = "C:/Users/Mary Lofton/Documents/Github/Reservoirs/Data/DataAlreadyUploadedToEDI/EDIProductionFiles/MakeEMLFluoroProbe/2019",
                          data.path = "C:/Users/Mary Lofton/Documents/Github/Reservoirs/Data/DataAlreadyUploadedToEDI/EDIProductionFiles/MakeEMLFluoroProbe/2019",
                          data.table = "FluoroProbe.csv",
                          write.file = TRUE)

template_table_attributes(path = "/Users/MaryLofton/RProjects/Reservoirs/Data/DataAlreadyUploadedToEDI/EDIProductionFiles/MakeEMLFluoroProbe/2022",
                          data.path = "/Users/MaryLofton/RProjects/Reservoirs/Data/DataAlreadyUploadedToEDI/EDIProductionFiles/MakeEMLFluoroProbe/2022",
                          data.table = "site_descriptions.csv",
                          write.file = TRUE)

template_table_attributes(path = "/Users/MaryLofton/RProjects/Reservoirs/Data/DataAlreadyUploadedToEDI/EDIProductionFiles/MakeEMLFluoroProbe/2023",
                          data.path = "/Users/MaryLofton/RProjects/Reservoirs/Data/DataAlreadyUploadedToEDI/EDIProductionFiles/MakeEMLFluoroProbe/2023",
                          data.table = "Maintenance_Log_FluoroProbe_2014_2023.txt",
                          write.file = TRUE)


#we want empty to be true for this because we don't include lat/long
#as columns within our dataset but would like to provide them
template_geographic_coverage(path = "C:/Users/Mary Lofton/Documents/Github/Reservoirs/Data/DataAlreadyUploadedToEDI/EDIProductionFiles/MakeEMLFluoroProbe/2019",
                             data.path = "C:/Users/Mary Lofton/Documents/Github/Reservoirs/Data/DataAlreadyUploadedToEDI/EDIProductionFiles/MakeEMLFluoroProbe/2019",
                             data.table = "FluoroProbe.csv",
                             empty = TRUE,
                             write.file = TRUE)

#Step 6: Script your workflow
#that's what this is, silly!

#Step 7: Abstract
#copy-paste the abstract from your Microsoft Word document into abstract.txt
#if you want to check your abstract for non-allowed characters, go to:
#https://pteo.paranoiaworks.mobi/diacriticsremover/
#paste text and click remove diacritics

#Step 8: Methods
#copy-paste the methods from your Microsoft Word document into methods.txt
#if you want to check your abstract for non-allowed characters, go to:
#https://pteo.paranoiaworks.mobi/diacriticsremover/
#paste text and click remove diacritics

#Step 9: Additional information
#this is where the authorship contribution and acknowledgements go

#Step 10: Keywords
#DO NOT EDIT KEYWORDS FILE USING A TEXT EDITOR!! USE EXCEL!!
#see the LabKeywords.txt file for keywords that are mandatory for all Carey Lab data products

#Step 11: Personnel
#copy-paste this information in from your metadata document
#Cayelan needs to be listed several times; she has to be listed separately for her roles as
#PI, creator, and contact, and also separately for each separate funding source (!!)

#Step 12: Attributes
#grab attribute names and definitions from your metadata word document
#for units....
# View and search the standard units dictionary
view_unit_dictionary()
#put flag codes and site codes in the definitions cell
#force reservoir to categorical

#if you need to make custom units that aren't in the unit dictionary,
#use the customunits.txt file and the directions on the EMLassemblyline Github to do so

#Step 13: Close files
#if all your files aren't closed, sometimes functions don't work

#Step 14: Categorical variables
# Run this function for your dataset
#THIS WILL ONLY WORK once you have filled out the attributes_FluoroProbe.txt and
#identified which variables are categorical
template_categorical_variables(path = "C:/Users/Mary Lofton/Documents/Github/Reservoirs/Data/DataAlreadyUploadedToEDI/EDIProductionFiles/MakeEMLFluoroProbe/2020",
                               data.path = "C:/Users/Mary Lofton/Documents/Github/Reservoirs/Data/DataAlreadyUploadedToEDI/EDIProductionFiles/MakeEMLFluoroProbe/2020",
                               write.file = TRUE)

#open the created value IN A SPREADSHEET EDITOR and add a definition for each category

#Step 15: Geographic coverage
#copy-paste the bounding_boxes.txt file that is Carey Lab specific into your working directory

## Step 16: Obtain a package.id.  ####
# Go to the EDI staging environment (https://portal-s.edirepository.org/nis/home.jsp),
# then login using one of the Carey Lab usernames and passwords.
# These are found in the Google Drive folder regarding making EMLs in the 
# workshop notes from the original May 24, 2018 workshop.

# Select Tools --> Data Package Identifier Reservations and click 
# "Reserve Next Available Identifier"
# A new value will appear in the "Current data package identifier reservations" 
# table (e.g., edi.123)
# Make note of this value, as it will be your package.id below

#Step 17: Make EML
# View documentation for this function
?make_eml

# taking your file path out
# /Users/MaryLofton/RProjects/Reservoirs

# Run this function
make_eml(
  path = "./Data/DataAlreadyUploadedToEDI/EDIProductionFiles/MakeEMLFluoroProbe/2023",
  data.path = "./Data/DataAlreadyUploadedToEDI/EDIProductionFiles/MakeEMLFluoroProbe/2023",
  eml.path = "./Data/DataAlreadyUploadedToEDI/EDIProductionFiles/MakeEMLFluoroProbe/2023",
  dataset.title = "Time-series of high-frequency profiles of fluorescence-based phytoplankton spectral groups in Beaverdam Reservoir, Carvins Cove Reservoir, Falling Creek Reservoir, Gatewood Reservoir, and Spring Hollow Reservoir in southwestern Virginia, USA 2014-2023",
  temporal.coverage = c("2014-05-04", "2023-11-14"),
  maintenance.description = 'ongoing',
  data.table = c("FluoroProbe_2014_2023.csv", "site_descriptions.csv","FluoroProbe_maintenancelog_2014_2023.csv"),
  data.table.name = c("FluoroProbe_2014_2023.csv", "site_descriptions.csv","FluoroProbe_maintenancelog_2014_2023.csv"),
  data.table.description = c("Reservoir FluoroProbe dataset","Sampling site descriptions","FluoroProbe maintenance log"),
  other.entity = c("FluoroProbe_qaqc_2014_2023.R","FluoroProbe_inspection_2014_2023.Rmd"),
  other.entity.name = c("FluoroProbe_qaqc_2014_2023.R","FluoroProbe_inspection_2014_2023.Rmd"),
  other.entity.description = c("data aggregation and quality control script","data visual inspection script"),
  user.id = 'melofton',
  #user.id = 'ccarey',
  user.domain = 'EDI',
  package.id = 'edi.1101.5')
  #package.id = 'edi.1112.2')

## Step 8: Check your data product! ####
# Return to the EDI staging environment (https://portal-s.edirepository.org/nis/home.jsp),
# then login using one of the Carey Lab usernames and passwords. 

# Select Tools --> Evaluate/Upload Data Packages, then under "EML Metadata File", 
# choose your metadata (.xml) file (e.g., edi.270.1.xml), check "I want to 
# manually upload the data by selecting files on my local system", then click Upload.

# Now, Choose File for each file within the data package (e.g., each zip folder), 
# then click Upload. Files will upload and your EML metadata will be checked 
# for errors. If there are no errors, your data product is now published! 
# If there were errors, click the link to see what they were, then fix errors 
# in the xml file. 
# Note that each revision results in the xml file increasing one value 
# (e.g., edi.270.1, edi.270.2, etc). Re-upload your fixed files to complete the 
# evaluation check again, until you receive a message with no errors.

## Step 9: PUBLISH YOUR DATA! ####
# Reserve a package.id for your error-free data package. 
# NEVER ASSIGN this identifier to a staging environment package.
# Go to the EDI Production environment (https://portal.edirepository.org/nis/home.jsp)
# and login using the ccarey (permanent) credentials. 

# Select Tools --> Data Package Identifier Reservations and click "Reserve Next 
# Available Identifier". A new value will appear in the "Current data package 
# identifier reservations" table (e.g., edi.518)
# This will be your PUBLISHED package.id

# In the make_eml command below, change the package.id to match your 
# PUBLISHED package id. This id should end in .1 (e.g., edi.518.1)

# ALL OTHER entries in the make_eml() command should match what you ran above,
# in step 7

make_eml(
  path = "./Data/DataAlreadyUploadedToEDI/EDIProductionFiles/MakeEMLFluoroProbe/2023",
  data.path = "./Data/DataAlreadyUploadedToEDI/EDIProductionFiles/MakeEMLFluoroProbe/2023",
  eml.path = "./Data/DataAlreadyUploadedToEDI/EDIProductionFiles/MakeEMLFluoroProbe/2023",
  dataset.title = "Time-series of high-frequency profiles of fluorescence-based phytoplankton spectral groups in Beaverdam Reservoir, Carvins Cove Reservoir, Falling Creek Reservoir, Gatewood Reservoir, and Spring Hollow Reservoir in southwestern Virginia, USA 2014-2023",
  temporal.coverage = c("2014-05-04", "2023-11-14"),
  maintenance.description = 'ongoing',
  data.table = c("FluoroProbe_2014_2023.csv", "site_descriptions.csv","FluoroProbe_maintenancelog_2014_2023.csv"),
  data.table.name = c("FluoroProbe_2014_2023.csv", "site_descriptions.csv","FluoroProbe_maintenancelog_2014_2023.csv"),
  data.table.description = c("Reservoir FluoroProbe dataset","Sampling site descriptions","FluoroProbe maintenance log"),
  other.entity = c("FluoroProbe_qaqc_2014_2023.R","FluoroProbe_inspection_2014_2023.Rmd"),
  other.entity.name = c("FluoroProbe_qaqc_2014_2023.R","FluoroProbe_inspection_2014_2023.Rmd"),
  other.entity.description = c("data aggregation and quality control script","data visual inspection script"),
  user.id = 'ccarey',
  user.domain = 'EDI',
  package.id = 'edi.272.8')

# Once your xml file with your PUBLISHED package.id is Done, return to the 
# EDI Production environment (https://portal.edirepository.org/nis/home.jsp)

# Select Tools --> Preview Your Metadata, then upload your metadata (.xml) file 
# associated with your PUBLISHED package.id. Look through the rendered 
# metadata one more time to check for mistakes (author order, bounding box, etc.)

# Select Tools --> Evaluate/Upload Data Packages, then under "EML Metadata File", 
# choose your metadata (.xml) file associated with your PUBLISHED package.id 
# (e.g., edi.518.1.xml), check "I want to manually upload the data by selecting 
# files on my local system", then click Upload.

# Now, Choose File for each file within the data package (e.g., each zip folder), 
# then click Upload. Files will upload and your EML metadata will be checked for 
# errors. Since you checked for and fixed errors in the staging environment, this 
# should run without errors, and your data product is now published! 

# Click the package.id hyperlink to view your final product! HOORAY!