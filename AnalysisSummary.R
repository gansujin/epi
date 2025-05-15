# packages to load
library(dplyr)
library(readr)

# analysisSummary
epiSummary <- read_csv("synology/storage/10/output/2025/ContKT/epi/T01/analysisSummary.csv")
epiSummary <- epiSummary %>% filter(outcomeId == 65)

Attrition_list <- list()

for (i in 1:8) {
  # 파일 경로 설정
  file_path <- paste0("~/synology/storage/10/output/2025/ContKT/epi/T01/cmOutput/Analysis_", i, "/om_t4123_c4124_o65.rds")
  Attrition <- readRDS(file_path)
  Attrition_df <- as.data.frame(Attrition$populationCounts)
  Attrition_df$Analysis <- i
  Attrition_list[[i]] <- Attrition_df
}

Attrition <- do.call(rbind, Attrition_list)

View(Attrition)

epiSummary <- merge(epiSummary, Attrition, by.x = 'analysisId', by.y = 'Analysis')
epiSummary <- epiSummary %>% select(analysisId, analysisDescription, outcomeId, targetId, targetName, comparatorId, comparatorName, rr, ci95lb, ci95ub, p,
                                     targetPersons, comparatorPersons, targetExposures, comparatorExposures, eventsTarget, eventsComparator, targetDays, comparatorDays)
# Round columns 
epiSummary[,8:11] <- lapply(epiSummary[, 8:11], function(x) round(x, 2))
epiSummary$crudeOR <- paste0(epiSummary$rr, " [", epiSummary$ci95lb, " - ", epiSummary$ci95ub, "]")
epiSummary$target_prevalence <- round((epiSummary$eventsTarget / epiSummary$targetExposures) * 100, 2)
epiSummary$comparator_prevalence <- round((epiSummary$eventsComparator / epiSummary$comparatorExposures) * 100, 2)
epiSummary$target_prevalence_formatted <- paste0(
  epiSummary$target_prevalence, " (", epiSummary$eventsTarget, "/", epiSummary$targetExposures, ")"
)
epiSummary$comparator_prevalence_formatted <- paste0(
  epiSummary$comparator_prevalence, " (", epiSummary$eventsComparator, "/", epiSummary$comparatorExposures, ")"
)

epiSummary <- epiSummary %>% select(analysisDescription, targetName, comparatorName, crudeOR, p, targetPersons, comparatorPersons, target_prevalence_formatted, comparator_prevalence_formatted) %>%
  rename('target_prevalence' = 'target_prevalence_formatted', 'comparator_prevalence' = 'comparator_prevalence_formatted')

write.csv(epiSummary, file = '~/synology/storage/10/study/2025/ContKT/analysis/epi/prevalence/epiSummary.csv')
