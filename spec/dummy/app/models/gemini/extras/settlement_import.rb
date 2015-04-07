module Gemini::Extras::SettlementImport
  def import_validation(ids)
    validate_settlement_date(ids, 0)
  end

  def import_validation_allow_prior_month(ids)
    validate_settlement_date(ids, 1)
  end

private
  def validate_settlement_date(ids, month_interval)
    # Given a set of ids, make sure that settlement mm/yy are not more
    # than x months older than current date.
    bad = where("id IN (?) AND " +
                "date_trunc('month', current_date) - " +
                "INTERVAL '#{month_interval} month' > " +
                "format('%s-%s-01', settlement_yy, settlement_mm)::date",
                ids).limit(1)

    return if bad.empty?

    x = bad[0]

    raise "One or more records failed validation. " +
      "Settlement #{x.settlement_mm}/#{x.settlement_yy} is " +
      "#{month_interval + 1 } or more months in the past."
  end
end
