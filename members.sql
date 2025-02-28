create table members(
memid serial primary key,
surname varchar(200),
firstname varchar(300),
address varchar(300),
zipcode integer,
telephone varchar(20),
recommendedby integer,
joindate timestamp default current_timestamp
);

create table facilities(
facid serial primary key,
facname varchar(100),
membercost numeric,
guestcost numeric,
initialoutlay numeric,
monthlymaintenance numeric
);

create table bookings(
facid integer not null references facilities(facid),
memid integer not null references members(memid),
starttime timestamp default current_timestamp,
slots integer,
primary key (facid,memid,starttime)--Yani aynı tesis, aynı üye ve aynı başlangıç zamanına sahip iki rezervasyonun girilmesi engellenmiş olur.
);


insert into members (surname, firstname, address, zipcode, telephone, recommendedby)
values
  ('Yılmaz', 'Ahmet', 'Istanbul, Taksim Mahallesi, Örnek Sokak 1', 34000, '5551234567', NULL),
  ('Kaya', 'Mehmet', 'Ankara, Kızılay, Örnek Cadde 5', 60000, '5552345678', 1),
  ('Demir', 'Ayşe', 'Izmir, Alsancak, Örnek Sokak 10', 35000, '5553456789', 1),
  ('Çelik', 'Fatma', 'Bursa, Osmangazi, Örnek Mahalle 3', 16000, '5554567890', 2),
  ('Aydın', 'Ali', 'Adana, Seyhan, Örnek Cadde 7', 1000, '5555678901', 3),
  ('Öztürk', 'Zeynep', 'Antalya, Lara, Örnek Sokak 15', 7000, '5556789012', 4),
  ('Arslan', 'Kemal', 'Gaziantep, Şehitkamil, Örnek Mahalle 8', 27000, '5557890123', NULL),
  ('Yıldırım', 'Hakan', 'Mersin, Toros, Örnek Cadde 12', 33000, '5558901234', 7),
  ('Şahin', 'Selin', 'Eskişehir, Odunpazarı, Örnek Sokak 20', 26000, '5559012345', 2),
  ('Güneş', 'Emre', 'Konya, Selçuklu, Örnek Cadde 25', 42000, '5550123456', 5);


insert into facilities (facname, membercost, guestcost, initialoutlay, monthlymaintenance)
values
  ('Yüzme Havuzu - VIP', 20.00, 35.00, 700.00, 70.00),
  ('Tenis Kortu - Açık Alan', 7.00, 17.00, 350.00, 32.00),
  ('Spor Salonu - Premium', 10.00, 22.00, 600.00, 60.00),
  ('Sauna - Özel', 9.00, 15.00, 280.00, 30.00),
  ('Yoga Salonu - Grup Dersi', 8.00, 16.00, 400.00, 38.00),
  ('Bilardo Salonu - VIP', 6.00, 12.00, 250.00, 25.00);

insert into facilities (facid, facname, membercost, guestcost, initialoutlay, monthlymaintenance)
values
  (1, 'Yüzme Havuzu - VIP', 12.00, 22.00, 550.00, 55.00),
  (2, 'Tenis Kortu - Açık Alan', 6.00, 16.00, 320.00, 35.00)
on conflict (facid) do update
  set membercost = EXCLUDED.membercost,
      guestcost = EXCLUDED.guestcost,
      initialoutlay = EXCLUDED.initialoutlay,
      monthlymaintenance = EXCLUDED.monthlymaintenance;

select * from facilities

insert into bookings (facid, memid, starttime, slots)
values
  (1, 2, '2025-03-01 10:00:00', 2),  -- Mehmet, Yüzme Havuzu'nu 2 saat rezerve etti
  (2, 3, '2025-03-02 14:00:00', 1),  -- Ayşe, Tenis Kortu'nu 1 saat rezerve etti
  (3, 4, '2025-03-03 09:00:00', 3),  -- Fatma, Spor Salonu'nu 3 saat rezerve etti
  (4, 5, '2025-03-04 18:00:00', 2),  -- Ali, Sauna'yı 2 saat rezerve etti
  (5, 6, '2025-03-05 08:00:00', 1),  -- Zeynep, Yoga Salonu'nu 1 saat rezerve etti
  (6, 7, '2025-03-06 16:00:00', 2),  -- Kemal, Bilardo Salonu'nu 2 saat rezerve etti
  (1, 8, '2025-03-07 11:00:00', 1),  -- Hakan, Yüzme Havuzu'nu 1 saat rezerve etti
  (2, 9, '2025-03-08 15:00:00', 2),  -- Selin, Tenis Kortu'nu 2 saat rezerve etti
  (3, 10, '2025-03-09 07:00:00', 3), -- Emre, Spor Salonu'nu 3 saat rezerve etti
  (4, 1, '2025-03-10 20:00:00', 1);  -- Ahmet, Sauna'yı 1 saat rezerve etti



--How can you produce a list of facilities that charge a fee to members?
select * from facilities where membercost>0

--How can you produce a list of facilities that charge a fee to members, 
--and that fee is less than 1/4th of the monthly maintenance cost? 
--Return the facid, facility name, member cost, and monthly maintenance of the facilities in question.
select facid, facname, membercost, monthlymaintenance 
     from facilities
     where 
         membercost>0 and (membercost<monthlymaintenance/4);


--How can you produce a list of all facilities with the word 'Tenis' in their name?
select * 
from facilities
where facname like '%Tenis%'


--How can you retrieve the details of facilities with ID 1 and 5? 
--Try to do it without using the OR operator.
select * 
from facilities
where
   facid in (1,5)


--How can you produce a list of facilities, with each labelled as 'ucuz' or 'pahalı' depending on if their monthly maintenance cost is more than $30? 
--Return the name and monthly maintenance of the facilities in question.
select facname,
      case 
	       when monthlymaintenance>30 then 'pahalı'
	       else 'ucuz'
	  end  as cost 
from facilities;	  

--How can you produce a list of members who joined after the start of February 2025? 
--Return the memid, surname, firstname, and joindate of the members in question.
select memid, surname, firstname, joindate 
from members
where
   joindate>='2025-02-01';


--How can you produce an ordered list of the first 10 surnames in the members table? 
--The list must not contain duplicates.
select distinct surname --aynı soyisimden birkaç tane varsa, bir tane döndürür.
from members
order by surname
limit 10;

--You, for some reason, want a combined list of all surnames and all facility names. Yes, this is a contrived example :-).
--Produce that list!
select surname
from members
union --iki veya daha fazla SELECT sorgusunun sonucunu birleştirmek için kullanılır. Tekrar eden (duplicate) satırları otomatik olarak kaldırır.
select facname
from facilities


--You'd like to get the signup date of your last member. How can you retrieve this information?
select max(joindate) as latest
from members


insert into members (surname, firstname, address, zipcode, telephone, recommendedby, joindate)  
values ('Kara', 'Elif', 'Ankara, Çankaya Mahallesi, Örnek Sokak 2', 06420, '5324567890', NULL, current_timestamp);


--You'd like to get the first and last name of the last member(s) who signed up - not just the date. How can you do that?
select firstname, surname, joindate
from members
where
joindate= (select max(joindate)from members)

