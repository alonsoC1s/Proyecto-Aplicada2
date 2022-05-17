# EJEMPLO REAL HETEROCEDASTICIDAD

library(AER)
data("CPSSWEducation")
attach(CPSSWEducation)

# Resumen
summary(CPSSWEducation)

#########################################
#### PARTE 1 #########
#########################################

# Modelo de regresión y gráficas
labor_model <- lm(earnings ~ education)

plot(education, 
     earnings, 
     ylim = c(0, 150))

abline(labor_model, 
       col = "steelblue", 
       lwd = 2)

summary(labor_model)
confint(labor_model)

#Encontramos (como ya sabemos) una relación positiva entre años de educación y salario
# la educación es significativa

#########################################
#### PARTE 2 #########
#########################################

# Probemos si existe heterocedasticidad

library(lmtest)
gqtest(labor_model)   #Goldfeld-Quandt test
bptest(labor_model)   #Breusch-Pagan test
bptest(labor_model, education ~ earnings + I(earnings^2))  #White test

################################################################


#########################################
#### PARTE 3 #########
#########################################


# Corrijamos la heterocedasticidad


# cálculo de "heteroskedasticity-robust standard errors" con el tipo HC1
# vcov es la matriz de covarianza robusta de los coeficientes
# robust_se son las desv est robustas de los coeficientes

vcov <- vcovHC(labor_model, type = "HC1")
vcov
robust_se <- sqrt(diag(vcov))
robust_se


coeftest(labor_model, vcov. = vcov)
