
-- ============================================================
-- JOB HUNT ANALYTICS
-- Recruitment Application-to-Offer Funnel Analysis
-- Database: PostgreSQL
-- Main table: applications
-- Supporting table: interviews
-- ============================================================


-- 1. OFFER CONVERSION BY APPLICATION SOURCE
-- ============================================================

SELECT
    source,
    COUNT(application_id) AS total_applications,
    COUNT(offer_id) AS total_offers,
    ROUND(
        COUNT(offer_id)::NUMERIC
        / NULLIF(COUNT(application_id), 0) * 100,
        2
    ) AS offer_conversion_rate
FROM applications
GROUP BY source
ORDER BY offer_conversion_rate DESC;


-- 2. RECRUITMENT FUNNEL AND KEY CONVERSION RATES
-- ============================================================

WITH funnel AS (
    SELECT
        COUNT(application_id) AS total_applications,
        COUNT(*) FILTER (
            WHERE total_interviews > 0
        ) AS interviewed_applications,
        COUNT(offer_id) AS applications_with_offer,
        COUNT(*) FILTER (
            WHERE accepted = TRUE
        ) AS accepted_offers
    FROM applications
)
SELECT
    *,
    ROUND(
        interviewed_applications::NUMERIC
        / NULLIF(total_applications, 0) * 100, 2
    ) AS application_to_interview_rate,
    ROUND(
        applications_with_offer::NUMERIC
        / NULLIF(total_applications, 0) * 100, 2
    ) AS application_to_offer_rate,
    ROUND(
        accepted_offers::NUMERIC
        / NULLIF(applications_with_offer, 0) * 100, 2
    ) AS offer_acceptance_rate,
    ROUND(
        accepted_offers::NUMERIC
        / NULLIF(total_applications, 0) * 100, 2
    ) AS application_to_hire_rate
FROM funnel;


-- 3. TOP FIVE COMPANIES BY OFFER CONVERSION
-- ============================================================

WITH company_summary AS (
    SELECT
        company_name,
        COUNT(application_id) AS total_applications,
        COUNT(offer_id) AS total_offers
    FROM applications
    GROUP BY company_name
),
company_ranking AS (
    SELECT
        *,
        ROUND(
            total_offers::NUMERIC
            / NULLIF(total_applications, 0) * 100,
            2
        ) AS offer_conversion_rate,
        DENSE_RANK() OVER (
            ORDER BY
                total_offers::NUMERIC
                / NULLIF(total_applications, 0) DESC
        ) AS company_rank
    FROM company_summary
)
SELECT *
FROM company_ranking
WHERE company_rank <= 5
ORDER BY company_rank;


-- 4. MONTH-OVER-MONTH APPLICATION GROWTH
-- ============================================================

WITH monthly_applications AS (
    SELECT
        DATE_TRUNC('month', applied_at)::DATE AS application_month,
        COUNT(application_id) AS total_applications
    FROM applications
    GROUP BY DATE_TRUNC('month', applied_at)
),
monthly_comparison AS (
    SELECT
        *,
        LAG(total_applications) OVER (
            ORDER BY application_month
        ) AS previous_month_applications
    FROM monthly_applications
)
SELECT
    *,
    ROUND(
        (total_applications - previous_month_applications)::NUMERIC
        / NULLIF(previous_month_applications, 0) * 100,
        2
    ) AS month_over_month_growth
FROM monthly_comparison
ORDER BY application_month;


-- 5. RANK COMPANIES BY TOTAL OFFERS
-- ============================================================

WITH company_rank AS (
    SELECT
        company_name,
        COUNT(offer_id) AS total_offers,
        COUNT(application_id) AS total_applications
    FROM applications
    GROUP BY company_name
)
SELECT
    *,
    ROW_NUMBER() OVER (
        ORDER BY total_offers DESC
    ) AS company_rank
FROM company_rank
ORDER BY company_rank;


-- 6. COMPARE COMPANY OFFERS WITH OVERALL AVERAGE
-- ============================================================

WITH company_average AS (
    SELECT
        company_name,
        COUNT(offer_id) AS total_offers
    FROM applications
    GROUP BY company_name
)
SELECT
    *,
    ROUND(AVG(total_offers) OVER (), 2) AS average_company_offers
FROM company_average
ORDER BY total_offers DESC;


-- 7. COMPANIES ABOVE THE OVERALL OFFER AVERAGE
-- ============================================================

WITH company_average AS (
    SELECT
        company_name,
        COUNT(offer_id) AS total_offers
    FROM applications
    GROUP BY company_name
),
company_comparison AS (
    SELECT
        *,
        AVG(total_offers) OVER () AS average_offers
    FROM company_average
)
SELECT *
FROM company_comparison
WHERE total_offers > average_offers
ORDER BY total_offers DESC;


-- 8. OFFER CONVERSION BY INDUSTRY
-- ============================================================

WITH industry_offer AS (
    SELECT
        industry,
        COUNT(application_id) AS total_applications,
        COUNT(offer_id) AS total_offers
    FROM applications
    GROUP BY industry
)
SELECT
    *,
    ROUND(
        total_offers::NUMERIC
        / NULLIF(total_applications, 0) * 100,
        2
    ) AS offer_conversion_rate
FROM industry_offer
ORDER BY offer_conversion_rate DESC;


-- 9. SALARY ANALYSIS BY ROLE AND EXPERIENCE
-- ============================================================

SELECT
    role_family,
    CASE
        WHEN years_experience <= 2 THEN 'Fresher'
        WHEN years_experience <= 5 THEN 'Junior'
        WHEN years_experience <= 10 THEN 'Mid-level'
        ELSE 'Senior'
    END AS experience_category,
    COUNT(offer_id) AS number_of_offers,
    ROUND(AVG(base_salary), 2) AS average_salary,
    MAX(base_salary) AS highest_salary,
    MIN(base_salary) AS lowest_salary
FROM applications
WHERE offer_id IS NOT NULL
GROUP BY
    role_family,
    experience_category
ORDER BY
    role_family,
    experience_category;


-- 10. OFFER CONVERSION BY TOP SKILL AREA
-- ============================================================

WITH skills_analysis AS (
    SELECT
        top_skill_area,
        COUNT(application_id) AS total_applications,
        COUNT(offer_id) AS total_offers
    FROM applications
    GROUP BY top_skill_area
)
SELECT
    *,
    ROUND(
        total_offers::NUMERIC
        / NULLIF(total_applications, 0) * 100,
        2
    ) AS offer_conversion_rate
FROM skills_analysis
ORDER BY offer_conversion_rate DESC;


-- 11. INTERVIEW ROUND PERFORMANCE
-- ============================================================

SELECT
    round_name,
    COUNT(interview_id) AS total_interviews,
    COUNT(*) FILTER (
        WHERE result = 'pass'
    ) AS passed_interviews,
    COUNT(*) FILTER (
        WHERE result = 'fail'
    ) AS failed_interviews,
    COUNT(*) FILTER (
        WHERE result = 'hold'
    ) AS hold_interviews,
    ROUND(
        COUNT(*) FILTER (
            WHERE result = 'pass'
        )::NUMERIC
        / NULLIF(COUNT(interview_id), 0) * 100,
        2
    ) AS pass_rate
FROM interviews
GROUP BY round_name
ORDER BY round_name;


-- 12. OFFER ACCEPTANCE BY INDUSTRY
-- ============================================================

SELECT
    industry,
    COUNT(offer_id) AS total_offers,
    COUNT(*) FILTER (
        WHERE accepted = TRUE
    ) AS accepted_offers,
    COUNT(*) FILTER (
        WHERE accepted = FALSE
    ) AS rejected_offers,
    ROUND(
        COUNT(*) FILTER (
            WHERE accepted = TRUE
        )::NUMERIC
        / NULLIF(COUNT(offer_id), 0) * 100,
        2
    ) AS acceptance_rate
FROM applications
WHERE offer_id IS NOT NULL
GROUP BY industry
ORDER BY acceptance_rate DESC;


-- 13. YEAR-OVER-YEAR MONTHLY APPLICATION GROWTH
-- ============================================================

WITH monthly_applications AS (
    SELECT
        DATE_TRUNC('month', applied_at)::DATE AS application_month,
        COUNT(application_id) AS total_applications
    FROM applications
    GROUP BY DATE_TRUNC('month', applied_at)
),
yearly_comparison AS (
    SELECT
        *,
        LAG(total_applications, 12) OVER (
            ORDER BY application_month
        ) AS previous_year_month
    FROM monthly_applications
)
SELECT
    *,
    ROUND(
        (total_applications - previous_year_month)::NUMERIC
        / NULLIF(previous_year_month, 0) * 100,
        2
    ) AS year_over_year_growth
FROM yearly_comparison
ORDER BY application_month;


-- 14. TOP THREE COMPANIES IN EACH INDUSTRY
-- ============================================================

WITH company_offers AS (
    SELECT
        industry,
        company_name,
        COUNT(offer_id) AS total_offers
    FROM applications
    GROUP BY industry, company_name
),
ranked_companies AS (
    SELECT
        *,
        DENSE_RANK() OVER (
            PARTITION BY industry
            ORDER BY total_offers DESC
        ) AS company_rank
    FROM company_offers
)
SELECT *
FROM ranked_companies
WHERE company_rank <= 3
ORDER BY industry, company_rank;


-- 15. ADVANCED RECRUITMENT KPIs BY ROLE FAMILY
-- ============================================================

WITH role_summary AS (
    SELECT
        role_family,
        COUNT(application_id) AS total_applications,
        COUNT(*) FILTER (
            WHERE total_interviews > 0
        ) AS interviewed_applications,
        COUNT(offer_id) AS total_offers,
        COUNT(*) FILTER (
            WHERE accepted = TRUE
        ) AS accepted_offers
    FROM applications
    GROUP BY role_family
)
SELECT
    *,
    ROUND(
        interviewed_applications::NUMERIC
        / NULLIF(total_applications, 0) * 100,
        2
    ) AS application_to_interview_rate,
    ROUND(
        total_offers::NUMERIC
        / NULLIF(total_applications, 0) * 100,
        2
    ) AS application_to_offer_rate,
    ROUND(
        accepted_offers::NUMERIC
        / NULLIF(total_offers, 0) * 100,
        2
    ) AS offer_acceptance_rate,
    ROUND(
        accepted_offers::NUMERIC
        / NULLIF(total_applications, 0) * 100,
        2
    ) AS application_to_hire_rate
FROM role_summary
ORDER BY application_to_hire_rate DESC;


-- ============================================================
-- END OF JOB HUNT ANALYTICS SQL ANALYSIS
-- ============================================================
