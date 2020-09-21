  SELECT main.*, hub_name, city_name
FROM
	(
	SELECT
		COALESCE(inv.product_id, throws.product_id) AS product_id,
		COALESCE(inv.hub_id, throws.hub_id) AS hub_id,
		COALESCE(inv.date, throws.date) AS date,
		EXTRACT(WEEK FROM COALESCE(inv.date, throws.date)) AS week,
		start_inventory,
		throws_qty
	FROM
		(
		SELECT 
			product_id,
			hub_id,
			CAST(created_at AS DATE) AS date,
			SUM(physical_closing_stock)+SUM(actual_dispatch_stock) AS start_inventory
		FROM consumer_omsv1_hub_dispatch_plan WHERE date(created_at) >= '2020-08-01'
		GROUP BY
			product_id,
			CAST(created_at AS DATE),
			hub_id
		) inv
	FULL OUTER JOIN
		(
		select 
			hub_id,
			sku AS product_id,
			date(dispatch_datetime) as date, 
			sum(dispatched_quantity)   AS throws_qty
		from 
			consumer_omsv1_operations_data data
		left join 
			(
			select DISTINCT city_id, hub_id, hub_name
			from 
				consumer_omsv1_hub_master
			) as hub_master
		on data.source_ = hub_master.hub_id
		left join 
			(
			select DISTINCT id, city_name
			from 
				consumer_omsv1_city_master 
			) as city_master
		on hub_master.city_id= city_master.id
		where data.to_ in ( '11','23','110','69')
		and date(data.createdAt) >= '2020-08-01'
		group by 
			hub_id,
			sku,
			date(dispatch_datetime)
		) throws
	ON inv.product_id = throws.product_id
	AND inv.hub_id = throws.hub_id
	AND inv.date = throws.date
	) main
LEFT JOIN

	(
	select DISTINCT city_id, hub_id, hub_name
	from 
		consumer_omsv1_hub_master
	) as hub_master
on main.hub_id = hub_master.hub_id
left join 
	(
	select DISTINCT id, city_name
	from 
		consumer_omsv1_city_master 
	) as city_master
on hub_master.city_id= city_master.id
