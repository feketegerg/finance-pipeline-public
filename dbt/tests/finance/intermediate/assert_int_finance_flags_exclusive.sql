select *
from {{ ref('int_finance') }}
where is_inflow = true
  and is_outflow = true
