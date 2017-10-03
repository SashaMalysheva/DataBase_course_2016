==> query1.sql <==
-- for each country: count of plantations that export to port in another country

WITH
	Counts AS (
		SELECT
			P.country_id, COUNT(*) AS exporters_cnt
			FROM
				Plantation P
				JOIN AmericanPort Port ON P.port_id = Port.id
			WHERE
				P.country_id != Port.country_id
			GROUP BY

==> query3.sql <==
WITH
	PortTransfer AS (
		SELECT
			TT.eu_port AS id,
			S.capacity AS capacity
			FROM
				TransferType TT
				JOIN Transfer T ON T.type = TT.id
				JOIN Ship S ON S.id = TT.ship
	),
	PortVolume AS (
		SELECT
			EP.id,
			EP.country_id,
			SUM(COALESCE(PT.capacity, 0)) AS volume
			FROM
				EuropeanPort EP
				LEFT JOIN PortTransfer PT ON PT.id = EP.id
			GROUP BY
				EP.id		
	),
	CountryVolume_ AS (
		SELECT
			country_id AS id,
			SUM(volume) AS volume
			FROM
				PortVolume
			GROUP BY country_id
	),
	CountryVolume AS (
		SELECT
			CountryVolume_.*,
			ROW_NUMBER() OVER (ORDER BY volume DESC) AS rank
			FROM
				CountryVolume_
	)
SELECT
	PortVolume.id::INT AS eu_port_id,
	PortVolume.volume::NUMERIC AS volume,
	--CountryVolume.volume AS country_volume,
	(
		CASE
		WHEN CountryVolume.volume = 0
			THEN NULL
		ELSE
			PortVolume.volume / CountryVolume.volume * 100 END
	)::NUMERIC(5, 2) AS volume_share,
	CountryVolume.rank::INT AS country_rank
	FROM
		PortVolume
		JOIN CountryVolume ON PortVolume.country_id = CountryVolume.id
	--ORDER BY
	--	country_rank
;
