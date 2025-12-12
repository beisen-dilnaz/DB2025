-- helper function
CREATE OR REPLACE FUNCTION public.get_rate(
    p_from CHAR(3),
    p_to   CHAR(3),
    p_at   TIMESTAMPTZ DEFAULT clock_timestamp()
) RETURNS NUMERIC(18,8)
LANGUAGE plpgsql
AS $$
DECLARE
    r NUMERIC(18,8);
BEGIN
    IF p_from = p_to THEN
        RETURN 1.0;
    END IF;

    SELECT rate INTO r
    FROM public.exchange_rates
    WHERE from_currency = p_from
      AND to_currency   = p_to
      AND p_at >= valid_from AND p_at < valid_to
    ORDER BY valid_from DESC
    LIMIT 1;

    IF r IS NOT NULL THEN
        RETURN r;
    END IF;

    SELECT (1.0 / rate) INTO r
    FROM public.exchange_rates
    WHERE from_currency = p_to
      AND to_currency   = p_from
      AND p_at >= valid_from AND p_at < valid_to
    ORDER BY valid_from DESC
    LIMIT 1;

    IF r IS NOT NULL THEN
        RETURN r;
    END IF;

    IF p_from <> 'KZT' AND p_to <> 'KZT' THEN
        RETURN public.get_rate(p_from, 'KZT', p_at) * public.get_rate('KZT', p_to, p_at);
    END IF;

    RAISE EXCEPTION 'Rate not found for % -> %', p_from, p_to;
END;
$$;

-- TASK 1
CREATE OR REPLACE PROCEDURE public.process_transfer(
    IN  p_from_acc VARCHAR,
    IN  p_to_acc   VARCHAR,
    IN  p_amount   NUMERIC(18,2),
    IN  p_curr     CHAR(3),
    IN  p_desc     TEXT,
    OUT success    BOOLEAN,
    OUT err_code   TEXT,
    OUT err_msg    TEXT,
    OUT tx_id      BIGINT
)
LANGUAGE plpgsql
AS $$
DECLARE
    a_from public.accounts%ROWTYPE;
    a_to   public.accounts%ROWTYPE;
    c_from public.customers%ROWTYPE;

    rate_to_kzt NUMERIC(18,8);
    amount_kzt  NUMERIC(18,2);
    debit_from  NUMERIC(18,2);
    credit_to   NUMERIC(18,2);

    used_today_kzt NUMERIC(18,2);
    lock1 BIGINT;
    lock2 BIGINT;
BEGIN
    success := FALSE;
    err_code := NULL;
    err_msg := NULL;
    tx_id := NULL;

    IF p_amount IS NULL OR p_amount <= 0 THEN
        err_code := 'E01';
        err_msg := 'Amount must be positive';
        INSERT INTO public.audit_log(table_name, record_id, action, old_values, new_values)
        VALUES ('transactions', NULL, 'INSERT', NULL, jsonb_build_object('fail',true,'code',err_code,'msg',err_msg));
        RETURN;
    END IF;

    SELECT * INTO a_from FROM public.accounts WHERE account_number = p_from_acc;
    IF NOT FOUND THEN
        err_code := 'E02'; err_msg := 'From account not found';
        INSERT INTO public.audit_log(table_name, record_id, action, old_values, new_values)
        VALUES ('transactions', NULL, 'INSERT', NULL, jsonb_build_object('fail',true,'code',err_code,'msg',err_msg,'from',p_from_acc));
        RETURN;
    END IF;

    SELECT * INTO a_to FROM public.accounts WHERE account_number = p_to_acc;
    IF NOT FOUND THEN
        err_code := 'E03'; err_msg := 'To account not found';
        INSERT INTO public.audit_log(table_name, record_id, action, old_values, new_values)
        VALUES ('transactions', NULL, 'INSERT', NULL, jsonb_build_object('fail',true,'code',err_code,'msg',err_msg,'to',p_to_acc));
        RETURN;
    END IF;

    lock1 := LEAST(a_from.account_id, a_to.account_id);
    lock2 := GREATEST(a_from.account_id, a_to.account_id);

    PERFORM 1 FROM public.accounts WHERE account_id = lock1 FOR UPDATE;
    PERFORM 1 FROM public.accounts WHERE account_id = lock2 FOR UPDATE;

    SELECT * INTO a_from FROM public.accounts WHERE account_id = a_from.account_id;
    SELECT * INTO a_to   FROM public.accounts WHERE account_id = a_to.account_id;

    IF NOT a_from.is_active THEN
        err_code := 'E04'; err_msg := 'From account inactive';
        INSERT INTO public.audit_log(table_name, record_id, action, old_values, new_values)
        VALUES ('transactions', NULL, 'INSERT', NULL, jsonb_build_object('fail',true,'code',err_code,'msg',err_msg));
        RETURN;
    END IF;

    IF NOT a_to.is_active THEN
        err_code := 'E05'; err_msg := 'To account inactive';
        INSERT INTO public.audit_log(table_name, record_id, action, old_values, new_values)
        VALUES ('transactions', NULL, 'INSERT', NULL, jsonb_build_object('fail',true,'code',err_code,'msg',err_msg));
        RETURN;
    END IF;

    SELECT * INTO c_from FROM public.customers WHERE customer_id = a_from.customer_id;
    IF c_from.status <> 'active' THEN
        err_code := 'E06'; err_msg := 'Customer blocked/frozen';
        INSERT INTO public.audit_log(table_name, record_id, action, old_values, new_values)
        VALUES ('transactions', NULL, 'INSERT', NULL, jsonb_build_object('fail',true,'code',err_code,'msg',err_msg,'status',c_from.status));
        RETURN;
    END IF;

    BEGIN
        rate_to_kzt := public.get_rate(p_curr, 'KZT', clock_timestamp());
        amount_kzt  := ROUND(p_amount * rate_to_kzt, 2);

        debit_from  := ROUND(p_amount * public.get_rate(p_curr, a_from.currency, clock_timestamp()), 2);
        credit_to   := ROUND(p_amount * public.get_rate(p_curr, a_to.currency,   clock_timestamp()), 2);
    EXCEPTION WHEN OTHERS THEN
        err_code := 'E07'; err_msg := 'FX error: ' || SQLERRM;
        INSERT INTO public.audit_log(table_name, record_id, action, old_values, new_values)
        VALUES ('transactions', NULL, 'INSERT', NULL, jsonb_build_object('fail',true,'code',err_code,'msg',err_msg));
        RETURN;
    END;

    IF a_from.balance < debit_from THEN
        err_code := 'E08'; err_msg := 'Insufficient funds';
        INSERT INTO public.audit_log(table_name, record_id, action, old_values, new_values)
        VALUES ('transactions', NULL, 'INSERT', NULL, jsonb_build_object('fail',true,'code',err_code,'msg',err_msg,'need',debit_from,'have',a_from.balance));
        RETURN;
    END IF;

    SELECT COALESCE(SUM(t.amount_kzt), 0.00)
      INTO used_today_kzt
      FROM public.transactions t
      JOIN public.accounts a ON a.account_id = t.from_account_id
     WHERE a.customer_id = a_from.customer_id
       AND t.type = 'transfer'
       AND t.status = 'completed'
       AND (t.created_at AT TIME ZONE 'Asia/Almaty')::date =
           (clock_timestamp() AT TIME ZONE 'Asia/Almaty')::date;

    IF used_today_kzt + amount_kzt > c_from.daily_limit_kzt THEN
        err_code := 'E09'; err_msg := 'Daily limit exceeded';
        INSERT INTO public.audit_log(table_name, record_id, action, old_values, new_values)
        VALUES ('transactions', NULL, 'INSERT', NULL, jsonb_build_object('fail',true,'code',err_code,'msg',err_msg,'used',used_today_kzt,'try',amount_kzt,'limit',c_from.daily_limit_kzt));
        RETURN;
    END IF;

    SAVEPOINT sp;

    BEGIN
        INSERT INTO public.transactions(
            from_account_id, to_account_id,
            amount, currency,
            exchange_rate, amount_kzt,
            type, status, description
        )
        VALUES (
            a_from.account_id, a_to.account_id,
            p_amount, p_curr,
            rate_to_kzt, amount_kzt,
            'transfer', 'pending', p_desc
        )
        RETURNING transaction_id INTO tx_id;

        UPDATE public.accounts
           SET balance = balance - debit_from
         WHERE account_id = a_from.account_id;

        UPDATE public.accounts
           SET balance = balance + credit_to
         WHERE account_id = a_to.account_id;

        UPDATE public.transactions
           SET status='completed', completed_at=clock_timestamp()
         WHERE transaction_id = tx_id;

        INSERT INTO public.audit_log(table_name, record_id, action, old_values, new_values)
        VALUES ('transactions', tx_id, 'UPDATE',
                jsonb_build_object('status','pending'),
                jsonb_build_object('status','completed','amount',p_amount,'currency',p_curr,'amount_kzt',amount_kzt));

        success := TRUE;
        RETURN;

    EXCEPTION WHEN OTHERS THEN
        ROLLBACK TO SAVEPOINT sp;
        err_code := 'E99';
        err_msg := 'Unexpected: ' || SQLERRM;

        INSERT INTO public.audit_log(table_name, record_id, action, old_values, new_values)
        VALUES ('transactions', NULL, 'INSERT', NULL, jsonb_build_object('fail',true,'code',err_code,'msg',err_msg));

        RETURN;
    END;

END;
$$;

-- task 2 - view 1
CREATE OR REPLACE VIEW public.customer_balance_summary AS
WITH acct AS (
    SELECT
        c.customer_id,
        c.iin,
        c.full_name,
        c.status,
        c.daily_limit_kzt,

        a.account_id,
        a.account_number,
        a.currency,
        a.balance,

        ROUND(a.balance * public.get_rate(a.currency, 'KZT', clock_timestamp()), 2) AS balance_kzt
    FROM public.customers c
    JOIN public.accounts  a ON a.customer_id = c.customer_id
),
totals AS (
    SELECT
        customer_id,
        SUM(balance_kzt) AS total_balance_kzt
    FROM acct
    GROUP BY customer_id
),
used_today AS (
    SELECT
        a.customer_id,
        COALESCE(SUM(t.amount_kzt), 0.00) AS used_today_kzt
    FROM public.accounts a
    LEFT JOIN public.transactions t
           ON t.from_account_id = a.account_id
          AND t.type   = 'transfer'
          AND t.status = 'completed'
          AND (t.created_at AT TIME ZONE 'Asia/Almaty')::date =
              (clock_timestamp() AT TIME ZONE 'Asia/Almaty')::date
    GROUP BY a.customer_id
)
SELECT
    acct.customer_id,
    acct.iin,
    acct.full_name,
    acct.status,

    acct.account_id,
    acct.account_number,
    acct.currency,
    acct.balance,
    acct.balance_kzt,

    totals.total_balance_kzt,

    ROUND(
        (used_today.used_today_kzt / NULLIF(acct.daily_limit_kzt, 0)) * 100.0
    , 2) AS daily_limit_utilization_pct,

    RANK() OVER (ORDER BY totals.total_balance_kzt DESC) AS customer_rank_by_total_balance_kzt
FROM acct
JOIN totals     USING (customer_id)
LEFT JOIN used_today USING (customer_id);



-- view 2
CREATE OR REPLACE VIEW public.daily_transaction_report AS
WITH daily AS (
    SELECT
        (t.created_at AT TIME ZONE 'Asia/Almaty')::date AS tx_date,
        t.type,
        COUNT(*)                    AS tx_count,
        ROUND(SUM(t.amount_kzt), 2) AS total_volume_kzt,
        ROUND(AVG(t.amount_kzt), 2) AS avg_amount_kzt
    FROM public.transactions t
    WHERE t.status = 'completed'
    GROUP BY 1,2
)
SELECT
    tx_date,
    type,
    tx_count,
    total_volume_kzt,
    avg_amount_kzt,

    ROUND(
        SUM(total_volume_kzt) OVER (PARTITION BY type ORDER BY tx_date)
    , 2) AS running_total_kzt,

    ROUND(
        CASE
            WHEN LAG(total_volume_kzt) OVER (PARTITION BY type ORDER BY tx_date) IS NULL THEN NULL
            WHEN LAG(total_volume_kzt) OVER (PARTITION BY type ORDER BY tx_date) = 0 THEN NULL
            ELSE
                (
                    (total_volume_kzt - LAG(total_volume_kzt) OVER (PARTITION BY type ORDER BY tx_date))
                    / LAG(total_volume_kzt) OVER (PARTITION BY type ORDER BY tx_date)
                ) * 100.0
        END
    , 2) AS day_over_day_growth_pct
FROM daily
ORDER BY tx_date, type;



-- view 3
CREATE OR REPLACE VIEW public.suspicious_activity_view
WITH (security_barrier = true)
AS
WITH base AS (
    SELECT
        t.transaction_id,
        t.created_at,
        t.from_account_id,
        t.to_account_id,
        t.amount,
        t.currency,
        t.amount_kzt,
        t.description,

        a.customer_id AS sender_customer_id,
        date_trunc('hour', t.created_at) AS tx_hour,

        LAG(t.created_at) OVER (
            PARTITION BY t.from_account_id
            ORDER BY t.created_at
        ) AS prev_tx_time
    FROM public.transactions t
    JOIN public.accounts a ON a.account_id = t.from_account_id
    WHERE t.status = 'completed'
      AND t.type   = 'transfer'
),
big_tx AS (
    SELECT transaction_id, 'OVER_5M_KZT'::text AS reason
    FROM base
    WHERE amount_kzt > 5000000.00
),
many_per_hour AS (
    SELECT b.transaction_id, 'MORE_THAN_10_PER_HOUR'::text AS reason
    FROM base b
    JOIN (
        SELECT sender_customer_id, tx_hour
        FROM base
        GROUP BY sender_customer_id, tx_hour
        HAVING COUNT(*) > 10
    ) x
      ON x.sender_customer_id = b.sender_customer_id
     AND x.tx_hour = b.tx_hour
),
rapid_seq AS (
    SELECT transaction_id, 'RAPID_SEQUENTIAL_LT_1_MIN'::text AS reason
    FROM base
    WHERE prev_tx_time IS NOT NULL
      AND (created_at - prev_tx_time) < INTERVAL '1 minute'
)
SELECT
    b.transaction_id,
    b.created_at,
    b.sender_customer_id,
    b.from_account_id,
    b.to_account_id,
    b.amount,
    b.currency,
    b.amount_kzt,
    b.description,
    r.reason
FROM base b
JOIN (
    SELECT * FROM big_tx
    UNION ALL
    SELECT * FROM many_per_hour
    UNION ALL
    SELECT * FROM rapid_seq
) r USING (transaction_id);


-- TASK 3
EXPLAIN ANALYZE
SELECT transaction_id, created_at, amount_kzt, description
FROM public.transactions
WHERE from_account_id = 1
  AND type = 'transfer'
  AND status = 'completed'
  AND created_at >= now() - interval '30 days'
ORDER BY created_at DESC
LIMIT 50;


EXPLAIN ANALYZE
SELECT account_id, account_number, currency, balance
FROM public.accounts
WHERE customer_id = 1
  AND is_active = true;

EXPLAIN ANALYZE
SELECT customer_id, full_name, email
FROM public.customers
WHERE LOWER(email) = LOWER('test@example.com');


EXPLAIN ANALYZE
SELECT log_id, table_name, record_id, action, changed_at
FROM public.audit_log
WHERE new_values @> '{"status":"completed"}'::jsonb
ORDER BY changed_at DESC
LIMIT 50;


EXPLAIN ANALYZE
SELECT COUNT(*)
FROM public.transactions
WHERE status = 'completed';


-- composite +b-tree index 
DROP INDEX IF EXISTS public.idx_tx_from_type_status_created_cover;
CREATE INDEX idx_tx_from_type_status_created_cover
ON public.transactions (from_account_id, type, status, created_at DESC)
INCLUDE (amount_kzt, description);

-- partial index
DROP INDEX IF EXISTS public.idx_accounts_active_customer;
CREATE INDEX idx_accounts_active_customer
ON public.accounts (customer_id, account_number)
WHERE is_active = true;

-- expression index
DROP INDEX IF EXISTS public.idx_customers_lower_email;
CREATE INDEX idx_customers_lower_email
ON public.customers (LOWER(email));

-- gin index
DROP INDEX IF EXISTS public.idx_audit_jsonb_gin;
CREATE INDEX idx_audit_jsonb_gin
ON public.audit_log
USING GIN (new_values, old_values);

-- hash index
DROP INDEX IF EXISTS public.idx_tx_status_hash;
CREATE INDEX idx_tx_status_hash
ON public.transactions USING HASH (status);

DROP INDEX IF EXISTS public.idx_fx_lookup;
CREATE INDEX idx_fx_lookup
ON public.exchange_rates (from_currency, to_currency, valid_from DESC, valid_to);


EXPLAIN ANALYZE
SELECT transaction_id, created_at, amount_kzt, description
FROM public.transactions
WHERE from_account_id = 1
  AND type = 'transfer'
  AND status = 'completed'
  AND created_at >= now() - interval '30 days'
ORDER BY created_at DESC
LIMIT 50;

EXPLAIN ANALYZE
SELECT account_id, account_number, currency, balance
FROM public.accounts
WHERE customer_id = 1
  AND is_active = true;

EXPLAIN ANALYZE
SELECT customer_id, full_name, email
FROM public.customers
WHERE LOWER(email) = LOWER('test@example.com');

EXPLAIN ANALYZE
SELECT log_id, table_name, record_id, action, changed_at
FROM public.audit_log
WHERE new_values @> '{"status":"completed"}'::jsonb
ORDER BY changed_at DESC
LIMIT 50;

EXPLAIN ANALYZE
SELECT COUNT(*)
FROM public.transactions
WHERE status = 'completed';

-- TASK 4
CREATE OR REPLACE PROCEDURE public.process_salary_batch(
    IN  p_company_acc VARCHAR,
    IN  p_payments JSONB,
    OUT successful_count INT,
    OUT failed_count INT,
    OUT failed_details JSONB
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_company_acc public.accounts%ROWTYPE;

    v_item JSONB;
    v_iin  VARCHAR(12);
    v_amount NUMERIC(18,2);
    v_desc   TEXT;

    v_to_acc public.accounts%ROWTYPE;

    v_debit_company NUMERIC(18,2);
    v_amount_kzt    NUMERIC(18,2);

    v_total_debit_company NUMERIC(18,2) := 0;
    v_company_new_balance NUMERIC(18,2);

    v_failed JSONB := '[]'::JSONB;
BEGIN
    successful_count := 0;
    failed_count := 0;
    failed_details := '[]'::JSONB;

    PERFORM pg_advisory_lock(hashtext(p_company_acc));

    BEGIN
        SELECT * INTO v_company_acc
        FROM public.accounts
        WHERE account_number = p_company_acc;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Company account not found: %', p_company_acc;
        END IF;

        PERFORM 1
        FROM public.accounts
        WHERE account_id = v_company_acc.account_id
        FOR UPDATE;

        FOR v_item IN SELECT * FROM jsonb_array_elements(p_payments)
        LOOP
            v_iin := v_item->>'iin';

            BEGIN
                v_amount := NULLIF(v_item->>'amount','')::NUMERIC;
            EXCEPTION WHEN OTHERS THEN
                CONTINUE;
            END;

            IF v_amount IS NULL OR v_amount <= 0 THEN
                CONTINUE;
            END IF;

            SELECT a.* INTO v_to_acc
            FROM public.accounts a
            JOIN public.customers c ON c.customer_id = a.customer_id
            WHERE c.iin = v_iin
              AND a.is_active = true
            ORDER BY a.opened_at NULLS LAST
            LIMIT 1;

            IF NOT FOUND THEN
                CONTINUE;
            END IF;

            v_debit_company := ROUND(
                v_amount * public.get_rate(v_to_acc.currency, v_company_acc.currency, clock_timestamp()),
            2);

            v_total_debit_company := v_total_debit_company + v_debit_company;
        END LOOP;

        IF v_company_acc.balance < v_total_debit_company THEN
            RAISE EXCEPTION 'Insufficient company balance. Need %, have %',
                v_total_debit_company, v_company_acc.balance;
        END IF;

        v_company_new_balance := v_company_acc.balance;

        FOR v_item IN SELECT * FROM jsonb_array_elements(p_payments)
        LOOP
            v_iin := v_item->>'iin';

            BEGIN
                v_amount := NULLIF(v_item->>'amount','')::NUMERIC;
            EXCEPTION WHEN OTHERS THEN
                v_failed := v_failed || jsonb_build_object(
                    'iin', v_iin,
                    'amount', v_item->>'amount',
                    'error', 'invalid amount'
                );
                failed_count := failed_count + 1;
                CONTINUE;
            END;

            IF v_amount IS NULL OR v_amount <= 0 THEN
                v_failed := v_failed || jsonb_build_object(
                    'iin', v_iin,
                    'amount', v_item->>'amount',
                    'error', 'invalid amount'
                );
                failed_count := failed_count + 1;
                CONTINUE;
            END IF;

            v_desc := COALESCE(v_item->>'description', 'Salary payment');

            BEGIN
                SELECT a.* INTO v_to_acc
                FROM public.accounts a
                JOIN public.customers c ON c.customer_id = a.customer_id
                WHERE c.iin = v_iin
                  AND a.is_active = true
                ORDER BY a.opened_at NULLS LAST
                LIMIT 1;

                IF NOT FOUND THEN
                    v_failed := v_failed || jsonb_build_object('iin', v_iin, 'amount', v_amount, 'error', 'recipient account not found');
                    failed_count := failed_count + 1;
                    CONTINUE;
                END IF;

                PERFORM 1
                FROM public.accounts
                WHERE account_id = v_to_acc.account_id
                FOR UPDATE;

                v_debit_company := ROUND(
                    v_amount * public.get_rate(v_to_acc.currency, v_company_acc.currency, clock_timestamp()),
                2);

                v_amount_kzt := ROUND(
                    v_amount * public.get_rate(v_to_acc.currency, 'KZT', clock_timestamp()),
                2);

                IF v_company_new_balance < v_debit_company THEN
                    v_failed := v_failed || jsonb_build_object('iin', v_iin, 'amount', v_amount, 'error', 'company balance became insufficient during batch');
                    failed_count := failed_count + 1;
                    CONTINUE;
                END IF;

                SAVEPOINT sp_one;

                BEGIN
                    v_company_new_balance := v_company_new_balance - v_debit_company;

                    UPDATE public.accounts
                       SET balance = balance + v_amount
                     WHERE account_id = v_to_acc.account_id;

                    INSERT INTO public.transactions(
                        from_account_id, to_account_id,
                        amount, currency, exchange_rate, amount_kzt,
                        type, status, description,
                        completed_at
                    )
                    VALUES (
                        v_company_acc.account_id, v_to_acc.account_id,
                        v_amount, v_to_acc.currency,
                        public.get_rate(v_company_acc.currency, v_to_acc.currency, clock_timestamp()),
                        v_amount_kzt,
                        'transfer', 'completed', v_desc,
                        clock_timestamp()
                    );

                    successful_count := successful_count + 1;

                EXCEPTION WHEN OTHERS THEN
                    ROLLBACK TO SAVEPOINT sp_one;
                    v_failed := v_failed || jsonb_build_object('iin', v_iin, 'amount', v_amount, 'error', SQLERRM);
                    failed_count := failed_count + 1;
                    CONTINUE;
                END;

            EXCEPTION WHEN OTHERS THEN
                v_failed := v_failed || jsonb_build_object('iin', v_iin, 'amount', v_amount, 'error', SQLERRM);
                failed_count := failed_count + 1;
                CONTINUE;
            END;
        END LOOP;

        UPDATE public.accounts
           SET balance = v_company_new_balance
         WHERE account_id = v_company_acc.account_id;

        failed_details := v_failed;

    EXCEPTION WHEN OTHERS THEN
        PERFORM pg_advisory_unlock(hashtext(p_company_acc));
        RAISE;
    END;

    PERFORM pg_advisory_unlock(hashtext(p_company_acc));
END;
$$;