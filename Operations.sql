CREATE OR REPLACE PROCEDURE accept_payment --принять платеж
    (account IN INTEGER, value_$ IN REAL, period IN DATE) 
    AS
    max_payment_id_value INTEGER;
    account_bill_id_value INTEGER;
    
    cursor max_payment_id is
    SELECT MAX(payment_id) FROM payment;
    
    cursor account_bill_id is
    SELECT bill_id FROM bill
        INNER JOIN period ON period.period_id = bill.period_id
        WHERE account = bill.account_id 
        AND period = period.fin_period
        AND ROWNUM = 1;
    

    BEGIN
        OPEN max_payment_id;
        FETCH max_payment_id into max_payment_id_value;
        
        OPEN account_bill_id;
        FETCH account_bill_id into account_bill_id_value;
        
        INSERT INTO payment (payment_id, bill_id, val_$) VALUES (
            max_payment_id_value + 1,
            account_bill_id_value,
            value_$
        );
        
        RETURN;
    END;
     
CREATE OR REPLACE PROCEDURE fill_balances_zero --закрыть период нулевыми балансами
    (account IN INTEGER, period IN DATE)
    AS
    
    max_service_id_value INTEGER;
    current_bill_id_value INTEGER;
    
    cursor current_bill_id is
    SELECT bill_id FROM bill
        INNER JOIN period ON period.period_id = bill.period_id
        WHERE account = bill.account_id 
        AND period = period.fin_period; 
    
    cursor max_service_id is
    SELECT max(service_id) FROM bill_det;
    
    BEGIN
        
        
        OPEN max_service_id;
        FETCH max_service_id INTO max_service_id_value;
        
        OPEN current_bill_id;
        FETCH current_bill_id INTO current_bill_id_value;
        
        DELETE FROM subaccount
        WHERE subaccount.account_id = account
        AND current_bill_id_value = subaccount.bill_id;
        
        FOR i IN 1 .. max_service_id_value
        LOOP
            INSERT INTO subaccount VALUES (account, current_bill_id_value, i, 0);
        END LOOP;
    END;

CREATE OR REPLACE PROCEDURE fill_balances --заполнение балансов корректировками и начислениями
    (account IN INTEGER, period IN DATE)
    AS

    BEGIN
        FOR adj_data_cur IN (
        SELECT adj.SERVICE_ID, adj.VAL_$, bill.bill_id AS bill_id_
        FROM adj 
        INNER JOIN bill ON bill.bill_id = adj.bill_id
        INNER JOIN period ON bill.period_id = period.period_id
        WHERE account = bill.account_id
        AND period.fin_period = period) 
        LOOP
            UPDATE subaccount
            SET val_$ = val_$ + adj_data_cur.val_$
            WHERE account_id = account
            AND service_id = adj_data_cur.service_id
            AND bill_id = adj_data_cur.bill_id_;
        END LOOP;
        
        FOR bill_det_data_cur IN (
        SELECT bill_det.service_id, bill_det.val_$, period.fin_period 
        FROM bill_det 
        INNER JOIN bill ON bill.bill_id = bill_det.bill_id
        INNER JOIN period ON period.period_id = bill.period_id
        WHERE bill.account_id = account 
        AND period.fin_period = period)
        LOOP
            UPDATE subaccount
            SET val_$ = val_$ + bill_det_data_cur.val_$
            WHERE account_id = account
            AND service_id = bill_det_data_cur.service_id
            AND period = bill_det_data_cur.fin_period;
        END LOOP;
 
    END; 
    
CREATE OR REPLACE PROCEDURE payment_distribution --разноска платежей пропорционально начислениям
(account IN INTEGER, period IN DATE)
    AS
    sum_tmp numeric(15,2);
    bill_id_ INTEGER;
    
    cursor bill_id_cur is
    SELECT bill_id
        FROM bill
        INNER JOIN period per ON per.period_id = bill.period_id
        WHERE account_id = account
        AND ROWNUM = 1
        AND per.fin_period = period;
        
    cursor sum_tmp_cur is
    SELECT SUM(val_$) FROM (
        SELECT * FROM subaccount
        WHERE val_$ > 0
        AND account_id = account
        AND bill_id = bill_id_);
    
    BEGIN
       
    OPEN bill_id_cur;
    FETCH bill_id_cur INTO bill_id_;
    
    FOR payment_cur IN (
    SELECT *
    FROM payment
    WHERE bill_id = bill_id_)
    LOOP
        OPEN sum_tmp_cur;
        FETCH sum_tmp_cur INTO sum_tmp;
        IF sum_tmp > 0 THEN
            FOR subacc_cur IN (
            SELECT *
            FROM subaccount
            WHERE bill_id = bill_id_
            AND account_id = account
            AND val_$ > 0)
            LOOP
                UPDATE subaccount
                SET val_$ = val_$ + (payment_cur.val_$ * (subacc_cur.val_$ / sum_tmp))
                WHERE bill_id = subacc_cur.bill_id
                AND subacc_cur.service_id = service_id;
                --INSERT INTO Testt VALUES (1);
                --INSERT INTO Testt VALUES (payment_cur.val_$ * (subacc_cur.val_$ / sum_tmp));
            END LOOP;
        ELSE    
            UPDATE subaccount
            SET val_$ = val_$ + payment_cur.val_$
            WHERE val_$ = (SELECT MAX(val_$) FROM subaccount WHERE bill_id = bill_id_);
            --INSERT INTO Testt VALUES (2);
            --INSERT INTO Testt VALUES (payment_cur.val_$);
        END IF;
        CLOSE sum_tmp_cur;
        
    END LOOP;
    CLOSE bill_id_cur;
    
    END;
    
CREATE OR REPLACE PROCEDURE prev_balance_add --добавление балансов предыдущего расчитанного месяца в указанный
(account IN INTEGER, period IN DATE)
    AS
    subacc_value numeric(20,10);
    CURSOR subacc_cursor (service_id_param IN INTEGER) IS
    SELECT val_$ FROM subaccount subacc
    INNER JOIN bill ON bill.bill_id = subacc.bill_id AND bill.account_id = account
    INNER JOIN period per ON per.period_id = bill.period_id
    WHERE per.fin_period < period
    AND subacc.service_id = service_id_param
    AND ROWNUM = 1
    ORDER BY per.fin_period;
    
    BEGIN
       
    FOR subacc_cur IN (
    SELECT subaccount.* FROM subaccount
    INNER JOIN bill ON bill.bill_id = subaccount.bill_id AND bill.account_id = account
    INNER JOIN period per ON per.period_id = bill.period_id
    WHERE per.fin_period = period)
    LOOP
        OPEN subacc_cursor(subacc_cur.service_id);
        FETCH subacc_cursor INTO subacc_value;
        INSERT INTO testt VALUES (subacc_value);
        IF subacc_value IS NOT NULL THEN
            UPDATE subaccount
            SET val_$ = val_$ + subacc_value
            WHERE subacc_cur.bill_id = bill_id
            AND subaccount.service_id = subacc_cur.service_id;
        CLOSE subacc_cursor;
        ELSE
        CLOSE subacc_cursor;
        CONTINUE;
        END IF;
        
        
    END LOOP;
    END;
    
CREATE OR REPLACE PROCEDURE close_month_for_one_account --закрытие месяца по одному счету
(account IN INTEGER, period IN DATE)
    AS 
BEGIN
    fill_balances_zero(account, period);
    fill_balances(account, period);
    payment_distribution(account, period);
    prev_balance_add(account, period);
END;

CREATE OR REPLACE PROCEDURE close_month_for_all --закрытие месяца по всем счетам
(period IN DATE)
    AS
BEGIN
    FOR acc_cur IN (
    SELECT *
    FROM account
    )
    LOOP
    close_month_for_one_account(acc_cur.account_id, period);
    END LOOP;
END;
    