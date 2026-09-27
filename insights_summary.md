# Key Insights — E-Commerce Sales Analytics

Findings below are the actual output of `02_analysis_queries.sql` run against
`ecommerce.db`. Use these as talking points when presenting the project.

## 1. Revenue overview
- **5,399 completed orders** generated **$5,706,317.79** in net revenue
  (after discounts), for an **average order value of $1,056.92**.
- Revenue climbs steadily through the year with a clear **holiday-season
  spike in November/December**, consistent with typical retail seasonality
  built into the order-generation model.

## 2. Category performance
| Category         | Revenue         | Profit Margin |
|-------------------|----------------:|--------------:|
| Technology         | $4,497,691.03   | 31.1%         |
| Furniture           | $1,001,739.65   | 43.1%         |
| Office Supplies     | $206,887.12     | 61.4%         |

**Insight:** Technology drives ~79% of all revenue but carries the thinnest
margin. Office Supplies is a small share of revenue but the most
profitable per dollar sold — a classic "volume vs. margin" trade-off worth
highlighting in any business review.

## 3. Customer segments
| Segment       | Customers | Revenue        |
|----------------|----------:|---------------:|
| Consumer        | 221       | $3,391,977.66  |
| Corporate       | 127       | $1,560,864.35  |
| Home Office     | 51        | $753,475.77    |

Consumer is the largest segment by both customer count and revenue, but
Home Office customers spend the most **per capita** ($14,774 avg vs.
$15,348 for Consumer, $12,290 for Corporate) — worth digging into for a
targeted retention campaign.

## 4. Pareto (80/20) analysis
| Quintile (by spend) | Customers | Revenue      | % of Total |
|----------------------|----------:|-------------:|-----------:|
| Top 20%               | 80        | $3,043,908   | 53.3%      |
| 2nd 20%               | 80        | $1,298,351   | 22.8%      |
| 3rd 20%               | 80        | $726,541     | 12.7%      |
| 4th 20%               | 80        | $459,004     | 8.0%       |
| Bottom 20%            | 79        | $178,514     | 3.1%       |

**Insight:** The top 40% of customers account for **~76% of revenue** —
a strong (though not literally "80/20") concentration that justifies
investing disproportionately in retaining the top two quintiles.

## 5. RFM customer segmentation
| Segment          | Customers |
|-------------------|----------:|
| At Risk / Churned  | 129       |
| Needs Attention    | 115       |
| Loyal Customer     | 85        |
| Champion           | 45        |
| New / Promising    | 25        |

**Insight:** Nearly a third of the customer base (129 of 400) is flagged
"At Risk" — recent-but-infrequent or long-lapsed high-value buyers. This is
the single most actionable output of the project: it converts raw
transaction data into a **prioritized win-back list**.

## 6. Operations
- Overall return rate: **6.87%** of all orders.
- Return rates are fairly flat across shipping modes (**6.2%–7.7%**), so
  shipping speed does not appear to meaningfully drive returns in this
  dataset — a useful "ruled-out" hypothesis to mention.
- Standard Class has the lowest return rate (6.22%) despite being the
  slowest shipping option.

## 7. Top products
1. **Classic Machine 6** (Technology) — $430,211.55
2. **Compact Machine 7** (Technology) — $299,710.95
3. **Pro Copier 1** (Technology) — $295,386.51

High-ticket Technology "Machines" and "Copiers" dominate the top-seller
list — consistent with the category-level margin/volume finding above.

---
**How to talk about this in an interview:** frame it as a story — *"I started
by measuring overall health (Q1–Q3), found where the money comes from
(Q4–Q6), then moved to who is buying (Q8–Q12) to find actionable segments,
and finally checked operational risk (Q13–Q14)."* That narrative arc is what
separates a portfolio project from a list of disconnected queries.
