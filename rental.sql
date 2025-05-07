--En Çok Film Kiralayan Müşteriyi Bul
SELECT c.customer_id, c.first_name, c.last_name, count(r.rental_id) as total_rentals
FROM customer c
join rental r on c.customer_id=r.customer_id
group by c.customer_id, c.first_name, c.last_name
order by total_rentals desc
limit 1


--Kategoriye Göre Toplam Film Süresi
select c.name, sum(f.length) as total_length
from category c
join film_category fc on c.category_id=fc.category_id
join film f on fc.film_id=f.film_id
group by c.name
order by total_length desc;

--Geciken Kiralamalar
select c.customer_id, c.first_name, c.last_name,
       f.title,
	   r.rental_date,
	   r.return_date,
	   r.rental_date + interval '1 day' * f.rental_duration as due_date
from rental r
join customer c on r.customer_id=c.customer_id
join inventory i on r.inventory_id=i.inventory_id
join film f on i.film_id=f.film_id
where r.return_date>(r.rental_date + interval '1 day' * f.rental_duration);


--Şehirlere Göre Müşteri Dağılımı
select ci.city, count(c.customer_id) as total_customers
from customer c
join address a on c.address_id=a.address_id
join city ci on a.city_id=ci.city_id
group by ci.city 
order by total_customers desc;


--En Kârlı Müşteriler
select c.customer_id, c.first_name, c.last_name,
       count(p.amount) as total_amount
from customer c
join payment p on c.customer_id=p.customer_id
group by c.customer_id, c.first_name, c.last_name
order by total_amount desc
limit 5;


--Aynı Günde Kiralanan ve İade Edilen Filmler
select f.title,
       r.rental_date, r.return_date
from rental r
join inventory i on r.inventory_id=i.inventory_id
join film f on i.film_id=f.film_id
where date(r.rental_date)=date(r.return_date);


--Aktör ve Kategoriye Göre Film Dağılımı
select a.actor_id, a.first_name, a.last_name,
       c.name, count(fa.film_id) as film_count
from actor a
join film_actor fa on a.actor_id=fa.actor_id
join film_category fc on fa.film_id=fc.film_id
join category c on fc.category_id=c.category_id
group by a.actor_id, a.first_name, a.last_name, c.name
order by film_count desc;

--- category_id indexinin kullanımını görmek için category_id filtresini uygulamak

--Aktör ve Kategoriye Göre Film Dağılımı
EXPLAIN (ANALYZE, BUFFERS) 
SELECT a.actor_id, a.first_name, a.last_name,
    c.name, COUNT(fa.film_id) AS film_count
FROM actor a
JOIN film_actor fa ON a.actor_id = fa.actor_id
JOIN film_category fc ON fa.film_id = fc.film_id
JOIN category c ON fc.category_id = c.category_id
WHERE fc.category_id IN (1, 2, 3, 4, 5)
GROUP BY a.actor_id, a.first_name, a.last_name, c.name
ORDER BY film_count DESC;


--Her Müşterinin Son Kiraladığı Film
select c.customer_id, c.first_name, c.last_name,
       f.title,
	   r.rental_date
from rental r
join customer c on r.customer_id=c.customer_id
join inventory i on r.inventory_id=i.inventory_id
join film f on i.film_id=f.film_id
where r.rental_date=(
     select max (re.rental_date)
	 from rental re 
	 where re.customer_id=c.customer_id
);


--Hiç Kiralanmamış Filmler
select f.film_id, f.title
from film f
where not exists (
    select 1
	from inventory i
	join rental r on r.inventory_id=i.inventory_id
	where i.film_id=f.film_id
);


--Kira Süresine Göre Ortalama Gecikme Ücreti
select c.name as category_name, 
       avg(extract(day from (r.return_date - r.rental_date))) as avg_delay_days,
       avg(p.amount) as avg_late_fee
from rental r
join inventory i on r.inventory_id = i.inventory_id
join film_category fc on i.film_id = fc.film_id
join category c on fc.category_id = c.category_id
join payment p on r.rental_id = p.rental_id
where r.return_date > r.rental_date  
group by c.name
order by avg_delay_days desc;


select return_date - rental_date from rental; --sadece ..day olarak döndürür
select extract(day from ('2024-02-07'::date - '2024-02-01'::date)) as days_diff;-- direkt sayı(aradaki farkı) döndürür








