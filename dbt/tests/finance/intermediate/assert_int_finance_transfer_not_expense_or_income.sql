select *
from {{ ref('int_finance') }}
where is_transfer = true
  and (is_expense = true or is_income = true)
