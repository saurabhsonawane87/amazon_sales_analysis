📊 Amazon Sales Performance & Order Failure Analysis
======================================================


Overview
---------

This project presents an end-to-end analysis of Amazon sales data to understand revenue performance, customer order behavior, and order failure risks. The analysis combines SQL for business logic, Python for validation and EDA, and an interactive dashboard for insight delivery.

The focus is not just on querying data, but on designing correct business metrics and identifying where revenue and customer experience are actually impacted.

##Data Availability 
The raw and cleaned datasets are not included in this repository due to file size constraints.
All data cleaning steps, SQL logic, and analysis workflows are fully documented in the provided notebooks and SQL scripts.


Business Questions Addressed
-----------------------------

- How is revenue trending over time, and is growth consistent or volatile?

- Which product categories contribute most to revenue and order value?

- How are customer orders distributed by value?

- Where are orders failing, and what type of failures drive revenue loss?

- Does shipping mode influence customer order outcomes?


Dataset Summary
----------------

- Source: Amazon sales transactional dataset

- Rows: ~128,000

- Unique Orders: ~120,000

- Granularity: Line-item level

Important Note:
All order-level metrics are calculated using distinct order IDs to avoid inflation caused by multi-item orders.


Tools & Skills Used
-------------------

- SQL (MySQL): CTEs, window functions, rolling metrics, order-level aggregation

- Python: EDA, validation, cross-checking business logic

- Dashboarding: Interactive visualization of revenue, categories, orders, and risks

- Analytical Skills: Metric definition, business reasoning, storytelling


Key Insights
-------------

- Revenue shows sustained upward momentum from April onward, confirmed by a 3-month rolling average rather than one-off spikes.

- A small subset of categories contributes disproportionately to overall revenue and higher average order values.

- Most customer-impact failures originate from pre-shipment cancellations and returns, not courier-related issues.

- Standard shipping has nearly double the customer-impact failure rate compared to Expedited shipping, suggesting shipping speed correlates with overall order reliability.

- Courier-related failures (lost or damaged shipments) are extremely rare, indicating strong logistics execution.


Dashboard
----------

The dashboard consolidates:

- Revenue trends and momentum

- Category-wise performance

- Customer order value segmentation

- Order outcome distribution

- Shipping risk comparison

- It is designed for quick decision-making rather than deep technical inspection.


Assumptions & Notes
-------------------

- Any non-delivered order is treated as a full revenue loss.

- Returns are considered customer-impact failures.

- Analysis is based on a historical snapshot of the data.


Conclusion
----------


This project demonstrates practical data analyst skills by translating raw transactional data into business-ready insights, with careful attention to metric correctness, consistency, and interpretability.
