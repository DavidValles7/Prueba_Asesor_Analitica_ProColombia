********************************************************************************
**   		PROGRAMACIÓN PRUEBA ANALISTA -ANALÍTICA PROCOLOMBIA        		  **
**      		ELABORÓ: DAVID ANDRÉS VALLES RESTREPO          				  **
**              			18 de diciembre de 2023							  **
********************************************************************************


/*Este codigo de programación de Stata 14.1 (.do file) se construyó en una carpeta 
del computador  personal del autor. Para replicar este codigo se recomenda 
cambiar directorio y guardar allí cada archivo utilizado*/


*------------------------------------------------------------------------------*

*Directorio de trabajo con las bases para facilitar importar y guardar:
clear all
cd "C:\Users\david\OneDrive\Documentos\Proyectos\Prueba ProColombia"


/* CASO PARA RESOLVER (BULLETS)

1. TAREA

-La vicepresidenta de exportaciones le pidió al equipo de Analítica que haga un 
análisis del tejido empresarial colombiano y de los pronósticos de las 
exportaciones para el año 2024.

-Identificar las empresas que tienen un alto potencial de atención en 
ProColombia.

-Bases de datos: Base de Exportaciones, Directorio de Empresas del DANE, Listado 
de Super Sociedades, Listado del Registro Único Empresarial (RUES) y un 
diccionario. Conexión usando el NIT.

-Debe entregar un listado con las empresas que sugiere contactar (Archivo en 
Excel), con insights sobre el análisis. */


*---------------------*
*Procedimiento Tarea 1*
*---------------------*


/*1. Se importan las bases una por una y se convierten en formato .do para 
facilitar el trabajo y conectar entre ellas. 
Dado que todos los archivos se encuentran en formato .txt se usa el comando 
"import delimited". Así mismo, se  ajustan las opciones  "delimiter" (para usar 
el tipo de separador), "varnames"(para tomar la primera fila como nombre de 
variable y "encoding" (para ajustar la codificación del texto) de acuerdo a las 
especificaciones de la prueba
Posteriormente, se guardan en formato .do (stata) en la nueva carpeta "Archivos 
formato stata"
*/



	*a) Importar y guardar base RUES 

import delimited "Datos\RUES.txt", delimiter("|") varnames(1) encoding(UTF-8) clear
save "Datos\Archivos formato stata\RUES.dta", replace

	*b) Importar y guardar base Directorio dane 

import delimited "Datos\Directorio_DANE.txt", delimiter("|") varnames(1) encoding(UTF-8) clear 
save "Datos\Archivos formato stata\Directorio_DANE.dta", replace

	*c) Importar y guardar base Exportaciones 

import delimited "Datos\Exportaciones.txt", delimiter("|") varnames(1) encoding(UTF-8) clear 
save "Datos\Archivos formato stata\Exportaciones.dta", replace

	*d) Importar y guardar base Supersociedades
		
import delimited "Datos\Supersociedades.txt", delimiter("|") varnames(1) encoding(UTF-8) clear 
save "Datos\Archivos formato stata\Supersociedades.dta", replace
	


/*2. Se pegan las cuatro bases usando como referencia la variable nit. 
Sin embargo, dado que las 4 bases tienen las mismas variables, se puede realizar 
un merge (horizontal usando nit como referencia) o un append (vertical y quitando 
posteriormente los nits duplicados entre bases). En este caso se usa "merge 1:1",
es decir, se juntan las bases uniendo un nit con su contraparte unica en la otra 
base. 

*/

	*a) Se parte usando la base RUES y juntandola con Directorio dane 
use "Datos\Archivos formato stata\RUES.dta", clear
merge 1:1 nit using "Datos\Archivos formato stata\Directorio_DANE.dta", force
drop _merge


	*b) Nueva base se junta con Exportaciones
merge 1:1 nit using "Datos\Archivos formato stata\Exportaciones.dta", force
drop _merge

	*c) Nueva base se junta con Supersociedades
merge 1:1 nit using "Datos\Archivos formato stata\Supersociedades.dta", force
drop _merge

	/*d) Se guarda esta nueva base compuesta por 50.000 empresas (sin duplicados)
	     Además, se cambia el formato de variables de valores de string a numerico
	     ajustando la "coma" como decimal pues stata por defecto usa "punto"
	     Nota: hay una observación erronea : nit="inferior o igual a 1.65%."|11|Bogo...." la cual se borra*/
	  
destring activos ingresosoperacionales antigüedadempresa expo2022 ///
		expopromult5años varexpo2022 tcacexpoult5años , dpcomma replace
		
drop if strpos(nit,"inferior o igual a 1.65%.")>0
	   
save "Datos\Archivos formato stata\Base unica empresarial.dta", replace

export delimited using "C:\Users\david\OneDrive\Documentos\Proyectos\Prueba ProColombia\Datos\Base unica empresarial.csv", replace




/*3. Se analizan cada una de las variables para ver que opciones se alinean con
los objetivos de ProColombia y con el potencial exportador de cada empresa. 
Por ejemplo, empresas no mineras, 
*/
use "Datos\Archivos formato stata\Base unica empresarial.dta", clear


	/*a) No se consideran las hayan exportado principalmente productos mineros en
		los ultimos 10 años.*/
drop if tipoult10años=="Mineras"

	/*b) Analizando la variable "Trayectoria expo", no se consideran empresas 
	     Top exportadora ya que son las principales exportadoras
		 Así mismo, no se consideran las Mineras, chatarra, otros, 
	     pues no entran en el objetivo de la entidad. Con lo cual solo se toman 
	     las Futuros exportadores y las No constantes */
keep if  trayectoriaexpo == "Futuros" | trayectoriaexpo == "No Constante" | trayectoriaexpo == "Pymex" 

	/*c) Se consideran las empresas que tengan minimo 4 años de antiguedad. 
	     Minimo 5 años de antigüedad para garantizar que no es subsistencia (32.000 emp)*/
keep if antigüedadempresa >= 4


	/*d) Aproximadamente la mitad de las 50.000 empresas tienen ingresos menores a 
		 $1.000.000. Para garantizar un minimo de exito de la operación se 	
		 solicitan ingresos minimos de $300.000.000 (quedan 12.000 empresas de las 50.0000) 
		 no se eliminan todas las micro que pueden tener hasta mil millones de ingresos*/
keep if ingresosoperacionales>300000000


	/*e) Aproximadamente 3.000 de las 50.000 empresas tienen activos menores a 
		 $1.000.000. Para garantizar un minimo de exito de la operación se
		 solicitan activos minimos de $200.000.000 (quedan 21.000 empresas de las 50.0000) 
		 no se eliminan todas las micro que pueden tener hasta seiscientos millones de activos*/
keep if activos>200000000


	/*f)Se consideran empresas con alto valor agregado en la producción de bienes
	   *(tecnología alta y media-alta) y servicios (intensivos en conocimiento 
	   alta tecnología, de mercado, financieros y otros) para garantizar un 
	   mayor valor de las exportaciones y que generen mayores ingresos
	   (quedan 17.000 empresas de las 50.0000)
	   */
keep if valoragregadoempresa == "Bienes tecnología alta" | ///
		valoragregadoempresa == "Bienes tecnología media-alta" | ///
		valoragregadoempresa == "Servicios de alta tecnología intensivos en conocimiento" | ///
		valoragregadoempresa == "Servicios de mercado intensivos en conocimiento" | ///
		valoragregadoempresa == "Otros servicios intensivos en conocimiento" | ///
		valoragregadoempresa == "Bienes tecnología media-alta" 
		
	/*g)Se consideran las empresas que con casa matriz en en el extranjero
	   */
keep if sucursalsociedadextranjera == "No determinado" | sucursalsociedadextranjera == "Si"
 

	/*h)Se descartan las empresas cuyo CIIU no está en una de las Cadenas de ProColombia
	   */
drop if cadenaciiuprincipal =="CIIU no aplica categoría ProColombia"
 


	/*i)Finalmente quedan 1.986 empresas a las cuales contacar. Se recomienda 
		dar prioridad a las empresas que han exportado en los últimos 10 años
		(188 empresas) y especialmente las 13 empresas que presentan una Tasa de
		crecimiento anual compuesto del valor exportado entre 2018-2022 positiva.
	    
	   Se exporta la base 
	   */	
	   
export excel using "Empresas con alto potencial de atención en ProColombia.xlsx", ////
	sheet("Hoja 1") sheetreplace firstrow(varlabels)


	
	
	
/*
2. TAREA
-Analizar las exportaciones no minero-energéticas (NME), proyectando su 
comportamiento para el cierre de 2023 y 2024.

-Uso de la Base de Exportaciones y la aplicación de un modelo predictivo

-Usen datos hasta diciembre de 2022 para entrenamiento y de enero a septiembre 
de 2023 para validación, midiendo el error cuadrático medio para evaluar la 
calidad del pronóstico, y luego realicen proyecciones hasta diciembre de 2024.*/
 
 
*---------------------*
*Procedimiento Tarea 2*
*---------------------*

 
import excel "Datos\expo_nme.xlsx", sheet("Hoja1") firstrow clear

gen fecha_mensual = mofd(Mes)

format fecha_mensual %tm

tsset fecha_mensual , monthly

save "Datos\Archivos formato stata\expo_nme.dta",replace



*Se toma la base hasta diciembre 2022 para entrenamiento

drop if fecha_mensual >= m(2023m1)

*::::::::::::::1 PASO -> ANALIZAR LA ESTACIONARIEDAD :::::::::::::::::::::

tsline Expo_NME 

/*al parecer no hay por que hay tendencia así que se hacen pruebas graficas. 
prueba autocorrelación y prueba de raiz unitaria*/
ac Expo_NME 
dfuller Expo_NME, trend

/*autocorrelación cae lentamente no hay estacionariedad. entonces se toma las diferencias 
*primera  y segunda diferencia para lograr estacionariedad (t1 - t-1). prueba dicki fuller*/
tsline D.Expo_NME
dfuller D.Expo_NME

tsline D2.Expo_NME
dfuller D2.Expo_NME

*el estadistico es menor al punto critico 5% (p-value:1,02) no hay estacionariedad en la serie ni en el ln


 *::::::::::::::3 PASO -> IDENTIFICAR EL MODELO :::::::::::::::::::::
*se usa prueba de autocorrelación simple  (ac) o parcial (pac)
 *cuantos  a) cuantas medias smoviles y b) auto-regresivo
*autocorelacion de expo con primera  y segunda diferencia, nos dice  el numero de medias moviles

ac D.Expo_NME/*1 rezago muy significativo, que esta fuera de las bandas de confianza*/
ac D2.Expo_NME/*1 rezago muy significativo, que esta fuera de las bandas de confianza*/

*autocorelacion parcial nos dice  el numero auto-regresivo

pac D.Expo_NME /*2 rezagos significativos, que esta fuera de las bandas de confianza. es decir proceso autoregresivo de orden 2*/
pac D2.Expo_NME /*4 rezagos significativos, que esta fuera de las bandas de confianza. es decir proceso autoregresivo de orden 4*/

*primer diferencia
*AC -> orden de los MA(1) proceso de medias moviles un rezago
*PAC-> orden de los AR(2) la funcion de autocorrelación parcial mostro que el orden de los rezagos del proceso autoregresivo es de orden 2

*Segunda diferencia
*AC -> orden de los MA(1) proceso de medias moviles un rezago
*PAC-> orden de los AR(4) la funcion de autocorrelación parcial mostro que el orden de los rezagos del proceso autoregresivo es de orden 2


*::::::::::::::4 PASO -> ESTIMACIÓN:::::::::::::::::::::

*arima D.Expo_NME, arima(componente autoreg,orden de diferenciación ,componente medias moviles)
*arima D.Expo_NME, arima(AR,I,MA)
*Se hace una combinación
arima D.Expo_NME, arima(1,0,1) /*rezago de AR no es significativo*/
arima D.Expo_NME, arima(2,0,1) /*el segundo rezagos del proceso AR no es significativo y el rezago del proceso MA es significativo*/

arima D2.Expo_NME, arima(1,0,1) /*rezago de AR y de MA es significativo*/
arima D2.Expo_NME, arima(2,0,1) /*2 rezagoS de AR y de MA es significativo*/
arima D2.Expo_NME, arima(3,0,1) /*tercer rezago de AR y de MA no son significativo*/
arima D2.Expo_NME, arima(4,0,1) /*tercer y cuarto rezago de AR y de MA no son significativo*/

*Tomamos modelo D.Expo_NME, arima(2,0,1), D2.Expo_NME, arima(1,0,1) D2.Expo_NME, arima(2,0,1)

*:::::::::::::: 4 PASO -> VALIDACION DEL MODELO :::::::::::::::::::::

*mejor modelo es el mas parsimonioso. si los errores son o no ruido blanco 
 

*---ARIMA(2,1) primera diferencia
quietly arima D.Expo_NME, arima(2,0,1)
predict resid21d1, resid
wntestb resid21d1, table /*test para erroes de ruido blanco. P-value>0.5 errores tienen ruido blanco*/

*luego se estiman los criterios de información
estat ic 

*la media del error debe ser cero
summarize resid11d1
scalar media_error11= r(mean)
tsline resid11, yline(`r(mean)')

*---ARIMA(1,1) segunda diferencia

quietly arima D2.Expo_NME, arima(1,0,1)
predict resid11d2, resid
wntestb resid11d2, table /*test para erroes de ruido blanco. P-value>0.5 errores tienen ruido blanco*/

estat ic


*---ARIMA(2,1) segunda diferencia

quietly arima D2.Expo_NME, arima(2,0,1)
predict resid21d2, resid
wntestb resid21d2, table /*test para erroes de ruido blanco. P-value>0.5 errores tienen ruido blanco*/

estat ic



/*Comparando los criterios de Akaike de los modelos ARIMA(2,1) primera diferencia, 
ARIMA (1,1) segunda diferencia y ARIMA (2,1) segunda diferencia con el test de 
información, el tercero tiene un criterio de información menor, es decir es más 
parsimonioso, por lo cual se escoge el modelo ARIMA (2,1) segunda diferencia

Sin embargo dadas, las indicaciones de la prueba tambien se mide error cuadrático 
medio de los 3 modelos para evaluar la calidad del pronóstico. 
*/

/* calculo error cuadratico medio con la proyección de la base de entrenamiento*/
tsappend, add(9)
arima Expo_NME, arima(2,1,1) 
predict Expo_NME_fut211, y dynamic(m(2023m1)) 

arima Expo_NME, arima(1,2,1) 
predict Expo_NME_fut121, y dynamic(m(2023m1)) 

arima Expo_NME, arima(2,2,1) 
predict Expo_NME_fut221, y dynamic(m(2023m1)) 


egen mse211 = mean(sum((Expo_NME_fut211 -Expo_NME)^2))

egen mse121 = mean(sum((Expo_NME_fut121 -Expo_NME)^2))

egen mse221 = mean(sum((Expo_NME_fut221 -Expo_NME)^2))


/* Comparando el Error cuadratico medio de los 3 modelos, el del modelo 
ARIMA (2,1) primera diferencia es el que presentam mejor calidad del pronostico 
así que se opta por este*/

*:::::::::::::: 4 PASO -> PREDICCION :::::::::::::::::::::

/*Se Vuelve a usar la base completa y se agregan los 15 hasta diciebre 2024 
que se van a proyectar usando el modelo seleccionado ARIMA (2,1) primera diferencia.
*/

use "Datos\Archivos formato stata\expo_nme.dta",clear

/*Modelo seleccionado usando la variable normal (primera diferencia se 
especifica en el segundo parametro de la funcion arima)*/
arima Expo_NME, arima(2,1,1) 
tsappend, add(15)
predict Expo_NME_fut, y dynamic(m(2023m10)) 

*Se grafica proyección y se guarda
tsline Expo_NME Expo_NME_fut, ytitle("Exportaciones NME") xtitle(" ") /// 
	ylabel(, angle(horizontal)) legend(order(1 "Exportaciones NME" /// 
	2 "Proyección Exportaciones NME")) tlab(2006m1(36)2024m12,valuelabels)
graph export "Proyeccion de exportaciones nme.png", as(png) replace

* Se exporta la salida a excel
export excel using "Exportaciones NME proyectadas.xlsx", sheet("Expo") sheetreplace firstrow(varlabels)
