### A Pluto.jl notebook ###
# v0.18.0

using Markdown
using InteractiveUtils

# ╔═╡ 0314c9ba-8e88-11ec-0b13-ff6d7516e4b5
begin
	using Pkg
	#Pkg.add(url="https://github.com/sdBrinkmann/HPFilter")
	Pkg.activate()
end

# ╔═╡ 84782bc2-92c5-4662-95f9-09c3312b6d4d
begin
	import GeoDataFrames as GDF
	using DataFramesMeta, CategoricalArrays, ArchGDAL
	using CSV, Glob, Dates, Statistics, StatsPlots
	using LinearAlgebra
	using SparseArrays
	using SingularSpectrumAnalysis
	using Interpolations
end

# ╔═╡ 58cdca1b-0ae8-409c-ade4-272fc741b392
md"""
# Prototipo para ver si funciona el concepto de Aplicada 2

**Objetivo**:
- Ver si hay correlaciones entre las variables: Número de estaciones de transporte público & utilización vehicular (o un proxy de eso).

Estoy usando solo metro y metrobus pero podemos tener acceso a todo [Afluencia Preliminar en Transporte Publico](https://datos.cdmx.gob.mx/dataset/afluencia-preliminar-en-transporte-publico/resource/c2a29b87-0809-4448-90a2-158d8fc5d180) & también tenemos datos de [Movilidad](https://datos.cdmx.gob.mx/dataset/movilidad-historico-covid-19) (específicamente para el contexto COVID-19 y cambios porcentuales).

### Pregunta
Se puede establecer una relación estilo: más transporte público $\implies$ menos viajes en automóvil?

- A nivel alcaldía
"""

# ╔═╡ b21f5c87-2700-4914-8ab4-8c1190e21148
md"## 1. Obteniendo, limpiando y acomodando datos"

# ╔═╡ 0fa93e3e-385c-413c-9035-30a4af9fdded
function segmenta_alcaldia(str_alcaldias)
	if occursin(r"Estado de México", str_alcaldias)
		return "EDOMX"
	elseif !occursin(r"/", str_alcaldias)
		return str_alcaldias
	else
		# Partiendo por "/" y regresando
		return split(str_alcaldias, "/")[rand(1:2)] |> rstrip |> lstrip
	end
end

# ╔═╡ 534d44ca-491c-4e93-8dae-b37f1cc91cb9
begin
	metro = GDF.read("stcmetro_shp/STC_Metro_estaciones_utm14n.shp")
	@chain metro begin
		
		@transform! @byrow :ALCALDIAS = segmenta_alcaldia(:ALCALDIAS)
		@transform! begin
			:lng = ArchGDAL.getx.(:geom, 0)
			:lat = ArchGDAL.gety.(:geom, 0)

			$(
				[:LINEA, :TIPO, :ALCALDIAS, :SISTEMA] .=> categorical
				.=> [:LINEA, :TIPO, :ALCALDIA, :SISTEMA]
			)
			
		end

		
		@select! begin
			:NOMBRE
			:ALCALDIA
			:SISTEMA
			:LINEA
			:AÑO
			:lng
			:lat
		end

	end

	CSV.write("data/metro_procesado.csv", metro; bom=true)
end

# ╔═╡ e0ce31f7-317f-4404-b21d-ced0a62c2422
begin
	trolebus = GDF.read("ste_trolebus_shp/STE_Trolebus_Paradas.shp")

	
	@chain trolebus begin
		@transform! @byrow :ALCALDIAS = segmenta_alcaldia(:ALCALDIAS)
		@transform! begin
			:lng = ArchGDAL.getx.(:geom, 0)
			:lat = ArchGDAL.gety.(:geom, 0)
			$(
				[:LINEA, :TIPO, :ALCALDIAS, :SISTEMA] .=> categorical
				.=> [:LINEA, :TIPO, :ALCALDIA, :SISTEMA]
			)
			
		end

		
		@select! begin
			:NOMBRE
			:ALCALDIA
			:SISTEMA
			:LINEA
			#:AÑO
			:lng
			:lat
		end
	end

	CSV.write("data/trolebus_procesado.csv", trolebus; bom=true)
end

# ╔═╡ 99457d78-d35f-45fe-832c-d82fb35a9738
begin
	cablebus = GDF.read("ste_cablebus_shp/STE_Cablebus_estaciones_utm14n.shp")

	
	@chain cablebus begin
		@transform! @byrow :ALCALDIAS = segmenta_alcaldia(:ALCALDIAS)
		@transform! begin
			:lng = ArchGDAL.getx.(:geom, 0)
			:lat = ArchGDAL.gety.(:geom, 0)
			$(
				[:LINEA, :TIPO, :ALCALDIAS, :SISTEMA] .=> categorical
				.=> [:LINEA, :TIPO, :ALCALDIA, :SISTEMA]
			)
			
		end

		
		@select! begin
			:NOMBRE
			:ALCALDIA
			:SISTEMA
			:LINEA
			:AÑO
			:lng
			:lat
		end
	end

	CSV.write("data/cablebus_procesado.csv", cablebus; bom=true)
end

# ╔═╡ 2f2ec59f-cd89-4a40-be43-e55d9fb577be
begin
	tren = GDF.read("ste_tren_ligero_shp/STE_TrenLigero_estaciones_utm14n.shp")

	@chain tren begin
		@transform! @byrow :ALCALDIAS = segmenta_alcaldia(:ALCALDIAS)
		@transform! begin
			:lng = ArchGDAL.getx.(:geom, 0)
			:lat = ArchGDAL.gety.(:geom, 0)
			$(
				[:LINEA, :TIPO, :ALCALDIAS, :SISTEMA] .=> categorical
				.=> [:LINEA, :TIPO, :ALCALDIA, :SISTEMA]
			)
			
		end

		
		@select! begin
			:NOMBRE
			:ALCALDIA
			:SISTEMA
			:LINEA
			:AÑO
			:lng
			:lat
		end
	end

	CSV.write("data/trenligero_procesado.csv", tren; bom=true)
end

# ╔═╡ 503e8694-45aa-42d2-ae38-747c8f35e5f2
begin
	metrobus = GDF.read("mb_shp/Metrobus_estaciones_utm14n.shp")
	
	@chain metrobus begin
		@transform! @byrow :ALCALDIAS = segmenta_alcaldia(:ALCALDIAS)
		@transform! begin
			:lng = ArchGDAL.getx.(:geom, 0)
			:lat = ArchGDAL.gety.(:geom, 0)
			$(
				[:LINEA, :TIPO, :ALCALDIAS, :SISTEMA] .=> categorical
				.=> [:LINEA, :TIPO, :ALCALDIA, :SISTEMA]
			)
			
		end
		
		@select! begin
			:NOMBRE
			:ALCALDIA
			:SISTEMA
			:LINEA
			:AÑO
			:lng
			:lat
		end
	end

	CSV.write("data/metrobus_procesado.csv", metrobus; bom=true)
end

# ╔═╡ 222349ef-d993-4af0-9975-f94acae44b88
md"Ahora tomo los datos del metrobus y lo junto todo"

# ╔═╡ 0ef2d15e-14ae-47cf-b73e-2565b621f670
# Juntando todo electrico
begin
	telectrico = vcat(metro, tren)
	# CSV.write("t_electico.csv", telectrico, bom=true)
end

# ╔═╡ fbb82ca7-c34e-4fe8-9b60-f39b5b7c4cb7
telectrico_chico = @chain telectrico begin
	groupby(:AÑO)
	@combine $(nrow => :EST_V)
end

# ╔═╡ 5641e8e1-8b86-4f94-b99c-c6cc63bd18be
md"Paso de la muerte. Hago un dataframe vacio que contiene todos los años desde 1980 hasta 2022 con total de estaciones verdes igual a cero. Después hago un innerjoin con año y alcaldía. Eso llena los espacios vacíos. Luego agrupo y reduzco con cumsum"

# ╔═╡ dc4208eb-e975-4c46-9d06-419e20bd1505
begin
	años = 1980:2022
	#alcaldias = levels(telectrico.ALCALDIA)

	#len = length(años) * length(alcaldias)

	#dense_alc = repeat(alcaldias; inner=length(años))
	#dense_yrs = repeat(años; outer=length(alcaldias))

	#denso = DataFrame(ALCALDIA=dense_alc, AÑO=dense_yrs, EST_V = zeros(len))
	denso = DataFrame(AÑO=años, EST_V = zeros(length(años)))
end

# ╔═╡ af5e5030-fbc4-4e7f-8b90-8fe214892290
#=
telectrico_denso = @chain outerjoin(denso, telectrico_chico; on=[:ALCALDIA, :AÑO], makeunique=true) begin
	coalesce.(0)
	sort
	@transform! :EST_V = :EST_V + :EST_V_1
	groupby(:ALCALDIA)
	@combine begin 
		:EST_V = cumsum(:EST_V)
		:AÑO
	end
end
=#

# ╔═╡ 0cb4cac9-d546-4f1f-ac46-9db51b990baa
telectricocdmx_denso = @chain outerjoin(denso, telectrico_chico; on=:AÑO, makeunique=true) begin
	coalesce.(0)
	sort
	@transform! :EST_V = :EST_V + :EST_V_1
	# groupby(:ALCALDIA)
	@combine begin 
		:EST_V = cumsum(:EST_V)
		:AÑO
	end
end

# ╔═╡ 371e8c14-5765-44d3-b78a-b5563344d311
# Juntando todo masivo
begin
	tmasivo = vcat(metro, metrobus, tren)
	#CSV.write("t_masivo.csv", telectrico, bom=true)
end

# ╔═╡ 3630f817-3415-4897-9524-164cdc9b1a64
filenames = Glob.glob("mediciones_por_estacion/csvs/*.csv")

# ╔═╡ 103850e9-5712-4b40-92fc-27b90efe4afe
estaciones = Dict(
	:AJU => "Tlalpan",
	:AJM => "Tlalpan",
	:BJU => "Benito Juarez",
	:CAM => "Azcapotzalco",
	:CCA => "Coyaocán",
	:TEC => "Gustavo A. Madero",
	:COR => "Xochimilco",
	:CUA =>	"Cuajimalpa de Morelos",
	:DIC => "Tlalpan",
	:EAJ => "Tlalpan",
	:EDL => "Cuajimalpa de Morelos",
	:GAM => "Gustavo A. Madero",
	:HGM => "Cuauhtémoc",
	:IZT => "Iztacalco",
	:LAA => "Gustavo A. Madero",
	:IBM => "Miguel Hidalgo",
	:LOM => "Miguel Hidalgo",
	:MER => "Venustiano Carranza",
	:MGH => "Miguel Hidalgo",
	:MPA => "Milpa Alta",
	:MCM => "Cuauhtémoc",
	:PED => "Álvaro Obregón",
	:SNT => "La Magdalena Contreras",
	:SFE => "Cuajimalpa de Morelos",
	:SAC => "Iztapalapa",
	:TAH => "Xochimilco",
	:UIZ => "Iztapalapa",
	:UAX => "Coyoacán",
)

# ╔═╡ 92f6b764-783b-4fef-811f-c4c4ec289acf
begin
	keep_cols = vcat(:FECHA, collect(keys(estaciones)))

	function parse_robusto(n)
		res = 0.0
		try
			res = parse(Float64, n)
		catch
			isa(n, Float64) ? res=n : res=0.0
		end

		return res
	end

	function ingest_data(filenames)
		filenames = Glob.glob("mediciones_por_estacion/csvs/*.csv")
		agg = DataFrame(FECHA = Date[], CONTAMINANTE = String[],
			CVE_EST = String[], VALUE = Float64[], ALCALDIA=String[])
		
		for filename in filenames
			df = CSV.read(filename, DataFrame; missingstring="-99", dateformat="yyyy/mm/dd", select=keep_cols)

			# Anotando con contaminante
			m = match(r"\d{4}(.*).csv" , filename, 29)
			@transform!(df, :CONTAMINANTE = m.captures[1])

			# Convirtiendo wide a long
			df = stack(df, Not([:FECHA, :CONTAMINANTE]); variable_name=:CVE_EST, value_name=:VALUE) |> dropmissing!

			@transform! df begin
				@byrow :ALCALDIA = estaciones[Symbol(:CVE_EST)]
				@byrow :VALUE = parse_robusto(:VALUE)
			end

			agg = vcat(agg, df)
		end

		return agg
	end
end

# ╔═╡ 41650a70-44f2-457d-b3c6-83ce6313f635
# aire = ingest_data(filenames)

# ╔═╡ 45ca6be3-e066-48c9-b252-085c969aee33
aire = CSV.read("RAMA_CDMX_86-22.csv", DataFrame)

# ╔═╡ 5f1ddd18-6b2f-4b87-91d7-8c421426ae0e
aire_general = @chain aire begin
	groupby([:FECHA, :CONTAMINANTE])
	@combine :VALUE = mean(:VALUE)
end

# ╔═╡ 75c38353-5d20-4cdc-8ecb-a55613a6d3c9
# CSV.write("RAMA_general_86-22.csv", aire_general; bom=true)

# ╔═╡ 4d516bd6-5fce-478e-8daf-9c114ef7a2ca
# CSV.write("RAMA_CDMX_86-22.csv", aire; bom=true)

# ╔═╡ a0a1d33d-f724-4870-bc70-5d8993c843c0
aire_groups = @chain aire_general begin
	coalesce(0)
	@transform begin
		@byrow :AÑO = Dates.year(:FECHA)
	end
	
	groupby([:CONTAMINANTE, :AÑO])
	#@transform! :VALUE = HP(Vector(:VALUE), Int(1e5))

	#=
	@combine :MEDIANA = mean(:VALUE)
	@select begin
		:CONTAMINANTE
		:ALCALDIA
		:MEDIANA
		:AÑO
	end
	=#
end

# ╔═╡ 5df66ff9-8f05-4294-a704-f94fb7e2eede
begin

	function wrap_analyzer(yn)
		trend = zeros(length(yn))
		try
			trend, _ = analyze(yn, 10, robust=true)
		catch
			@debug "Problema"
		end
		return trend
	end
			
	for ai in aire_groups
		# @transform!(ai, :VALUE = HP(Vector(:VALUE), Int(1e5)))
		@transform!(ai, :VALUE, _ = wrap_analyzer(:VALUE))
	end
	
	aire_suavizado = @combine(aire_groups, :MEAN_CONT = median(:VALUE))
	@subset!(aire_suavizado, @byrow :MEAN != 0)
end

# ╔═╡ 8bac2538-4048-442f-bd7c-02f51ac7173d
aire_suavizado

# ╔═╡ b3c64a51-dd00-42d3-930a-f5165e09884e
# CSV.write("RAMA_CDMX_86-22_suavizado.csv", aire_suavizado; bom=true)

# ╔═╡ 41053f6f-ecd1-489d-b7f5-6302ef8d58a7
begin
	yn = aire_groups[10].VALUE

	#=
	yt, ys = analyze(yn, 10, robust=true) # trend and seasonal components
	plot(yt, lab="Trend")
	plot!(ys, lab="Season")
	plot!(yn, lab="Orig")
	=#

	plot(wrap_analyzer(yn), lab="Am")
end

# ╔═╡ 191830d1-c247-4c36-8b08-8c327d5d4afb
co_98 = @chain aire begin
	# @transform @byrow :AÑO = Dates.year(:FECHA)
	@subset begin
		@byrow :AÑO == 1998
		#@byrow :ALCALDIA  == "Venustiano Carranza"
		@byrow :CONTAMINANTE == "CO"
	end
	#@df plot(:FECHA, :VALUE)
end

# ╔═╡ 9ec43c0a-a7a4-4188-b434-31a7cb4ce7f5

begin
	@df co_98 plot(:FECHA, :VALUE)
	plot!(co_98.FECHA, HP(co_98.VALUE, Int(1e5)))
end

# ╔═╡ 2e5e8b42-197c-4d3f-b33f-b85232833994
poblacion = @chain CSV.read("poblacion_alcaldias.csv", DataFrame) begin
	@subset @byrow :ALCALDIA == "CDMX"
end

# ╔═╡ fa1bbb87-ed47-4ac5-b9b5-7cd511bd8349
begin
	@df poblacion scatter(:AÑO, :POBLACION)
	#@df poblacion plot(LinearInterpolation(:AÑO, :POBLACION))
end

# ╔═╡ 71209b46-ecf2-4721-9e04-f64e76411b64
begin
	itp = interpolate((poblacion.AÑO,), poblacion.POBLACION, Gridded(Linear()))
	
	plot!(1990:1:2020, itp(1990:1:2020))
end

# ╔═╡ 6ddf350b-b847-4867-afd5-d7bdab5fb62d
poblacion_denso = DataFrame(
	AÑO=1990:1:2020, ALCALDIA=fill("CDMX", 31),
	POBLACION=Float64.(itp(1990:1:2020))
)

# ╔═╡ 0ec8a2fe-cded-44b0-af31-57314d9a9e74
begin
	function parsea_inegi(str)
		try
			return parse(Int, replace(str, "," => ""))
		catch
			return missing
		end
	end
		
	
	vehic = @chain CSV.read("vehiculos_circulacion_1990-2019_64.csv", missingstring="-", DataFrame) begin
		@transform! begin
			@byrow :TOTAL = parsea_inegi(:TOTAL)
			$(:TIPO => categorical => :TIPO)
		end

		@subset! @byrow :TIPO  == "Automóviles"

		rename!(Dict(:TOTAL => :AUTOMOVILES))
		select!(Not(:TIPO))
	end
end

# ╔═╡ 3f725649-ae2c-41c2-899e-b4bcb9ee273b
# CSV.write("parque_1980-2020.csv", vehic; bom=true)

# ╔═╡ 15060361-9c2f-4557-b45c-1e893381d398
begin
	MAIN = innerjoin(aire_suavizado, poblacion_denso, telectricocdmx_denso, vehic; on=:AÑO, makeunique=true)
	#transform!(MAIN, [:CONTAMINANTE, :ALCALDIA] .=> categorical; renamecols=false)
	sort!(MAIN, :AÑO)
end

# ╔═╡ c8174734-b36c-4113-90c4-eec8ba5188b3
# CSV.write("procesados.csv", MAIN; bom=true)

# ╔═╡ 57659165-e2d8-47fb-8bb3-3f2b844cb3fa
md"## Población"

# ╔═╡ Cell order:
# ╠═0314c9ba-8e88-11ec-0b13-ff6d7516e4b5
# ╠═84782bc2-92c5-4662-95f9-09c3312b6d4d
# ╟─58cdca1b-0ae8-409c-ade4-272fc741b392
# ╟─b21f5c87-2700-4914-8ab4-8c1190e21148
# ╠═0fa93e3e-385c-413c-9035-30a4af9fdded
# ╠═534d44ca-491c-4e93-8dae-b37f1cc91cb9
# ╠═e0ce31f7-317f-4404-b21d-ced0a62c2422
# ╠═99457d78-d35f-45fe-832c-d82fb35a9738
# ╠═2f2ec59f-cd89-4a40-be43-e55d9fb577be
# ╠═503e8694-45aa-42d2-ae38-747c8f35e5f2
# ╟─222349ef-d993-4af0-9975-f94acae44b88
# ╠═0ef2d15e-14ae-47cf-b73e-2565b621f670
# ╠═fbb82ca7-c34e-4fe8-9b60-f39b5b7c4cb7
# ╠═5641e8e1-8b86-4f94-b99c-c6cc63bd18be
# ╠═dc4208eb-e975-4c46-9d06-419e20bd1505
# ╠═af5e5030-fbc4-4e7f-8b90-8fe214892290
# ╠═0cb4cac9-d546-4f1f-ac46-9db51b990baa
# ╠═371e8c14-5765-44d3-b78a-b5563344d311
# ╠═3630f817-3415-4897-9524-164cdc9b1a64
# ╠═103850e9-5712-4b40-92fc-27b90efe4afe
# ╠═92f6b764-783b-4fef-811f-c4c4ec289acf
# ╠═41650a70-44f2-457d-b3c6-83ce6313f635
# ╠═45ca6be3-e066-48c9-b252-085c969aee33
# ╠═5f1ddd18-6b2f-4b87-91d7-8c421426ae0e
# ╠═75c38353-5d20-4cdc-8ecb-a55613a6d3c9
# ╠═4d516bd6-5fce-478e-8daf-9c114ef7a2ca
# ╠═a0a1d33d-f724-4870-bc70-5d8993c843c0
# ╠═5df66ff9-8f05-4294-a704-f94fb7e2eede
# ╠═8bac2538-4048-442f-bd7c-02f51ac7173d
# ╠═b3c64a51-dd00-42d3-930a-f5165e09884e
# ╠═41053f6f-ecd1-489d-b7f5-6302ef8d58a7
# ╠═191830d1-c247-4c36-8b08-8c327d5d4afb
# ╠═9ec43c0a-a7a4-4188-b434-31a7cb4ce7f5
# ╠═2e5e8b42-197c-4d3f-b33f-b85232833994
# ╠═fa1bbb87-ed47-4ac5-b9b5-7cd511bd8349
# ╠═71209b46-ecf2-4721-9e04-f64e76411b64
# ╠═6ddf350b-b847-4867-afd5-d7bdab5fb62d
# ╠═0ec8a2fe-cded-44b0-af31-57314d9a9e74
# ╠═3f725649-ae2c-41c2-899e-b4bcb9ee273b
# ╠═15060361-9c2f-4557-b45c-1e893381d398
# ╠═c8174734-b36c-4113-90c4-eec8ba5188b3
# ╟─57659165-e2d8-47fb-8bb3-3f2b844cb3fa
