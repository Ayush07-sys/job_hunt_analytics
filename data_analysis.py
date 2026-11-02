
import pandas as pd

# =========================================================
# JOB HUNT ANALYTICS
# Recruitment Application-to-Offer Funnel Analysis
# =========================================================


# 1. LOAD ALL DATASETS
# =========================================================

applications = pd.read_csv("applications.csv")
candidates = pd.read_csv("candidates.csv")
companies = pd.read_csv("companies.csv")
jobs = pd.read_csv("jobs.csv")
interviews = pd.read_csv("interviews.csv")
offers = pd.read_csv("offers.csv")

print("=" * 60)
print("JOB HUNT ANALYTICS - PYTHON DATA ANALYSIS")
print("=" * 60)
print("All six datasets loaded successfully.")


# 2. DATASET EXPLORATION
# =========================================================

print("\nAPPLICATIONS DATASET OVERVIEW")
print("Shape:", applications.shape)
print("Columns:", applications.columns.tolist())
print("\nFirst five records:")
print(applications.head())
print("\nDataset information:")
applications.info()


# 3. DATA QUALITY CHECKS
# =========================================================

applications["applied_at"] = pd.to_datetime(
    applications["applied_at"]
)

applications["application_year"] = (
    applications["applied_at"].dt.year
)

applications["application_month"] = (
    applications["applied_at"].dt.month
)

print("\nMISSING VALUES")
print(applications.isnull().sum())

print("\nDUPLICATE ROWS")
print(applications.duplicated().sum())

print("\nAPPLICATION STAGES")
print(applications["stage"].value_counts())


# 4. RECRUITMENT FUNNEL ANALYSIS
# =========================================================

total_applications = len(applications)

stage_counts = applications["stage"].value_counts()

stage_percentages = (
    stage_counts / total_applications * 100
).round(2)

print("\nRECRUITMENT FUNNEL")
print(stage_counts)

print("\nRECRUITMENT FUNNEL PERCENTAGES")
print(stage_percentages)


# 5. APPLICATION SOURCE ANALYSIS
# =========================================================

source_analysis = applications.groupby("source").agg(
    total_applications=("application_id", "count"),
    average_score=("score", "mean")
)

source_analysis["average_score"] = (
    source_analysis["average_score"].round(2)
)

print("\nAPPLICATION SOURCE ANALYSIS")
print(
    source_analysis.sort_values(
        by="total_applications",
        ascending=False
    )
)


# 6. MONTHLY APPLICATION TRENDS
# =========================================================

monthly_trends = (
    applications.groupby(
        ["application_year", "application_month"]
    )
    .size()
    .reset_index(name="total_applications")
)

print("\nMONTHLY APPLICATION TRENDS")
print(monthly_trends)


# 7. APPLICATION SCORE ANALYSIS
# =========================================================

print("\nAPPLICATION SCORE SUMMARY")
print(applications["score"].describe())

score_by_stage = (
    applications.groupby("stage")["score"]
    .mean()
    .round(3)
)

print("\nAVERAGE SCORE BY STAGE")
print(score_by_stage)


# 8. MERGE DATASETS
# =========================================================

final_df = applications.merge(
    candidates,
    on="candidate_id",
    how="left",
    validate="many_to_one"
)

final_df = final_df.merge(
    jobs,
    on="job_id",
    how="left",
    validate="many_to_one"
)

final_df = final_df.merge(
    companies,
    on="company_id",
    how="left",
    validate="many_to_one"
)

final_df = final_df.merge(
    offers,
    on="application_id",
    how="left",
    validate="one_to_one"
)

# Summarise interviews before merging.
# This keeps one row per application.

interview_summary = (
    interviews.groupby("application_id")
    .agg(
        total_interviews=("interview_id", "count")
    )
    .reset_index()
)

final_df = final_df.merge(
    interview_summary,
    on="application_id",
    how="left",
    validate="one_to_one"
)

final_df["total_interviews"] = (
    final_df["total_interviews"].fillna(0).astype(int)
)

print("\nFINAL MERGED DATASET")
print("Shape:", final_df.shape)
print(final_df.head())


# 9. INTERVIEW ANALYSIS
# =========================================================

interview_analysis = interviews.groupby("round_name").agg(
    total_interviews=("interview_id", "count"),
    passed_interviews=(
        "result",
        lambda values: (values == "pass").sum()
    ),
    failed_interviews=(
        "result",
        lambda values: (values == "fail").sum()
    ),
    hold_interviews=(
        "result",
        lambda values: (values == "hold").sum()
    )
)

interview_analysis["pass_rate"] = (
    interview_analysis["passed_interviews"]
    / interview_analysis["total_interviews"] * 100
).round(2)

print("\nINTERVIEW ROUND ANALYSIS")
print(interview_analysis)


# 10. OFFER ACCEPTANCE ANALYSIS
# =========================================================

total_offers = final_df["offer_id"].count()

accepted_offers = (
    final_df["accepted"].eq(True).sum()
)

rejected_offers = (
    final_df["accepted"].eq(False).sum()
)

acceptance_rate = (
    accepted_offers / total_offers * 100
    if total_offers else 0
)

print("\nOFFER ACCEPTANCE ANALYSIS")
print("Total Offers:", total_offers)
print("Accepted Offers:", accepted_offers)
print("Rejected Offers:", rejected_offers)
print("Offer Acceptance Rate:", round(acceptance_rate, 2), "%")


# 11. INDUSTRY OFFER CONVERSION
# =========================================================

industry_analysis = final_df.groupby("industry").agg(
    total_applications=("application_id", "count"),
    total_offers=("offer_id", "count")
)

industry_analysis["offer_conversion_rate"] = (
    industry_analysis["total_offers"]
    / industry_analysis["total_applications"] * 100
).round(2)

print("\nINDUSTRY OFFER CONVERSION")
print(
    industry_analysis.sort_values(
        by="offer_conversion_rate",
        ascending=False
    )
)


# 12. SALARY ANALYSIS BY ROLE FAMILY
# =========================================================

salary_analysis = (
    final_df[final_df["offer_id"].notna()]
    .groupby("role_family")
    .agg(
        total_offers=("offer_id", "count"),
        average_salary=("base_salary", "mean"),
        highest_salary=("base_salary", "max"),
        lowest_salary=("base_salary", "min")
    )
)

salary_analysis = salary_analysis.round(2)

print("\nSALARY ANALYSIS BY ROLE FAMILY")
print(salary_analysis)


# 13. FINAL RECRUITMENT KPIs
# =========================================================

total_applications = len(final_df)

interviewed_applications = (
    final_df["total_interviews"].gt(0).sum()
)

total_offers = final_df["offer_id"].count()

accepted_offers = (
    final_df["accepted"].eq(True).sum()
)

application_to_interview_rate = (
    interviewed_applications / total_applications * 100
    if total_applications else 0
)

application_to_offer_rate = (
    total_offers / total_applications * 100
    if total_applications else 0
)

offer_acceptance_rate = (
    accepted_offers / total_offers * 100
    if total_offers else 0
)

application_to_hire_rate = (
    accepted_offers / total_applications * 100
    if total_applications else 0
)

print("\nFINAL RECRUITMENT KPIs")
print("Total Applications:", total_applications)
print("Interviewed Applications:", interviewed_applications)
print("Total Offers:", total_offers)
print("Accepted Offers:", accepted_offers)

print(
    "Application-to-Interview Rate:",
    round(application_to_interview_rate, 2), "%"
)

print(
    "Application-to-Offer Rate:",
    round(application_to_offer_rate, 2), "%"
)

print(
    "Offer Acceptance Rate:",
    round(offer_acceptance_rate, 2), "%"
)

print(
    "Application-to-Hire Rate:",
    round(application_to_hire_rate, 2), "%"
)


# 14. EXPORT FINAL DATASET
# =========================================================

final_df.to_csv(
    "final_recruitment_data.csv",
    index=False
)

print("\nFINAL DATASET EXPORTED")
print("File: final_recruitment_data.csv")
print("Final dataset shape:", final_df.shape)

print("\n" + "=" * 60)
print("PYTHON ANALYSIS COMPLETED SUCCESSFULLY")
print("=" * 60)
