--- (1) Wybrać tytuł i autora książki, która była najczęściej wypożyczana w 2019 roku.      
SELECT k.tytul, a.imie, a.nazwisko
    FROM ksiazki k JOIN autorzy a ON (k.id_autora=a.id_autora) 
        WHERE k.id_ksiazki = (SELECT Stats_mode(id_ksiazki)
                              FROM historia_wyp 
                              WHERE EXTRACT(year FROM data_wyp) = 2019);
    

---- (2) Z którego działu książki najczęściej wypożyczane były w latach 2018, 2019.

SELECT dzial
    FROM (SELECT d.id_dzialu as dzial
            FROM dzialy d JOIN ksiazki k ON (k.id_dzialu=d.id_dzialu) JOIN historia_wyp h ON (k.id_ksiazki = h.id_ksiazki)
                WHERE  EXTRACT(year FROM data_wyp) = 2018 OR EXTRACT(year FROM data_wyp) = 2019
                    GROUP BY d.id_dzialu
                        ORDER BY count(*) desc)
        WHERE rownum = 1;
                
                  
---- (3) Podać działy, z których w roku 2020 wypożyczono więcej niż 5 różnych książek.

SELECT d.nazwa, count(distinct k.tytul) as liczba
    FROM ksiazki k JOIN dzialy d on k.id_dzialu=d.id_dzialu join historia_wyp h on k.id_ksiazki=h.id_ksiazki
        WHERE EXTRACT(year FROM data_wyp) = 2020
            GROUP BY d.nazwa
                HAVING COUNT(distinct k.tytul)>5;

--- (4) Który czytelnik najczęściej przetrzymywał książki w latach 2018-2020?
SELECT czytelnik 
     FROM (SELECT h.id_czytelnika as czytelnik, count(*) as il
            FROM historia_wyp h join czytelnicy c on h.id_czytelnika= c.id_czytelnika
                WHERE (h.data_zwrotu > h.plan_data_zwrotu or h.przetrzymana=1 ) AND
                EXTRACT(year FROM data_wyp)>2017 and EXTRACT(year FROM data_wyp)<=2020
                    group by h.id_czytelnika 
                        order by count(*) desc)
             WHERE rownum = 1;

--- (5) Podać wydawców książek danego autora.

SELECT DISTINCT a.imie, a.nazwisko, w.nazwa 
    FROM ksiazki k join autorzy a on k.id_autora=a.id_autora JOIN wydawnictwa w on k.id_wydawnictwa= w.id_wydawnictwa
        ORDER BY 1,2,3;

--- (6) Przez jakie wydawnictwa wydawane są poszczególne książki?

SELECT DISTINCT k.tytul, w.nazwa 
    FROM ksiazki k JOIN wydawnictwa w on k.id_wydawnictwa= w.id_wydawnictwa
        ORDER BY k.tytul, w.nazwa;

--- (7) Tytuły książek, które nigdy nie były wypożyczone.

SELECT tytul 
    FROM ksiazki
        WHERE id_ksiazki not in (select distinct id_ksiazki from historia_wyp);

--- (8) Ile jest aktualnie wypożyczonych książek z poszczególnych działów?

SELECT d.nazwa, count(*) as ilosc
    FROM ksiazki k join dzialy d on k.id_dzialu=d.id_dzialu join historia_wyp h on k.id_ksiazki=h.id_ksiazki
            WHERE k.wypozyczona=1
                GROUP BY d.nazwa
                    ORDER by d.nazwa;
                    
--- (9) Gdzie znajduje się najczesciej wypozyczana ksiazka

SELECT d.reg_pocz as regal_poczatkowy, d.reg_kon as regal_koncowy 
    FROM dzialy d join ksiazki k on (k.id_dzialu = d.id_dzialu)
        WHERE k.id_ksiazki = (SELECT Stats_mode(id_ksiazki) FROM historia_wyp);

--- (10) Ile średnio ksiazek wypozyczyl czytelnik biblioteki

SELECT avg(count(*))
    from historia_wyp
    group by id_czytelnika;
        
        
