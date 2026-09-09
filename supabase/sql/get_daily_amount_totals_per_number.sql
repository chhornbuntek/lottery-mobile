-- Branch 3/1/4: daily money-limit totals across ALL agents.
-- Run this in Supabase SQL editor for each branch that uses money_limit.

CREATE OR REPLACE FUNCTION public.get_daily_amount_totals_per_number(
  p_bet_date date,
  p_lottery_time text,
  p_exclude_pending_id bigint DEFAULT NULL,
  p_exclude_bet_id bigint DEFAULT NULL
)
RETURNS TABLE(bet_number text, total_amount bigint)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    number_text AS bet_number,
    COALESCE(SUM(amount), 0)::bigint AS total_amount
  FROM (
    SELECT
      unnest(pb.bet_numbers)::text AS number_text,
      pb.amount_per_number AS amount
    FROM public.pending_bets pb
    WHERE pb.bet_date = p_bet_date
      AND pb.lottery_time = p_lottery_time
      AND (p_exclude_pending_id IS NULL OR pb.id <> p_exclude_pending_id)

    UNION ALL

    SELECT
      unnest(b.bet_numbers)::text AS number_text,
      b.amount_per_number AS amount
    FROM public.bets b
    WHERE b.bet_date = p_bet_date
      AND b.lottery_time = p_lottery_time
      AND (p_exclude_bet_id IS NULL OR b.id <> p_exclude_bet_id)
  ) t
  GROUP BY number_text;
$$;

REVOKE ALL ON FUNCTION public.get_daily_amount_totals_per_number(date, text, bigint, bigint) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_daily_amount_totals_per_number(date, text, bigint, bigint) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_daily_amount_totals_per_number(date, text, bigint, bigint) TO anon;

-- Optional: ensure agents can read money_limit rows
-- ALTER TABLE public.money_limit ENABLE ROW LEVEL SECURITY;
-- CREATE POLICY money_limit_select_authenticated
--   ON public.money_limit FOR SELECT TO authenticated USING (true);
