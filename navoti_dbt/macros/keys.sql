{#- Deterministic surrogate key from one or more natural-key columns. -#}
{% macro surrogate_key(columns) -%}
    md5({%- for c in columns -%}
        coalesce(cast({{ c }} as varchar), '_null_'){% if not loop.last %} || '|' || {% endif %}
    {%- endfor -%})
{%- endmacro %}

{#- Hash of all tracked attributes; used to detect changed rows for the MERGE. -#}
{% macro row_hash(columns) -%}
    {{ surrogate_key(columns) }}
{%- endmacro %}

{#-
  Incremental change filter: on incremental runs keep only rows that are new
  or whose attributes changed (row_hash differs). Unchanged rows never reach the MERGE.
-#}
{% macro only_new_or_changed(key_column, alias='src') -%}
    {% if is_incremental() %}
    where not exists (
        select 1 from {{ this }} tgt
        where tgt.{{ key_column }} = {{ alias }}.{{ key_column }}
          and tgt.row_hash = {{ alias }}.row_hash
    )
    {% endif %}
{%- endmacro %}
