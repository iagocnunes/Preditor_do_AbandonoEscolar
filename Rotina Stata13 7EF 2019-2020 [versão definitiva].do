clear all
set more off
global in "\\ijsn625\ijsn\Projetos\Núcleo de Educação\9. Preditor de Abandono\Abandono 2020\iago"
global out "\\ijsn625\ijsn\Projetos\Núcleo de Educação\9. Preditor de Abandono\Abandono 2020\iago\Global Out"
local ano 2019 2020
foreach x of local ano {
clear all
set more off
use "$out\base 7EF ano `x'.dta", clear
gen flaginep = 0
replace flaginep = 1 if  codigo_inep != .
tab flaginep, m
preserve
contract idaluno flaginep
tab flaginep
restore
rename disciplina dc_programa_pedagogico_item
gen disciplina = ""
replace disciplina = "HISTORIA" if dc_programa_pedagogico_item == "HISTÓRIA"
replace disciplina = "LINGUA PORTUGUESA" if dc_programa_pedagogico_item == "LÍNGUA PORTUGUESA"
replace disciplina = "MATEMATICA" if dc_programa_pedagogico_item == "MATEMÁTICA"
replace disciplina = "CIENCIAS" if dc_programa_pedagogico_item == "CIÊNCIAS"
replace disciplina = "GEOGRAFIA" if dc_programa_pedagogico_item == "GEOGRAFIA"
tab disciplina, m
drop dc_programa_pedagogico_item
keep if disciplina != ""
drop vl_nota_2_tri vl_falta_2_tri vl_dias_2_tri vl_nota_3_tri vl_falta_3_tri vl_dias_3_tri
preserve
keep if codigo_inep == .
contract idaluno
count
restore
rename vl_nota_1_tri nota
rename vl_falta_1_tri faltas
tab periodo, m
format %20.0g codigo_inep
egen keyidd = group(idaluno disciplina)
sort keyidd
quietly by keyidd: gen dup = cond(_N==1,0,_n)
gen dtencerr = substr(dt_encerramento ,1,10)
drop dt_encerramento 
rename dtencerr dtencerramento
split dtencerramento, p("-") 
rename dtencerramento1 ano
rename dtencerramento2 mes
rename dtencerramento3 dia
destring dia, replace
destring mes, replace
destring ano, replace
gen dtencerr = mdy(mes, dia, ano)
format dtencerr %d
drop mes dia ano
gen dtmat = substr(dt_matricula,1,10)
drop dt_matricula
rename dtmat dtmatricula
split dtmatricula, p("-")
rename dtmatricula1 ano
rename dtmatricula2 mes
rename dtmatricula3 dia
destring dia, replace
destring mes, replace
destring ano, replace
gen dtmatric = mdy(mes, dia, ano)
format dtmatric %d
drop mes dia ano
drop dtencerramento dtmatricula
quietly by keyidd, sort: egen max_date = max(dtmatric) if dtmatric !=. & dup > 0 & dup !=.
format max_date %d
preserve
keep if dup>0 & dup !=. & dtmatric!=. & dtmatric!=max_date
capture contract idaluno flaginep
tab flaginep
restore
drop if dup>0 & dup !=. & dtmatric!=. & dtmatric!=max_date
preserve
contract idaluno flaginep
tab flaginep
restore
drop dup max_date
quietly by keyidd, sort: gen dup = cond(_N==1,0,_n)
tab dup
egen miss = rowmiss(nota)
quietly by keyidd, sort: egen miss_id = min(miss) 
preserve
capture keep if miss!=miss_id & dup > 0 & dup !=.
capture contract idaluno flaginep
capture tab flaginep
restore
drop if miss!=miss_id & dup > 0 & dup !=.
drop dup miss miss_id
preserve
sort keyidd
quietly by keyidd: gen dup = cond(_N==1,0,_n)
tab dup
replace dup = 1 if dup > 1 & dup !=.
contract idaluno dup
tab dup
restore
preserve
contract idaluno flaginep
tab flaginep
restore
quietly by keyidd, sort: gen dup = cond(_N==1,0,_n)
tab dup
sort idaluno disciplina
set seed 2102`x'
gen rnd = runiform()
sort rnd 
gen n = _n
order dup* n rnd, last
sort keyidd n
by keyidd: egen max_n = max(n) if dup > 0 & dup !=.
preserve
keep if dup>0 & dup !=. & n!=max_n
capture contract idaluno flaginep
tab flaginep
restore
drop if dup>0 & dup !=. & n!=max_n
drop max_n dup
preserve
contract idaluno flaginep
tab flaginep
restore
preserve
contract idaluno codigo_inep
drop if codigo_inep == .
sort codigo_inep
quietly by codigo_inep: gen dup = cond(_N==1,0,_n)
tab dup
keep if dup > 0
sort idaluno codigo_inep
drop _freq dup
save "$out\\inep com 2 idaluno 7EF `x'", replace
restore
preserve
keep if codigo_inep == .
egen groupid2 = group(idaluno)
codebook groupid2
contract idaluno
count
restore
sort keyidd
quietly by keyidd: gen dup = cond(_N==1,0,_n)
tab dup
drop rnd n
save "$out\\Base 7EF `x' Sem Duplicados", replace
}
local ano 2019 2020
foreach x of local ano {
clear all
use "$out\\Base 7EF `x' Sem Duplicados", clear
tab disciplina
replace disciplina = "cien" if disciplina=="CIENCIAS"
replace disciplina = "geo" if disciplina=="GEOGRAFIA"
replace disciplina = "his" if disciplina=="HISTORIA"
replace disciplina = "lp" if disciplina=="LINGUA PORTUGUESA"
replace disciplina = "mt" if disciplina=="MATEMATICA"
tab disciplina
rename vl_dias_1_tri dletivo
rename statamatricula status_matricula
levelsof disciplina, local(levels) 
foreach l of local levels {
preserve
keep if disciplina == "`l'"
foreach var of varlist nota faltas dletivo {
rename `var' `var'_`l'
}
sort idaluno
save "$out\\base 7EF `x'_`l'", replace
restore
}
use "$out\\base 7EF `x'_cien", clear
foreach l in  "geo" "his" "lp" "mt"{
merge 1:1 idaluno using "$out\\base 7EF `x'_`l'"
rename _merge _merge_`l'
sort idaluno
}
use "$out\\base 6EF `x'_geo", clear
foreach l in  "his" "lp" "mt" "cien"{
merge 1:1 idaluno using "$out\\base 7EF `x'_`l'"
rename _merge _merge_`l'
sort idaluno
}
gen abandono1 = .
replace abandono1 = 1 if status_matricula=="Abandonou o curso"  | status_matricula=="Deixou de Frequentar" | status_matricula=="DESISTENTE DE MATRÍCULA" | status_matricula=="ABANDONO" | status_matricula=="DESISTENTE MATRICULA"
replace abandono1 = 0 if status_matricula=="Aprovado" |  status_matricula=="RECLASSIFICADO" | status_matricula=="RECLASSIFICADO POR AVANÇO" | status_matricula=="Reprovado" | status_matricula=="MATR. SUPLEMENTAR" | status_matricula=="MATRICULADO" | status_matricula=="AVANÇO ESCOLAR"
gen matriculado = 1 if status_matricula == "APROVADO" | status_matricula == "REPROVADO" | status_matricula == "MATRICULADO"
gen suplementar = 1 if status_matricula == "MATR. SUPLEMENTAR"
gen transf_desistente = 1 if status_matricula=="ABANDONOU O CURSO"  | status_matricula=="DEIXOU DE FREQUENTAR" | status_matricula=="DESISTENTE DE MATRÍCULA" | status_matricula=="TRANSFERIDO" |  status_matricula=="TRANSFERIDO DE MODALIDADE" | status_matricula=="ABANDONO" | status_matricula=="DESISTENTE MATRICULA"
tab status_matricula abandono, m
tab status_matricula matriculado, m
tab status_matricula suplementar, m
tab status_matricula transf_desistente, m
rename nm_aluno aluno
rename dt_nascimento dtnascimento
egen keyfim = group(aluno dtnascimento)
order keyfim codigo_inep aluno dtnascimento dtmatric
quietly by keyfim, sort: gen dupp = cond(_N==1,0,_n)
tab dupp, m
quietly by keyfim, sort: gen dupp4 = cond(_N==1,0,_n)
tab dupp4, m
sort keyfim
quietly by keyfim: egen max_date = max(dtmatric) if dupp4 > 0 & dupp4 !=.
format max_date %d
drop if dupp4>0 & dupp4 != . & dtmatric!=. & dtmatric!=max_date
drop dupp4 max_date 
preserve
contract idaluno abandono1
tab abandono1, m
restore
preserve
keep if codigo_inep !=.
contract idaluno codigo_inep abandono1
tab abandono1, m
restore
quietly by keyfim, sort: gen dupp5 = cond(_N==1,0,_n)
tab dupp5
gsort aluno dtnascimento -codigo_inep
set seed 2102`x'
gen rnd = runiform()
sort rnd 
gen n = _n
order dup* n rnd, last
sort keyfim n
by keyfim: egen max_n = max(n) if dupp5 > 0 
drop if dupp5>0 & dupp5 !=. & n!=max_n
drop max_n dupp5
preserve
contract idaluno abandono1
tab abandono1, m
restore
preserve
keep if codigo_inep !=.
contract idaluno codigo_inep abandono1
tab abandono1, m
restore
quietly by keyfim, sort: gen dupp6 = cond(_N==1,0,_n)
tab dupp6
drop dupp6
quietly by codigo_inep, sort: gen duplo = cond(_N==1,0,_n) if codigo_inep != .
tab duplo
quietly by codigo_inep, sort: gen duplo4 = cond(_N==1,0,_n) if codigo_inep != .
tab duplo4, m
sort codigo_inep
quietly by codigo_inep: egen max_date = max(dtmatric) if duplo4 > 0 & duplo4 !=.
format max_date %d
drop if duplo4>0 & duplo4 != . & dtmatric!=. & dtmatric!=max_date
drop duplo4 max_date 
preserve
contract idaluno abandono1
tab abandono1, m
restore
preserve
keep if codigo_inep !=.
contract idaluno codigo_inep abandono1
tab abandono1, m
restore
quietly by codigo_inep, sort: gen duplo5 = cond(_N==1,0,_n) if codigo_inep != .
tab duplo5
drop rnd n
sort codigo_inep
set seed 2102`x'
gen rnd = runiform()
sort rnd 
gen n = _n
order dup* n rnd, last
sort codigo_inep n
by codigo_inep: egen max_n = max(n) if duplo5 > 0  & duplo5 !=. 
drop if duplo5>0 & duplo5 !=. & n!=max_n
drop max_n duplo5
preserve
contract idaluno abandono1
tab abandono1, m
restore
preserve
keep if codigo_inep !=.
contract idaluno codigo_inep abandono1
tab abandono1, m
restore
quietly by codigo_inep, sort: gen duplo6 = cond(_N==1,0,_n) if codigo_inep !=. 
tab duplo6
drop duplo6
gen dtnasc = substr(dtnascimento,1,10)
drop dtnascimento
rename dtnasc dtnascimento
split dtnascimento, p("-") 
rename dtnascimento1 ano
rename dtnascimento2 mes
rename dtnascimento3 dia
destring dia, replace
destring mes, replace
destring ano, replace
gen dtnas = mdy(mes, dia, ano)
format dtnas %d
gen idade = dtmatric - dtnas
replace idade = floor(idade/365.25)
drop dia mes ano
order idaluno
sort idaluno
drop disciplina
save "$out\\Base 7EF `x' Sem Duplicados Merge", replace
}
local ano 2019 2020
foreach x of local ano{
clear all
use "$out\Base 7EF `x' Sem Duplicados Merge", clear
order codigo_escola
sort codigo_escola
tab periodo
gen turno_m=0
replace turno_m=1 if dc_turno=="MANHA" | dc_turno=="MANHÃ"
gen turno_t=0
replace turno_t=1 if dc_turno=="TARDE"
gen turno_n=0
replace turno_n=1 if dc_turno=="NOITE"
gen turno_i=0
replace turno_i=1 if dc_turno=="INTEGRAL"
tab sre, gen(regional)
gen masculino = .
replace masculino = 1 if tp_sexo == "M"
replace masculino = 0 if tp_sexo == "F"
tab masculino tp_sexo, m
sort codigo_inep
egen tot_falta = rowtotal(faltas_lp faltas_mt faltas_cien  faltas_geo faltas_his)
egen tot_eletivo = rowtotal(dletivo_lp dletivo_mt dletivo_cien dletivo_geo dletivo_his)
gen prop_falta = tot_falta/tot_eletivo
gen propensofalta = .
replace propensofalta = 1 if prop_falta >0.25 
replace propensofalta = 0 if prop_falta <=0.25
foreach var of varlist nota_cien nota_geo nota_his nota_lp nota_mt{
gen dummynota1`var' = 0
replace dummynota1`var' = 1 if `var' <=15 & `var'!=.
replace dummynota1`var' = 0 if `var'>15 & `var' !=.
}
egen notatotal = rowtotal(dummynota1nota_cien  dummynota1nota_geo dummynota1nota_his dummynota1nota_lp dummynota1nota_mt)
drop dummynota1nota_cien dummynota1nota_geo dummynota1nota_his dummynota1nota_lp dummynota1nota_mt
gen propensonota = .
replace propensonota= 1 if notatotal >3
replace propensonota = 0 if notatotal <=3
foreach name in "lp" "mt" "cien" "geo" "his" {
gen prop_faltas_`name' = .
replace prop_faltas_`name' = faltas_`name'/dletivo_`name' 
}
drop dletivo_lp dletivo_mt dletivo_cien dletivo_geo dletivo_his
egen keyinep = group(codigo_inep)
egen keyadt = group(aluno dtnascimento) if codigo_inep == .
gen anoref = `x'
quietly by codigo_inep, sort: gen duplo6 = cond(_N==1,0,_n) if codigo_inep !=. 
tab duplo6
drop duplo6
gen ErroCadastro = 0
 replace ErroCadastro =1 if dtencerr <= d(30may`x')
 
 gen basenota = 2
drop quilombola
save "$out\\Base 7EF `x' Final Nova Iago", replace
}
clear all
use using "$out\\Base 7EF 2019 Final Nova Iago", clear
append using "$out\\Base 7EF 2020 Final Nova Iago"
egen mean_nota = rowmean(nota_cien nota_geo nota_his nota_lp nota_mt)
egen max_falta = rowmax(prop_faltas_lp prop_faltas_mt prop_faltas_cien prop_faltas_geo prop_faltas_his)
egen gturma = group(codigo_escola classe anoref basenota)
foreach var of varlist nota_cien nota_geo nota_his nota_lp nota_mt {
gen dummynota1`var' = 0
replace dummynota1`var' = 1 if `var' == .
replace `var' = 0 if `var'==.
by gturma, sort: egen mean = mean(`var')
by gturma, sort: egen sd = sd(`var')
gen pad_`var' = (`var' - mean) / sd
drop mean sd
}
foreach var of varlist prop_faltas_lp prop_faltas_mt prop_faltas_cien prop_faltas_geo prop_faltas_his {
gen dummyfalta1`var' = 0
replace dummyfalta1`var' = 1 if `var' ==.
replace `var' = 1 if `var'==.
replace `var' = 1 if `var' > 1 & `var' !=.
}
egen dummynota = rowtotal(dummynota1*)
egen dummyfalta = rowtotal(dummyfalta1*)
replace dummynota = 1 if dummynota >= 1 & dummynota !=.
replace dummyfalta = 1 if dummyfalta >= 1 & dummyfalta !=.
by gturma, sort: egen turma_nota_lp = mean(nota_lp)
by gturma, sort: egen turma_nota_mt = mean(nota_mt)
egen gescola = group(codigo_escola anoref)
by gescola, sort: egen esc_nota_lp = mean(nota_lp)
by gescola, sort: egen esc_nota_mt = mean(nota_mt)
egen long gsre = group(sre)
egen sreescola=group(gsre codigo_escola)
drop if abandono1 ==. & anoref<=2018
keep if anoref>=2019
stepwise, pr(.10):logit abandono1 idade masculino turno_m nota_lp nota_mt nota_geo nota_his nota_cien prop_faltas_lp prop_faltas_mt prop_faltas_geo prop_faltas_his prop_faltas_cien turma_nota_lp turma_nota_mt esc_nota_lp esc_nota_mt propensofalta propensonota if anoref<=2019, cluster(codigo_escola)
predict predm7, p
estimates store m7
label define tabclass 1 "Verdadeiro-positivo" 2 "Verdadeiro-negativo" 3 "Falso-positivo" 4 "Falso-negativo" 
label define prevabandono 0 "não abandono" 1 "abandono"
lsens, genprob(cutsm7) gensens(Sm7) genspec(Em7)
gen SporEm7 = Sm7/Em7
gen prov = cutsm7 if round(Em7,.001)== round(Sm7,.001)
egen probcortem7=mean(prov)
drop prov
gen classm7 = 1 if  predm7>=probcortem7
replace classm7= 0 if predm7<probcortem7
gen segm7 = 1 if abandono1==1 & classm7==1
replace segm7= 2 if abandono1==0 & classm7==0
replace segm7 = 3 if abandono1==0 & classm7==1
replace segm7 = 4 if abandono1==1 & classm7==0
label values segm7 tabclass 
label values classm7 prevabandono
label variable segm7 "Tabela de classificação - Grupo de Maximização"
label variable classm7 "Previsão de abandono - Grupo de Maximização%"
gsort anoref -predm7 
by anoref, sort : egen float key15cortem7 = rank(predm7)
by anoref, sort : egen float numobsm7 = count(key15cortem7)
gen pontocorte15m7 = round(numobsm7*0.15)
gen t2m7=numobsm7-pontocorte15m7
gen classm7_15 = 1
replace classm7_15 = 0 if key15cortem7 <=t2m7
replace classm7_15 = . if key15cortem7 ==. & anoref==2019  
drop key15cortem7 numobsm7 pontocorte15m7 t2m7
gen segm7_15 = 1 if abandono1==1 & classm7==1
replace segm7_15= 2 if abandono1==0 & classm7==0
replace segm7_15 = 3 if abandono1==0 & classm7==1
replace segm7_15 = 4 if abandono1==1 & classm7==0
label values segm7_15 tabclass 
label values classm7_15 prevabandono
label variable segm7_15 "Tabela de classificação - Grupo de 15%"
label variable classm7_15 "Previsão de abandono - Grupo de 15%"
keep if  anoref==2020 & classm7_15 == 1
save "\\ijsn625\ijsn\Projetos\Núcleo de Educação\9. Preditor de Abandono\Abandono 2020\iago\Global Out\base Lista 7EF 2020.dta", replace

clear all
cd "\\ijsn625\ijsn\Projetos\Núcleo de Educação\9. Preditor de Abandono\Abandono 2020\iago\Global Out"
use "base Lista 7EF 2020.dta"
keep sre codigo_escola escola municipio tipo_ensino periodo_letivo idaluno aluno tp_sexo raa idade classm7_15 nota_mt nota_lp nota_geo nota_his nota_cien prop_falta
rename sre SRE
tostring codigo_escola, replace
gen teste = " - "
*keep if codigo_escola==32037791
egen cod_escola = concat(codigo_escola teste escola)
drop teste
* Segmentando a base por disciplina no arquivo "output"
quietly  levelsof cod_escola, local(levels) 
foreach l of local levels {
preserve
keep if cod_escola == "`l'"
quietly  export excel using "`l'.xlsx",  firstrow(variables) replace
restore
}
