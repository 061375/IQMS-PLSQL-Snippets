
# aq_trigger_bi_ps_ticket
## When a user moves the center schedule position this adds a zero location for the work order.
## Jeremy Heminger <jeremy.heminger@aquamor.com>, <contact@jeremyheminger.com>

                                                ᓚᘏᗢ



# Versions

## 📅 May 17, 2025
## ⬆️📅 June 1, 2025
## ⬆️ 1.0.0.6

*   🐞 KNOWN - Currently the extraction of the data from the Rich Text editor only allows for all upper case and no formatting or it will strip letters

* ## 1.0.0.6
*   🐞 use cntr_seq column on cntr_sched table in order to avoid conflict with update schedule feature
* ## 1.0.0.5
*   🐞 date comparison method was incorrect
* ## 1.0.0.4
*   🐞 handle daily Update Schedule conflict
* ## 1.0.0.3
*   🐱 filter by building 1
* ## 1.0.0.2
*   🐞 make sure the first select is only using FG
* ## 1.0.0.1
*   🐱 allow multiple batches 
* ## 1.0.0.0
