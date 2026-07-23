--PROCEDURA(1) DODAJĄCA WYPOŻYCZENIE KSIĄŻKI DO HISTORI WYPOŻYCZEŃ

CREATE OR REPLACE PROCEDURE addBookBorrow
(
    p_id_ksiazki NUMBER,
    p_id_czytelnika NUMBER,
    p_data_wyp DATE
)
AS
 --definicja zmiennych lokalnych
    v_id_ksiazki ksiazki.id_ksiazki%TYPE;
    v_id_czytelnika czytelnicy.id_czytelnika%TYPE;
    v_blokada czytelnicy.blokada%TYPE;
    v_data_zwrotu historia_wyp.plan_data_zwrotu%TYPE; 
    v_old_liczba_wyp_ksiazek czytelnicy.liczba_wyp_ksiazek%TYPE;
    v_wypozyczona ksiazki.wypozyczona%TYPE;

BEGIN
        
    SELECT id_ksiazki INTO v_id_ksiazki
    FROM ksiazki WHERE id_ksiazki LIKE p_id_ksiazki;
        
    SELECT id_czytelnika INTO v_id_czytelnika
    FROM czytelnicy WHERE id_czytelnika LIKE p_id_czytelnika;
    
    SELECT Add_Months(p_data_wyp, 3) INTO v_data_zwrotu
    FROM dual;
    
    SELECT liczba_wyp_ksiazek INTO v_old_liczba_wyp_ksiazek
    FROM czytelnicy WHERE id_czytelnika LIKE p_id_czytelnika;
    
    SELECT wypozyczona INTO v_wypozyczona
    FROM ksiazki WHERE id_ksiazki LIKE p_id_ksiazki;
    
    FOR rekord IN (SELECT id_ksiazki, id_czytelnika, plan_data_zwrotu, data_zwrotu, przetrzymana
                 FROM historia_wyp 
                 WHERE (id_czytelnika = v_id_czytelnika AND data_zwrotu IS NULL AND SYSDATE>plan_data_zwrotu))
    LOOP
        UPDATE historia_wyp SET przetrzymana = 1 WHERE id_ksiazki = rekord.id_ksiazki AND id_czytelnika = rekord.id_czytelnika;
        UPDATE czytelnicy SET blokada = 1 WHERE id_czytelnika = rekord.id_czytelnika;
    END LOOP; 
    
   
    
    SELECT blokada INTO v_blokada
    FROM czytelnicy WHERE id_czytelnika LIKE v_id_czytelnika;
        
    IF v_blokada = 0  AND v_wypozyczona = 0 THEN
        
        INSERT INTO historia_wyp VALUES (v_id_ksiazki, v_id_czytelnika, p_data_wyp, v_data_zwrotu, NULL, 0);
        UPDATE czytelnicy SET liczba_wyp_ksiazek = v_old_liczba_wyp_ksiazek+1 WHERE id_czytelnika=v_id_czytelnika;
        UPDATE ksiazki SET wypozyczona = 1 where id_ksiazki = v_id_ksiazki;
    
    ELSE 
        dbms_output.put_line ('Ten czytelnik ma zablokowane konto lub książka jest wypozyczona');
    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
    dbms_output.put_line ('Sprawdz ponownie id ksiazki, lub id czytelnika');
END addBookBorrow;   

-----WYZWALACZ(1) USTAWIAJĄCY BLOKADĘ GDY CZYTELNIK MA WYPOŻYCZONE 3 KSIĄŻKI W TYM SAMYM CZASIE

CREATE OR REPLACE TRIGGER set_blokada
AFTER 
INSERT ON historia_wyp
FOR EACH ROW
DECLARE
licz_ksiaz NUMBER;
BEGIN
    SELECT liczba_wyp_ksiazek INTO licz_ksiaz FROM czytelnicy WHERE id_czytelnika = :new.id_czytelnika;
    
    IF licz_ksiaz = 2 THEN
    UPDATE czytelnicy SET blokada = 1 WHERE id_czytelnika = :new.id_czytelnika; 
    END IF;
END;

-----PROCEDURA(2) POZWALAJĄCA DODAĆ KSIĄŻKĘ DO BIBLIOTEKI
CREATE OR REPLACE PROCEDURE addBook
(
    p_ISBN          	NUMBER,
    p_TYTUL	            VARCHAR2,
    p_IMIE_AUTORA	    VARCHAR2,
    p_NAZWISKO_AUTORA   VARCHAR2,
    p_NAZWA_WYDAWNICTWA	VARCHAR2,
    p_NAZWA_DZIALU	    VARCHAR2
)
AS
 --definicja zmiennych lokalnych
    v_id_autora autorzy.id_autora%TYPE;
    v_id_wydawnictwa wydawnictwa.id_wydawnictwa%TYPE;
    v_id_dzialu dzialy.id_dzialu%TYPE;
    
BEGIN
        
    SELECT id_autora INTO v_id_autora
    FROM autorzy WHERE (imie LIKE p_imie_autora AND nazwisko like p_nazwisko_autora);
        
    SELECT id_wydawnictwa INTO v_id_wydawnictwa
    FROM wydawnictwa WHERE nazwa LIKE p_nazwa_wydawnictwa;
    
    SELECT id_dzialu INTO v_id_dzialu
    FROM dzialy WHERE nazwa LIKE p_nazwa_dzialu;
    
    INSERT INTO ksiazki VALUES (9999, p_ISBN, p_tytul, v_id_autora, v_id_wydawnictwa, v_id_dzialu, 0);
        
EXCEPTION
    WHEN NO_DATA_FOUND THEN
    dbms_output.put_line ('Sprawdz ponownie wprowadzone dane');
END addBook; 

-----WYZWALACZ(2) KTÓRY AUTOMATYCZNIE USTAWIA ID DODANEJ KSIĄŻKI

CREATE OR REPLACE TRIGGER set_id_ksiazki
BEFORE 
INSERT ON ksiazki
FOR EACH ROW
DECLARE
new_id NUMBER;
BEGIN
    SELECT max(id_ksiazki)+1 INTO new_id FROM ksiazki;
    :new.id_ksiazki := new_id;
END;

----PROCEDURA(3) UMOŻLIWIAJĄCA "ZWRÓCENIE KSIĄŻKI DO BIBLIOTEKI"

CREATE OR REPLACE PROCEDURE returnBook
(
    p_id_ksiazki NUMBER,
    p_id_czytelnika NUMBER
)
AS
 --definicja zmiennych lokalnych
    v_id_ksiazki ksiazki.id_ksiazki%TYPE;
    v_id_czytelnika czytelnicy.id_czytelnika%TYPE;
    v_old_liczba_wyp_ksiazek czytelnicy.liczba_wyp_ksiazek%TYPE;

BEGIN
        
    SELECT id_ksiazki INTO v_id_ksiazki
    FROM ksiazki WHERE id_ksiazki LIKE p_id_ksiazki;
        
    SELECT id_czytelnika INTO v_id_czytelnika
    FROM czytelnicy WHERE id_czytelnika LIKE p_id_czytelnika;
    
    SELECT liczba_wyp_ksiazek INTO v_old_liczba_wyp_ksiazek
    FROM czytelnicy WHERE id_czytelnika LIKE p_id_czytelnika;
    
    UPDATE historia_wyp SET przetrzymana = 0 WHERE id_ksiazki = v_id_ksiazki AND id_czytelnika = v_id_czytelnika;
    UPDATE historia_wyp SET data_zwrotu = SYSDATE WHERE id_ksiazki = v_id_ksiazki AND id_czytelnika = v_id_czytelnika;
    UPDATE czytelnicy SET blokada = 0 WHERE id_czytelnika = v_id_czytelnika;    
    UPDATE czytelnicy SET liczba_wyp_ksiazek = v_old_liczba_wyp_ksiazek-1 WHERE id_czytelnika=v_id_czytelnika;
    UPDATE ksiazki SET wypozyczona = 0 where id_ksiazki = v_id_ksiazki;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
    dbms_output.put_line ('Sprawdz ponownie id ksiazki, lub id czytelnika');
END returnBook;   

-----FUNKCJA(1) WYŚWIETLAJĄCA CZYTELNIKA KTÓRY WYPOŻYCZYŁ NAJWIĘCEJ KSIĄŻEK W CIĄGU OSTATNICH 3 MIESIĘCY

CREATE OR REPLACE FUNCTION bestReaderInLastQuater
RETURN VARCHAR2
AS
CURSOR c IS
    SELECT czytelnicy.id_czytelnika as id_czyt, count(*) as suma
    FROM czytelnicy
    JOIN historia_wyp ON czytelnicy.id_czytelnika = historia_wyp.id_czytelnika
    WHERE historia_wyp.data_wyp >= Add_Months(SYSDATE, -3) AND historia_wyp.data_zwrotu<= SYSDATE
    GROUP BY czytelnicy.id_czytelnika;
    
    max_liczba czytelnicy.liczba_wyp_ksiazek%type := -100;
    id_best_reader czytelnicy.id_czytelnika%type;
    best_reader_dane VARCHAR2(100 byte);
BEGIN
    FOR i IN c
    LOOP
        IF i.suma > max_liczba THEN
            max_liczba := i.suma;
            id_best_reader := i.id_czyt;     
        END IF;
    END LOOP;
    
    SELECT concat(imie, nazwisko) INTO best_reader_dane
    From czytelnicy WHERE id_czytelnika = id_best_reader;
    
    RETURN best_reader_dane;
END;

-----FUNKCJA(2) WYŚWIETLAJĄCA REKOMENDOWANĄ KSIĄŻKĘ DO WYPOŻYCZENIA DLA DANEGO CZYTELNIKA

CREATE OR REPLACE FUNCTION recomenadtionFor
(
    p_id_czytelnika NUMBER
)
RETURN VARCHAR2
AS    
    v_id_najczesciej_czyt_dzialu dzialy.id_dzialu%TYPE; 
    v_id_ksiazki ksiazki.id_ksiazki%type;
    v_sprawdzenie NUMBER(4);
    v_wybor VARCHAR2(100 byte);
    i NUMBER := 1; 
    
BEGIN
    SELECT Stats_mode(d.id_dzialu) INTO v_id_najczesciej_czyt_dzialu
    FROM czytelnicy c
    JOIN historia_wyp h ON (c.id_czytelnika = h.id_czytelnika)
    JOIN ksiazki k ON (h.id_ksiazki = k.id_ksiazki)
    JOIN dzialy d ON (d.id_dzialu = k.id_dzialu)
    WHERE c.id_czytelnika = p_id_czytelnika; 
    
    IF v_id_najczesciej_czyt_dzialu IS NULL THEN
        SELECT id_ksiazki INTO v_id_ksiazki
        FROM (SELECT id_ksiazki FROM ksiazki  
        ORDER BY dbms_random.value)  
        WHERE rownum = 1;
    ELSE
        LOOP  
        EXIT WHEN i=10;  
        SELECT id_ksiazki into v_id_ksiazki
          FROM (SELECT id_ksiazki FROM ksiazki 
          WHERE id_dzialu = v_id_najczesciej_czyt_dzialu
          ORDER BY dbms_random.value)
          WHERE rownum = 1;
        
          SELECT count(*) INTO v_sprawdzenie
          FROM czytelnicy c
          JOIN historia_wyp h ON (c.id_czytelnika = h.id_czytelnika)
          JOIN ksiazki k ON (h.id_ksiazki = k.id_ksiazki)
          JOIN dzialy d ON (d.id_dzialu = k.id_dzialu)
          WHERE c.id_czytelnika = p_id_czytelnika and k.id_dzialu =  v_id_najczesciej_czyt_dzialu and k.id_ksiazki = v_id_ksiazki; 
          
          IF v_sprawdzenie = 0 THEN
            i := 10;
          END IF;  
        END LOOP;  
    END IF;
    
    SELECT (' ID ksiazki:' || to_char(id_ksiazki) || ' Tytul: ' || tytul) INTO v_wybor
    From ksiazki WHERE id_ksiazki = v_id_ksiazki;
    
    RETURN v_wybor;
END;

-----FUNKCJA(3) WYŚWIETLAJĄCA AUTORA KTÓRY ODNOTOWAŁ NAJWIĘKSZY PRZYROST WYPOŻYCZEŃ JEGO KSIĄŻEK W STOSUNKU DO POPRZEDNIEGO MIESIĄCA

CREATE OR REPLACE FUNCTION biggestIncrementation
RETURN VARCHAR2
AS
CURSOR c IS
    select a.id_autora as id_a, sum(case EXTRACT(month FROM h.data_wyp) when EXTRACT(month FROM SYSDATE) then 1 else 0 end) as mies_obecny, sum(case EXTRACT(month FROM h.data_wyp) when EXTRACT(month FROM Add_Months(SYSDATE, -1)) then 1 else 0 end) as mies_poprz
    FROM autorzy a
    JOIN ksiazki k ON (k.id_autora = a.id_autora)
    JOIN historia_wyp h ON (h.id_ksiazki = k.id_ksiazki)
    GROUP BY a.id_autora;
    
    max_przyrost NUMBER(7) := -100;
    new_przyrost NUMBER(7);
    id_najlepszy_autor autorzy.id_autora%type;
    najlepszy_autor_dane VARCHAR2(100 byte);
    
BEGIN
    FOR i IN c
    LOOP
      IF i.mies_poprz = 0 THEN
	i.mies_poprz := 1;
	i.mies_obecny := i.mies_obecny + 1;
      END IF;

      new_przyrost := (((i.mies_obecny - i.mies_poprz)/i.mies_poprz)-1)*100;
      IF new_przyrost > max_przyrost THEN
            max_przyrost := new_przyrost;
            id_najlepszy_autor := i.id_a;     
        END IF;
    END LOOP;
    
    SELECT (imie || ' ' || nazwisko) INTO  najlepszy_autor_dane 
    From autorzy WHERE id_autora = id_najlepszy_autor;
    
    RETURN najlepszy_autor_dane;
END;

