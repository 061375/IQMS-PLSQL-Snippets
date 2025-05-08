# v_aq_search_iqalert_sql
## quickly search IQALERT tables that have SQL queries attached
## Jeremy Heminger <contact@jeremyheminger.com>

                                                ᓚᘏᗢ

# select * from v_aq_search_iqalert_sql where upper(detail_sql) like upper('%releases%')


# Versions

## 📅 January 12, 2024
## ⬆️📅 November 7, 2024

* ## 1.0.0.2
*  🐱 add email subject for easier search of email alerts
* ## 1.0.0.1
* 	🐞 not all alerts are attached to a group
* ## 1.0.0.0