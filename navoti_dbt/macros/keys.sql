{% macro surrogate_key(columns) -%}
    md5({%- for c in columns -%}
        coalesce(cast({{ c }} as varchar), '_null_'){% if not loop.last %} || '|' || {% endif %}
    {%- endfor -%})
{%- endmacro %}

{% macro row_hash(columns) -%}
    {{ surrogate_key(columns) }}
{%- endmacro %}

{% macro only_new_or_changed(key_column, alias='src') -%}
    {% if is_incremental() %}
    where not exists (
        select 1 from {{ this }} tgt
        where tgt.{{ key_column }} = {{ alias }}.{{ key_column }}
          and tgt.row_hash = {{ alias }}.row_hash
    )
    {% endif %}
{%- endmacro %}
