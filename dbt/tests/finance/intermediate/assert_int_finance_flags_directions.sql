select *
from {{ ref('int_finance') }}
where is_inflow = false
  and is_outflow = false
