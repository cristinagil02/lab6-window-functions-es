USE SAKILA;
-- 1. Calcular la duración media del alquiler (en días) para cada película:
-- over se utiliza para hacer promedios globales, 
SELECT title,rental_duration, AVG(rental_duration) over()
FROM film
GROUP BY title,rental_duration
;

-- 2. Calcular el importe medio de los pagos para cada miembro del personal:
-- con partition by hacemos la mediana de los distintos id
SELECT DISTINCT staff_id,AVG(amount) over (partition by staff_id)
FROM payment
;

-- 3. Calcular los ingresos totales para cada cliente, mostrando el total acumulado dentro del historial de alquileres de cada cliente:
SELECT a.customer_id,a.rental_id,a.rental_date,b.amount,SUM(b.amount) over (partition by a.customer_id order by a.rental_date) 
FROM rental as a
LEFT JOIN
payment AS b 
	ON a.rental_id=b.rental_id
ORDER BY a.customer_id,a.rental_date
;

-- 4.Determinar el cuartil para las tarifas de alquiler de las películas
-- Usamos rank() asigna un rango a cada fila dentro de una partición con el mismo rango para valores empatados
SELECT title, rental_rate, rank() over(partition by rental_rate)
FROM film
;

-- 5. Determinar la primera y última fecha de alquiler para cada cliente:
SELECT DISTINCT customer_id,FIRST_VALUE(rental_date) OVER(PARTITION BY customer_id ORDER BY rental_id),LAST_VALUE(rental_date) OVER(PARTITION BY customer_id RANGE BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING)
FROM rental
;

-- 6. Calcular el rango de los clientes basado en el número de sus alquileres:
SELECT DISTINCT subconsulta.customer_id,subconsulta.total_alquiler,rank () over(partition by a.customer_id order by subconsulta.total_alquiler DESC)
FROM customer as a
JOIN (SELECT customer_id, COUNT(rental_date) as total_alquiler
FROM rental
GROUP BY customer_id ) subconsulta
;

-- 7.Calcular el total acumulado de ingresos por día para la categoría de películas 'Familiar':

SELECT f.title as film_category,
	   sub.rental_date,
	   sub.amount,
       sum(sub.amount) OVER(PARTITION by  sub.rental_date order by sub.amount ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as daily_revenue
FROM film as f
JOIN film_category as fc
ON f.film_id = fc.film_id
JOIN category as c
ON fc.category_id = c.category_id 
JOIN inventory as i
ON f.film_id = i.film_id
JOIN (
    SELECT
        r.inventory_id,
        r.rental_date,
        p.amount
    FROM
        rental as r
    JOIN
        payment as p 
	ON r.rental_id = p.rental_id
) sub
ON
	i.inventory_id = sub.inventory_id
where C.NAME='Family';

-- 8.Asignar un ID único a cada pago dentro del historial de pagos de cada cliente:
SELECT customer_id,payment_id,ROW_NUMBER() OVER(partition by customer_id)
FROM payment
;

-- 9.Calcular la diferencia en días entre cada alquiler y el alquiler anterior para cada cliente:
-- customer_id	rental_id	rental_date	previous_rental_date	days_between_rentals
SELECT sub.customer_id, 
		sub.rental_id, 
		sub.rental_date,
		sub.previous_rental_date,
        DATEDIFF(sub.rental_date,sub.previous_rental_date) as days_between_rentals
from (
select r.customer_id, r.rental_id, r.rental_date , LAG(r.rental_date,1) OVER (PARTITION BY  r.customer_id ORDER BY r.rental_date) as previous_rental_date
from rental as r
) sub
;
