# Enterprise Sales Data Analysis Pipeline (MySQL)
End-to-end SQL project focused on data exploration, defensive data cleaning, missing value imputation, and advanced cohort/revenue reporting using MySQL.

## 📌 Project Overview
An end-to-end SQL data analytics pipeline designed to ingest, clean, and model retail transactional data. This project transforms raw, chaotic tables into optimized business intelligence reporting layers while handling real-world data anomalies (orphaned records, inconsistent country strings, and invalid date formats).

## 🛠 Key Tech & Concepts Demonstrated
* **Window Functions:** `ROW_NUMBER() OVER (PARTITION BY...)` utilized for defensive deduplication.
* **Data Cleansing:** Comprehensive missing value imputation via `COALESCE` and bulk string standardization using conditional `CASE WHEN` logic.
* **Data Quality Auditing:** Isolated hidden reporting gaps (e.g., 3 orphaned order records missing matching customer profiles) to guarantee absolute financial reporting accuracy using defensive `LEFT JOIN` handling.
* **Reporting Layers:** Created high-performance SQL `VIEWS` for C-suite executive reporting, including global market shares, Monthly Revenue Trends, and Average Order Value (AOV).

## 📂 Repository Structure
* `sql_scripts/` - Production-ready, sequential SQL files mapping the ETL process.
* `README.md` - Portfolio presentation and executive summary.

## 📈 Executive Insights Revealed
* **Data Quality Alert:** Identified 3 high-value orders containing orphaned customer IDs. Standard inner joins would have silently omitted these from financial reporting. Using an engineered fallback architecture preserved 100% revenue attribution.
* **Operational Bottlenecks:** Built an order-to-ship speed verification view to flag negative or delayed shipping transit timelines for logistical auditing.

## 🚀 How to Run This Project
1. Clone the repository.
2. Open your favorite SQL client (e.g., MySQL Workbench).
3. Execute the scripts sequentially within the `sql_scripts/` directory to build the schema, clean the records, and deploy the analytic reporting views.
