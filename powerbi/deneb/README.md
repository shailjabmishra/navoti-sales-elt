# Deneb visuals (Vega-Lite)

Custom visuals for `Navoti_Sales.pbix`, written in Vega-Lite for the certified **Deneb** visual.
Open `preview.html` in a browser to see all four with sample data before pasting them into Power BI.

| Spec | Page | Fields to add to the Deneb **Values** well |
|---|---|---|
| `01_sales_trend.json` | Overview | `DIM_DATE[YEAR_MONTH]`, `[Sales Amount (Trend)]` |
| `02_win_rate_dumbbell.json` | Sales Team | `DIM_SALES_PERSON[FULL_NAME]`, `[Win Rate %]`, `[Win Rate % (Team)]`, `[Won Tasks]` |
| `03_win_rate_heatmap.json` | Channels | `DIM_SALES_PERSON[FULL_NAME]`, `DIM_CHANNEL[CHANNEL]`, `[Win Rate %]`, `[Total Tasks]` |
| `04_pipeline_funnel.json` | Overview | `[Total Tasks]`, `[Closed Tasks]`, `[Won Tasks]` |

Extra measure needed for the dumbbell (team average that ignores the sales-person filter):

```dax
Win Rate % (Team) = CALCULATE([Win Rate %], REMOVEFILTERS(DIM_SALES_PERSON))
```

Setup per visual: add a Deneb visual → add the fields above → `...` → **Edit** → **Vega-Lite**, empty template →
paste the spec into **Specification** → **Apply**. Field names in the spec must match the field names in the visual exactly;
if you rename a field in Power BI, rename it in the spec too.
