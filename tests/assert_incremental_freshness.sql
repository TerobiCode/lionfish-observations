select 1
from LIONFISH_DB.RAW.INCREMENTAL_OBSERVATIONS
having max(INGESTION_DATE) < current_date() - 2