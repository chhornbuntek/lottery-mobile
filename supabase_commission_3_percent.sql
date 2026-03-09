-- =============================================================================
-- Commission 3%: fix Supabase functions (run on self-hosting / Supabase SQL Editor)
-- =============================================================================
-- FORMULAS (must match mobile app):
--   net_profit     = total_bet_amount - total_win_amount   (agent profit)
--   commission 3%  = ROUND(total_bet_amount * 3 / 100)     (ប្រាក់រង្វាន់)
-- 1. create_commission_on_bet_insert: trigger on bet insert
-- 2. process_bets_for_result_with_commission: when results are processed
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1) Fix trigger: create_commission_on_bet_insert
--    - Use 3% for total_commission_amount (was wrongly using full bet amount)
--    - Set commission_rate = 3
--    - net_profit = total_bet - total_win (positive when no payouts yet)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.create_commission_on_bet_insert()
RETURNS trigger
LANGUAGE plpgsql
AS $function$
DECLARE
    existing_commission RECORD;
    new_total_bet BIGINT;
    new_commission_amount INT;
    new_net_profit INT;
    commission_rate_val NUMERIC := 3;  -- 3%
BEGIN
    -- Get existing commission record for this user and date
    SELECT * INTO existing_commission
    FROM commissions
    WHERE user_id = NEW.user_id
    AND date = NEW.bet_date;

    IF FOUND THEN
        new_total_bet := existing_commission.total_bet_amount + NEW.total_amount;
        new_commission_amount := ROUND(new_total_bet * commission_rate_val / 100)::INT;
        -- net_profit = total_bet - total_win (keep existing total_win_amount; will be updated when results processed)
        new_net_profit := new_total_bet - COALESCE(existing_commission.total_win_amount, 0);
        UPDATE commissions
        SET
            total_bet_amount = new_total_bet,
            bet_count = bet_count + 1,
            total_commission_amount = new_commission_amount,
            commission_rate = commission_rate_val,
            net_profit = new_net_profit,
            updated_at = NOW()
        WHERE user_id = NEW.user_id
        AND date = NEW.bet_date;
    ELSE
        new_commission_amount := ROUND(NEW.total_amount * commission_rate_val / 100)::INT;
        -- net_profit = total_bet - total_win; when no results yet, total_win=0 so net_profit = NEW.total_amount (positive)
        INSERT INTO commissions (
            user_id,
            date,
            total_bet_amount,
            total_commission_amount,
            commission_rate,
            bet_count,
            total_win_amount,
            total_loss_amount,
            net_profit,
            admin_id
        ) VALUES (
            NEW.user_id,
            NEW.bet_date,
            NEW.total_amount,
            new_commission_amount,
            commission_rate_val,
            1,
            0,
            0,
            NEW.total_amount,  -- net_profit = bets - 0 = positive until results processed
            NEW.admin_id
        );
    END IF;

    RETURN NEW;
END;
$function$;

-- -----------------------------------------------------------------------------
-- 2) Fix process_bets_for_result_with_commission: use 3% instead of 5%
--    - commission_rate variable 0.05 -> 0.03 (and store as 3 in table)
--    - agent_commission_amount = total_bets * 0.03
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.process_bets_for_result_with_commission(result_id_param integer)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
    result_record RECORD;
    bet_record RECORD;
    result_2digit TEXT[];
    result_3digit TEXT[];
    bet_numbers TEXT[];
    win_numbers TEXT[];
    win_amount DECIMAL(10,2);
    is_winning BOOLEAN := false;
    win_cause_text TEXT;
    channel_code TEXT;
    number_type TEXT;
    total_win_amount DECIMAL(10,2) := 0;
    i INTEGER;
    j INTEGER;
    k INTEGER;
    bet_length INTEGER;
    result_2digit_length INTEGER;
    result_3digit_length INTEGER;
    all_unique_wins TEXT[] := ARRAY[]::TEXT[];
    processed_bets INTEGER := 0;
    total_wins INTEGER := 0;
    num_value INTEGER;
    temp_array INTEGER[];
    selected_conditions_array TEXT[];

    -- Commission: 3% (was 0.05)
    agent_commission RECORD;
    agent_total_bets DECIMAL(10,2);
    agent_total_winnings DECIMAL(10,2);
    agent_net_profit DECIMAL(10,2);
    commission_rate_pct NUMERIC := 3;
    agent_commission_amount DECIMAL(10,2);
BEGIN
    RAISE NOTICE 'Starting process_bets_for_result_with_commission with result_id: %', result_id_param;

    SELECT * INTO result_record FROM results WHERE id = result_id_param;

    IF NOT FOUND THEN
        RAISE NOTICE 'Result not found for id: %', result_id_param;
        RETURN json_build_object('success', false, 'error', 'Result not found');
    END IF;

    RAISE NOTICE 'Found result: date=%, time=%, name=%', result_record.date, result_record.time, result_record.name;

    DELETE FROM bet_results WHERE result_id = result_id_param;
    RAISE NOTICE 'Cleared existing bet_results for result_id: %', result_id_param;

    FOR bet_record IN
        SELECT b.*, lt.time_name
        FROM bets b
        LEFT JOIN lottery_times lt ON b.lottery_time_id = lt.id
        WHERE b.bet_date = result_record.date
        AND lt.time_name = result_record.time
    LOOP
        processed_bets := processed_bets + 1;
        RAISE NOTICE 'Processing bet %: id=%, user_id=%, total_amount=%, selected_conditions=%',
            processed_bets, bet_record.id, bet_record.user_id, bet_record.total_amount, bet_record.selected_conditions;

        IF bet_record.selected_conditions IS NOT NULL THEN
            SELECT ARRAY(SELECT jsonb_array_elements_text(bet_record.selected_conditions)) INTO selected_conditions_array;
        ELSE
            selected_conditions_array := ARRAY[]::TEXT[];
        END IF;

        RAISE NOTICE 'Selected conditions for bet %: %', bet_record.id, selected_conditions_array;

        is_winning := false;
        total_win_amount := 0;
        win_cause_text := '';
        all_unique_wins := ARRAY[]::TEXT[];

        FOR channel_code IN SELECT unnest(ARRAY['A', 'B', 'C', 'D', 'Lo', 'F', 'N', 'I', 'O', 'K']) LOOP
            IF array_length(selected_conditions_array, 1) > 0 AND NOT (channel_code = ANY(selected_conditions_array)) THEN
                RAISE NOTICE 'Skipping channel % - not in selected_conditions %', channel_code, selected_conditions_array;
                CONTINUE;
            END IF;

            RAISE NOTICE 'Checking channel % for bet %', channel_code, bet_record.id;

            result_2digit := ARRAY[]::TEXT[];
            result_3digit := ARRAY[]::TEXT[];

            CASE channel_code
                WHEN 'A' THEN temp_array := result_record.type_a_two;
                WHEN 'B' THEN temp_array := result_record.type_b_two;
                WHEN 'C' THEN temp_array := result_record.type_c_two;
                WHEN 'D' THEN temp_array := result_record.type_d_two;
                WHEN 'Lo' THEN temp_array := result_record.type_lo_two;
                WHEN 'F' THEN temp_array := result_record.type_f_two;
                WHEN 'N' THEN temp_array := result_record.type_n_two;
                WHEN 'I' THEN temp_array := result_record.type_i_two;
                WHEN 'O' THEN temp_array := result_record.type_o_two;
                WHEN 'K' THEN temp_array := result_record.type_k_two;
                ELSE temp_array := ARRAY[]::INTEGER[];
            END CASE;

            IF temp_array IS NOT NULL AND array_length(temp_array, 1) > 0 THEN
                FOREACH num_value IN ARRAY temp_array LOOP
                    result_2digit := array_append(result_2digit, int_to_padded_string(num_value, 2));
                END LOOP;
            END IF;

            CASE channel_code
                WHEN 'A' THEN temp_array := result_record.type_a_three;
                WHEN 'B' THEN temp_array := result_record.type_b_three;
                WHEN 'C' THEN temp_array := result_record.type_c_three;
                WHEN 'D' THEN temp_array := result_record.type_d_three;
                WHEN 'Lo' THEN temp_array := result_record.type_lo_three;
                WHEN 'F' THEN temp_array := result_record.type_f_three;
                WHEN 'N' THEN temp_array := result_record.type_n_three;
                WHEN 'I' THEN temp_array := result_record.type_i_three;
                WHEN 'O' THEN temp_array := result_record.type_o_three;
                WHEN 'K' THEN temp_array := result_record.type_k_three;
                ELSE temp_array := ARRAY[]::INTEGER[];
            END CASE;

            IF temp_array IS NOT NULL AND array_length(temp_array, 1) > 0 THEN
                FOREACH num_value IN ARRAY temp_array LOOP
                    result_3digit := array_append(result_3digit, int_to_padded_string(num_value, 3));
                END LOOP;
            END IF;

            bet_length := COALESCE(array_length(bet_record.bet_numbers, 1), 0);
            result_2digit_length := COALESCE(array_length(result_2digit, 1), 0);
            result_3digit_length := COALESCE(array_length(result_3digit, 1), 0);

            IF bet_length > 0 AND result_2digit_length > 0 THEN
                win_numbers := ARRAY[]::TEXT[];
                FOR i IN 1..bet_length LOOP
                    FOR j IN 1..result_2digit_length LOOP
                        IF bet_record.bet_numbers[i] = result_2digit[j] THEN
                            win_numbers := array_append(win_numbers, bet_record.bet_numbers[i]);
                            IF NOT (bet_record.bet_numbers[i] = ANY(all_unique_wins)) THEN
                                all_unique_wins := array_append(all_unique_wins, bet_record.bet_numbers[i]);
                            END IF;
                        END IF;
                    END LOOP;
                END LOOP;

                IF array_length(win_numbers, 1) > 0 THEN
                    is_winning := true;
                    total_wins := total_wins + 1;
                    win_cause_text := CASE
                        WHEN win_cause_text = '' THEN array_to_string(win_numbers, ',') || ' (2digit-' || channel_code || ')'
                        ELSE win_cause_text || ', ' || array_to_string(win_numbers, ',') || ' (2digit-' || channel_code || ')'
                    END;
                    number_type := '2digit';
                    win_amount := bet_record.amount_per_number * 95 * array_length(win_numbers, 1);
                    total_win_amount := total_win_amount + win_amount;

                    RAISE NOTICE '2-digit win found: numbers=%, win_amount=%', array_to_string(win_numbers, ','), win_amount;

                    INSERT INTO bet_results (
                        bet_id, result_id, channel_code, bet_numbers, result_numbers,
                        bet_amount_per_number, total_bet_amount, multiplier, win_amount,
                        is_win, win_cause, number_type, lottery_time, date
                    ) VALUES (
                        bet_record.id, result_id_param, channel_code, bet_record.bet_numbers, result_2digit,
                        bet_record.amount_per_number, bet_record.total_amount, bet_record.multiplier,
                        win_amount, true, array_to_string(win_numbers, ','), number_type, bet_record.time_name, result_record.date
                    );
                END IF;
            END IF;

            IF bet_length > 0 AND result_3digit_length > 0 THEN
                win_numbers := ARRAY[]::TEXT[];
                FOR i IN 1..bet_length LOOP
                    FOR j IN 1..result_3digit_length LOOP
                        IF bet_record.bet_numbers[i] = result_3digit[j] THEN
                            win_numbers := array_append(win_numbers, bet_record.bet_numbers[i]);
                            IF NOT (bet_record.bet_numbers[i] = ANY(all_unique_wins)) THEN
                                all_unique_wins := array_append(all_unique_wins, bet_record.bet_numbers[i]);
                            END IF;
                        END IF;
                    END LOOP;
                END LOOP;

                IF array_length(win_numbers, 1) > 0 THEN
                    is_winning := true;
                    total_wins := total_wins + 1;
                    win_cause_text := CASE
                        WHEN win_cause_text = '' THEN array_to_string(win_numbers, ',') || ' (3digit-' || channel_code || ')'
                        ELSE win_cause_text || ', ' || array_to_string(win_numbers, ',') || ' (3digit-' || channel_code || ')'
                    END;
                    number_type := '3digit';
                    win_amount := bet_record.amount_per_number * 900 * array_length(win_numbers, 1);
                    total_win_amount := total_win_amount + win_amount;

                    RAISE NOTICE '3-digit win found: numbers=%, win_amount=%', array_to_string(win_numbers, ','), win_amount;

                    INSERT INTO bet_results (
                        bet_id, result_id, channel_code, bet_numbers, result_numbers,
                        bet_amount_per_number, total_bet_amount, multiplier, win_amount,
                        is_win, win_cause, number_type, lottery_time, date
                    ) VALUES (
                        bet_record.id, result_id_param, channel_code, bet_record.bet_numbers, result_3digit,
                        bet_record.amount_per_number, bet_record.total_amount, bet_record.multiplier,
                        win_amount, true, array_to_string(win_numbers, ','), number_type, bet_record.time_name, result_record.date
                    );
                END IF;
            END IF;
        END LOOP;
    END LOOP;

    RAISE NOTICE 'Processed % bets, found % wins', processed_bets, total_wins;
    RAISE NOTICE 'Starting commission calculation for date: % (3%%)', result_record.date;

    -- Commission at 3% (commission_rate_pct = 3)
    FOR agent_commission IN
        WITH all_unique_bets AS (
            SELECT
                DISTINCT ON (b.id)
                b.id,
                b.user_id,
                b.admin_id,
                b.total_amount
            FROM bets b
            WHERE b.bet_date = result_record.date
        )
        SELECT
            aub.user_id,
            aub.admin_id,
            COUNT(*) as bet_count,
            SUM(aub.total_amount) as total_bet_amount,
            (SELECT COALESCE(SUM(br.win_amount), 0)
             FROM bet_results br
             WHERE br.bet_id IN (SELECT id FROM all_unique_bets WHERE user_id = aub.user_id)) as total_win_amount
        FROM all_unique_bets aub
        GROUP BY aub.user_id, aub.admin_id
    LOOP
        agent_total_bets := agent_commission.total_bet_amount;
        agent_total_winnings := agent_commission.total_win_amount;
        agent_net_profit := agent_total_bets - agent_total_winnings;
        agent_commission_amount := ROUND(agent_total_bets * commission_rate_pct / 100)::DECIMAL(10,2);

        RAISE NOTICE 'Agent %: bets=%, winnings=%, net_profit=%, commission(3%%)=%',
            agent_commission.user_id, agent_total_bets, agent_total_winnings, agent_net_profit, agent_commission_amount;

        INSERT INTO commissions (
            user_id, date, total_bet_amount, total_commission_amount, commission_rate, bet_count,
            total_win_amount, total_loss_amount, net_profit, admin_id
        ) VALUES (
            agent_commission.user_id, result_record.date, agent_total_bets::INTEGER, agent_commission_amount::INTEGER,
            commission_rate_pct, agent_commission.bet_count, agent_total_winnings::INTEGER,
            CASE WHEN agent_net_profit < 0 THEN ABS(agent_net_profit)::INTEGER ELSE 0 END,
            agent_net_profit::INTEGER, agent_commission.admin_id
        )
        ON CONFLICT (user_id, date)
        DO UPDATE SET
            total_bet_amount = EXCLUDED.total_bet_amount,
            total_commission_amount = EXCLUDED.total_commission_amount,
            commission_rate = EXCLUDED.commission_rate,
            bet_count = EXCLUDED.bet_count,
            total_win_amount = EXCLUDED.total_win_amount,
            total_loss_amount = EXCLUDED.total_loss_amount,
            net_profit = EXCLUDED.net_profit,
            admin_id = EXCLUDED.admin_id,
            updated_at = NOW();
    END LOOP;

    RAISE NOTICE 'Commission calculation completed for date: %', result_record.date;

    RETURN json_build_object(
        'success', true,
        'processed_bets', processed_bets,
        'total_wins', total_wins,
        'result_id', result_id_param,
        'commissions_updated', true,
        'commission_date', result_record.date
    );
END;
$function$;

-- -----------------------------------------------------------------------------
-- 3) Optional: fix existing rows that still have 0.05 to 3% and recalc amount
-- -----------------------------------------------------------------------------
UPDATE public.commissions
SET
  commission_rate = 3,
  total_commission_amount = ROUND(total_bet_amount * 3.0 / 100)::INT,
  updated_at = NOW()
WHERE commission_rate = 0.05 OR commission_rate != 3;

-- -----------------------------------------------------------------------------
-- 4) Fix net_profit sign: net_profit = total_bet_amount - total_win_amount (agent profit)
--    Run this to correct rows where net_profit was stored as negative for new agents
-- -----------------------------------------------------------------------------
UPDATE public.commissions
SET
  net_profit = (total_bet_amount - total_win_amount)::INT,
  updated_at = NOW()
WHERE net_profit != (total_bet_amount - total_win_amount);
