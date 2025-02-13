##########################################################


  # Title:  Propensity Scores for SVH Survival Analysis
  # Editor: Jason Massey
  # Date:   4/4/2024


##########################################################



#####################

# Libraries

#####################
library("dplyr")
library("ggplot2")
library("tidyr")
library("survival")
library("survminer")
library("PSweight")
library("broom")
library("haven")
library("summarytools")

options(scipen=999)

#####################

# Reading Data

#####################

# Read in Survival Data
survival <- read.csv("//cdc.gov/project/CCID_NCPDCID_NHSN_SAS/Data/work/_Projects/LTC/COVID-19/Codes/Jason/Mary_Projects/SVH_survival/propensity_updatedmm4.csv")

# Read in Facility Covariate Data
covariates <- read_sas("//cdc.gov/project/CCID_NCPDCID_NHSN_SAS/Data/work/_Projects/LTC/COVID-19/Codes/Jason/Mary_Projects/SVH_survival/ltc_facility_svh.sas7bdat")

# Left Join Covariates to propensity 
propensity <- left_join(survival, covariates, by = "orgid")


#####################

# Recoding Variables 

#####################

# Creating region Variable
propensity$region <- ifelse(propensity$state == "NY", "Northeast" , propensity$state)
propensity$region <- ifelse(propensity$state == "NJ", "Northeast" , propensity$region)
propensity$region <- ifelse(propensity$state == "CT", "Northeast" , propensity$region)
propensity$region <- ifelse(propensity$state == "ME", "Northeast" , propensity$region)
propensity$region <- ifelse(propensity$state == "MA", "Northeast" , propensity$region)
propensity$region <- ifelse(propensity$state == "NH", "Northeast" , propensity$region)
propensity$region <- ifelse(propensity$state == "RI", "Northeast" , propensity$region)
propensity$region <- ifelse(propensity$state == "VT", "Northeast" , propensity$region)
propensity$region <- ifelse(propensity$state == "PA", "Northeast" , propensity$region)
propensity$region <- ifelse(propensity$state == "FL", "South" , propensity$region)
propensity$region <- ifelse(propensity$state == "GA", "South" , propensity$region)
propensity$region <- ifelse(propensity$state == "LA", "South" , propensity$region)
propensity$region <- ifelse(propensity$state == "TX", "South" , propensity$region)
propensity$region <- ifelse(propensity$state == "DE", "South" , propensity$region)
propensity$region <- ifelse(propensity$state == "DC", "South" , propensity$region)
propensity$region <- ifelse(propensity$state == "TN", "South" , propensity$region)
propensity$region <- ifelse(propensity$state == "OK", "South" , propensity$region)
propensity$region <- ifelse(propensity$state == "AR", "South" , propensity$region)
propensity$region <- ifelse(propensity$state == "MS", "South" , propensity$region)
propensity$region <- ifelse(propensity$state == "KY", "South" , propensity$region)
propensity$region <- ifelse(propensity$state == "WV", "South" , propensity$region)
propensity$region <- ifelse(propensity$state == "VA", "South" , propensity$region)
propensity$region <- ifelse(propensity$state == "NC", "South" , propensity$region)
propensity$region <- ifelse(propensity$state == "SC", "South" , propensity$region)
propensity$region <- ifelse(propensity$state == "AL", "South" , propensity$region)
propensity$region <- ifelse(propensity$state == "MD", "South" , propensity$region)
propensity$region <- ifelse(propensity$state == "WA", "Pacific" , propensity$region)
propensity$region <- ifelse(propensity$state == "OR", "Pacific" , propensity$region)
propensity$region <- ifelse(propensity$state == "CA", "Pacific" , propensity$region)
propensity$region <- ifelse(propensity$state == "AK", "Pacific" , propensity$region)
propensity$region <- ifelse(propensity$state == "HI", "Pacific" , propensity$region)
propensity$region <- ifelse(propensity$state == "ID", "Mountain" , propensity$region)
propensity$region <- ifelse(propensity$state == "NV", "Mountain" , propensity$region)
propensity$region <- ifelse(propensity$state == "AZ", "Mountain" , propensity$region)
propensity$region <- ifelse(propensity$state == "UT", "Mountain" , propensity$region)
propensity$region <- ifelse(propensity$state == "MT", "Mountain" , propensity$region)
propensity$region <- ifelse(propensity$state == "WY", "Mountain" , propensity$region)
propensity$region <- ifelse(propensity$state == "CO", "Mountain" , propensity$region)
propensity$region <- ifelse(propensity$state == "NM", "Mountain" , propensity$region)
propensity$region <- ifelse(propensity$state == "ND", "Midwest" , propensity$region)
propensity$region <- ifelse(propensity$state == "SD", "Midwest" , propensity$region)
propensity$region <- ifelse(propensity$state == "NE", "Midwest" , propensity$region)
propensity$region <- ifelse(propensity$state == "KS", "Midwest" , propensity$region)
propensity$region <- ifelse(propensity$state == "MO", "Midwest" , propensity$region)
propensity$region <- ifelse(propensity$state == "IA", "Midwest" , propensity$region)
propensity$region <- ifelse(propensity$state == "MN", "Midwest" , propensity$region)
propensity$region <- ifelse(propensity$state == "WI", "Midwest" , propensity$region)
propensity$region <- ifelse(propensity$state == "IL", "Midwest" , propensity$region)
propensity$region <- ifelse(propensity$state == "MI", "Midwest" , propensity$region)
propensity$region <- ifelse(propensity$state == "IN", "Midwest" , propensity$region)
propensity$region <- ifelse(propensity$state == "OH", "Midwest" , propensity$region)
propensity$region <- ifelse(propensity$state == "PR", "Territory" , propensity$region)


# Recode 19 - ltcCert, State - 4 observations --> only use medicare, medicaid, and dual;
#                                             drop state and put under *Other:
#                                             (excludes medicare and medicaid )   
propensity$ltcCert <- ifelse(propensity$ltcCert == "STATE", "" , propensity$ltcCert )


# LTC Affiliation: Combine independent, combine hospital 
propensity$ltcAff <- ifelse(propensity$ltcAff == "HSA", "Non-Ind", propensity$ltcAff )
propensity$ltcAff <- ifelse(propensity$ltcAff == "HSFS", "Non-Ind", propensity$ltcAff )
propensity$ltcAff <- ifelse(propensity$ltcAff == "MFO", "Non-Ind", propensity$ltcAff )
propensity$ltcAff <- ifelse(propensity$ltcAff == "ICC", "Ind", propensity$ltcAff )
propensity$ltcAff <- ifelse(propensity$ltcAff == "IFS", "Ind", propensity$ltcAff )
propensity$ltcAff <- ifelse(propensity$ltcAff == "", "Ind", propensity$ltcAff )

#Urbanicity: Combine 1/2 3/4 5/6
propensity$urbanicity <- ifelse(propensity$urbancode == 1, "urban", propensity$urbancode )
propensity$urbanicity <- ifelse(propensity$urbancode == 2, "urban", propensity$urbancode )
propensity$urbanicity <- ifelse(propensity$urbancode == 3, "suburban", propensity$urbancode )
propensity$urbanicity <- ifelse(propensity$urbancode == 4, "suburban", propensity$urbancode )
propensity$urbanicity <- ifelse(propensity$urbancode == 5, "rural", propensity$urbancode )
propensity$urbanicity <- ifelse(propensity$urbancode == 6, "rural", propensity$urbancode )

table(propensity$urbanicity
      )


# # Drop Missing
# propensity <- propensity[propensity$urbanicity != "", ] 
# 
# # Drop Territory 
# propensity <- propensity[propensity$region != "Territory", ] 


# 
# propensity_s = subset(propensity, select = c(status, days, biv, age, race, gender ))
# 
# propensity<- na.omit(propensity_s)
# 
# table(propensity_s$race)
# 
# propensity2 <- propensity_s[ which(propensity_s$race != "unknown"), ]
# 
# table(propensity_s$biv, propensity_s$status)



# Set References for each Covariate 
propensity$region <- relevel(factor(propensity$region), "Midwest" )
propensity$race <-  relevel(factor(propensity$race), "white")
propensity$gender <-  relevel(factor(propensity$gender), "M")
propensity$urbanicity <-  relevel(factor(propensity$urbanicity), "rural")

# Frequencies of All Variables (good for categorical variables)
dfSummary(propensity, style = "grid", plain.ascii = TRUE)

table(propensity$urbancode)
table(propensity$svi)



#####################

# Regression Analysis

#####################
# Crude Cox Regression before weighting:
res.cox <- res.cox <- coxph(Surv(days, status) ~ biv , 
                                  data =  propensity)

res.cox_test <- res.cox <- coxph(Surv(days, status) ~ biv + age + as.factor(race) + as.factor(gender) , 
                            data =  propensity)
  
# Adjusted Cox Regression before weighting:
res.cox <- coxph(Surv(days, status) ~ biv + age +  as.factor(ltcAff) + 
                    as.factor(urbanicity) + as.factor(region),
                   data =  propensity)

res.cox.W <- coxph(Surv(days, status) ~ biv + age +  as.factor(ltcAff) + 
                   as.factor(urbanicity) + as.factor(region), 
                   data = subset(propensity, 
                                 race == "white"))

res.cox.B <- coxph(Surv(days, status) ~ biv + age +  as.factor(ltcAff) + 
                   as.factor(urbanicity) + as.factor(region), 
                   data = subset(propensity, 
                                 race== "black"))


summary(res.cox)
summary(res.cox.W)
summary(res.cox.B)

# Confidence Limits  
ci <- confint.default(res.cox)
colnames(ci) <- c('UpperCI', 'LowerCI')
ci <- ci[, c(2,1)]

ci.W <- confint.default(res.cox.W)
colnames(ci.W) <- c('UpperCI', 'LowerCI')
ci.W <- ci.W[, c(2,1)]

ci.B <- confint.default(res.cox.B)
colnames(ci.B) <- c('UpperCI', 'LowerCI')
ci.B <- ci.B[, c(2,1)]


# Exp for estimates and limits for OR and CI
est <- exp(cbind(OR = coef(res.cox),ci))
est <- as.data.frame(est)

est.W <- exp(cbind(OR = coef(res.cox.W), ci.W))
est.W <- as.data.frame(est.W)

est.B <- exp(cbind(OR = coef(res.cox.B), ci.B))
est.B <- as.data.frame(est.B)


# Vaccine Effectivness 
est$OR <-      (1-est$OR)*100
est$LowerCI <- (1-est$LowerCI)*100
est$UpperCI <- (1-est$UpperCI)*100

est.W$OR <-      (1-est.W$OR)*100
est.W$LowerCI <- (1-est.W$LowerCI)*100
est.W$UpperCI <- (1-est.W$UpperCI)*100

est.B$OR <-      (1-est.B$OR)*100
est.B$LowerCI <- (1-est.B$LowerCI)*100
est.B$UpperCI <- (1-est.B$UpperCI)*100




#################################################################

# Calculating Inverse Probability Treatment of Weights (IPTW)

#################################################################

propensity = subset(propensity, select = c(status, days, biv, age, race, gender, urbanicity, region, ltcAff))
                                          
#propensity <- na.omit(propensity)


######################################
# Calcultaing Propensity Scores 
######################################

iptw.model=glm(biv~ age + as.factor(gender) + as.factor(race),
               data=propensity,
               family = binomial(link="logit"))

new.propensity <-augment(iptw.model,
                         propensity,
                         type.predict = "response") %>%
  rename(propensity=.fitted) %>%
  select(status,days, biv, age, gender, race, urbanicity, region, ltcAff, propensity)

head(new.propensity) 



######################################
# Generate inverse probability weights
######################################

# Creating unstable, stable, treated, and overlapping weights
# using indicator function for biv = 1/0 
ipw.data<-new.propensity %>%
  mutate(uw=(biv/propensity)+(1-biv)/(1-propensity)) %>%
  
  mutate(sw=mean(biv)*(biv/propensity)+mean(biv)*(1-biv)/(1-propensity)) %>%
  
  mutate(tr=propensity*(biv/propensity)+propensity*(1-biv)/(1-propensity)) %>%
  
  mutate(ov=propensity*(1-propensity)*(biv/propensity)+
           propensity*(1-propensity)*(1-biv)/(1-propensity))


# Estimating Average Treatment Effect on the Treated (ATT)
model1.fit=coxph(Surv(days, status) ~ biv + age +as.factor(ltcAff) + as.factor(urbanicity) +
                   as.factor(region),
              data=ipw.data,
              weights = uw)

model2.fit=coxph(Surv(days, status) ~ biv + age +as.factor(ltcAff) + as.factor(urbanicity) +
                   as.factor(region),
                 data=ipw.data,
                 weights = sw)

model3.fit=coxph(Surv(days, status) ~ biv + age +as.factor(ltcAff) + as.factor(urbanicity) +
                   as.factor(region),
                 data=ipw.data,
                 weights = tr)

model4.fit=coxph(Surv(days, status) ~ biv + age +as.factor(ltcAff) + as.factor(urbanicity) +
                   as.factor(race) + as.factor(gender) + as.factor(region),
                 data=ipw.data,
                 weights = ov)

tidy(model1.fit)
tidy(model2.fit)
tidy(model3.fit)
tidy(model4.fit)

# Adjusted Cox Regression estimates after weighting:
summary(model1.fit)
summary(model2.fit)
summary(model3.fit)
summary(model4.fit)



##############################################

# Assessing the PH Assumptions for Covariates 

##############################################

test.ph <- cox.zph(model4.fit)
test.ph


ggcoxzph(test.ph)


ggcoxdiagnostics(model4.fit, type = "dfbeta",
                 linear.predictions = FALSE, ggtheme = theme_bw())

ggcoxfunctional(Surv(days, status) ~ age + log(age) + sqrt(age), data = ipw.data)


# NOTES:
# Try to look up some methods for assessing PH assumptions failing for BIV 
# try to find continuous urbanicity 
# try to fit parametric model Weibull etc. 


#######################

# Checking Balance

#######################

ps.mult <- biv ~ age + as.factor(ltcAff) + as.factor(urbanicity) + as.factor(region)

bal.ipw <- SumStat(ps.formula = ps.mult,
                   weight = c("IPW"), data = propensity)

bal.treat <- SumStat(ps.formula = ps.mult,
                    weight = c("treated"), data = propensity)

bal.over <- SumStat(ps.formula = ps.mult,
                    weight = c("overlap"), data = propensity)

#Balance Plots 
plot(bal.ipw, type = "density")
plot(bal.treat, type = "density")
plot(bal.over, type = "density")


# Produce MSD Results
plot(bal.ipw, metric = "ASD")
plot(bal.treat, metric = "ASD")
plot(bal.over, metric = "ASD")


# Can Insert Trimming #






##########################

# Final Estimates

##########################

# Confidence Limits  
ci4 <- confint.default(model4.fit)
colnames(ci4) <- c('UpperCI', 'LowerCI')
ci4 <- ci4[, c(2,1)]

# Exp for estimates and limits for OR and CI
est4 <- exp(cbind(OR = coef(model4.fit),ci))
est4 <- as.data.frame(est4)

# Vaccine Effectivness 
est4$OR      <- (1-est4$OR)*100
est4$LowerCI <- (1-est4$LowerCI)*100
est4$UpperCI <- (1-est4$UpperCI)*100



# Final Results
summary(model4.fit)
summary(res.cox.W)
summary(res.cox.B)

ve_results <- rbind(est4[1,],
      est.W[1,],
      est.B[1,])






