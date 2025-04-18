library(tidyverse)
library(lubridate)



qaqc <- function(data_file, data2_file,  maintenance_file, output_file)
{
  CATDATA_COL_NAMES = c("DateTime", "RECORD", "CR6_Batt_V", "CR6Panel_Temp_C", "ThermistorTemp_C_surface",
                        "ThermistorTemp_C_1", "ThermistorTemp_C_2", "ThermistorTemp_C_3", "ThermistorTemp_C_4",
                        "ThermistorTemp_C_5", "ThermistorTemp_C_6", "ThermistorTemp_C_7", "ThermistorTemp_C_8",
                        "ThermistorTemp_C_9", "RDO_mgL_5", "RDOsat_percent_5", "RDOTemp_C_5", "RDO_mgL_9",
                        "RDOsat_percent_9", "RDOTemp_C_9", "EXO_Date", "EXO_Time", "EXOTemp_C_1", "EXOCond_uScm_1",
                        "EXOSpCond_uScm_1", "EXOTDS_mgL_1", "EXODOsat_percent_1", "EXODO_mgL_1", "EXOChla_RFU_1",
                        "EXOChla_ugL_1", "EXOBGAPC_RFU_1", "EXOBGAPC_ugL_1", "EXOfDOM_RFU_1", "EXOfDOM_QSU_1",
                        "EXO_pressure", "EXO_depth", "EXO_battery", "EXO_cablepower", "EXO_wiper")
  
  PRESSURE_COL_NAMES = c("DateTime", "RECORD", "Lvl_psi", "LvlTemp_c_9")
  
  # after maintenance, DO values will continue to be replaced by NA until DO_mgL returns within this threshold (in mg/L)
  # of the pre-maintenance value
  DO_RECOVERY_THRESHOLD <- 1
  
  # columns where certain values are stored
  DO_MGL_COLS <- c(28, 15, 18)
  DO_SAT_COLS <- c(27, 16, 19)
  DO_FLAG_COLS <- c(43, 44, 45)
  
  # depths at which DO is measured
  DO_DEPTHS <- c(1, 5, 9)
  
  # EXO sonde sensor data that differs from the mean by more than the standard deviation multiplied by this factor will
  # either be replaced with NA and flagged (if between 2018-10-01 and 2019-03-01) or just flagged (otherwise)
  EXO_FOULING_FACTOR <- 4
  
  
  
  # read catwalk data and maintenance log
  # NOTE: date-times throughout this script are processed as UTC
  catdata <- read_csv(data_file, skip = 4, col_names = CATDATA_COL_NAMES,
                      col_types = cols(.default = col_double(), DateTime = col_datetime()))
  
  pressure <- read_csv(data2_file, skip = 4, col_names = PRESSURE_COL_NAMES,
                       col_types = cols(.default = col_double(), DateTime = col_datetime()))
  pressure=pressure%>%
    select(-RECORD)
  
  catdata=merge(catdata,pressure, all.x=T)

  log <- read_csv(maintenance_file, col_types = cols(
    .default = col_character(),
    TIMESTAMP_start = col_datetime("%Y-%m-%d %H:%M:%S%*"),
    TIMESTAMP_end = col_datetime("%Y-%m-%d %H:%M:%S%*"),
    flag = col_integer()
  ))
  
  # remove NaN data at beginning
  catdata <- catdata %>% filter(DateTime >= ymd_hms("2018-07-05 14:50:00"))
  
  # add flag columns
  catdata$Flag_All <- 0
  catdata$Flag_DO_1 <- 0
  catdata$Flag_DO_5 <- 0
  catdata$Flag_DO_9 <- 0
  catdata$Flag_Chla <- 0
  catdata$Flag_Phyco <- 0
  catdata$Flag_TDS <- 0
  
  # replace negative DO values with 0
  catdata <- catdata %>%
    mutate(Flag_DO_1 = ifelse((! is.na(EXODO_mgL_1) & EXODO_mgL_1 < 0)
                            | (! is.na(EXODOsat_percent_1) & EXODOsat_percent_1 < 0), 3, Flag_DO_1)) %>%
    mutate(EXODO_mgL_1 = ifelse(EXODO_mgL_1 < 0, 0, EXODO_mgL_1)) %>%
    mutate(EXODOsat_percent_1 = ifelse(EXODOsat_percent_1 <0, 0, EXODOsat_percent_1))
  
  catdata <- catdata %>%
    mutate(Flag_DO_5 = ifelse((! is.na(RDO_mgL_5) & RDO_mgL_5 < 0)
                            | (! is.na(RDOsat_percent_5) & RDOsat_percent_5 < 0), 3, Flag_DO_5)) %>%
    mutate(RDO_mgL_5 = ifelse(RDO_mgL_5 < 0, 0, RDO_mgL_5)) %>%
    mutate(RDOsat_percent_5 = ifelse(RDOsat_percent_5 < 0, 0, RDOsat_percent_5))

  catdata <- catdata %>%
    mutate(Flag_DO_9 = ifelse((! is.na(RDO_mgL_9) & RDO_mgL_9 < 0)
                            | (! is.na(RDOsat_percent_9) & RDOsat_percent_9 < 0), 3, Flag_DO_9)) %>%
    mutate(RDO_mgL_9 = ifelse(RDO_mgL_9 < 0, 0, RDO_mgL_9)) %>%
    mutate(RDOsat_percent_9 = ifelse(RDOsat_percent_9 < 0, 0, RDOsat_percent_9))
  
  # modify catdata based on the information in the log
  for(i in 1:nrow(log))
  {
    # get start and end time of one maintenance event
    start <- log$TIMESTAMP_start[i]
    end <- log$TIMESTAMP_end[i]
    
    # get indices of columns affected by maintenance
    if(grepl("^\\d+$", log$colnumber[i])) # single num
    {
      maintenance_cols <- intersect(c(2:41), as.integer(log$colnumber[i]))
    }
    else if(grepl("^c\\(\\s*\\d+\\s*(;\\s*\\d+\\s*)*\\)$", log$colnumber[i])) # c(x;y;...)
    {
      maintenance_cols <- intersect(c(2:41), as.integer(unlist(regmatches(log$colnumber[i],
                                                                          gregexpr("\\d+", log$colnumber[i])))))
    }
    else if(grepl("^c\\(\\s*\\d+\\s*:\\s*\\d+\\s*\\)$", log$colnumber[i])) # c(x:y)
    {
      bounds <- as.integer(unlist(regmatches(log$colnumber[i], gregexpr("\\d+", log$colnumber[i]))))
      maintenance_cols <- intersect(c(2:41), c(bounds[1]:bounds[2]))
    }
    else
    {
      warning(paste("Could not parse column colnumber in row", i, "of the maintenance log. Skipping maintenance for",
        "that row. The value of colnumber should be in one of three formats: a single number (\"47\"), a",
        "semicolon-separated list of numbers in c() (\"c(47;48;49)\"), or a range of numbers in c() (\"c(47:74)\").",
        "Other values (even valid calls to c()) will not be parsed properly."))
      next
    }
    
    # remove EXO_Date and EXO_Time columns from the list of maintenance columns, because they will be deleted later
    maintenance_cols <- setdiff(maintenance_cols, c(21, 22))
    
    if(length(maintenance_cols) == 0)
    {
      warning(paste("Did not parse any valid data columns in row", i, "of the maintenance log. Valid columns have",
        "indices 2 through 39, excluding 21 and 22, which are deleted by this script. Skipping maintenance for that row."))
      next
    }
    
    # replace relevant data with NAs and set "all" flag while maintenance was in effect
    catdata[catdata$DateTime >= start & catdata$DateTime <= end, maintenance_cols] <- NA
    catdata[catdata$DateTime >= start & catdata$DateTime <= end, "Flag_All"] <- 1
  
    # if DO data was affected by maintenance, set the appropriate DO flags, and replace DO data with NAs after maintenance
    # was in effect until value returns to within a threshold of the value when maintenance began, because the sensors take
    # time to re-adjust to ambient conditions
    last_row_before_maintenance <- tail(catdata %>% filter(DateTime < start), 1)
    for(j in 1:3)
    {
      # if maintenance was not in effect on DO data, then skip
      if(! (DO_MGL_COLS[j] %in% maintenance_cols | DO_SAT_COLS[j] %in% maintenance_cols))
      {
        next
      }
      
      # set the appropriate DO flag while maintenance was in effect
      catdata[catdata$DateTime >= start & catdata$DateTime <= end, DO_FLAG_COLS[j]] <- 1
      
      last_DO_before_maintenance <- last_row_before_maintenance[[DO_MGL_COLS[j]]][1]
      if(is.na(last_DO_before_maintenance))
      {
        warning(paste("For row", i, "of the maintenance log, the pre-maintenance DO value at depth", DO_DEPTHS[j],
          "could not be found. Not replacing DO values after the end of maintenance. This could occur because the start",
          "date-time for maintenance is at or before the first date-time in the data, or simply because the value was",
          "missing or replaced in prior maintenance."))
      }
      else
      {
        DO_recovery_time <- (catdata %>%
                               filter(DateTime > end &
                                      abs(catdata[[DO_MGL_COLS[j]]] - last_DO_before_maintenance) <= DO_RECOVERY_THRESHOLD)
                            )$DateTime[1]
        
        # if the recovery time cannot be found, then raise a warning and replace post-maintenance DO values until the end of
        # the file
        if(is.na(DO_recovery_time))
        {
          warning(paste("For row", i, "of the maintenance log, post-maintenance DO levels at depth", DO_DEPTHS[j],
            "never returned within the given threshold of the pre-maintenance DO value. All post-maintenance DO values",
            "have been replaced with NA. This could occur because the end date-time for maintenance is at or after the",
            "last date-time in the data, or simply because post-maintenance levels never returned within the threshold."))
          catdata[catdata$DateTime > end, intersect(maintenance_cols, c(DO_MGL_COLS[j], DO_SAT_COLS[j]))] <- NA
          catdata[catdata$DateTime > end, DO_FLAG_COLS[j]] <- 1
        }
        else
        {
          catdata[catdata$DateTime > end & catdata$DateTime < DO_recovery_time,
                  intersect(maintenance_cols, c(DO_MGL_COLS[j], DO_SAT_COLS[j]))] <- NA
          catdata[catdata$DateTime > end & catdata$DateTime < DO_recovery_time, DO_FLAG_COLS[j]] <- 1
        }
      }
    }
  }
  
  # find EXO sonde sensor data that differs from the mean by more than the standard deviation times a given factor, and
  # replace with NAs between October and March, due to sensor fouling
  Chla_RFU_1_mean <- mean(catdata$EXOChla_RFU_1, na.rm = TRUE)
  Chla_ugL_1_mean <- mean(catdata$EXOChla_ugL_1, na.rm = TRUE)
  BGAPC_RFU_1_mean <- mean(catdata$EXOBGAPC_RFU_1, na.rm = TRUE)
  BGAPC_ugL_1_mean <- mean(catdata$EXOBGAPC_ugL_1, na.rm = TRUE)
  Chla_RFU_1_threshold <- EXO_FOULING_FACTOR * sd(catdata$EXOChla_RFU_1, na.rm = TRUE)
  Chla_ugL_1_threshold <- EXO_FOULING_FACTOR * sd(catdata$EXOChla_ugL_1, na.rm = TRUE)
  BGAPC_RFU_1_threshold <- EXO_FOULING_FACTOR * sd(catdata$EXOBGAPC_RFU_1, na.rm = TRUE)
  BGAPC_ugL_1_threshold <- EXO_FOULING_FACTOR * sd(catdata$EXOBGAPC_ugL_1, na.rm = TRUE)

  catdata <- catdata %>%
    mutate(Flag_Chla = ifelse(DateTime >= ymd("2018-10-01") & DateTime < ymd("2019-03-01") &
                                (! is.na(EXOChla_RFU_1) & abs(EXOChla_RFU_1 - Chla_RFU_1_mean) > Chla_RFU_1_threshold |
                                 ! is.na(EXOChla_ugL_1) & abs(EXOChla_ugL_1 - Chla_ugL_1_mean) > Chla_ugL_1_threshold),
                              4, Flag_Chla)) %>%
    mutate(Flag_Phyco = ifelse(DateTime >= ymd("2018-10-01") & DateTime < ymd("2019-03-01") &
                                 (! is.na(EXOBGAPC_RFU_1) & abs(EXOBGAPC_RFU_1 - BGAPC_RFU_1_mean) > BGAPC_RFU_1_threshold |
                                  ! is.na(EXOBGAPC_ugL_1) & abs(EXOBGAPC_ugL_1 - BGAPC_ugL_1_mean) > BGAPC_ugL_1_threshold),
                               4, Flag_Phyco)) %>%
    mutate(EXOChla_RFU_1 = ifelse(DateTime >= ymd("2018-10-01") & DateTime < ymd("2019-03-01") &
                                  abs(EXOChla_RFU_1 - Chla_RFU_1_mean) > Chla_RFU_1_threshold, NA, EXOChla_RFU_1)) %>%
    mutate(EXOChla_ugL_1 = ifelse(DateTime >= ymd("2018-10-01") & DateTime < ymd("2019-03-01") &
                                  abs(EXOChla_ugL_1 - Chla_ugL_1_mean) > Chla_ugL_1_threshold, NA, EXOChla_ugL_1)) %>%
    mutate(EXOBGAPC_RFU_1 = ifelse(DateTime >= ymd("2018-10-01") & DateTime < ymd("2019-03-01") &
                                   abs(EXOBGAPC_RFU_1 - BGAPC_RFU_1_mean) > BGAPC_RFU_1_threshold, NA, EXOBGAPC_RFU_1)) %>%
    mutate(EXOBGAPC_ugL_1 = ifelse(DateTime >= ymd("2018-10-01") & DateTime < ymd("2019-03-01") &
                                   abs(EXOBGAPC_ugL_1 - BGAPC_ugL_1_mean) > BGAPC_ugL_1_threshold, NA, EXOBGAPC_ugL_1))
  
  # flag EXO sonde sensor data of value above 4 * standard deviation at other times
  catdata <- catdata %>%
    mutate(Flag_Phyco = ifelse(! is.na(EXOBGAPC_RFU_1) & abs(EXOBGAPC_RFU_1 - BGAPC_RFU_1_mean) > BGAPC_RFU_1_threshold |
                               ! is.na(EXOBGAPC_ugL_1) & abs(EXOBGAPC_ugL_1 - BGAPC_ugL_1_mean) > BGAPC_ugL_1_threshold,
                               5, Flag_Phyco))
  
  # delete EXO_Date and EXO_Time columns
  catdata <- catdata %>% select(-EXO_Date, -EXO_Time)
  
  # add Reservoir and Site columns
  catdata$Reservoir <- "FCR"
  catdata$Site <- "50"
  
  # reorder columns
  catdata <- catdata %>% select(Reservoir, Site, -RECORD, -CR6_Batt_V, -CR6Panel_Temp_C, -Flag_All, -Flag_DO_1, -Flag_DO_5,
                                -Flag_DO_9, -Flag_Chla, -Flag_Phyco, -Flag_TDS, everything())
  
  # replace NaNs with NAs
  catdata[is.na(catdata)] <- NA
  
  # convert datetimes to characters so that they are properly formatted in the output file
  catdata$DateTime <- as.character(catdata$DateTime)
  
  # write to output file
  write_csv(catdata, output_file)
}

# example usage
# qaqc("https://raw.githubusercontent.com/CareyLabVT/SCCData/mia-data/Catwalk.csv",
#      'https://raw.githubusercontent.com/FLARE-forecast/FCRE-data/fcre-catwalk-data/FCRWaterLevel.csv'
#      "https://raw.githubusercontent.com/CareyLabVT/SCCData/mia-data/CAT_MaintenanceLog.txt",
#      "Catwalk.csv")
      
      