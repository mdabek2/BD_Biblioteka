--PROCEDURA(1) DODAJĄCA WYPOŻYCZENIE KSIĄŻKI DO HISTORI WYPOŻYCZEŃ
BEGIN
    addbookborrow(59, 1, '20/05/11');
END;

--- jak widać, zwiększyła się liczba wypożyczonych książek u czytelnika nr 1:
select * from czytelnicy;

--- książka została wypożyczona:
select * from ksiazki where id_ksiazki = 59;

--- wypożyczenie zostało dodane do historii wypożyczeń:
select * from historia_wyp;

-- procedura ta blokuje też wypożyczenie kolejnej książki jeżeli jedna już jest już przetrzymana przez danego użytkownika:
BEGIN
    addbookborrow(34, 2, '20/02/11');
END;

--- przy próbie wypozyczenia kolejnej ksiązki procedura rozpoznaje że jedna z książek jest przetrzymana i blokuje konto
BEGIN
    addbookborrow(35, 2, '20/04/11');
END;

--- jak widać, konto nr 2 jest zablokowane:
select * from czytelnicy;

-- wypożyczenie książki nr 35 nie zostało dodane do historii wypożyczeń, a książka nr 34 uznzna za przetrzymaną
select * from historia_wyp;



-----WYZWALACZ(1) USTAWIAJĄCY BLOKADĘ GDY CZYTELNIK MA WYPOŻYCZONE 3 KSIĄŻKI W TYM SAMYM CZASIE
BEGIN
    addbookborrow(60, 1, '20/06/01');
    addbookborrow(61, 1, '20/06/01');
END;

--- nie da się wypożyczyć czwartej ksiażki:
BEGIN
   addbookborrow(62, 1, '20/06/01');
END;

--- jak widać, konto nr 1 jest zablokowane:
select * from czytelnicy;

-----PROCEDURA(2) POZWALAJĄCA DODAĆ KSIĄŻKĘ DO BIBLIOTEKI i WYZWALACZ(2) KTÓRY AUTOMATYCZNIE USTAWIA ID DODANEJ KSIĄŻKI

--- procedura automatycznie pobiera dane z tabeli autorzy, wydawnictwa, dzialy i sprawdza czy te podane są już wprowadzone do systemu
BEGIN
   addbook(9788375362879, 'Miedzianka. Historia znikania', 'Filip', 'Springer', 'Czarne', 'literatura_faktu');
END;

--- książka została dodana z automatycznie ustawionym przez wyzwalacz ID:
select * from ksiazki;

----PROCEDURA(3) UMOŻLIWIAJĄCA "ZWRÓCENIE KSIĄŻKI DO BIBLIOTEKI"
BEGIN
   returnbook(61, 1);
END;

-- ksiazka juz nie jest wypozyczona, w historii wypozyczen został zanotowany zwrot, a onto czytelnika odblokowane
select * from ksiazki where id_ksiazki = 61;
select * from historia_wyp where id_czytelnika = 1;
select * from czytelnicy where id_czytelnika = 1;

-----FUNKCJA(1) WYŚWIETLAJĄCA CZYTELNIKA KTÓRY WYPOŻYCZYŁ NAJWIĘCEJ KSIĄŻEK W CIĄGU OSTATNICH 3 MIESIĘCY

BEGIN
   dbms_output.put_line (bestreaderinlastquater());
END;

-----FUNKCJA(2) WYŚWIETLAJĄCA REKOMENDOWANĄ KSIĄŻKĘ DO WYPOŻYCZENIA DLA DANEGO CZYTELNIKA

---- książka wyświetlana jest na podstawie działu z którego czytelnink wypożyczył najwięcej książek, jeśli nie wypożyczył żadnej książki, polecana jest mu losowa

BEGIN
   dbms_output.put_line (recomenadtionfor(1));
END;

SELECT Stats_mode(d.id_dzialu)
    FROM czytelnicy c
    JOIN historia_wyp h ON (c.id_czytelnika = h.id_czytelnika)
    JOIN ksiazki k ON (h.id_ksiazki = k.id_ksiazki)
    JOIN dzialy d ON (d.id_dzialu = k.id_dzialu)
    WHERE c.id_czytelnika = 1; 
    
--- aby sprawdzić poprawność działania procedury, należy sprawdzić w tabeli książki czy id działu polecanej książki jest takie jak wynik powyższego zapytania SELECT

    
BEGIN
   dbms_output.put_line (recomenadtionfor(2));
END;

SELECT Stats_mode(d.id_dzialu)
    FROM czytelnicy c
    JOIN historia_wyp h ON (c.id_czytelnika = h.id_czytelnika)
    JOIN ksiazki k ON (h.id_ksiazki = k.id_ksiazki)
    JOIN dzialy d ON (d.id_dzialu = k.id_dzialu)
    WHERE c.id_czytelnika = 2; 

--- przykład działania funkcji dla czytelnika który nic jeszcze nie wypożyczył:

BEGIN
   dbms_output.put_line (recomenadtionfor(8));
END;

-----FUNKCJA(3) WYŚWIETLAJĄCA AUTORA KTÓRY ODNOTOWAŁ NAJWIĘKSZY PRZYROST WYPOŻYCZEŃ JEGO KSIĄŻEK W STOSUNKU DO POPRZEDNIEGO MIESIĄCA

BEGIN
   dbms_output.put_line (biggestincrementation());
END;

