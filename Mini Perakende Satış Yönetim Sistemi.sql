create table products(
product_id serial primary key,
product_name varchar(100) not null,
category varchar(50),
price numeric(10,2) not null,
created_at timestamp default current_timestamp,
unique (product_name,category)
);

create table customers(
customer_id serial primary key,
customer_name varchar(100) not null,
email varchar(100) unique,
phone varchar(11),
created_at timestamp default current_timestamp
);

create table sales(
sale_id serial primary key,
sale_date date not  null,
product_id integer not null references products(product_id),
customer_id integer references customers(customer_id),
quantity integer not null,
total_amount numeric(10,2) not null,
created_at timestamp default current_timestamp
);

--Var olan bir ürünü güncellemez; mevcut kayıt olduğu gibi kalır.
--Eğer ürün daha önce eklenmemişse, yeni kayıt eklenir.
insert into products (product_name, category, price)
values 
  ('Laptop', 'Elektronik', 3500.00),
  ('Telefon', 'Elektronik', 1500.00),
  ('Klavye', 'Aksesuar', 150.00),
  ('Tablet', 'Elektronik', 2000.00),
  ('Kulaklık', 'Aksesuar', 250.00)
on conflict (product_name, category) do nothing;

-- Farklı tarih ve ürün kombinasyonları ile satış kayıtları ekleyelim
insert into sales (sale_date, product_id, customer_id, quantity, total_amount)
values 
  ('2024-03-01', (select product_id from products where product_name = 'Laptop' and category = 'Elektronik'), 1, 1, 3500.00),
  ('2024-03-01', (select product_id from products where product_name = 'Telefon' and category = 'Elektronik'), 2, 2, 3000.00),
  ('2024-03-02', (select product_id from products where product_name = 'Klavye' and category = 'Aksesuar'), 3, 5, 750.00),
  ('2024-03-02', (select product_id from products where product_name = 'Tablet' and category = 'Elektronik'), 1, 2, 4000.00),
  ('2024-03-03', (select product_id from products where product_name = 'Kulaklık' and category = 'Aksesuar'), 2, 3, 750.00)
on conflict do nothing;


--Transaction ile Veri Eklemeleri (Upsert Örneği)
begin;
insert into products(product_name, category, price)
values('Akıllı Saat','Elektronik',1200.00)
on conflict (product_name, category)
do update set price= excluded.price;

insert into sales (sale_date, product_id, customer_id, quantity, total_amount)
values(
   '2024-03-04',
   (select product_id from products where product_name='Akıllı Saat' and category='Elektronik'),
   (select customer_id from customers where email= 'berna@gmail.com'),
   1,
   1200.00
)
on conflict do nothing;
commit;


--Transaction içinde hata aldığınızda, 
--tüm işlemleri geri almak için aşağıdaki gibi ROLLBACK komutunu kullanabilirsiniz:
rollback;


select * from sales


--Günlük bazda ürün satış özetlerini hesaplayan view.
create view sales_summary as 
select 
    s.sale_date,
	p.product_name,
	sum(s.total_amount) as total_sales,
	sum(s.quantity) as total_quantity
from sales s
join products p on s.product_id= p.product_id
group by s.sale_date, p.product_name;

select * from sales_summary



create materialized view sales_summary_materialized as
select
   s.sale_date,
   p.product_name,
   sum(s.total_amount) as total_sales,
   sum(s.quantity) as total_quantity
from sales s
join products p on s.product_id= p.product_id
group by s.sale_date, p.product_name
with no data;
-- Veri güncellendikçe materialized view'in de yenilenmesi gerekir:
refresh materialized view sales_summary_materialized;

--view nedir?;
--Sanaldır, yani verileri fiziksel olarak saklamaz,
--Sadece bir SQL sorgusunun sonucunu temsil eder,
--Veriler her sorgulandığında tekrar hesaplanır,
--Gerçek zamanlı olarak en güncel veriyi gösterir.

--materialized view nedir?;
--Fiziksel olarak verileri saklar, yani önceden hesaplanmış sorgu sonuçlarını bir tablo gibi tutar,
--Güncelleme gerektirir, çünkü veriler değişse bile kendisi otomatik olarak yenilenmez,
--Performans avantajı sağlar, çünkü veri her sorguda tekrar hesaplanmaz.


SELECT * FROM sales_summary ORDER BY sale_date, product_name;
SELECT * FROM sales_summary_materialized ORDER BY sale_date, product_name;


--Common Table Expressions (CTE - WITH Sorguları);

--Günlük Satış Özetini Hesaplayan
with daily_sales as(
    select sale_date, sum(total_amount) as total_sales
	from sales 
	group by sale_date
)
select sale_date, total_sales
from daily_sales
where total_sales > 5000
order by sale_date;

--En çok harcama yapan ilk 2 müşteriyi getiren
with customer_spending as(
   select 
      c.customer_id,
	  c.customer_name,
	  sum(s.total_amount) as total_spent
   from sales s
   join customers c on s.customer_id=c.customer_id
   group by c.customer_id, c.customer_name
)
select customer_name, total_spent
from customer_spending
order by total_spent desc
limit 2;

--Müşterilerin Son Yaptıkları Satın Alma İşlemini Bulma
with last_purchase as(
   select 
      customer_id,
	  max(sale_date) as last_sale_date
    from sales
	group by customer_id
)
select c.customer_name, l.last_sale_date
from last_purchase l
join customers c on l.customer_id= c.customer_id
order by l.last_sale_date desc;

--NOT;
--Basit (tek tabloya dayalı) view’ler genellikle otomatik olarak updatable (güncellenebilir) olur.
--Kompleks view’ler (join, aggregate, vs.) doğrudan güncellenemez; bu durumlarda INSTEAD OF trigger’lar kullanarak DML işlemleri uygulanabilir.

--1)Basit Updatable View Üzerinden DML İşlemleri

create view product_view as
select product_id, product_name, category, price
from products;

--insert işlemi
insert into product_view(product_name, category, price)
values('Yeni Ürün','Elektronik',1500.00);

select * from product_view
--update işlemi
update product_view
set price=price*0.9
where product_id=7;

--delete işlemi
delete from product_view
where product_id=7;

--2)Join İçeren veya Karmaşık View Üzerinden DML İşlemleri

create view sales_detail as
select
    s.sale_id,
	s.sale_date,
	s.quantity,
	s.total_amount,
	p.product_name
from sales s
join products p on s.product_id=p.product_id;

--Bu view üzerinden doğrudan UPDATE işlemi yapılamayacağından,
--aşağıdaki INSTEAD OF trigger ile güncelleme işlemini yönlendirebiliriz:
create or replace sales_detail_update()
returns trigger as $$
begin
    update sales
    set 
        sale_date   = NEW.sale_date,
        quantity    = NEW.quantity,
        total_amount = NEW.total_amount
    where sale_id = OLD.sale_id;

    return new;
end;
$$ language plpgsql;
create trigger trig_sales_detail_update
instead of update on sales_detail
for each row
execute function sales_detail_update();

--sales tablosunu değişimi gözlemlemek için çağıralım
select * from sales order by sale_id asc

--artık view üzerinden güncelleme yapabiliriz:
update sales_detail
set quantity=10, total_amount=10000.00
where sale_id=3;

--view üzerinden DELETE işlemi yapmak için:
create or replace function sales_detail_delete()
returns trigger as $$
begin
    delete from sales
	where sale_id= old.sale_id;
	return old;
end;
$$ language plpgsql;

create trigger trig_sales_detail_delete
instead of delete on sales_detail
for each row
execute function sales_detail_delete();
	
--artık view üzerinden kayıt silme işlemi de gerçekleştirilebilir:
delete from sales_detail
where sale_id=3;

--sales tablosunu silme işlemini gözlemlemek için çağıralım
select * from sales 


--INSTEAD OF INSERT Trigger için Fonksiyon Oluşturma
create or replace function sales_detail_insert()
returns trigger as $$
declare
    v_product_id int; --fonksiyon içinde geçici bir değişken oluşturduk.
begin
    --ürünün id'sini almak için aynı isimde product var mı kontrol et
	select product_id into v_product_id
	from products
	where product_name = new.product_name; 
--önemli not, into şu anlama gelir;
--Eğer eşleşen bir kayıt varsa, product_id'yi v_product_id değişkenine ata.
--Eğer eşleşen kayıt yoksa, v_product_id NULL olur.
     if v_product_id is null then
	    raise exception 'ürün bulunamadı: %', new.product_name;
	 end if;	

     --sales tablosuna yeni satış ekleyelim
	 insert into sales(sale_date, product_id, quantity, total_amount)
	 values(new.sale_date, v_product_id, new.quantity, new.total_amount);
	 
     return new;
end;
$$ language plpgsql;

--yukarıdaki fonksiyonu çalıştıracak trigger
create trigger trig_sales_detail_insert
instead of insert on sales_detail
for each row
execute function sales_detail_insert();

--Artık doğrudan sales_detail view’ına INSERT yapabiliriz:
insert into sales_detail(sale_date, product_name, quantity, total_amount)
values ('2025-02-25','Laptop',2,5000.00);

select * from sales
-- olmayan bir ürün eklemeye çalışalım
insert into sales_detail(sale_date, product_name, quantity, total_amount)
values ('2025-02-25','Olmayan Ürün',1,2000.00);









