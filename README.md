# 🏥 Health Insurance Claim Fraud Detection using SAS

This project demonstrates an end-to-end pipeline for detecting potentially fraudulent health insurance claims using **SAS**. By combining statistical methods (like IQR-based outlier detection) with domain-specific business rules, the system identifies suspicious claims based on claim amount, patient income, and demographic behavior.

---

## 📌 Project Summary

- 🔍 **Objective**: Identify and flag suspicious health insurance claims based on statistical anomalies and risk factors.
- 📊 **Approach**: Rule-based detection + clustering + logistic regression
- 🛠️ **Tools**: SAS Studio, PROC UNIVARIATE, PROC FASTCLUS, PROC LOGISTIC
- 📁 **Dataset**: [Enhanced Health Insurance Claims Dataset on Kaggle](https://www.kaggle.com/datasets/leandrenash/enhanced-health-insurance-claims-dataset)
- 📈 **Output**: Flags, cluster insights, risk scores, and visual analytics

---

## 🧠 Key Techniques
- IQR-based outlier detection for claim amounts
- Claim-to-income ratio as a risk metric
- Composite fraud risk scoring
- Clustering with `PROC FASTCLUS` to identify behavioral segments
- Logistic regression to model fraud likelihood

---

## 🔎 Use Case

Ideal for insurers, analysts, or healthcare researchers who want to:
- Build interpretable fraud detection systems
- Analyze claim risk with minimal labeled data
- Apply SAS to real-world anomaly detection problems
