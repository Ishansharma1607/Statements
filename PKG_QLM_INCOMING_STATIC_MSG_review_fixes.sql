SET DEFINE OFF
/
CREATE OR REPLACE PACKAGE QLM_OWNER.PKG_QLM_INCOMING_STATIC_MSG
AS
/*
*********************************************************************************************************
Package Name   : PKG_QLM_INCOMING_STATIC_MSG
Last Updated   : 02/Jun/2026
Created By     : Saipriya Damarapati
Description    : C166472-2144 :: Static Holiday upload from Flexcube to QFXLM
Modified by			Modified date	Change Description
Saipriya			08-Aug-2019		C166472-2123 :: Static Customer Accounts upload from Flexcube to QFXLM
Saipriya			19-Sep-2019		Add customer from ISG cloud stage if customer doesn't exist
Gowtham P			05/May/2020		C166472-1016 : QFX DBS Handoff credit and debit gl
Muniappan Mohanraj	19-Jun-2020		JIRA - 5225 - Changed the input parameter condition for p_threshold_amt, p_generate_receive_notice
Muniappan Mohanraj	02-Jul-2020		JIRA - 5343 - Changed the input parameter condition for p_rd_acc_no
Muniappan Mohanraj	23-Jul-2020		JIRA - 5373 - adding lv_trade_details_mm and lv_trade_details_fx for propagation
Muniappan Mohanraj	17/Aug/2020		Updating the acc_branch with alpha_branch_code
Swathi R 	        26/Aug/2020     C166472-5615 - Customer/ Account deactivation (ISG) changes
Muniappan Mohanraj	01/Sep/2020		Updating the threshold_amt and receive_notice flag for editions
Chandramohan S      09/Oct/2020     C166472-6144 -- Handled new input parameter in prc_save_customer_accounts_q
Padmini M			09/Dec/2020		C166472-6034 -- added new table for Customer Account propagation
Maharaja S			01/Feb/2021     C166472-6734 Skip balance check for compen account changes internal_account_flag input parameter in prc_save_customer_accounts_q
Vishal.S			08/Feb/2021		C166472-6034: Flexcube-QFXLM customer account online:catch up previous records
Suganya				25/May/2021		To update Flex Holiday
Priyadharsini 		07-Jun-2021		C166472-7149 QFXLM NAM -eTacs TimeStamp change
Akhila M			01/Nov/2023		C166472-16456 - QFXLM : NYK : Customer Base Number Handling
Karthikeyan G		05/Nov/2023		C166472-16649 - Customer account maintenance in QFXLM - 0 padding
Karthikeyan G		01/Jan/2024		C166472-16388: Charge Details changes
Vinoth G			14/May/2024		C166472-20053 : QFXLM | APAC | FX | 24.03 Post Production issues
Sai Annam			16/May/2024		C166472-19893 : C166472-19893- customer account additional info- IBAN column addition
Arunkumar B			19/Jun/2024		C166472-20251 : Customer Account is not created automatically when the Customer Account received early to Customer Static
Karthikeyan G		06/Aug/2024		C166472-21772 - Customer account Derivation Logic Changes
Karthikeyan G		13/Aug/2024		C166472-21772 - changes to get the FLEX_ISG is Maintained branch code.-In General it will be maintained for Primary BRanch
Karthikeyan G		27/Aug/2024		C166472-21772 - Changes in the Length of Customer Account
Padma				08/May/2025		C166472-27250 - Global - FX - ISG Cross Branch Flow for Customer Accounts not working
Jegannathan B       19/May/2025     C166472-27420 - Client account entries are existing without S01 and S04 in Prefix under Account.no lookup
Akhila M			23/Jun/2025		C166472-28093 - QFXLM PL - Data Consumption from ISG Cloud - Base & Account Number
JayavanthKumar A    26/Jun/2025     C166472-28605 - Changes to Consume Acti from ISG for Customer Accounts.
JayavanthKumar A    04/Jul/2025     C166472-28822 - Changes to Update the Acti
JayavanthKumar A    07/Oct/2025     C166472-31475 - fix for Etacs message consumption in log table
Aharamuthalvan      20/Nov/2025     C166472-32521 - Exception block refinement
Abirami     		11/Nov/2025		C166472-31979 - Enhance to log customer account from ISG in qlm_incoming_static_msg
Abirami             05/Jan/2026     C166472-33304 - Changes in paramter positions for ISG FLOW : Customer Acc no is not getting populated
Raghul R            17/Mar/2026     C166472-33636 - IBAN account number consumption
Adyasha Parida      08/Apr/2026         C166472-35511-India FX- Account_category Field consuption from AMCAR messsage
Akhila M            22/May/2026     C166472-37277 - QFXLM PL SD Mig - Customer Account# from ISG Cloud to QLM_CUSTOMER_ACCOUNTS table
Sandagorda P        02/Jun/2026     C166472-37161 - Change maker/checker IDs from SYSTEM to ISGDATA for ISG Cloud Customer Account Records
Pravallika S        16/Oct/2026     C166472-43045 - Added wrapper procedure prc_mlv_conf_party_bic for party BIC maintenance
Ishan Sharma        12/Nov/2026     C166472-43178 - Added MLV Customer Message Address wrapper.
*********************************************************************************************************
*/
    PROCEDURE prc_log_incoming_static_msg
    (
        p_static_type         IN  qlm_incoming_static_msg.static_type%TYPE,
        p_fo_branch_code      IN  qlm_incoming_static_msg.fo_branch_code%TYPE,
        p_incoming_static_msg IN  tab_incoming_static_msg,
        p_in_or_out           IN  qlm_incoming_static_msg.in_or_out%TYPE,
        p_msg_status          IN  qlm_incoming_static_msg.msg_status%TYPE,
        p_source_system       IN  qlm_incoming_static_msg.source_system%TYPE,
        p_success_flag        OUT VARCHAR2,
        p_error_message       OUT VARCHAR2,
        p_customer_code       IN  qlm_incoming_static_msg.customer_code%TYPE DEFAULT NULL,
        p_customer_acc        IN  qlm_incoming_static_msg.customer_acc_no%TYPE DEFAULT NULL,
        p_msgtimestamp        IN  qlm_incoming_static_msg.TRAN_DATE%TYPE DEFAULT SYSTIMESTAMP
    );

    PROCEDURE prc_static_hol_upload
    (
        p_year           IN  VARCHAR2,
        p_holidays       IN  tab_static_holiday_list,
        p_fo_branch_code IN  qlm_branch.alpha_branch_code%TYPE,
        p_success_flag   OUT VARCHAR2,
        p_error_message  OUT VARCHAR2
    );

    PROCEDURE prc_mlv_conf_party_bic
    (
        p_user_id                     IN  qlm_conf_party_bic_q.maker_id%TYPE,
        p_auto_auth_flag              IN  PLS_INTEGER,
        p_action                      IN  qlm_conf_party_bic_q.action%TYPE,
        p_branch_code                 IN  VARCHAR2,
        p_customer_code               IN  qlm_conf_party_bic_q.customer_code%TYPE,
        p_module                      IN  qlm_conf_party_bic_q.module%TYPE,
        p_location                    IN  qlm_conf_party_bic_q.location%TYPE,
        p_party_83_flag               IN  qlm_conf_party_bic_q.party_83_flag%TYPE,
        p_party_83_bic_code           IN  qlm_conf_party_bic_q.party_83_bic_code%TYPE,
        p_party_83_value_1            IN  qlm_conf_party_bic_q.party_83_value_1%TYPE,
        p_party_83_value_2            IN  qlm_conf_party_bic_q.party_83_value_2%TYPE,
        p_party_83_value_3            IN  qlm_conf_party_bic_q.party_83_value_3%TYPE,
        p_party_83cls_flag            IN  qlm_conf_party_bic_q.party_83cls_flag%TYPE,
        p_party_83cls_bic_code        IN  qlm_conf_party_bic_q.party_83cls_bic_code%TYPE,
        p_party_83cls_value_1         IN  qlm_conf_party_bic_q.party_83cls_value_1%TYPE,
        p_party_83cls_value_2         IN  qlm_conf_party_bic_q.party_83cls_value_2%TYPE,
        p_party_83cls_value_3         IN  qlm_conf_party_bic_q.party_83cls_value_3%TYPE,
        p_party_87_flag               IN  qlm_conf_party_bic_q.party_87_flag%TYPE,
        p_party_87_bic_code           IN  qlm_conf_party_bic_q.party_87_bic_code%TYPE,
        p_party_87_value_1            IN  qlm_conf_party_bic_q.party_87_value_1%TYPE,
        p_party_87_value_2            IN  qlm_conf_party_bic_q.party_87_value_2%TYPE,
        p_party_87_value_3            IN  qlm_conf_party_bic_q.party_87_value_3%TYPE,
        p_pri_pay_sndr_rcvr_info_flag IN  qlm_conf_party_bic_q.pri_pay_sndr_rcvr_info_flag%TYPE,
        p_pri_pay_sndr_rcvr_info1     IN  qlm_conf_party_bic_q.pri_pay_sndr_rcvr_info1%TYPE,
        p_pri_pay_sndr_rcvr_info2     IN  qlm_conf_party_bic_q.pri_pay_sndr_rcvr_info2%TYPE,
        p_pri_pay_sndr_rcvr_info3     IN  qlm_conf_party_bic_q.pri_pay_sndr_rcvr_info3%TYPE,
        p_pri_pay_sndr_rcvr_info4     IN  qlm_conf_party_bic_q.pri_pay_sndr_rcvr_info4%TYPE,
        p_pri_pay_sndr_rcvr_info5     IN  qlm_conf_party_bic_q.pri_pay_sndr_rcvr_info5%TYPE,
        p_pri_pay_sndr_rcvr_info6     IN  qlm_conf_party_bic_q.pri_pay_sndr_rcvr_info6%TYPE,
        p_copied_from_pri_branch_flag IN  qlm_conf_party_bic_q.copied_from_pri_branch_flag%TYPE,
        p_copy_to_sub_branch_flag     IN  qlm_conf_party_bic_q.copy_to_sub_branch_flag%TYPE,
        p_currency_code               IN  qlm_conf_party_bic_q.currency_code%TYPE DEFAULT '000',
        p_version                     IN  qlm_conf_party_bic_q.version%TYPE,
        p_active_flag                 IN  qlm_conf_party_bic_q.active_flag%TYPE,
        p_party_57_buy_flag           IN  qlm_conf_party_bic_q.party_57_buy_flag%TYPE,
        p_party_57_buy_bic_code       IN  qlm_conf_party_bic_q.party_57_buy_bic_code%TYPE,
        p_party_57_buy_value_1        IN  qlm_conf_party_bic_q.party_57_buy_value_1%TYPE,
        p_party_57_buy_value_2        IN  qlm_conf_party_bic_q.party_57_buy_value_2%TYPE,
        p_party_57_buy_value_3        IN  qlm_conf_party_bic_q.party_57_buy_value_3%TYPE,
        p_party_57_buy_value_4        IN  qlm_conf_party_bic_q.party_57_buy_value_4%TYPE,
        p_party_57_sell_flag          IN  qlm_conf_party_bic_q.party_57_sell_flag%TYPE,
        p_party_57_sell_bic_code      IN  qlm_conf_party_bic_q.party_57_sell_bic_code%TYPE,
        p_party_57_sell_value_1       IN  qlm_conf_party_bic_q.party_57_sell_value_1%TYPE,
        p_party_57_sell_value_2       IN  qlm_conf_party_bic_q.party_57_sell_value_2%TYPE,
        p_party_57_sell_value_3       IN  qlm_conf_party_bic_q.party_57_sell_value_3%TYPE,
        p_party_57_sell_value_4       IN  qlm_conf_party_bic_q.party_57_sell_value_4%TYPE,
        p_party_57_flag               IN  qlm_conf_party_bic_q.party_57_flag%TYPE,
        p_party_57_bic_code           IN  qlm_conf_party_bic_q.party_57_bic_code%TYPE,
        p_party_57_value1             IN  qlm_conf_party_bic_q.party_57_value1%TYPE,
        p_party_57_value2             IN  qlm_conf_party_bic_q.party_57_value2%TYPE,
        p_party_57_value3             IN  qlm_conf_party_bic_q.party_57_value3%TYPE,
        p_party_57_value4             IN  qlm_conf_party_bic_q.party_57_value4%TYPE,
        p_party_53_flag               IN  qlm_conf_party_bic_q.party_53_flag%TYPE,
        p_party_53_bic_code           IN  qlm_conf_party_bic_q.party_53_bic_code%TYPE,
        p_party_53_value1             IN  qlm_conf_party_bic_q.party_53_value1%TYPE,
        p_party_53_value2             IN  qlm_conf_party_bic_q.party_53_value2%TYPE,
        p_party_53_value3             IN  qlm_conf_party_bic_q.party_53_value3%TYPE,
        p_party_53_value4             IN  qlm_conf_party_bic_q.party_53_value4%TYPE,
        p_party_56_ta_buy_lcy_flag    IN  qlm_conf_party_bic_q.party_56_ta_buy_lcy_flag%TYPE,
        p_party_56_ta_bic_code        IN  qlm_conf_party_bic_q.party_56_ta_bic_code%TYPE,
        p_party_83_value_4            IN  qlm_conf_party_bic_q.party_83_value_4%TYPE,
        p_party_83cls_value_4         IN  qlm_conf_party_bic_q.party_83cls_value_4%TYPE,
        p_party_87_value_4            IN  qlm_conf_party_bic_q.party_87_value_4%TYPE,
        p_party_56_sell_flag          IN  qlm_conf_party_bic_q.party_56_sell_flag%TYPE,
        p_party_56_sell_bic_code      IN  qlm_conf_party_bic_q.party_56_sell_bic_code%TYPE,
        p_success_flag                OUT VARCHAR2,
        p_error_message               OUT VARCHAR2
    );

    PROCEDURE prc_static_cust_acc_update
    (
        p_customer_code          IN  qlm_customer_accounts_q.customer_code%TYPE,
        p_acc_number             IN  qlm_customer_accounts_q.acc_number%TYPE,
        p_acc_currency           IN  qlm_customer_accounts_q.acc_currency%TYPE,
        p_acc_description        IN  qlm_customer_accounts_q.acc_description%TYPE,
        p_credit_gl_acc          IN  qlm_customer_accounts.linked_gl_acc%TYPE,
        p_debit_gl_acc           IN  qlm_customer_accounts.linked_gl_acc%TYPE,
        p_threshold_amt          IN  qlm_customer_accounts.threshold_amt%TYPE,
        p_generate_receive_notice IN qlm_customer_accounts.generate_receive_notice%TYPE,
        p_rd_acc_no              IN  qlm_customer_accounts.rd_acc_no%TYPE,
        p_charge_details         IN  qlm_customer_accounts_q.charge_details%TYPE,
        p_alternate_acc_number   IN  qlm_customer_accounts_q.alternate_acc_number%TYPE,
        p_acc_open_date          IN  qlm_customer_accounts_q.acc_open_date%TYPE,
        p_account_class          IN  qlm_customer_accounts_q.account_class%TYPE,
        p_cost_center            IN  qlm_customer_accounts_q.cost_center%TYPE,
        p_active_flag            IN  qlm_customer_accounts_q.active_flag%TYPE,
        p_alpha_branch_code      IN  qlm_branch.alpha_branch_code%TYPE,
        p_ext_system             IN  VARCHAR2,
        p_actId                  IN  qlm_customer_accounts.acti%TYPE DEFAULT NULL,
        p_iban_acc_no            IN  qlm_customer_accounts.iban_acc_no%TYPE,
        p_acc_category           IN  qlm_customer_accounts.acc_category%TYPE,
        p_success_flag           OUT VARCHAR2,
        p_error_message          OUT VARCHAR2,
        p_trade_details_mm       OUT SYS_REFCURSOR,
        p_trade_details_fx       OUT SYS_REFCURSOR,
        p_trade_details_fi       OUT SYS_REFCURSOR
    );

    PROCEDURE prc_mlv_customer_addl_info
    (
        p_user_id                       IN  qlm_customer_addl_info.maker_id%TYPE,
        p_auto_auth_flag                IN  PLS_INTEGER,
        p_action                        IN  qlm_customer_addl_info_q.action%TYPE,
        p_branch_code                   IN  qlm_branch.alpha_branch_code%TYPE,
        p_customer_code                 IN  qlm_customer_addl_info.customer_code%TYPE,
        p_pay_type_pref                 IN  qlm_customer_addl_info.pay_type_pref%TYPE,
        p_csr_code                      IN  qlm_customer_addl_info.csr_code%TYPE,
        p_fx_stlmnt_risk_grp            IN  qlm_customer_addl_info.fx_stlmnt_risk_grp%TYPE,
        p_inrnl_trade_grp               IN  qlm_customer_addl_info.inrnl_trade_grp%TYPE,
        p_charge_details                IN  qlm_customer_addl_info.charge_details%TYPE,
        p_casual_netter_flag            IN  qlm_customer_addl_info.casual_netter_flag%TYPE,
        p_pri_casual_netter_flag        IN  qlm_customer_addl_info.pri_casual_netter_flag%TYPE,
        p_pri_casual_cust               IN  qlm_customer_addl_info.pri_casual_cust%TYPE,
        p_credit_check_reqd_flag        IN  qlm_customer_addl_info.credit_check_reqd_flag%TYPE,
        p_credit_check                  IN  qlm_customer_addl_info.credit_check%TYPE,
        p_future_check_flag             IN  qlm_customer_addl_info.future_check_flag%TYPE,
        p_credit_check_effective_date   IN  qlm_customer_addl_info.credit_check_effective_date%TYPE,
        p_tracer_reqd_flag              IN  qlm_customer_addl_info.tracer_reqd_flag%TYPE,
        p_tracer_days                   IN  qlm_customer_addl_info.tracer_days%TYPE,
        p_tracer_first_day              IN  qlm_customer_addl_info.tracer_first_day%TYPE,
        p_eod_trade_sum_reqd_flag       IN  qlm_customer_addl_info.eod_trade_sum_reqd_flag%TYPE,
        p_eod_netting_sum_reqd_flag     IN  qlm_customer_addl_info.eod_netting_sum_reqd_flag%TYPE,
        p_eod_stlmnt_sum_reqd_flag      IN  qlm_customer_addl_info.eod_stlmnt_sum_reqd_flag%TYPE,
        p_cust_withholding_tax_flag     IN  qlm_customer_addl_info.customer_withholding_tax_flag%TYPE,
        p_customer_tax_group            IN  qlm_customer_addl_info.customer_tax_group%TYPE,
        p_dvp_flag                      IN  qlm_customer_addl_info.dvp_flag%TYPE,
        p_dvp_rule                      IN  qlm_customer_addl_info.dvp_rule%TYPE,
        p_spot_waive_inc_conf_flag      IN  qlm_customer_addl_info.spot_waive_incoming_conf_flag%TYPE,
        p_no_conf_no_pay_indctr_flag    IN  qlm_customer_addl_info.no_conf_no_pay_indctr_flag%TYPE,
        p_include_fx_online_bal_flag    IN  qlm_customer_addl_info.include_fx_online_bal_chk_flag%TYPE,
        p_hold_liquidation_flag         IN  qlm_customer_addl_info.hold_liquidation_flag%TYPE,
        p_include_breakage_fee_flag     IN  qlm_customer_addl_info.include_breakage_fee_flag%TYPE,
        p_include_brokerage_fee_flag    IN  qlm_customer_addl_info.include_brokerage_fee_flag%TYPE,
        p_local_clearing_flag           IN  qlm_customer_addl_info.local_clearing_flag%TYPE,
        p_bulk_auth_flag                IN  qlm_customer_addl_info.bulk_auth_flag%TYPE,
        p_suppress_paper_conf_flag      IN  qlm_customer_addl_info.suppress_paper_conf_flag%TYPE,
        p_suppress_email_conf_flag      IN  qlm_customer_addl_info.suppress_email_conf_flag%TYPE,
        p_suppress_fax_conf_flag        IN  qlm_customer_addl_info.suppress_fax_conf_flag%TYPE,
        p_suppress_mt54x_flag           IN  qlm_customer_addl_info.suppress_mt54x_flag%TYPE,
        p_department_code               IN  qlm_customer_addl_info.department_code%TYPE, /*24/sep/2013*/
        p_sales_person_id               IN  qlm_customer_addl_info.sales_person_id%TYPE,
        p_retail_netting_flag           IN  qlm_customer_addl_info.retail_netting_flag%TYPE,
        p_rn_stlmnt_ccy                 IN  qlm_customer_addl_info.rn_stlmnt_ccy%TYPE,
        p_stlmnt_pri_flag               IN  qlm_customer_addl_info.stlmnt_pri_flag%TYPE,
        p_stlmnt_pri_customer           IN  qlm_customer_addl_info.stlmnt_pri_customer%TYPE,
        p_mt304_effective_date          IN  qlm_customer_addl_info.mt304_effective_date%TYPE,
        p_mt304_effective_date_basis    IN  qlm_customer_addl_info.mt304_effective_date_basis%TYPE,
        p_mca_eligible_flag             IN  qlm_customer_addl_info.mca_eligible_flag%TYPE,
        p_mca_effective_date            IN  qlm_customer_addl_info.mca_effective_date%TYPE,
        p_mts_deal_flag                 IN  qlm_customer_addl_info.mts_deal_flag%TYPE,
        p_itg_many_to_many_flag         IN  qlm_customer_addl_info.itg_many_to_many_flag%TYPE,
        p_wfdo_conf_for_draws_flag      IN  qlm_customer_addl_info.wfdo_conf_for_draws_flag%TYPE,
        p_pbg_customer_flag             IN  qlm_customer_addl_info.pbg_customer_flag%TYPE,
        p_skip_sundry_process_flag      IN  qlm_customer_addl_info.skip_sundry_process_flag%TYPE,
        p_affiliate_code                IN  qlm_customer_addl_info.affiliate_code%TYPE,
        p_sic_code                      IN  qlm_customer_addl_info.sic_code%TYPE,
        p_itg_flag                      IN  qlm_customer_addl_info.itg_flag%TYPE,
        p_itg_type                      IN  qlm_customer_addl_info.itg_type%TYPE,
        p_generate_mt304_flag           IN  qlm_customer_addl_info.generate_mt304_flag%TYPE,
        p_mt304_send_to_cp              IN  qlm_customer_addl_info.mt304_send_to_cp%TYPE,
        p_suppress_si_conf_flag         IN  qlm_customer_addl_info.suppress_si_conf_flag%TYPE,
        p_customer_model                IN  qlm_customer_addl_info.customer_model%TYPE,
        p_customer_classification       IN  qlm_customer_addl_info.customer_classification%TYPE,
        p_cust_group                    IN  qlm_customer_addl_info.cust_group%TYPE,
        p_fo_short_name                 IN  qlm_customer_addl_info.fo_short_name%TYPE,
        p_fo_long_name                  IN  qlm_customer_addl_info.fo_long_name%TYPE,
        p_cls_member_type               IN  qlm_customer_addl_info.cls_member_type%TYPE,
        p_cls_agent                     IN  qlm_customer_addl_info.cls_agent%TYPE,
        p_uti_in_out_conf               IN  qlm_customer_addl_info.uti_in_out_conf%TYPE,
        p_cancel_queue_required_flag    IN  qlm_customer_addl_info.cancel_queue_required_flag%TYPE,
        p_skip_dual_authorization       IN  qlm_customer_addl_info.skip_dual_authorization%TYPE,
        p_no_credit_facility_flag       IN  qlm_customer_addl_info.no_credit_facility_flag%TYPE,
        p_transfer_type                 IN  qlm_customer_addl_info.transfer_type%TYPE,
        p_external_client               IN  qlm_customer_addl_info.external_client%TYPE,
        p_intermediary_cust             IN  qlm_customer_addl_info.intermediary_cust%TYPE,
        p_mt103_tag_23e                 IN  qlm_customer_addl_info.mt103_tag_23e%TYPE,
        p_citi_ny_acc                   IN  qlm_customer_addl_info.citi_ny_acc%TYPE,
        p_dda_enabled                   IN  qlm_customer_addl_info.dda_enabled%TYPE,
        p_customer_identification       IN  qlm_customer_addl_info.customer_identification%TYPE,
        p_modules                       IN  qlm_customer_addl_info.modules%TYPE,
        p_parent_base_no                IN  qlm_customer_addl_info.parent_base_no%TYPE,
        p_addl_customer_category        IN  qlm_customer_addl_info.addl_customer_category%TYPE,
        p_customer_type1                IN  qlm_customer_addl_info.customer_type1%TYPE,
        p_customer_type2                IN  qlm_customer_addl_info.customer_type2%TYPE,
        p_us_sic_code                   IN  qlm_customer_addl_info.us_sic_code%TYPE,
        p_location_ccy                  IN  qlm_customer_addl_info.location_ccy%TYPE,
        p_restricted_acc_flag           IN  qlm_customer_addl_info.restricted_acc_flag%TYPE,
        p_restricted_effective_date     IN  qlm_customer_addl_info.restricted_effective_date%TYPE,
        p_restricted_branch             IN  qlm_customer_addl_info.restricted_branch%TYPE,
        p_continuous_roll_flag          IN  qlm_customer_addl_info.continuous_roll_flag%TYPE,
        p_customer_goc                  IN  qlm_customer_addl_info.customer_goc%TYPE,
        p_place                         IN  qlm_customer_addl_info.place%TYPE,
        p_customer_ouc                  IN  qlm_customer_addl_info.customer_ouc%TYPE,
        p_cb2_flag                      IN  qlm_customer_addl_info.cb2_flag%TYPE,
        p_nygc_flag                     IN  qlm_customer_addl_info.nygc_flag%TYPE,
        p_fx_spl_q_reqd_flag            IN  qlm_customer_addl_info.fx_spl_q_reqd_flag%TYPE,
        p_mm_spl_q_reqd_flag            IN  qlm_customer_addl_info.mm_spl_q_reqd_flag%TYPE,
        p_fi_buy_spl_q_reqd_flag        IN  qlm_customer_addl_info.fi_buy_spl_q_reqd_flag%TYPE,
        p_fi_sell_spl_q_reqd_flag       IN  qlm_customer_addl_info.fi_sell_spl_q_reqd_flag%TYPE,
        p_fi_rep_spl_q_reqd_flag        IN  qlm_customer_addl_info.fi_rep_spl_q_reqd_flag%TYPE,
        p_fi_rev_spl_q_reqd_flag        IN  qlm_customer_addl_info.fi_rev_spl_q_reqd_flag%TYPE,
        p_fi_wtk_spl_q_reqd_flag        IN  qlm_customer_addl_info.fi_wtk_spl_q_reqd_flag%TYPE,
        p_fi_wgv_spl_q_reqd_flag        IN  qlm_customer_addl_info.fi_wgv_spl_q_reqd_flag%TYPE,
        p_fi_len_spl_q_reqd_flag        IN  qlm_customer_addl_info.fi_len_spl_q_reqd_flag%TYPE,
        p_fi_bor_spl_q_reqd_flag        IN  qlm_customer_addl_info.fi_bor_spl_q_reqd_flag%TYPE,
        p_customer_tax_id               IN  qlm_customer_addl_info.customer_tax_id%TYPE,
        p_copied_from_pri_branch_flag   IN  qlm_customer_addl_info.copied_from_pri_branch_flag%TYPE DEFAULT 0,
        p_copy_to_sub_Branch_flag       IN  qlm_customer_addl_info.copy_to_sub_Branch_flag%TYPE DEFAULT 0,
        p_tts_customer_flag             IN  qlm_customer_addl_info.tts_customer_flag%TYPE,
        p_suppress_sdr_flag             IN  qlm_customer_addl_info.suppress_sdr_flag%TYPE,
        p_full_movement_flag            IN  qlm_customer_addl_info.full_movement_flag%TYPE,
        p_suppress_mt518_flag           IN  qlm_customer_addl_info.suppress_mt518_flag%TYPE,
        p_version                       IN  qlm_customer_addl_info.version%TYPE,
        p_active_flag                   IN  qlm_customer_addl_info.active_flag%TYPE,
        p_supp_cls_new_conf_flag        IN  qlm_customer_addl_info.supp_cls_new_conf_flag%TYPE,
        p_supp_cls_amend_conf_flag      IN  qlm_customer_addl_info.supp_cls_amend_conf_flag%TYPE,
        p_supp_cls_can_conf_flag        IN  qlm_customer_addl_info.supp_cls_can_conf_flag%TYPE,
        p_swift_confo_code_94a          IN  qlm_customer_addl_info.swift_confo_code_94a%TYPE,
        p_upstream_sys_ref              IN  qlm_customer_addl_info.upstream_sys_ref%TYPE,
        p_pershing_flag                 IN  qlm_customer_addl_info.pershing_flag%TYPE,
        p_pershing_parent               IN  qlm_customer_addl_info.pershing_parent%TYPE,
        p_credit_netting_flag           IN  qlm_customer_addl_info.credit_netting_flag%TYPE,
        p_credit_parent_base_no         IN  qlm_customer_addl_info.credit_parent_base_no%TYPE,
        p_block_customer_flag           IN  qlm_customer_addl_info.block_customer_flag%TYPE,
        p_comfort_partner_flag          IN  qlm_customer_addl_info.comfort_partner_flag%TYPE,
        p_dda_account                   IN  qlm_customer_addl_info.dda_account%TYPE,
        p_original_branch               IN  qlm_customer_addl_info.original_branch%TYPE,
        p_apr_num                       IN  qlm_customer_addl_info.apr_num%TYPE,
        p_division                      IN  qlm_customer_addl_info.division%TYPE,
        p_fi_investment_service         IN  qlm_customer_addl_info.fi_investment_service%TYPE,
        p_fi_contract_number            IN  qlm_customer_addl_info.fi_contract_number%TYPE,
        p_fi_customer_category          IN  qlm_customer_addl_info.fi_customer_category%TYPE,
        p_ops_remarks                   IN  qlm_customer_addl_info.ops_remarks%TYPE,
        p_relationship_manager          IN  qlm_customer_addl_info.relationship_manager%TYPE,
        p_mm_waive_incoming_conf_flag   IN  qlm_customer_addl_info.mm_waive_incoming_conf_flag%TYPE,
        p_mm_no_conf_no_pay_indct_flag  IN  qlm_customer_addl_info.mm_no_conf_no_pay_indctr_flag%TYPE,
        p_fatca_eligible                IN  qlm_customer_addl_info.fatca_eligible%TYPE,
        p_banxico_cust_flag             IN  qlm_customer_addl_info.banxico_cust_flag%TYPE,
        p_fx_conf_waiver                IN  qlm_customer_addl_info.fx_conf_waiver%TYPE,
        p_govt_issuer_flag              IN  qlm_customer_addl_info.govt_issuer_flag%TYPE,
        p_internal_custody_flag         IN  qlm_customer_addl_info.internal_custody_flag%TYPE,
        p_generate_mt350_flag           IN  qlm_customer_addl_info.generate_mt350_flag%TYPE,
        p_gmra_customer                 IN  qlm_customer_addl_info.gmra_customer%TYPE,
        p_fi_customer_tax_id            IN  qlm_customer_addl_info.fi_customer_tax_id%TYPE,
        p_residency_flag                IN  qlm_customer_addl_info.residency_flag%TYPE,
        p_calm_legal_vechile_code       IN  qlm_customer_addl_info.calm_legal_vechile_code%TYPE,
        p_mxn_customer_profile          IN  qlm_customer_addl_info.mxn_customer_profile%TYPE,
        p_mxn_executive_phone_number    IN  qlm_customer_addl_info.mxn_executive_phone_number%TYPE,
        p_mxn_executive_name            IN  qlm_customer_addl_info.mxn_executive_name%TYPE,
        p_op_waive_incoming_conf_flag   IN  qlm_customer_addl_info.op_waive_incoming_conf_flag%TYPE,
        p_op_no_conf_no_pay_indct_flag  IN  qlm_customer_addl_info.op_no_conf_no_pay_indctr_flag%TYPE,
        p_op_spl_q_reqd_flag            IN  qlm_customer_addl_info.op_spl_q_reqd_flag%TYPE,
        p_ft_fee_flag                   IN  qlm_customer_addl_info.ft_fee_flag%TYPE,
        p_ft_debit_acc_no               IN  qlm_customer_addl_info.ft_debit_acc_no%TYPE,
        p_ft_fee_deduction_ccy          IN  qlm_customer_addl_info.ft_fee_deduction_ccy%TYPE,
        p_success_flag                  OUT VARCHAR2,
        p_error_message                 OUT VARCHAR2
    );

    PROCEDURE prc_mlv_customer_msg_addr
    (
        p_user_id                        IN  qlm_customer_msg_addr_q.maker_id%TYPE,
        p_auto_auth_flag                 IN  PLS_INTEGER,
        p_action                         IN  qlm_customer_msg_addr_q.action%TYPE,
        p_alpha_branch_code              IN  qlm_branch.alpha_branch_code%TYPE,
        p_modules                        IN  qlm_customer_msg_addr_q.modules%TYPE,
        p_customer_code                  IN  qlm_customer_msg_addr_q.customer_code%TYPE,
        p_media                          IN  qlm_customer_msg_addr_q.media%TYPE,
        p_location                       IN  qlm_customer_msg_addr_q.location%TYPE,
        p_gcn_mapping_bic                IN  qlm_customer_msg_addr_q.gcn_mapping_bic%TYPE,
        p_supp_new_conf_flag             IN  qlm_customer_msg_addr_q.supp_new_conf_flag%TYPE,
        p_supp_amend_conf_flag           IN  qlm_customer_msg_addr_q.supp_amend_conf_flag%TYPE,
        p_supp_tracer_conf_flag          IN  qlm_customer_msg_addr_q.supp_tracer_conf_flag%TYPE,
        p_tag_83D                        IN  qlm_customer_msg_addr_q.tag_83D%TYPE,
        p_tag_87D                        IN  qlm_customer_msg_addr_q.tag_87D%TYPE,
        p_tag_83DCLS                     IN  qlm_customer_msg_addr_q.tag_83DCLS%TYPE,
        p_gcn_msg_identifier             IN  qlm_customer_msg_addr_q.gcn_msg_identifier%TYPE,
        p_copied_from_pri_branch_flag    IN  qlm_customer_msg_addr_q.copied_from_pri_branch_flag%TYPE DEFAULT 0,
        p_copy_to_sub_Branch_flag        IN  qlm_customer_msg_addr_q.copy_to_sub_Branch_flag%TYPE DEFAULT 0,
        p_fi_straight_through            IN  qlm_customer_msg_addr_q.fi_straight_through%TYPE DEFAULT 0,
        p_supp_new_eod_conf_flag         IN  qlm_customer_msg_addr_q.supp_new_eod_conf_flag%TYPE,
        p_version                        IN  qlm_customer_msg_addr_q.version%TYPE,
        p_active_flag                    IN  qlm_customer_msg_addr_q.active_flag%TYPE,
        p_tab_cust_msg_addr_pii          IN  tab_cust_msg_addr_pii,
        p_tab_cust_msg_addr_types        IN  tab_cust_msg_addr_types,
        p_tab_cust_emailaddress_pii      IN  tab_cust_emailaddress_pii,
        p_tab_cust_msg_fax               IN  tab_cust_msg_fax,
        p_tab_cust_docusign_pii          IN  tab_cust_docusign_pii,
        p_language                       IN  qlm_customer_msg_addr_q.language%TYPE,
        p_supp_new_cms_conf_flag         IN  qlm_customer_msg_addr_q.supp_new_cms_conf_flag%TYPE,
        p_supp_amend_cms_conf_flag       IN  qlm_customer_msg_addr_q.supp_amend_cms_conf_flag%TYPE,
        p_mandatory_docu_signers         IN  qlm_customer_msg_addr_q.mandatory_docu_signers%TYPE,
        p_affirm_advice_flag             IN  qlm_customer_msg_addr_q.affirm_advice_flag%TYPE,
        p_msg_type                       IN  qlm_customer_msg_addr_q.msg_type%TYPE,
        p_success_flag                   OUT VARCHAR2,
        p_error_message                  OUT VARCHAR2
    );

    FUNCTION fnc_get_cust_account
    (
        p_acc_number         IN  qlm_customer_accounts_q.acc_number%TYPE,
        p_branch_code        IN  qlm_branch_currency.branch_code%TYPE,
        p_custacc_max_length IN  qlm_ext_branch.customer_number_max_length%TYPE,
        p_custacc_prefix     IN  qlm_ext_branch.customer_number_prefix%TYPE,
        p_custacc_prefix_val IN  qlm_ext_branch.customer_number_prefix_value%TYPE
    )
    RETURN VARCHAR2;

    FUNCTION get_maker_id
    (
        p_ext_system IN VARCHAR2
    )
    RETURN VARCHAR2;
END PKG_QLM_INCOMING_STATIC_MSG;
/
SHOW ERR

CREATE OR REPLACE PACKAGE BODY QLM_OWNER.PKG_QLM_INCOMING_STATIC_MSG
AS

/*
************************************************************************
Last Updated   : 02/Jun/2026
Created By     : Saipriya Damarapati
Description    : Modifying the Holiday list based on Data Feed
----------------------------------------------------------------
List of Procedures : 1) prc_log_incoming_static_msg
					 2) prc_static_hol_upload
					 3) prc_static_cust_acc_update
					 4) prc_mlv_conf_party_bic
					 Modified by			Modified date	Change Description
Saipriya			08-Aug-2019		C166472-2123 :: Static Customer Accounts upload from Flexcube to QFXLM
Saipriya			19-Sep-2019		Add customer from ISG cloud stage if customer doesn't exist
Gowtham P			05/May/2020		C166472-1016 : QFX DBS Handoff credit and debit gl
Muniappan Mohanraj	19-Jun-2020		JIRA - 5225 - Changed the input parameter condition for p_threshold_amt, p_generate_receive_notice
Muniappan Mohanraj	02-Jul-2020		JIRA - 5343 - Changed the input parameter condition for p_rd_acc_no
Muniappan Mohanraj	23-Jul-2020		JIRA - 5373 - adding p_trade_details_mm and p_trade_details_fx for propagation
Muniappan Mohanraj	17/Aug/2020		Updating the acc_branch with alpha_branch_code
Muniappan Mohanraj	01/Sep/2020		Updating the threshold_amt and receive_notice flag for editions
Chandramohan S      09/Oct/2020     C166472-6144 -- Handled new input parameter in prc_save_customer_accounts_q
Padmini M			09/Dec/2020		C166472-6034 -- added new table for Customer Account propagation
Vishal.S			08/Feb/2021		C166472-6034: Flexcube-QFXLM customer account online:catch up previous records
Suganya				25/May/2021		To update Flex Holiday
Karthikeyan G		05/Nov/2023		C166472-16649 - Customer account maintenance in QFXLM - 0 padding
Karthikeyan G		01/Jan/2024		C166472-16388: Charge Details changes
Arunkumar B			19/Jun/2024		C166472-20251 : Customer Account is not created automatically when the Customer Account received early to Customer Static
Karthikeyan G		06/Aug/2024		C166472-21772 - Customer account Derivation Logic Changes
Karthikeyan G		13/Aug/2024		C166472-21772 - changes to get the FLEX_ISG is Maintained branch code.-In General it will be maintained for Primary BRanch
Karthikeyan G		27/Aug/2024		C166472-21772 - Changes in the Length of Customer Account
JayavanthKumar A    26/Jun/2025     C166472-28605 - Changes to Consume Acti from ISG for Customer Accounts.
JayavanthKumar A    04/Jul/2025     C166472-28822 - Changes to Update the Acti
JayavanthKumar A    07/Oct/2025     C166472-31475 - fix for Etacs message consumption in log table
Raghul R            17/Mar/2026     C166472-33636 - IBAN account number consumption
Adyasha Parida      08/Apr/2026     C166472-35511-India FX- Account_category Field consuption from AMCAR messsage
Sandagorda P        02/Jun/2026     C166472-37161 - Change maker/checker IDs from SYSTEM to ISGDATA for ISG Cloud Customer Account Records
Ishan Sharma		08/Oct/2026	    C166472-42566 - Added customer additional-info incoming static message wrapper with customer existence validation.
Pravallika S        16/Oct/2026     C166472-43045 - Added wrapper procedure prc_mlv_conf_party_bic for party BIC maintenance
Ishan Sharma		03/Nov/2026	    Applied Mohan's MLV wrapper contract corrections for alpha branch resolution, action/version derivation, and XML parameter mapping.
Ishan Sharma        12/Nov/2026     C166472-43178 - Added MLV Customer Message Address wrapper.
*************************************************************************
*/

PROCEDURE prc_log_incoming_static_msg
(
	p_static_type			IN		qlm_incoming_static_msg.static_type%TYPE,
	p_fo_branch_code		IN		qlm_incoming_static_msg.fo_branch_code%TYPE,
	p_incoming_static_msg   IN  	tab_incoming_static_msg,
	p_in_or_out				IN		qlm_incoming_static_msg.in_or_out%TYPE,
	p_msg_status			IN		qlm_incoming_static_msg.msg_status%TYPE,
	p_source_system			IN		qlm_incoming_static_msg.source_system%TYPE,
	p_success_flag			OUT		VARCHAR2,
	p_error_message			OUT		VARCHAR2,
    p_customer_code			IN		qlm_incoming_static_msg.customer_code%TYPE DEFAULT NULL,
    p_customer_acc			IN		qlm_incoming_static_msg.customer_acc_no%TYPE DEFAULT NULL,
	p_msgtimestamp			IN		qlm_incoming_static_msg.TRAN_DATE%TYPE DEFAULT SYSTIMESTAMP
)
/*
	****************************************************
		Procedure Name 	: prc_log_incoming_static_msg
		Last Updated   	:
		Created By     	: Saipriya D
		Created date	: 07/Oct/2025  01:15:00 PM
		Description    	: This procedure inserts incoming static message.
		Change History	:
		Modified by         Modified date	Change Description
	    Karthikeyan G		06/Aug/2024		C166472-21772 - Customer account Derivation Logic Changes
	    Karthikeyan G		13/Aug/2024		C166472-21772 - changes to get the FLEX_ISG is Maintained branch code.-In General it will be maintained for Primary BRanch
	    Karthikeyan G		27/Aug/2024		C166472-21772 - Changes in the Length of Customer Account
	    Abirami     		11/Nov/2025		C166472-31979 - Enhance to log customer account from ISG in qlm_incoming_static_msg
	---------------------------------------------------------------------------
	****************************************************
	*/
IS
	lv_static_seq 		        NUMBER;
	lv_systimestamp		        TIMESTAMP(3) 					            := 	 p_msgtimestamp;
	lv_global_asofdate	        DATE							            :=	 pkg_utils_extension.fnc_get_global_asofdate();
	lv_branch_code		        qlm_branch.branch_code%TYPE;
	lv_customer_code            qlm_customer_accounts.customer_code%TYPE	:=	p_customer_code;
	lv_isg_count                NUMBER;
    lv_prim_branch_code         qlm_branch.branch_code%TYPE;

	BEGIN

        IF UPPER(p_source_system) = 'ETACS' THEN
             SELECT MAX(branch_code)
             INTO   lv_branch_code
             FROM   qlm_branch b
             WHERE  alpha_branch_code   = p_fo_branch_code
             AND    active_flag         = 1;
        ELSE
            SELECT MAX(branch_code)
            INTO   lv_branch_code
            FROM   qlm_branch b
            WHERE  alpha_branch_code   = p_fo_branch_code
            AND    active_flag         = 1
            AND    EXISTS (    SELECT  1
                            FROM    qlm_ext_branch qeb
                            WHERE   qeb.branch_code = b.branch_code
                            AND     qeb.ext_system  = P_source_system
                            AND     qeb.active_flag = 1);
        END IF;

         IF lv_branch_code IS NULL THEN

             SELECT MAX(propagation_branch_code)
             INTO 	lv_branch_code
             FROM	qlm_cust_acc_propagation qcp
             WHERE	acc_branch_code 	= 	p_fo_branch_code
             AND 	active_flag 		= 	1
             AND    EXISTS (    SELECT  1
                                FROM    qlm_ext_branch qeb
                                WHERE   qeb.branch_code = qcp.propagation_branch_code
                                AND     qeb.ext_system  = P_source_system
                                AND     qeb.active_flag = 1);
        END IF;

        IF lv_branch_code IS NULL THEN
            p_success_flag	:= 'N';
            p_error_message	:= 'S02~'||p_source_system||' is not maintained in EXT Branch... cannot consume this customer account for this branch : '||p_fo_branch_code;
            RETURN;
        END IF;

		lv_static_seq := TO_CHAR(lv_global_asofdate, 'YYDDD')||LPAD(seq_static_msg_code.NEXTVAL, 11, 0);

		IF p_source_system = 'ISG_CUST_ACC' THEN

		   SELECT  NVL(MAX(bai.branch_code),lv_branch_code)
           INTO    lv_prim_branch_code
           FROM    qlm_branch b1, qlm_branch b2, qlm_branch_addl_info bai
           WHERE   b1.alpha_branch_code        = p_fo_branch_code
           AND     b1.org_code                 = b2.org_code
           AND     b2.branch_code              = bai.branch_code
           AND     bai.static_propagation_flag = 1;

           SELECT COUNT(1)
           INTO   lv_isg_count
           FROM   QLM_EXT_BRANCH
           WHERE  BRANCH_CODE   = lv_prim_branch_code
           AND    EXT_SYSTEM    = 'FLEX_ISG'
           AND    ACTIVE_FLAG   = 1;

           -- This block derives the customer code based on the primary branch of the country using 'FLEX_ISG' configuration.
           IF lv_isg_count > 0 THEN
               lv_customer_code := pkg_utils.fnc_get_issuer(lv_customer_code, lv_prim_branch_code, 'FLEX_ISG', null);
           ELSE
               lv_customer_code := pkg_utils.fnc_get_issuer(lv_customer_code, lv_prim_branch_code, 'ISG_CUSTOMER_ESALES', null);
           END IF;

		END IF;

		INSERT INTO qlm_incoming_static_msg
		    (static_msg_code, static_type, in_or_out, source_system, msg_status, fo_branch_code, branch_code, tran_date, customer_code, customer_acc_no)
		VALUES
		    (lv_static_seq, p_static_type, p_in_or_out, p_source_system, p_msg_status, p_fo_branch_code, lv_branch_code, p_msgtimestamp, lv_customer_code, p_customer_acc);

		IF p_incoming_static_msg.COUNT > 0 THEN
				FOR rec IN p_incoming_static_msg.FIRST..p_incoming_static_msg.LAST
				    LOOP
						INSERT INTO qlm_incoming_static_msg_dtls
						    (static_msg_code, message_seq, message)
						VALUES
						    (lv_static_seq, p_incoming_static_msg(rec).message_seq, p_incoming_static_msg(rec).message);
				    END LOOP;
		END IF;

		p_success_flag	:= 'Y';
		p_error_message	:= NULL;

	EXCEPTION
		WHEN OTHERS THEN
			ROLLBACK;
			p_success_flag	:= 'N';
            p_error_message	:= SQLERRM;
			pkg_error_mgmt.prc_log_error_message
				(p_program_name => 'PKG_QLM_INCOMING_STATIC_MSG.PRC_LOG_INCOMING_STATIC_MSG',
				p_error_code 	=> SQLERRM,
				p_error_message => SUBSTR(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE(),1,4000),
				p_created_by 	=> 'SYSTEM',
				p_param_value 	=> 'P_STATIC_TYPE:'||p_static_type||'~'||'P_FO_BRANCH_CODE:'||p_fo_branch_code||'~'||'P_INCOMING_STATIC_MSG:'||p_incoming_static_msg.COUNT||'~'||
									'P_IN_OR_OUT:'||p_in_or_out||'~'||'P_MSG_STATUS:'||p_msg_status||'~'||'P_SOURCE_SYSTEM:'||p_source_system);
			RAISE_APPLICATION_ERROR(-20001,'Error others while storing incoming static message. '||SQLERRM);
	END prc_log_incoming_static_msg;

    PROCEDURE prc_static_hol_upload
	(
		p_year					IN		VARCHAR2,
		p_holidays				IN		tab_static_holiday_list,
		p_fo_branch_code		IN		qlm_branch.alpha_branch_code%TYPE,
		p_success_flag			OUT		VARCHAR2,
		p_error_message			OUT		VARCHAR2
	)
	/*
	****************************************************
		Procedure Name 	: prc_static_hol_upload
		Last Updated   	:
		Created By     	: Saipriya D
		Created date	: 17/Jul/2019  01:15:00 PM
		Description    	: This procedure updates static holidays FROM FLEX INTO QFXLM
		Change History	:
		Modified by    Modified date	Change Description
	---------------------------------------------------------------------------
	****************************************************
	*/
	IS

		lv_success_flag				VARCHAR2(1);
		lv_error_message			VARCHAR2(500);
		lv_calendar_code			qlm_calendar.calendar_code%TYPE;
		lv_calendar_description		qlm_calendar.calendar_description%TYPE;
		lv_weekend					qlm_calendar.weekend%TYPE;
		lv_version					qlm_calendar.version%TYPE;
		lv_queue_exists				PLS_INTEGER;
		lv_tab_holiday_list			tab_holiday_list;

		TYPE rec_weekend_exception_list IS RECORD
		(
			holiday_date		DATE,
			action_flag			VARCHAR2(1), --C or E
			version				PLS_INTEGER
		);

		TYPE tab_weekend_exception_list IS TABLE OF rec_weekend_exception_list;
		lv_tab_weekend_exception_list	tab_weekend_exception_list	:=	tab_weekend_exception_list();

		TYPE tab_weekend_queue_list IS TABLE OF VARCHAR2(1);
		lv_tab_weekend_queue_list	tab_weekend_queue_list	:=	tab_weekend_queue_list();

	BEGIN

		FOR rec IN (
				SELECT 	branch_code
				FROM	qlm_ext_branch
				WHERE	ext_system = 'FLEX_BRANCH_HOLIDAY'
				AND		ext_branch_code = p_fo_branch_code
				AND 	active_flag = 1
				)
	 LOOP
		SELECT NVL(MAX(qbai.gl_system_calendar), MAX(qb.holiday_calendar))
		INTO   lv_calendar_code
		FROM   qlm_branch qb, qlm_branch_addl_info qbai
		WHERE  qb.branch_code 	= rec.branch_code
		AND    qb.active_flag 	= 1
		AND    qb.branch_code 	= qbai.branch_code
		AND    qbai.active_flag = 1;

		IF lv_calendar_code IS NOT NULL THEN
			SELECT NVL(MAX(calendar_description),lv_calendar_code), NVL(MAX(weekend),71), NVL(MAX(version),0)
			INTO lv_calendar_description, lv_weekend, lv_version
			FROM qlm_calendar
			WHERE calendar_code = lv_calendar_code
			AND active_flag = 1;

			--CASE 1 :: Holidays falling on weekdays processing
			WITH row_gen AS
			(
			SELECT ROWNUM rn FROM dual CONNECT BY LEVEL <=31
			)
			SELECT 	REC_HOLIDAY_LIST(TO_DATE(day_of_month||'-'||month_string||'-'||p_year, 'DD-MM-YYYY'))
			BULK COLLECT INTO	lv_tab_holiday_list
			--month_string, holidays_string, day_of_month, indiv_char, to_date(day_of_month||'-'||month_string||'-'||2012, 'DD-MM-YYYY') as full_date, to_char(to_date(day_of_month||'-'||month_string||'-'||2012, 'DD-MM-YYYY'), 'D') as week_day
			FROM
			(
				SELECT	month_string, holidays_string, row_gen.rn AS day_of_month, SUBSTR(holidays_string, row_gen.rn, 1) AS indiv_char
				FROM 	TABLE(CAST(p_holidays  AS tab_static_holiday_list )) hol, row_gen
			)
			WHERE	indiv_char IS NOT NULL
			AND 	INSTR(TO_CHAR(lv_weekend), TO_CHAR(TO_DATE(day_of_month||'-'||month_string||'-'||p_year, 'DD-MM-YYYY'), 'D'))	=  0
			AND 	indiv_char 																										= 'H';

			lv_queue_exists := 0;
			SELECT COUNT(1)
			INTO lv_queue_exists
			FROM qlm_calendar_q
			WHERE calendar_code = lv_calendar_code ;

			IF lv_queue_exists > 0 THEN
				pkg_calendar_mgmt.prc_auth_calendar
				(
					p_user_id			=> 'SYSTEM',
					p_auth_status		=> 'R',	-- 'A' - Approved, 'R' - Rejected
					p_calendar_code		=> lv_calendar_code,
					p_remark			=> 'Rejected; because main table updated from Flex',
					p_success_flag		=> lv_success_flag,
					p_error_message		=> lv_error_message,
					p_auto_auth_flag    => 0,
					p_calendar_year		=> '1900'
				);
				IF lv_success_flag <> 'Y' THEN
					p_success_flag	:= lv_success_flag;
					p_error_message	:= lv_error_message;
					RETURN;
				END IF;
			END IF;

			pkg_calendar_mgmt.prc_edit_calendar
			(
				p_user_id 				=> 'SYSTEM',
				p_auto_auth_flag		=> 1,
				p_action 				=> 'E',
				p_calendar_code 		=> lv_calendar_code,
				p_calendar_description 	=> lv_calendar_description,
				p_weekend 				=> lv_weekend,
				p_tab_holiday_list		=> lv_tab_holiday_list,
				p_version 				=> lv_version,
				p_active_flag 			=> 1,
				p_hmc_code				=> NULL,
				p_success_flag			=> lv_success_flag,
				p_error_message			=> lv_error_message
			);

			IF lv_success_flag <> 'Y' THEN
				p_success_flag	:= lv_success_flag;
				p_error_message	:= lv_error_message;
				RETURN;
			END IF;

			/* processing for weekend exception */
			lv_tab_holiday_list := NULL;
			lv_success_flag		:= NULL;
			lv_error_message	:= NULL;

			--CASE 2 : weekend exception in the feed
			WITH row_gen AS
			(
			SELECT ROWNUM rn FROM dual CONNECT BY LEVEL <=31
			)
			SELECT	inline_view.holiday_date, CASE WHEN qwe.calendar_code IS NULL THEN 'C' ELSE 'E' END, NVL(qwe.version, 0) AS version
			BULK COLLECT INTO lv_tab_weekend_exception_list
			FROM
			(
				SELECT 	TO_DATE(day_of_month||'-'||month_string||'-'||p_year, 'DD-MM-YYYY') AS holiday_date
				FROM
				(
					SELECT	month_string, holidays_string, row_gen.rn AS day_of_month, SUBSTR(holidays_string, row_gen.rn, 1) AS indiv_char
					FROM 	TABLE(CAST(p_holidays  AS tab_static_holiday_list )) hol, row_gen
				)
				WHERE	indiv_char IS NOT NULL
				AND 	INSTR(TO_CHAR(lv_weekend), TO_CHAR(TO_DATE(day_of_month||'-'||month_string||'-'||p_year, 'DD-MM-YYYY'), 'D'))	>  0
				AND 	indiv_char 																								= 'W'
			) inline_view
			LEFT OUTER JOIN qlm_weekend_exception qwe
			ON
			(
						inline_view.holiday_date		=	qwe.weekend_date
				AND		qwe.calendar_code				=	lv_calendar_code
			);


			FOR rec IN 1 ..  lv_tab_weekend_exception_list.COUNT
			LOOP
				lv_queue_exists := 0;
				SELECT 	COUNT(1)
				INTO 	lv_queue_exists
				FROM 	qlm_weekend_exception_q
				WHERE 	calendar_code = lv_calendar_code
				AND 	weekend_date = lv_tab_weekend_exception_list(rec).holiday_date;

				IF lv_queue_exists > 0 THEN
					pkg_weekend_exception_mgmt.prc_auth_weekend_exception
					(
						p_user_id			=> 'SYSTEM',
						p_auth_status		=> 'R',
						p_calendar_code     => lv_calendar_code,
						p_weekend_date      => lv_tab_weekend_exception_list(rec).holiday_date,
						p_remark            => 'Rejected; because main table updated from Flex',
						p_success_flag		=> lv_success_flag,
						p_error_message		=> lv_error_message,
						p_auto_auth_flag    => 0
					);
					IF lv_success_flag <> 'Y' THEN
						p_success_flag	:= lv_success_flag;
						p_error_message	:= lv_error_message;
						RETURN;
					END IF;
				END IF;

				pkg_weekend_exception_mgmt.prc_edit_weekend_exception
				(
					p_user_id 			=> 'SYSTEM',
					p_auto_auth_flag	=> 1,
					p_action 			=> lv_tab_weekend_exception_list(rec).action_flag,
					p_calendar_code 	=> lv_calendar_code,
					p_weekend_date 		=> lv_tab_weekend_exception_list(rec).holiday_date,
					p_version 			=> lv_tab_weekend_exception_list(rec).version,
					p_active_flag 		=> 1,
					p_success_flag		=> lv_success_flag,
					p_error_message		=> lv_error_message
				);

				IF lv_success_flag <> 'Y' THEN
					p_success_flag	:= lv_success_flag;
					p_error_message	:= lv_error_message;
					RETURN;
				END IF;
			END LOOP;

			--CASE 3 :: Existing Weekend exception received as Holiday in current feed
			WITH row_gen AS
			(
			SELECT ROWNUM rn FROM dual CONNECT BY LEVEL <=31
			)
			SELECT 	REC_HOLIDAY_LIST(TO_DATE(day_of_month||'-'||month_string||'-'||p_year, 'DD-MM-YYYY')), q_indicator
			BULK COLLECT INTO	lv_tab_holiday_list, lv_tab_weekend_queue_list
			--month_string, holidays_string, day_of_month, indiv_char, to_date(day_of_month||'-'||month_string||'-'||2012, 'DD-MM-YYYY') as full_date, to_char(to_date(day_of_month||'-'||month_string||'-'||2012, 'DD-MM-YYYY'), 'D') as week_day
			FROM
			(
				SELECT	month_string, holidays_string, row_gen.rn AS day_of_month, SUBSTR(holidays_string, row_gen.rn, 1) AS indiv_char,
						CASE WHEN q.weekend_date IS NOT NULL THEN 'Q' ELSE NULL END AS q_indicator
				FROM 	TABLE(CAST(p_holidays  AS tab_static_holiday_list )) hol
				CROSS JOIN row_gen
				LEFT OUTER JOIN qlm_weekend_exception_q q
				ON
				(
					q.calendar_code							=	lv_calendar_code
				AND	q.weekend_date							=	TO_DATE(row_gen.rn||'-'||hol.month_string||'-'||p_year, 'DD-MM-YYYY')
				AND	SUBSTR(holidays_string, row_gen.rn, 1)	IS NOT NULL
				)
			)
			WHERE	indiv_char IS NOT NULL
			AND 	INSTR(TO_CHAR(lv_weekend), TO_CHAR(TO_DATE(day_of_month||'-'||month_string||'-'||p_year, 'DD-MM-YYYY'), 'D'))	>  0
			AND 	indiv_char 																										= 'H';

			FOR idx IN 1..lv_tab_holiday_list.COUNT
			LOOP
				IF lv_tab_weekend_queue_list(idx)	=	'Q' THEN
					pkg_weekend_exception_mgmt.prc_auth_weekend_exception
					(
						p_user_id			=> 'SYSTEM',
						p_auth_status		=> 'R',
						p_calendar_code     => lv_calendar_code,
						p_weekend_date      => lv_tab_holiday_list(idx).holiday_date,
						p_remark            => 'Rejected; because main table updated from Flex',
						p_success_flag		=> lv_success_flag,
						p_error_message		=> lv_error_message,
						p_auto_auth_flag    => 0
					);

					IF lv_success_flag <> 'Y' THEN
						p_success_flag	:= lv_success_flag;
					 p_error_message	:= lv_error_message;
						RETURN;
					END IF;
				END IF;
			END LOOP;

			UPDATE	qlm_weekend_exception qwe
			SET		version						=	version	+ 1,
					active_flag					=	0,
					maker_id					=	'SYSTEM',
					maker_dt					=	SYSTIMESTAMP,
					checker_id					=	'SYSTEM',
					checker_dt					=	SYSTIMESTAMP
			WHERE	EXISTS
			(
				SELECT	1
				FROM	TABLE(CAST(lv_tab_holiday_list AS tab_holiday_list)) tab
				WHERE	tab.holiday_date		=	qwe.weekend_date
				AND		qwe.calendar_code		=	lv_calendar_code
			);

			IF lv_success_flag <> 'Y' THEN
				p_success_flag	:= lv_success_flag;
				p_error_message	:= lv_error_message;
				RETURN;
			ELSE
				p_success_flag	:= 'Y';
				p_error_message	:= NULL;
			END IF;

		ELSE
			p_success_flag := 'N';
			p_error_message := 'S01~Branch calendar does not exist';
			RETURN;
		END IF;
	END LOOP;
	EXCEPTION
		WHEN OTHERS THEN
			ROLLBACK;
			p_success_flag	:= 'N';
            p_error_message	:= SQLERRM;

			pkg_error_mgmt.prc_log_error_message
				(p_program_name => 'PKG_QLM_INCOMING_STATIC_MSG.PRC_STATIC_HOL_UPLOAD',
				p_error_code 	=> SQLERRM,
				p_error_message => SUBSTR(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE(),1,4000),
				p_created_by 	=> 'SYSTEM',
				p_param_value 	=> 'P_YEAR:'||p_year||'~'||'P_FO_BRANCH_CODE:'||p_fo_branch_code);
			RAISE_APPLICATION_ERROR(-20001,'Error others while updating incoming static holidays. '||SQLERRM);

	END prc_static_hol_upload;

    PROCEDURE prc_mlv_conf_party_bic
	(
		p_user_id                        IN  qlm_conf_party_bic_q.maker_id%TYPE,
		p_auto_auth_flag                 IN  PLS_INTEGER,
		p_action                         IN  qlm_conf_party_bic_q.action%TYPE,
		p_branch_code                    IN  VARCHAR2,
		p_customer_code                  IN  qlm_conf_party_bic_q.customer_code%TYPE,
		p_module                         IN  qlm_conf_party_bic_q.module%TYPE,
		p_location                       IN  qlm_conf_party_bic_q.location%TYPE,
		p_party_83_flag                  IN  qlm_conf_party_bic_q.party_83_flag%TYPE,
		p_party_83_bic_code              IN  qlm_conf_party_bic_q.party_83_bic_code%TYPE,
		p_party_83_value_1               IN  qlm_conf_party_bic_q.party_83_value_1%TYPE,
		p_party_83_value_2               IN  qlm_conf_party_bic_q.party_83_value_2%TYPE,
		p_party_83_value_3               IN  qlm_conf_party_bic_q.party_83_value_3%TYPE,
		p_party_83cls_flag               IN  qlm_conf_party_bic_q.party_83cls_flag%TYPE,
		p_party_83cls_bic_code           IN  qlm_conf_party_bic_q.party_83cls_bic_code%TYPE,
		p_party_83cls_value_1            IN  qlm_conf_party_bic_q.party_83cls_value_1%TYPE,
		p_party_83cls_value_2            IN  qlm_conf_party_bic_q.party_83cls_value_2%TYPE,
		p_party_83cls_value_3            IN  qlm_conf_party_bic_q.party_83cls_value_3%TYPE,
		p_party_87_flag                  IN  qlm_conf_party_bic_q.party_87_flag%TYPE,
		p_party_87_bic_code              IN  qlm_conf_party_bic_q.party_87_bic_code%TYPE,
		p_party_87_value_1               IN  qlm_conf_party_bic_q.party_87_value_1%TYPE,
		p_party_87_value_2               IN  qlm_conf_party_bic_q.party_87_value_2%TYPE,
		p_party_87_value_3               IN  qlm_conf_party_bic_q.party_87_value_3%TYPE,
		p_pri_pay_sndr_rcvr_info_flag    IN  qlm_conf_party_bic_q.pri_pay_sndr_rcvr_info_flag%TYPE,
		p_pri_pay_sndr_rcvr_info1        IN  qlm_conf_party_bic_q.pri_pay_sndr_rcvr_info1%TYPE,
		p_pri_pay_sndr_rcvr_info2        IN  qlm_conf_party_bic_q.pri_pay_sndr_rcvr_info2%TYPE,
		p_pri_pay_sndr_rcvr_info3        IN  qlm_conf_party_bic_q.pri_pay_sndr_rcvr_info3%TYPE,
		p_pri_pay_sndr_rcvr_info4        IN  qlm_conf_party_bic_q.pri_pay_sndr_rcvr_info4%TYPE,
		p_pri_pay_sndr_rcvr_info5        IN  qlm_conf_party_bic_q.pri_pay_sndr_rcvr_info5%TYPE,
		p_pri_pay_sndr_rcvr_info6        IN  qlm_conf_party_bic_q.pri_pay_sndr_rcvr_info6%TYPE,
		p_copied_from_pri_branch_flag    IN  qlm_conf_party_bic_q.copied_from_pri_branch_flag%TYPE,
		p_copy_to_sub_branch_flag        IN  qlm_conf_party_bic_q.copy_to_sub_branch_flag%TYPE,
		p_currency_code                  IN  qlm_conf_party_bic_q.currency_code%TYPE DEFAULT '000',
		p_version                        IN  qlm_conf_party_bic_q.version%TYPE,
		p_active_flag                    IN  qlm_conf_party_bic_q.active_flag%TYPE,
		p_party_57_buy_flag              IN  qlm_conf_party_bic_q.party_57_buy_flag%TYPE,
		p_party_57_buy_bic_code          IN  qlm_conf_party_bic_q.party_57_buy_bic_code%TYPE,
		p_party_57_buy_value_1           IN  qlm_conf_party_bic_q.party_57_buy_value_1%TYPE,
		p_party_57_buy_value_2           IN  qlm_conf_party_bic_q.party_57_buy_value_2%TYPE,
		p_party_57_buy_value_3           IN  qlm_conf_party_bic_q.party_57_buy_value_3%TYPE,
		p_party_57_buy_value_4           IN  qlm_conf_party_bic_q.party_57_buy_value_4%TYPE,
		p_party_57_sell_flag             IN  qlm_conf_party_bic_q.party_57_sell_flag%TYPE,
		p_party_57_sell_bic_code         IN  qlm_conf_party_bic_q.party_57_sell_bic_code%TYPE,
		p_party_57_sell_value_1          IN  qlm_conf_party_bic_q.party_57_sell_value_1%TYPE,
		p_party_57_sell_value_2          IN  qlm_conf_party_bic_q.party_57_sell_value_2%TYPE,
		p_party_57_sell_value_3          IN  qlm_conf_party_bic_q.party_57_sell_value_3%TYPE,
		p_party_57_sell_value_4          IN  qlm_conf_party_bic_q.party_57_sell_value_4%TYPE,
		p_party_57_flag                  IN  qlm_conf_party_bic_q.party_57_flag%TYPE,
		p_party_57_bic_code              IN  qlm_conf_party_bic_q.party_57_bic_code%TYPE,
		p_party_57_value1                IN  qlm_conf_party_bic_q.party_57_value1%TYPE,
		p_party_57_value2                IN  qlm_conf_party_bic_q.party_57_value2%TYPE,
		p_party_57_value3                IN  qlm_conf_party_bic_q.party_57_value3%TYPE,
		p_party_57_value4                IN  qlm_conf_party_bic_q.party_57_value4%TYPE,
		p_party_53_flag                  IN  qlm_conf_party_bic_q.party_53_flag%TYPE,
		p_party_53_bic_code              IN  qlm_conf_party_bic_q.party_53_bic_code%TYPE,
		p_party_53_value1                IN  qlm_conf_party_bic_q.party_53_value1%TYPE,
		p_party_53_value2                IN  qlm_conf_party_bic_q.party_53_value2%TYPE,
		p_party_53_value3                IN  qlm_conf_party_bic_q.party_53_value3%TYPE,
		p_party_53_value4                IN  qlm_conf_party_bic_q.party_53_value4%TYPE,
		p_party_56_ta_buy_lcy_flag       IN  qlm_conf_party_bic_q.party_56_ta_buy_lcy_flag%TYPE,
		p_party_56_ta_bic_code           IN  qlm_conf_party_bic_q.party_56_ta_bic_code%TYPE,
		p_party_83_value_4               IN  qlm_conf_party_bic_q.party_83_value_4%TYPE,
		p_party_83cls_value_4            IN  qlm_conf_party_bic_q.party_83cls_value_4%TYPE,
		p_party_87_value_4               IN  qlm_conf_party_bic_q.party_87_value_4%TYPE,
		p_party_56_sell_flag             IN  qlm_conf_party_bic_q.party_56_sell_flag%TYPE,
		p_party_56_sell_bic_code         IN  qlm_conf_party_bic_q.party_56_sell_bic_code%TYPE,
		p_success_flag                   OUT VARCHAR2,
		p_error_message                  OUT VARCHAR2
	)
	IS
		lv_customer_maintenance PLS_INTEGER := 0;
		lv_action               qlm_conf_party_bic_q.action%TYPE;
		lv_version              qlm_conf_party_bic_q.version%TYPE := 0;
		lv_branch_code          qlm_conf_party_bic_q.branch_code%TYPE;
	BEGIN
		SELECT MAX(branch_code)
		INTO lv_branch_code
		FROM qlm_branch
		WHERE alpha_branch_code = p_branch_code
		AND active_flag = 1;

		SELECT COUNT(1)
		INTO lv_customer_maintenance
		FROM qlm_customer
		WHERE branch_code   = lv_branch_code
		AND customer_code = p_customer_code
		AND active_flag   = 1;

		IF lv_customer_maintenance = 0 THEN
			p_success_flag := 'N';
			p_error_message := p_branch_code || '/' || p_customer_code || ' Customer is not maintained for the branch';
			RETURN;
		END IF;

		BEGIN
			SELECT bic.version
			INTO lv_version
			FROM qlm_conf_party_bic bic
			WHERE bic.branch_code   = lv_branch_code
			AND   bic.customer_code = p_customer_code
			AND   bic.module        = p_module
			AND   bic.location      = p_location
			AND   bic.currency_code = '000';

			lv_action := 'E';
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				lv_action  := 'C';
				lv_version := 0;
		END;

		PKG_CONF_PARTY_BIC_MGMT.prc_edit_conf_party_bic(
			p_user_id                      => 'MLVDATA',
			p_auto_auth_flag               => 1,
			p_action                       => lv_action,
			p_branch_code                  => lv_branch_code,
			p_customer_code                => p_customer_code,
			p_module                       => p_module,
			p_location                     => p_location,
			p_party_83_flag                => p_party_83_flag,
			p_party_83_bic_code            => p_party_83_bic_code,
			p_party_83_value_1             => p_party_83_value_1,
			p_party_83_value_2             => p_party_83_value_2,
			p_party_83_value_3             => p_party_83_value_3,
			p_party_83cls_flag             => p_party_83cls_flag,
			p_party_83cls_bic_code         => p_party_83cls_bic_code,
			p_party_83cls_value_1          => p_party_83cls_value_1,
			p_party_83cls_value_2          => p_party_83cls_value_2,
			p_party_83cls_value_3          => p_party_83cls_value_3,
			p_party_87_flag                => p_party_87_flag,
			p_party_87_bic_code            => p_party_87_bic_code,
			p_party_87_value_1             => p_party_87_value_1,
			p_party_87_value_2             => p_party_87_value_2,
			p_party_87_value_3             => p_party_87_value_3,
			p_pri_pay_sndr_rcvr_info_flag  => p_pri_pay_sndr_rcvr_info_flag,
			p_pri_pay_sndr_rcvr_info1      => p_pri_pay_sndr_rcvr_info1,
			p_pri_pay_sndr_rcvr_info2      => p_pri_pay_sndr_rcvr_info2,
			p_pri_pay_sndr_rcvr_info3      => p_pri_pay_sndr_rcvr_info3,
			p_pri_pay_sndr_rcvr_info4      => p_pri_pay_sndr_rcvr_info4,
			p_pri_pay_sndr_rcvr_info5      => p_pri_pay_sndr_rcvr_info5,
			p_pri_pay_sndr_rcvr_info6      => p_pri_pay_sndr_rcvr_info6,
			p_copied_from_pri_branch_flag  => p_copied_from_pri_branch_flag,
			p_copy_to_sub_branch_flag      => p_copy_to_sub_branch_flag,
			p_currency_code                => p_currency_code,
			p_version                      => lv_version,
			p_active_flag                  => p_active_flag,
			p_party_57_buy_flag            => p_party_57_buy_flag,
			p_party_57_buy_bic_code        => p_party_57_buy_bic_code,
			p_party_57_buy_value_1         => p_party_57_buy_value_1,
			p_party_57_buy_value_2         => p_party_57_buy_value_2,
			p_party_57_buy_value_3         => p_party_57_buy_value_3,
			p_party_57_buy_value_4         => p_party_57_buy_value_4,
			p_party_57_sell_flag           => p_party_57_sell_flag,
			p_party_57_sell_bic_code       => p_party_57_sell_bic_code,
			p_party_57_sell_value_1        => p_party_57_sell_value_1,
			p_party_57_sell_value_2        => p_party_57_sell_value_2,
			p_party_57_sell_value_3        => p_party_57_sell_value_3,
			p_party_57_sell_value_4        => p_party_57_sell_value_4,
			p_party_57_flag                => p_party_57_flag,
			p_party_57_bic_code            => p_party_57_bic_code,
			p_party_57_value1              => p_party_57_value1,
			p_party_57_value2              => p_party_57_value2,
			p_party_57_value3              => p_party_57_value3,
			p_party_57_value4              => p_party_57_value4,
			p_party_53_flag                => p_party_53_flag,
			p_party_53_bic_code            => p_party_53_bic_code,
			p_party_53_value1              => p_party_53_value1,
			p_party_53_value2              => p_party_53_value2,
			p_party_53_value3              => p_party_53_value3,
			p_party_53_value4              => p_party_53_value4,
			p_party_56_ta_buy_lcy_flag     => p_party_56_ta_buy_lcy_flag,
			p_party_56_ta_bic_code         => p_party_56_ta_bic_code,
			p_party_83_value_4             => p_party_83_value_4,
			p_party_83cls_value_4          => p_party_83cls_value_4,
			p_party_87_value_4             => p_party_87_value_4,
			p_party_56_sell_flag           => p_party_56_sell_flag,
			p_party_56_sell_bic_code       => p_party_56_sell_bic_code,
			p_success_flag                 => p_success_flag,
			p_error_message                => p_error_message
		);

	EXCEPTION
		WHEN OTHERS THEN
			ROLLBACK;
			pkg_error_mgmt.prc_log_error_message(
				p_program_name  => 'PKG_QLM_INCOMING_STATIC_MSG.PRC_MLV_CONF_PARTY_BIC',
				p_error_code    => SQLERRM,
				p_error_message => SUBSTR(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE(), 1, 4000),
				p_created_by    => p_user_id,
				p_param_value   => 'P_ACTION:'||p_action||'~P_BRANCH_CODE:'||p_branch_code||
									   '~P_CUSTOMER_CODE:'||p_customer_code||'~P_MODULE:'||p_module||
									   '~P_LOCATION:'||p_location||'~P_CURRENCY_CODE:'||p_currency_code
			);
			p_success_flag := 'N';
			p_error_message := 'S03~Error in prc_mlv_conf_party_bic. ' || SQLERRM;
			RAISE_APPLICATION_ERROR(-20001, 'Error others in prc_mlv_conf_party_bic. ' || SQLERRM);
	END prc_mlv_conf_party_bic;

    PROCEDURE prc_static_cust_acc_update
	(
		p_customer_code				IN	qlm_customer_accounts_q.customer_code%TYPE,
		p_acc_number				IN	qlm_customer_accounts_q.acc_number%TYPE,
		p_acc_currency				IN	qlm_customer_accounts_q.acc_currency%TYPE,
		p_acc_description			IN	qlm_customer_accounts_q.acc_description%TYPE,
		p_credit_gl_acc				IN 	qlm_customer_accounts.linked_gl_acc%TYPE,
		p_debit_gl_acc				IN 	qlm_customer_accounts.linked_gl_acc%TYPE,
		p_threshold_amt				IN	qlm_customer_accounts.threshold_amt%TYPE,
		p_generate_receive_notice	IN	qlm_customer_accounts.generate_receive_notice%TYPE,
		p_rd_acc_no					IN  qlm_customer_accounts.rd_acc_no%TYPE,
		p_charge_details			IN	qlm_customer_accounts_q.charge_details%TYPE,
		p_alternate_acc_number		IN  qlm_customer_accounts_q.alternate_acc_number%TYPE,
		p_acc_open_date				IN  qlm_customer_accounts_q.acc_open_date%TYPE,
		p_account_class				IN  qlm_customer_accounts_q.account_class%TYPE,
		p_cost_center				IN 	qlm_customer_accounts_q.cost_center%TYPE,
		p_active_flag				IN 	qlm_customer_accounts_q.active_flag%TYPE,
		p_alpha_branch_code			IN	qlm_branch.alpha_branch_code%TYPE,
		p_ext_system				IN  VARCHAR2,
		p_actId                     IN  qlm_customer_accounts.acti%TYPE DEFAULT NULL,
		p_iban_acc_no               IN  qlm_customer_accounts.iban_acc_no%TYPE,
		p_acc_category              IN  qlm_customer_accounts.acc_category%TYPE,
		p_success_flag				OUT	VARCHAR2,
		p_error_message				OUT	VARCHAR2,
		p_trade_details_mm			OUT	SYS_REFCURSOR,
		p_trade_details_fx			OUT	SYS_REFCURSOR,
		p_trade_details_fi			OUT	SYS_REFCURSOR
	)
	/*
	****************************************************
		Procedure Name 	: prc_static_cust_acc_update
		Last Updated   	: 05/Jun/2026
		Created By     	: Saipriya D
		Created date	: 06/Aug/2019  01:15:00 PM
		Description    	: This procedure updates static Customer Accounts FROM FLEX INTO QFXLM
		Change History	:
		Modified by    		Modified date	Change Description
		Saipriya			19-Sep-2019		Add customer from ISG cloud stage if customer doesn't exist
		Muniappan Mohanraj	19-Jun-2020		JIRA - 5225 - Changed the input paramter condition for p_threshold_amt, p_generate_receive_notice
		Muniappan Mohanraj	02-Jul-2020		JIRA - 5343 - Changed the input parameter condition for p_rd_acc_no
		Muniappan Mohanraj	23-Jul-2020		JIRA - 5373 - adding p_trade_details_mm and p_trade_details_fx for propagation
		Muniappan Mohanraj	17/Aug/2020		Updating the acc_branch with alpha_branch_code
		Muniappan Mohanraj	01/Sep/2020		Updating the threshold_amt and receive_notice flag for editions
		Chandramohan S      09/Oct/2020     C166472-6144 -- Handled new input parameter in prc_save_customer_accounts_q
		Padmini M			09/Dec/2020		C166472-6034 -- added new table for Customer Account propagation
		Maharaja S			01/Feb/2021     C166472-6734 Skip balance check for compen account changes internal_account_flag input parameter in prc_save_customer_accounts_q
		Vishal.S			08/Feb/2021		C166472-6034: Flexcube-QFXLM customer account online:catch up previous records
		Akhila M			01/Nov/2023		C166472-16456 - QFXLM : NYK : Customer Base Number Handling
		Karthikeyan G		01/Jan/2024		C166472-16388: Charge Details changes
		Akhila M			15/May/2024		C166472-20053 : QFXLM | APAC | FX | 24.03 Post Production issues
		Sai Annam			16/May/2024		C166472-19893 : C166472-19893- customer account additional info- IBAN column addition
		Arunkumar B			19/Jun/2024		C166472-20251 : Customer Account is not created automatically when the Customer Account received early to Customer Static
		Karthikeyan G		06/Aug/2024		C166472-21772 - Customer account Derivation Logic Changes
		Karthikeyan G		13/Aug/2024		C166472-21772 - changes to get the FLEX_ISG is Maintained branch code.-In General it will be maintained for Primary BRanch
		Karthikeyan G		27/Aug/2024		C166472-21772 - Changes in the Length of Customer Account
		JayavanthKumar A    26/Jun/2025     C166472-28605 - Changes to Consume Acti from ISG for Customer Accounts.
		JayavanthKumar A    04/Jul/2025     C166472-28822 - Changes to Update the Acti
		Adyasha Parida      08/Apr/2026     C166472-35511-India FX- Account_category Field consuption from AMCAR messsage
		Sandagorda P        02/Jun/2026     C166472-37161 - Change maker/checker IDs from SYSTEM to ISGDATA for ISG Cloud Customer Account Records
		Aharamuthalvan      05/Jun/2026     C166472-35511 - Log improvement
		Akhila M            08/Jun/2026     C166472-38841 - changes to get account branch in tech mode for qfx enabled branches
	---------------------------------------------------------------------------
	****************************************************
	*/
	IS
		lv_branch_code				qlm_branch.branch_code%TYPE;
		lv_customer_code            qlm_customer_accounts.customer_code%TYPE	:=	p_customer_code;
		lv_branch_desc				qlm_branch.branch_description%TYPE;
		lv_acc_type					qlm_customer_accounts.acc_type%TYPE;
		link_gl_ind					qlm_account_class.link_gl_ind%TYPE;
		lv_linked_gl_acc			qlm_customer_accounts.linked_gl_acc%TYPE;
		lv_queue_exists				PLS_INTEGER;
		lv_version					qlm_customer_accounts.version%TYPE;
		lv_count					NUMBER(2,0);
		lv_sys_refcursor			SYS_REFCURSOR;
		lv_success_flag				VARCHAR2(1);
		lv_error_message			VARCHAR2(500);
		lv_rd_acc_no				qlm_customer_accounts.rd_acc_no%TYPE;
		lv_alpha_branch_code		qlm_branch.alpha_branch_code%TYPE;
		lv_threshold_amt			qlm_customer_accounts.threshold_amt%TYPE;
		lv_receive_notice			qlm_customer_accounts.generate_receive_notice%TYPE;
		lv_rtgs_flag                qlm_customer_accounts.rtgs_flag%TYPE;
		lv_internal_account_flag    qlm_customer_accounts.internal_account_flag%TYPE;
		lv_iban_acc_no              qlm_customer_accounts.iban_acc_no%TYPE;
		lv_acti                     qlm_customer_accounts.acti%TYPE;
		lv_acc_category             qlm_customer_accounts.acc_category%TYPE;
		lv_cust_acc_prop_exists		PLS_INTEGER  := 0;
		lv_cust_acc_resultset		SYS_REFCURSOR;
		lv_cust_account             qlm_customer_accounts.acc_number%type;
        lv_custacc_max_length	    qlm_ext_branch.customer_number_max_length%TYPE;
        lv_custacc_prefix		    qlm_ext_branch.customer_number_prefix%TYPE;
        lv_custacc_prefix_val	    qlm_ext_branch.customer_number_prefix_value%TYPE;
        lv_charge_details           qlm_customer_accounts.charge_details%TYPE;
        lv_cust_count			    NUMBER(2,0);
        lv_isg_count                NUMBER;
        lv_prim_branch_code         qlm_branch.branch_code%TYPE;
        lv_branch_conf				qlm_branch.branch_code%TYPE;
		lv_field_value				qlm_branch_config.field_value%TYPE;

	BEGIN
		 SELECT MAX(c.field_value), MAX(b.branch_code)
		 INTO 	lv_field_value, lv_branch_conf
		 FROM 	qlm_branch_config c, qlm_branch b
		 WHERE  c.org_code 			= 	 b.org_code
		 AND	b.active_flag       =    1
		 AND 	c.field_name			= 	'QFX_ACCOUNT_BRANCH'
		 AND 	c.module 				= 	'FX'
		 AND 	c.source_system 		= 	'PORTAL'
		 AND 	c.active_flag 		= 	1
		 AND 	EXISTS( SELECT	1
						FROM 	qlm_branch_config bc
						WHERE 	bc.org_code			=		b.org_code
						AND 	bc.module			LIKE 	'%X%'
						AND 	bc.source_system	=		'PORTAL_TO_STATIC'
						AND 	bc.field_name		=		'BRANCH_ENABLED'
						AND 	bc.field_value		IN		('Y','Z')
						AND		bc.active_flag		=		1);

	  FOR rec IN (
					SELECT 	DISTINCT propagation_branch_code branch_code
                    FROM	qlm_cust_acc_propagation qcp
                    WHERE	acc_branch_code = p_alpha_branch_code
                    AND 	active_flag = 1
                    AND     EXISTS (SELECT  1
                                    FROM    qlm_ext_branch qeb
                                    WHERE   qeb.branch_code = qcp.propagation_branch_code
                                    AND     qeb.ext_system  = p_ext_system
                                    AND     qeb.active_flag = 1)
					UNION
					SELECT      mb.branch_code FROM
					(SELECT  	alpha_branch_code, lv_branch_conf branch_code FROM (
					SELECT 		REGEXP_SUBSTR(lv_field_value,'[^,]+', 1, LEVEL) AS alpha_branch_code
					FROM 		DUAL	CONNECT BY LEVEL <= LENGTH(lv_field_value)-LENGTH(replace(lv_field_value, ','))+1 ORDER BY 1)
				 	WHERE 		alpha_branch_code <> 'ALL') mb, qlm_ext_branch ex
				 	WHERE 		ex.branch_code      	= lv_branch_conf
				 	AND			mb.branch_code 			= ex.branch_code
				 	AND   		ex.ext_system			IN ('ISG_CUST_ACC')
				 	AND		    mb.alpha_branch_code 	= p_alpha_branch_code
				 	AND   		ex.active_flag			= 1
				)
	  LOOP
	  	lv_cust_acc_prop_exists := 1;

		SELECT MAX(branch_code), MAX(branch_description), MAX(alpha_branch_code)
		INTO lv_branch_code, lv_branch_desc, lv_alpha_branch_code
		FROM qlm_branch
		WHERE branch_code = rec.branch_code --p_alpha_branch_code
		AND active_flag = 1;

		IF lv_branch_code IS NOT NULL THEN
            IF p_ext_system = 'ISG_CUST_ACC' THEN

               SELECT  NVL(MAX(bai.branch_code),lv_branch_code)
               INTO    lv_prim_branch_code
               FROM    qlm_branch b1, qlm_branch b2, qlm_branch_addl_info bai
               WHERE   b1.alpha_branch_code        = p_alpha_branch_code
               AND     b1.org_code                 = b2.org_code
               AND     b2.branch_code              = bai.branch_code
               AND     bai.static_propagation_flag = 1;

               SELECT COUNT(1)
               INTO   lv_isg_count
               FROM   QLM_EXT_BRANCH
               WHERE  BRANCH_CODE   = lv_prim_branch_code
               AND    EXT_SYSTEM    = 'FLEX_ISG'
               AND    ACTIVE_FLAG   = 1;
                -- This block derives the customer code based on the primary branch of the country using 'FLEX_ISG' configuration.
               IF lv_isg_count > 0 THEN
                     lv_customer_code := pkg_utils.fnc_get_issuer(p_customer_code, lv_prim_branch_code, 'FLEX_ISG', null);
               ELSE
                      lv_customer_code := pkg_utils.fnc_get_issuer(p_customer_code, lv_prim_branch_code, 'ISG_CUSTOMER_ESALES', null);
               END IF;
            END IF;

			SELECT 	COUNT(1)
			INTO	lv_count
			FROM	qlm_customer
			WHERE	branch_code		=	lv_branch_code
			AND 	customer_code	=	lv_customer_code
			AND		active_flag		=	1;

			/* checks whether the customer is not present then it calls isg customer info table to get insert into customer table */
			IF lv_count = 0 THEN
		   		PKG_CUSTOMER_MGMT.prc_isg_customer_check(lv_branch_code,lv_customer_code,p_success_flag,p_error_message,'ISG_FLOW');
        	END IF;

            /* Re checks whether new customer created if any from post prc_isg_customer_check*/
        	SELECT 	COUNT(1)
            INTO	lv_cust_count
            FROM	qlm_customer
            WHERE	branch_code		=	lv_branch_code
            AND 	customer_code	=	lv_customer_code
            AND		active_flag		=	1;

        	SELECT	MAX(customer_number_max_length), MAX(customer_number_prefix), MAX(customer_number_prefix_value)
        	INTO	lv_custacc_max_length, lv_custacc_prefix, lv_custacc_prefix_val
            FROM    qlm_ext_branch
            WHERE   branch_code         =   lv_branch_code
            AND     UPPER(ext_system)   =   p_ext_system
            AND     in_or_out           =   'I'
            AND     active_flag         =   1;

            IF lv_custacc_max_length > 0 AND p_ext_system = 'ISG_CUST_ACC' THEN
                lv_cust_account     :=    p_alpha_branch_code || p_acc_number;
                IF lv_custacc_max_length > LENGTH(p_acc_number)  THEN
                    lv_cust_account      := fnc_get_cust_account(lv_cust_account, lv_branch_code, lv_custacc_max_length, lv_custacc_prefix, lv_custacc_prefix_val);
                END IF;
            ELSE
               lv_cust_account := p_acc_number;
            END IF;

        	IF lv_cust_count = 0 THEN
	        	p_success_flag	:= 'N';
				p_error_message	:= 'S02~Customer Code ' ||lv_customer_code|| ' does not exist in QFXLM while consuming cust_acct'|| lv_cust_account ||'from AMC';

				/* To store only the latest version of Cust Acct info, deleting the existing record from stage before insertion */
				DELETE	FROM	qlm_customer_acc_static_stage
				WHERE			branch_code		=	lv_branch_code
				AND				acc_number		=	lv_cust_account;

				INSERT INTO qlm_customer_acc_static_stage
							(customer_code, branch_code, alpha_branch_code, acc_number, acc_currency, acc_description, credit_gl_acc, debit_gl_acc,
			 				charge_details, alternate_acc_number, acc_open_date, account_class, cost_center, version, active_flag, maker_id, maker_dt, acti, IBAN_ACC_NO, acc_category)
				VALUES 		(lv_customer_code, lv_branch_code, p_alpha_branch_code, lv_cust_account, p_acc_currency, p_acc_description, p_credit_gl_acc, p_debit_gl_acc,
			 				 p_charge_details, p_alternate_acc_number, p_acc_open_date, p_account_class, p_cost_center, 1, p_active_flag, get_maker_id(p_ext_system), systimestamp, p_actId, p_iban_acc_no, p_acc_category);
				RETURN;
			END IF;

			SELECT 	NVL(MAX(version),0), NVL(p_rd_acc_no,MAX(rd_acc_no)), NVL(p_threshold_amt, MAX(threshold_amt)), NVL(MAX(generate_receive_notice), 0), NVL(MAX(rtgs_flag),0), NVL(MAX(internal_account_flag),0) , NVL(p_iban_acc_no,MAX(iban_acc_no)), NVL(p_actId,MAX(acti)), NVL(p_acc_category,MAX(acc_category))
            INTO 	lv_version, lv_rd_acc_no, lv_threshold_amt, lv_receive_notice, lv_rtgs_flag,  lv_internal_account_flag, lv_iban_acc_no, lv_acti, lv_acc_category
			FROM 	qlm_customer_accounts
			WHERE 	branch_code = lv_branch_code
			AND 	acc_number = lv_cust_account;

			SELECT COUNT(1) INTO lv_queue_exists FROM qlm_customer_accounts_q WHERE branch_code = lv_branch_code AND acc_number = lv_cust_account;

			IF lv_queue_exists > 0 THEN
				pkg_customer_accounts_mgmt.prc_auth_customer_accounts
				(
					p_user_id				=> get_maker_id(p_ext_system),
					p_auth_status			=> 'R',	-- 'A' - Approved, 'R' - Rejected
					p_branch_code			=> lv_branch_code,
					p_acc_number			=> lv_cust_account,
					p_remark				=> 'Rejected; because main table updated from Flex',
					p_cust_acc_man_flag 	=> 0, -- '1' - Manual Customer Account Creation, '0' -- Customer Account Migration
					p_queue_resultset   	=> lv_sys_refcursor,
					p_success_flag			=> lv_success_flag,
					p_error_message			=> lv_error_message,
					p_auto_auth_flag    	=> 0,
					p_trade_details_mm		=> p_trade_details_mm,
					p_trade_details_fx		=> p_trade_details_fx,
					p_trade_details_fi		=> p_trade_details_fi,
					p_cust_acc_result_set 	=> lv_cust_acc_resultset
				);
				IF lv_success_flag <> 'Y' THEN
					p_success_flag	:= lv_success_flag;
					p_error_message	:= lv_error_message;
					RETURN;
				END IF;
			END IF;

			BEGIN
				SELECT 	account_type, CASE link_gl_ind WHEN 'D' THEN p_debit_gl_acc ELSE p_credit_gl_acc END
				INTO 	lv_acc_type, lv_linked_gl_acc
				FROM 	qlm_account_class qac
				WHERE 	qac.branch_code 	= 	lv_branch_code
				AND 	qac.account_class 	= 	p_account_class
				AND 	qac.active_flag		=	1;
			EXCEPTION WHEN NO_DATA_FOUND THEN
				p_success_flag	:= 'N';
				p_error_message	:= 'Account class not found ~ ' || p_account_class || ' for ' || lv_branch_code || ' branch'|| ' ~ Account:'||lv_cust_account;
				RETURN;
			END;
			lv_charge_details 	:= CASE WHEN p_charge_details = 'S' THEN 'SHA'
                                        WHEN p_charge_details = 'B' THEN 'BEN'
                                        WHEN p_charge_details = 'O' THEN 'OUR'
                                        ELSE p_charge_details END;

			pkg_customer_accounts_mgmt.prc_save_customer_accounts_q
			(
				p_user_id 					=> 	get_maker_id(p_ext_system),
				p_auto_auth_flag			=>	1, -- TRUE => Auto authorization
				p_action 					=> 	CASE lv_version WHEN 0 THEN 'C' ELSE 'E' END,
				p_customer_code 			=> 	lv_customer_code,
				p_acc_number 				=> 	lv_cust_account,
				p_branch_code 				=> 	lv_branch_code,
				p_acc_currency 				=> 	p_acc_currency,
				p_acc_type 					=> 	lv_acc_type,
				p_acc_branch 				=> 	p_alpha_branch_code, --lv_alpha_branch_code,
				p_acc_description 			=> 	p_acc_description,
				p_linked_gl_acc          	=> 	lv_linked_gl_acc,
				p_threshold_amt          	=>	CASE WHEN lv_version = 0 AND lv_acc_type = 'OA' THEN 0 ELSE lv_threshold_amt END,
				p_generate_receive_notice	=>	CASE WHEN lv_version = 0 AND lv_acc_type = 'OA' THEN 1 ELSE lv_receive_notice END,
				p_rd_acc_no                 =>  lv_rd_acc_no,
				p_charge_details			=>	lv_charge_details,
				p_version 					=> 	lv_version,
				p_active_flag 				=> 	p_active_flag,
				p_alternate_acc_number      =>  p_alternate_acc_number,
				p_acc_open_date   	        =>  p_acc_open_date,
				p_account_class 		    =>  p_account_class,
				p_cost_center 			    => 	p_cost_center,
				p_dbs_credit_gl				=>	p_credit_gl_acc,
				p_dbs_debit_gl				=>	p_debit_gl_acc,
				p_rtgs_flag					=>  lv_rtgs_flag,
				p_cust_acc_man_flag 		=>  0, -- '1' - Manual Customer Account Creation, '0' -- Customer Account Migration
				p_internal_account_flag		=>	lv_internal_account_flag,
				p_iban_acc_no               =>  lv_iban_acc_no,
				p_acti                      =>  lv_acti,
				p_acc_category              =>  lv_acc_category,
				p_queue_resultset           => 	lv_sys_refcursor,
				p_success_flag				=>	lv_success_flag,
				p_error_message				=>	lv_error_message,
				p_alpha_branch_code			=>	p_alpha_branch_code,
				p_trade_details_mm			=> 	p_trade_details_mm,
				p_trade_details_fx			=>	p_trade_details_fx,
				p_trade_details_fi			=>	p_trade_details_fi,
				p_cust_acc_result_set		=>	lv_cust_acc_resultset
			);
			IF lv_success_flag <> 'Y' THEN
				p_success_flag	:= lv_success_flag;
				p_error_message	:= lv_error_message;
				RETURN;
			ELSE
				p_success_flag	:= 'Y';
				p_error_message	:= NULL;
			END IF;
		ELSE
			p_success_flag	:= 'N';
			p_error_message	:= 'S02~Alpha Branch Code ' ||p_alpha_branch_code|| ' does not exist while consuming AMC Customer/Accounts:'||lv_customer_code||'~'||lv_cust_account;
		END IF;
	END LOOP;

	IF lv_cust_acc_prop_exists = 0 THEN
		p_success_flag	:= 'N';
		p_error_message	:= 'Customer Account Propagation data does not exists for ' ||p_alpha_branch_code||' While consuming AMC Customer/Accounts:'||lv_customer_code||'~'||lv_cust_account;
	END IF;

	EXCEPTION
		WHEN OTHERS THEN
			ROLLBACK;
			p_success_flag	:= 'N';
            p_error_message	:= SQLERRM;
			pkg_error_mgmt.prc_log_error_message
				(p_program_name => 'PKG_QLM_INCOMING_STATIC_MSG.PRC_STATIC_CUST_ACC_UPDATE',
				p_error_code 	=> SQLERRM,
				p_error_message => SUBSTR(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE(),1,4000),
				p_created_by 	=> get_maker_id(p_ext_system),
				p_param_value 	=> 'P_CUSTOMER_CODE:'||lv_customer_code||'~'||'P_ACC_NUMBER:'||p_acc_number||'~'||'P_ALPHA_BRANCH_CODE:'||p_alpha_branch_code);
			RAISE_APPLICATION_ERROR(-20001,'Error others while updating incoming static customer accounts. '||SQLERRM);
	END prc_static_cust_acc_update;
    PROCEDURE prc_mlv_customer_addl_info
    (
        p_user_id 						     IN 	qlm_customer_addl_info.maker_id%TYPE,
        p_auto_auth_flag					 IN		pls_integer,
        p_action 						     IN 	qlm_customer_addl_info_q.action%TYPE,
        p_branch_code 					     IN 	qlm_branch.alpha_branch_code%TYPE,
        p_customer_code 					 IN 	qlm_customer_addl_info.customer_code%TYPE,
        p_pay_type_pref					     IN 	qlm_customer_addl_info.pay_type_pref%TYPE,
        p_csr_code						     IN 	qlm_customer_addl_info.csr_code%TYPE,
        p_fx_stlmnt_risk_grp				 IN 	qlm_customer_addl_info.fx_stlmnt_risk_grp%TYPE,
        p_inrnl_trade_grp					 IN 	qlm_customer_addl_info.inrnl_trade_grp%TYPE,
        p_charge_details					 IN 	qlm_customer_addl_info.charge_details%TYPE,
        p_casual_netter_flag				 IN 	qlm_customer_addl_info.casual_netter_flag%TYPE,
        p_pri_casual_netter_flag	         IN 	qlm_customer_addl_info.pri_casual_netter_flag%TYPE,
        p_pri_casual_cust			         IN 	qlm_customer_addl_info.pri_casual_cust%TYPE,
        p_credit_check_reqd_flag			 IN 	qlm_customer_addl_info.credit_check_reqd_flag%TYPE,
        p_credit_check					     IN 	qlm_customer_addl_info.credit_check%TYPE,
        p_future_check_flag				     IN 	qlm_customer_addl_info.future_check_flag%TYPE,
        p_credit_check_effective_date		 IN 	qlm_customer_addl_info.credit_check_effective_date%TYPE,
        p_tracer_reqd_flag				     IN 	qlm_customer_addl_info.tracer_reqd_flag%TYPE,
        p_tracer_days					     IN 	qlm_customer_addl_info.tracer_days%TYPE,
        p_tracer_first_day				     IN 	qlm_customer_addl_info.tracer_first_day%TYPE,
        p_eod_trade_sum_reqd_flag			 IN 	qlm_customer_addl_info.eod_trade_sum_reqd_flag%TYPE,
        p_eod_netting_sum_reqd_flag			 IN 	qlm_customer_addl_info.eod_netting_sum_reqd_flag%TYPE,
        p_eod_stlmnt_sum_reqd_flag			 IN 	qlm_customer_addl_info.eod_stlmnt_sum_reqd_flag%TYPE,
        p_cust_withholding_tax_flag			 IN 	qlm_customer_addl_info.customer_withholding_tax_flag%TYPE,
        p_customer_tax_group			     IN 	qlm_customer_addl_info.customer_tax_group%TYPE,
        p_dvp_flag	                         IN 	qlm_customer_addl_info.dvp_flag%TYPE,
        p_dvp_rule			     		     IN 	qlm_customer_addl_info.dvp_rule%TYPE,
        p_spot_waive_inc_conf_flag		 	 IN 	qlm_customer_addl_info.spot_waive_incoming_conf_flag%TYPE,
        p_no_conf_no_pay_indctr_flag		 IN 	qlm_customer_addl_info.no_conf_no_pay_indctr_flag%TYPE,
        p_include_fx_online_bal_flag	     IN 	qlm_customer_addl_info.include_fx_online_bal_chk_flag%TYPE,
        p_hold_liquidation_flag				 IN 	qlm_customer_addl_info.hold_liquidation_flag%TYPE,
        p_include_breakage_fee_flag			 IN 	qlm_customer_addl_info.include_breakage_fee_flag%TYPE,
        p_include_brokerage_fee_flag	     IN 	qlm_customer_addl_info.include_brokerage_fee_flag%TYPE,
        p_local_clearing_flag 			     IN 	qlm_customer_addl_info.local_clearing_flag%TYPE,
        p_bulk_auth_flag 				     IN 	qlm_customer_addl_info.bulk_auth_flag%TYPE,
        p_suppress_paper_conf_flag 	         IN 	qlm_customer_addl_info.suppress_paper_conf_flag%TYPE,
        p_suppress_email_conf_flag 	         IN 	qlm_customer_addl_info.suppress_email_conf_flag%TYPE,
        p_suppress_fax_conf_flag 	         IN 	qlm_customer_addl_info.suppress_fax_conf_flag%TYPE,
        p_suppress_mt54x_flag 			     IN 	qlm_customer_addl_info.suppress_mt54x_flag%TYPE,
        p_department_code 				     IN 	qlm_customer_addl_info.department_code%TYPE, /*24/sep/2013*/
        p_sales_person_id				     IN 	qlm_customer_addl_info.sales_person_id%TYPE,
        p_retail_netting_flag			     IN 	qlm_customer_addl_info.retail_netting_flag%TYPE,
        p_rn_stlmnt_ccy					     IN 	qlm_customer_addl_info.rn_stlmnt_ccy%TYPE,
        p_stlmnt_pri_flag				     IN 	qlm_customer_addl_info.stlmnt_pri_flag%TYPE,
        p_stlmnt_pri_customer			     IN 	qlm_customer_addl_info.stlmnt_pri_customer%TYPE,
        p_mt304_effective_date			     IN		qlm_customer_addl_info.mt304_effective_date%TYPE,
        p_mt304_effective_date_basis		 IN		qlm_customer_addl_info.mt304_effective_date_basis%TYPE,
        p_mca_eligible_flag				     IN 	qlm_customer_addl_info.mca_eligible_flag%TYPE,
        p_mca_effective_date			     IN 	qlm_customer_addl_info.mca_effective_date%TYPE,
        p_mts_deal_flag					     IN 	qlm_customer_addl_info.mts_deal_flag%TYPE,
        p_itg_many_to_many_flag			     IN 	qlm_customer_addl_info.itg_many_to_many_flag%TYPE,
        p_wfdo_conf_for_draws_flag			 IN 	qlm_customer_addl_info.wfdo_conf_for_draws_flag%TYPE,
        p_pbg_customer_flag				     IN 	qlm_customer_addl_info.pbg_customer_flag%TYPE,
        p_skip_sundry_process_flag			 IN 	qlm_customer_addl_info.skip_sundry_process_flag%TYPE,
        p_affiliate_code				     IN		qlm_customer_addl_info.affiliate_code%TYPE,
        p_sic_code						     IN		qlm_customer_addl_info.sic_code%TYPE,
        p_itg_flag                           IN     qlm_customer_addl_info.itg_flag%TYPE,
        p_itg_type                           IN     qlm_customer_addl_info.itg_type%TYPE,
        p_generate_mt304_flag 			     IN 	qlm_customer_addl_info.generate_mt304_flag%TYPE,
        p_mt304_send_to_cp				     IN		qlm_customer_addl_info.mt304_send_to_cp%TYPE,
        p_suppress_si_conf_flag			     IN 	qlm_customer_addl_info.suppress_si_conf_flag%TYPE,
        p_customer_model					 IN		qlm_customer_addl_info.customer_model%TYPE,
        p_customer_classification			 IN		qlm_customer_addl_info.customer_classification%TYPE,
        p_cust_group						 IN		qlm_customer_addl_info.cust_group%TYPE,
        p_fo_short_name					     IN		qlm_customer_addl_info.fo_short_name%TYPE,
        p_fo_long_name					     IN		qlm_customer_addl_info.fo_long_name%TYPE,
        p_cls_member_type				     IN		qlm_customer_addl_info.cls_member_type%TYPE,
        p_cls_agent                          IN		qlm_customer_addl_info.cls_agent%TYPE,
        p_uti_in_out_conf				     IN		qlm_customer_addl_info.uti_in_out_conf%TYPE,
        p_cancel_queue_required_flag 		 IN		qlm_customer_addl_info.cancel_queue_required_flag%TYPE,
        p_skip_dual_authorization			 IN		qlm_customer_addl_info.skip_dual_authorization%TYPE,
        p_no_credit_facility_flag			 IN		qlm_customer_addl_info.no_credit_facility_flag%TYPE,
        p_transfer_type					     IN     qlm_customer_addl_info.transfer_type%TYPE,
        p_external_client 				     IN    	qlm_customer_addl_info.external_client%TYPE,
        p_intermediary_cust 			     IN 	qlm_customer_addl_info.intermediary_cust%TYPE,
        p_mt103_tag_23e					     IN		qlm_customer_addl_info.mt103_tag_23e%TYPE,
        p_citi_ny_acc					     IN		qlm_customer_addl_info.citi_ny_acc%TYPE,
        p_dda_enabled					     IN		qlm_customer_addl_info.dda_enabled%TYPE,
        p_customer_identification            IN     qlm_customer_addl_info.customer_identification%TYPE,
        p_modules				 		     IN		qlm_customer_addl_info.modules%TYPE,
        p_parent_base_no                 	 IN		qlm_customer_addl_info.parent_base_no%TYPE,
        p_addl_customer_category         	 IN		qlm_customer_addl_info.addl_customer_category%TYPE,
        p_customer_type1                 	 IN		qlm_customer_addl_info.customer_type1%TYPE,
        p_customer_type2                 	 IN		qlm_customer_addl_info.customer_type2%TYPE,
        p_us_sic_code                    	 IN		qlm_customer_addl_info.us_sic_code%TYPE,
        p_location_ccy                   	 IN		qlm_customer_addl_info.location_ccy%TYPE,
        p_restricted_acc_flag            	 IN		qlm_customer_addl_info.restricted_acc_flag%TYPE,
        p_restricted_effective_date      	 IN		qlm_customer_addl_info.restricted_effective_date%TYPE,
        p_restricted_branch              	 IN		qlm_customer_addl_info.restricted_branch%TYPE,
        p_continuous_roll_flag           	 IN		qlm_customer_addl_info.continuous_roll_flag%TYPE,
        p_customer_goc                   	 IN		qlm_customer_addl_info.customer_goc%TYPE,
        p_place                          	 IN		qlm_customer_addl_info.place%TYPE,
        p_customer_ouc                   	 IN		qlm_customer_addl_info.customer_ouc%TYPE,
        p_cb2_flag                       	 IN		qlm_customer_addl_info.cb2_flag%TYPE,
        p_nygc_flag                      	 IN		qlm_customer_addl_info.nygc_flag%TYPE,
        p_fx_spl_q_reqd_flag             	 IN		qlm_customer_addl_info.fx_spl_q_reqd_flag%TYPE,
        p_mm_spl_q_reqd_flag             	 IN		qlm_customer_addl_info.mm_spl_q_reqd_flag%TYPE,
        p_fi_buy_spl_q_reqd_flag         	 IN		qlm_customer_addl_info.fi_buy_spl_q_reqd_flag%TYPE,
        p_fi_sell_spl_q_reqd_flag        	 IN		qlm_customer_addl_info.fi_sell_spl_q_reqd_flag%TYPE,
        p_fi_rep_spl_q_reqd_flag         	 IN		qlm_customer_addl_info.fi_rep_spl_q_reqd_flag%TYPE,
        p_fi_rev_spl_q_reqd_flag         	 IN		qlm_customer_addl_info.fi_rev_spl_q_reqd_flag%TYPE,
        p_fi_wtk_spl_q_reqd_flag         	 IN		qlm_customer_addl_info.fi_wtk_spl_q_reqd_flag%TYPE,
        p_fi_wgv_spl_q_reqd_flag         	 IN		qlm_customer_addl_info.fi_wgv_spl_q_reqd_flag%TYPE,
        p_fi_len_spl_q_reqd_flag         	 IN		qlm_customer_addl_info.fi_len_spl_q_reqd_flag%TYPE,
        p_fi_bor_spl_q_reqd_flag          	 IN		qlm_customer_addl_info.fi_bor_spl_q_reqd_flag%TYPE,
        p_customer_tax_id                	 IN		qlm_customer_addl_info.customer_tax_id%TYPE,
        p_copied_from_pri_branch_flag		 IN		qlm_customer_addl_info.copied_from_pri_branch_flag%TYPE DEFAULT 0,
        p_copy_to_sub_Branch_flag			 IN		qlm_customer_addl_info.copy_to_sub_Branch_flag%TYPE DEFAULT 0,
        p_tts_customer_flag 				 IN 	qlm_customer_addl_info.tts_customer_flag%TYPE,
        p_suppress_sdr_flag				     IN 	qlm_customer_addl_info.suppress_sdr_flag%TYPE,
        p_full_movement_flag				 IN 	qlm_customer_addl_info.full_movement_flag%TYPE,
        p_suppress_mt518_flag			     IN 	qlm_customer_addl_info.suppress_mt518_flag%TYPE,
        p_version 						     IN 	qlm_customer_addl_info.version%TYPE,
        p_active_flag 					     IN 	qlm_customer_addl_info.active_flag%TYPE,
        p_supp_cls_new_conf_flag             IN		qlm_customer_addl_info.supp_cls_new_conf_flag%TYPE,
        p_supp_cls_amend_conf_flag           IN		qlm_customer_addl_info.supp_cls_amend_conf_flag%TYPE,
        p_supp_cls_can_conf_flag             IN		qlm_customer_addl_info.supp_cls_can_conf_flag%TYPE,
        p_swift_confo_code_94a               IN		qlm_customer_addl_info.swift_confo_code_94a%TYPE,
        p_upstream_sys_ref                   IN     qlm_customer_addl_info.upstream_sys_ref%TYPE,
        p_pershing_flag                      IN     qlm_customer_addl_info.pershing_flag%TYPE,
        p_pershing_parent                    IN     qlm_customer_addl_info.pershing_parent%TYPE,
        p_credit_netting_flag                IN     qlm_customer_addl_info.credit_netting_flag%TYPE,
        p_credit_parent_base_no              IN     qlm_customer_addl_info.credit_parent_base_no%TYPE,
        p_block_customer_flag                IN     qlm_customer_addl_info.block_customer_flag%TYPE,
        p_comfort_partner_flag 		         IN     qlm_customer_addl_info.comfort_partner_flag%TYPE,
        p_dda_account                        IN     qlm_customer_addl_info.dda_account%TYPE,
        p_original_branch					 IN		qlm_customer_addl_info.original_branch%TYPE,
        p_apr_num 							 IN		qlm_customer_addl_info.apr_num%TYPE,
        p_division							 IN		qlm_customer_addl_info.division%TYPE,
        p_fi_investment_service				 IN		qlm_customer_addl_info.fi_investment_service%TYPE,
        p_fi_contract_number				 IN 	qlm_customer_addl_info.fi_contract_number%TYPE,
        p_fi_customer_category				 IN 	qlm_customer_addl_info.fi_customer_category%TYPE,
        p_ops_remarks    		             IN		qlm_customer_addl_info.ops_remarks%TYPE,
        p_relationship_manager               IN		qlm_customer_addl_info.relationship_manager%TYPE,
        p_mm_waive_incoming_conf_flag        IN 	qlm_customer_addl_info.mm_waive_incoming_conf_flag%TYPE,
        p_mm_no_conf_no_pay_indct_flag       IN     qlm_customer_addl_info.mm_no_conf_no_pay_indctr_flag%TYPE,
        p_fatca_eligible					 IN     qlm_customer_addl_info.fatca_eligible%TYPE,
        p_banxico_cust_flag       			 IN 	qlm_customer_addl_info.banxico_cust_flag%TYPE,
        p_fx_conf_waiver 					 IN 	qlm_customer_addl_info.fx_conf_waiver%TYPE,
        p_govt_issuer_flag					 IN		qlm_customer_addl_info.govt_issuer_flag%TYPE,
        p_internal_custody_flag       		 IN     qlm_customer_addl_info.internal_custody_flag%TYPE,
        p_generate_mt350_flag				 IN		qlm_customer_addl_info.generate_mt350_flag%TYPE,
        p_gmra_customer						 IN		qlm_customer_addl_info.gmra_customer%TYPE,
        p_fi_customer_tax_id                 IN     qlm_customer_addl_info.fi_customer_tax_id%TYPE,
        p_residency_flag					 IN		qlm_customer_addl_info.residency_flag%TYPE,
        p_calm_legal_vechile_code			 IN 	qlm_customer_addl_info.calm_legal_vechile_code%TYPE,
        p_mxn_customer_profile			     IN		qlm_customer_addl_info.mxn_customer_profile%TYPE,
        p_mxn_executive_phone_number		 IN		qlm_customer_addl_info.mxn_executive_phone_number%TYPE,
        p_mxn_executive_name				 IN		qlm_customer_addl_info.mxn_executive_name%TYPE,
        p_op_waive_incoming_conf_flag		 IN		qlm_customer_addl_info.op_waive_incoming_conf_flag%TYPE,
        p_op_no_conf_no_pay_indct_flag		 IN		qlm_customer_addl_info.op_no_conf_no_pay_indctr_flag%TYPE,
        p_op_spl_q_reqd_flag             	 IN		qlm_customer_addl_info.op_spl_q_reqd_flag%TYPE,
        p_ft_fee_flag						 IN  	qlm_customer_addl_info.ft_fee_flag%TYPE,
        p_ft_debit_acc_no			     IN  	qlm_customer_addl_info.ft_debit_acc_no%TYPE,
        p_ft_fee_deduction_ccy				 IN		qlm_customer_addl_info.ft_fee_deduction_ccy%TYPE,
        p_success_flag				         OUT	VARCHAR2,
        p_error_message			             OUT	VARCHAR2
    )
IS
    lv_queue_resultset            SYS_REFCURSOR;
    lv_result_set                 SYS_REFCURSOR;
    lv_deal_resultset             SYS_REFCURSOR;
    lv_trade_details_mm           SYS_REFCURSOR;
    lv_trade_details_fx           SYS_REFCURSOR;
    lv_trade_details_fi           SYS_REFCURSOR;
    lv_customer_maintenance       PLS_INTEGER := 0;
    lv_branch_code                qlm_branch.branch_code%TYPE;
    lv_action                     qlm_customer_addl_info_q.action%TYPE;
    lv_version                    qlm_customer_addl_info.version%TYPE := 0;
    lv_cust_product_mapping_records TAB_CUST_PRODUCT_MAPPING := TAB_CUST_PRODUCT_MAPPING();

BEGIN
    SELECT NVL(MAX(branch_code), 0)
    INTO lv_branch_code
    FROM qlm_branch
    WHERE alpha_branch_code = p_branch_code
    AND active_flag = 1;

    IF lv_branch_code = 0 THEN
      p_success_flag := 'N';
      p_error_message := 'S03~ Branch is not active ' || p_branch_code;
      RETURN;
    END IF;

    SELECT COUNT(1)
    INTO lv_customer_maintenance
    FROM qlm_customer
    WHERE branch_code = lv_branch_code
    AND customer_code = p_customer_code;

    IF lv_customer_maintenance = 0 THEN
      p_success_flag := 'N';
      p_error_message := 'S02~' || lv_branch_code || '/' || p_customer_code ||
                 ' Customer is not maintained for the branch';
      RETURN;
    END IF;

    SELECT MAX(version)
    INTO lv_version
    FROM qlm_customer_addl_info
    WHERE branch_code = lv_branch_code
    AND customer_code = p_customer_code;

    IF lv_version IS NULL THEN
      lv_action := 'C';
      lv_version := 0;
    ELSE
      lv_action := 'E';
    END IF;

    PKG_CUSTOMER_ADDL_INFO_MGMT.prc_edit_customer_addl_info
    (
                p_user_id						 => 'MLVDATA',
                p_auto_auth_flag				 => 1,
                p_action						 => lv_action,
                p_branch_code					 => lv_branch_code,
                p_customer_code					 => p_customer_code,
                p_pay_type_pref					 => p_pay_type_pref,
                p_csr_code						 => p_csr_code,
                p_fx_stlmnt_risk_grp			 => p_fx_stlmnt_risk_grp,
                p_inrnl_trade_grp				 => p_inrnl_trade_grp,
                p_charge_details				 => p_charge_details,
                p_casual_netter_flag			 => p_casual_netter_flag,
                p_pri_casual_netter_flag		 => p_pri_casual_netter_flag,
                p_pri_casual_cust				 => p_pri_casual_cust,
                p_credit_check_reqd_flag		 => p_credit_check_reqd_flag,
                p_credit_check					 => p_credit_check,
                p_future_check_flag				 => p_future_check_flag,
                p_credit_check_effective_date	 => p_credit_check_effective_date,
                p_tracer_reqd_flag				 => p_tracer_reqd_flag,
                p_tracer_days					 => p_tracer_days,
                p_tracer_first_day				 => p_tracer_first_day,
                p_eod_trade_sum_reqd_flag		 => p_eod_trade_sum_reqd_flag,
                p_eod_netting_sum_reqd_flag		 => p_eod_netting_sum_reqd_flag,
                p_eod_stlmnt_sum_reqd_flag		 => p_eod_stlmnt_sum_reqd_flag,
                p_cust_withholding_tax_flag		 => p_cust_withholding_tax_flag,
                p_customer_tax_group			 => p_customer_tax_group,
                p_dvp_flag						 => p_dvp_flag,
                p_dvp_rule						 => p_dvp_rule,
                p_spot_waive_inc_conf_flag		 => p_spot_waive_inc_conf_flag,
                p_no_conf_no_pay_indctr_flag	 => p_no_conf_no_pay_indctr_flag,
                p_include_fx_online_bal_flag	 => p_include_fx_online_bal_flag,
                p_hold_liquidation_flag			 => p_hold_liquidation_flag,
                p_include_breakage_fee_flag		 => p_include_breakage_fee_flag,
                p_include_brokerage_fee_flag	 => p_include_brokerage_fee_flag,
                p_local_clearing_flag			 => p_local_clearing_flag,
                p_bulk_auth_flag				 => p_bulk_auth_flag,
                p_suppress_paper_conf_flag		 => p_suppress_paper_conf_flag,
                p_suppress_email_conf_flag		 => p_suppress_email_conf_flag,
                p_suppress_fax_conf_flag		 => p_suppress_fax_conf_flag,
                p_suppress_mt54x_flag			 => p_suppress_mt54x_flag,
                p_department_code				 => p_department_code,
                p_sales_person_id				 => p_sales_person_id,
                p_retail_netting_flag			 => p_retail_netting_flag,
                p_rn_stlmnt_ccy					 => p_rn_stlmnt_ccy,
                p_stlmnt_pri_flag				 => p_stlmnt_pri_flag,
                p_stlmnt_pri_customer			 => p_stlmnt_pri_customer,
                p_mt304_effective_date			 => p_mt304_effective_date,
                p_mt304_effective_date_basis	 => p_mt304_effective_date_basis,
                p_mca_eligible_flag				 => p_mca_eligible_flag,
                p_mca_effective_date			 => p_mca_effective_date,
                p_mts_deal_flag					 => p_mts_deal_flag,
                p_itg_many_to_many_flag			 => p_itg_many_to_many_flag,
                p_wfdo_conf_for_draws_flag		 => p_wfdo_conf_for_draws_flag,
                p_pbg_customer_flag				 => p_pbg_customer_flag,
                p_skip_sundry_process_flag		 => p_skip_sundry_process_flag,
                p_affiliate_code				 => p_affiliate_code,
                p_sic_code						 => p_sic_code,
                p_itg_flag                       => p_itg_flag,
                p_itg_type                       => p_itg_type,
                p_generate_mt304_flag			 => p_generate_mt304_flag,
                p_mt304_send_to_cp				 => p_mt304_send_to_cp,
                p_suppress_si_conf_flag			 => p_suppress_si_conf_flag,
                p_customer_model				 => p_customer_model,
                p_customer_classification		 => p_customer_classification,
                p_cust_group					 => p_cust_group,
                p_fo_short_name					 => p_fo_short_name,
                p_fo_long_name					 => p_fo_long_name,
                p_cls_member_type				 => p_cls_member_type,
                p_cls_agent                      => p_cls_agent,
                p_uti_in_out_conf				 => p_uti_in_out_conf,
                p_cancel_queue_required_flag	 => p_cancel_queue_required_flag,
                p_skip_dual_authorization		 => p_skip_dual_authorization,
                p_no_credit_facility_flag		 => p_no_credit_facility_flag,
                p_transfer_type					 => p_transfer_type,
                p_external_client				 => p_external_client,
                p_intermediary_cust				 => p_intermediary_cust,
                p_mt103_tag_23e					 => p_mt103_tag_23e,
                p_citi_ny_acc					 => p_citi_ny_acc,
                p_dda_enabled					 => p_dda_enabled,
                p_customer_identification		 => p_customer_identification,
                p_modules						 => p_modules,
                p_parent_base_no				 => p_parent_base_no,
                p_addl_customer_category		 => p_addl_customer_category,
                p_customer_type1				 => p_customer_type1,
                p_customer_type2				 => p_customer_type2,
                p_us_sic_code					 => p_us_sic_code,
                p_location_ccy					 => p_location_ccy,
                p_restricted_acc_flag			 => p_restricted_acc_flag,
                p_restricted_effective_date	     => p_restricted_effective_date,
                p_restricted_branch				 => p_restricted_branch,
                p_continuous_roll_flag			 => p_continuous_roll_flag,
                p_customer_goc					 => p_customer_goc,
                p_place							 => p_place,
                p_customer_ouc					 => p_customer_ouc,
                p_cb2_flag						 => p_cb2_flag,
                p_nygc_flag						 => p_nygc_flag,
                p_fx_spl_q_reqd_flag			 => p_fx_spl_q_reqd_flag,
                p_mm_spl_q_reqd_flag			 => p_mm_spl_q_reqd_flag,
                p_fi_buy_spl_q_reqd_flag		 => p_fi_buy_spl_q_reqd_flag,
                p_fi_sell_spl_q_reqd_flag		 => p_fi_sell_spl_q_reqd_flag,
                p_fi_rep_spl_q_reqd_flag		 => p_fi_rep_spl_q_reqd_flag,
                p_fi_rev_spl_q_reqd_flag		 => p_fi_rev_spl_q_reqd_flag,
                p_fi_wtk_spl_q_reqd_flag		 => p_fi_wtk_spl_q_reqd_flag,
                p_fi_wgv_spl_q_reqd_flag		 => p_fi_wgv_spl_q_reqd_flag,
                p_fi_len_spl_q_reqd_flag		 => p_fi_len_spl_q_reqd_flag,
                p_fi_bor_spl_q_reqd_flag		 => p_fi_bor_spl_q_reqd_flag,
                p_customer_tax_id				 => p_customer_tax_id,
                p_copied_from_pri_branch_flag	 => p_copied_from_pri_branch_flag,
                p_copy_to_sub_Branch_flag		 => p_copy_to_sub_Branch_flag,
                p_tts_customer_flag				 => p_tts_customer_flag,
                p_suppress_sdr_flag				 => p_suppress_sdr_flag,
                p_full_movement_flag			 => p_full_movement_flag,
                p_suppress_mt518_flag			 => p_suppress_mt518_flag,
                p_version						 => lv_version,
                p_active_flag					 => p_active_flag,
                p_supp_cls_new_conf_flag		 => p_supp_cls_new_conf_flag,
                p_supp_cls_amend_conf_flag		 => p_supp_cls_amend_conf_flag,
                p_supp_cls_can_conf_flag		 => p_supp_cls_can_conf_flag,
                p_swift_confo_code_94a			 => p_swift_confo_code_94a,
                p_upstream_sys_ref				 => p_upstream_sys_ref,
                p_pershing_flag					 => p_pershing_flag,
                p_pershing_parent				 => p_pershing_parent,
                p_credit_netting_flag			 => p_credit_netting_flag,
                p_credit_parent_base_no			 => p_credit_parent_base_no,
                p_block_customer_flag			 => p_block_customer_flag,
                p_comfort_partner_flag			 => p_comfort_partner_flag,
                p_dda_account					 => p_dda_account,
                p_original_branch				 => p_original_branch,
                p_apr_num						 => p_apr_num,
                p_division						 => p_division,
                p_fi_investment_service			 => p_fi_investment_service,
                p_fi_contract_number			 => p_fi_contract_number,
                p_fi_customer_category			 => p_fi_customer_category,
                p_ops_remarks					 => p_ops_remarks,
                p_relationship_manager			 => p_relationship_manager,
                p_mm_waive_incoming_conf_flag	 => p_mm_waive_incoming_conf_flag,
                p_mm_no_conf_no_pay_indct_flag	 => p_mm_no_conf_no_pay_indct_flag,
                p_fatca_eligible				 => p_fatca_eligible,
                p_banxico_cust_flag				 => p_banxico_cust_flag,
                p_fx_conf_waiver				 => p_fx_conf_waiver,
                p_govt_issuer_flag				 => p_govt_issuer_flag,
                p_internal_custody_flag			 => p_internal_custody_flag,
                p_generate_mt350_flag			 => p_generate_mt350_flag,
                p_gmra_customer					 => p_gmra_customer,
                p_fi_customer_tax_id			 => p_fi_customer_tax_id,
                p_residency_flag				 => p_residency_flag,
                p_calm_legal_vechile_code		 => p_calm_legal_vechile_code,
                p_mxn_statement_setup			 => 0,
                p_mxn_customer_profile			 => p_mxn_customer_profile,
                p_mxn_executive_phone_number	 => p_mxn_executive_phone_number,
                p_mxn_executive_name			 => p_mxn_executive_name,
                p_safe_keeping_acc_no			 => NULL,
                p_pass_through_account_flag		 => 0,
                p_collater_dep_indicator_flag	 => 0,
                p_op_waive_incoming_conf_flag	 => p_op_waive_incoming_conf_flag,
                p_op_no_conf_no_pay_indct_flag	 => p_op_no_conf_no_pay_indct_flag,
                p_op_spl_q_reqd_flag			 => p_op_spl_q_reqd_flag,
                p_hedging_customer_flag			 => 0,
                p_mm_hold_maturity_payment_flg	 => 0,
                p_cust_mnemonic					 => NULL,
                p_cust_tax_country				 => NULL,
                p_tax_exempt_status				 => NULL,
                p_cust_doc_expiry_date			 => NULL,
                p_cust_doc_valid_from			 => NULL,
                p_cust_doc_submission_date		 => NULL,
                p_cust_tax_entity_type			 => NULL,
                p_cust_tax_client_code			 => NULL,
                p_cust_tax_code					 => NULL,
                p_charges_and_vat_flag			 => 0,
                p_vat_group						 => NULL,
                p_mm_rtgs_local_resi_tag108	     => NULL,
                p_rtgs_non_loc_resi_bc_tag108	 => NULL,
                p_rtgs_non_loc_resi_ac_tag108	 => NULL,
                p_isda_date						 => NULL,
                p_include_dep_guarantor_flag	 => 0,
                p_consolidate_conf_flag			 => 0,
                p_fx_rtgs_local_resi_tag108	     => NULL,
                p_fi_bsb_spl_q_reqd_flag		 => 0,
                p_fi_sbb_spl_q_reqd_flag		 => 0,
                p_tab_cust_addl_info_addattr	 => NULL,
                p_mx_statements_audit_flag		 => 0,
                p_ft_fee_flag					 => p_ft_fee_flag,
                p_ft_debit_acc_no				 => p_ft_debit_acc_no,
                p_fx_disable_obc_ta_rcv_flag	 => 0,
                p_mm_disable_obc_ta_rcv_flag	 => 0,
                p_cls_netting_flag				 => 0,
                p_cls_net_eligible_prod			 => NULL,
                p_net_segregation_module		 => NULL,
                p_aggregation_flag				 => 0,
                p_aggregation_parent_flag		 => 0,
                p_aggregation_parent_base		 => NULL,
                p_mts_we_flag					 => 0,
                p_mts_we_branch					 => NULL,
                p_ft_fee_deduction_ccy			 => p_ft_fee_deduction_ccy,
                p_options_scrub_account			 => NULL,
                p_bank_acronym					 => NULL,
                p_fx_rtgs_resi_priority_flag	 => 0,
                p_mm_propagate_cust_wht_flag	 => 0,
                p_cms_ns_pwd_protection_flag	 => 0,
                p_exempt_77D_flag				 => 0,
                p_entity_type					 => NULL,
                p_fi_mac_flag					 => 0,
                p_fx_mac_flag					 => 0,
                p_fi_obc_supp_flag				 => 1,
                p_fi_pay_supp_flag				 => 1,
                p_genesis_preterm_allowed_ind	 => NULL,
                p_contract_opening_date			 => NULL,
                p_fwd_waive_incoming_conf_flag	 => 0,
                p_ncnp_waive_inc_conf_flag		 => 0,
                p_sector						 => NULL,
                p_credit_stage					 => NULL,
                p_gmra_date						 => NULL,
                p_op_sameday_set_spl_q_flag		 => 0,
                p_op_b2b_bank_flag				 => 0,
                p_clearing_location				 => NULL,
                p_include_mm_online_bal_flag	 => 0,
                p_include_op_online_bal_flag	 => 0,
                p_op_disable_obc_ta_rcv_flag	 => 0,
                p_isda_id						 => NULL,
                p_mt518_far_leg_suppress_flag	 => 0,
                p_fx_custody_b2b_client_flag	 => 0,
                p_large_company_cust_flag		 => 0,
                p_cp_code						 => NULL,
                p_id_general_justice		     => NULL,
                p_qfx_collat_customer			 => 'N',
                p_client_type					 => NULL,
                p_is_prime_broker				 => NULL,
                p_cpty_ref_type				     => NULL,
                p_isda_status					 => 'N',
                p_isda_version					 => NULL,
                p_isda_definition_year			 => 1998,
                p_fx_conf_tag21_fo_text_flag	 => 0,
                p_op_casual_netter_flag			 => 0,
                p_op_pri_casual_netter_flag		 => 0,
                p_op_pri_casual_cust			 => NULL,
                p_exempt_mt300_39M_flag			 => 0,
                p_exempt_mt300_77H_flag			 => 0,
                p_retail_customer_flag			 => 0,
                p_isda_customer_flag			 => 0,
                p_resident_customer_flag		 => 0,
                p_mm_customer_model				 => NULL,
                p_ft_rtgs_local_resi_tag108		 => NULL,
                p_customer_broker_fee_group		 => NULL,
                p_treasury_master_agreement_dt	 => NULL,
                p_fi_disable_obc_ta_rcv_flag	 => 0,
                p_fi_dvp_flag					 => 0,
                p_netting_ndf_category			 => NULL,
                p_enable_london_customer		 => 0,
                p_is_fund_manager_customer		 => 0,
                p_exclude_fx_ar_customer_flag	 => 0,
                p_fx_auto_debit_flag			 => 0,
                p_gst_charges					 => 'NA',
                p_ccil_membership_code			 => NULL,
                p_reuters_code					 => NULL,
                p_ccil_customer_flag			 => 0,
                p_customer_lei_id				 => NULL,
                p_lei_id_expire_date			 => NULL,
                p_ibu_flag						 => 0,
                p_sub_residency_category		 => NULL,
                p_rbs_classification			 => NULL,
                p_settlement_on_trade_date		 => 0,
                p_customer_category				 => NULL,
                p_customer_segment				 => NULL,
                p_pvp_net_flag					 => 0,
                p_enable_mt305_knockin_flag		 => 0,
                p_enable_mt305_exercise_flag	 => 0,
                p_is_oep_nonswift_reqd_flag		 => 1,
                p_is_ndo_nonswift_reqd_flag		 => 1,
                p_notional_deal_identifier_flg	 => 0,
                p_mm_casual_netter_flag			 => 0,
                p_mm_pri_casual_netter_flag		 => 0,
                p_mm_pri_casual_cust			 => NULL,
                p_enable_mt306_knockin_flag		 => 0,
                p_enable_mt306_knock_out_flag	 => 0,
                p_enable_mt306_expire_flag		 => 0,
                p_cust_product_mapping_records	 => lv_cust_product_mapping_records,
                p_fi_no_conf_no_pay_indctr_flag	 => 0,
                p_fi_waive_incoming_conf_flag	 => 0,
                p_success_flag					 => p_success_flag,
                p_error_message					 => p_error_message,
                p_queue_resultset				 => lv_queue_resultset,
                p_result_set					 => lv_result_set,
                p_deal_resultset				 => lv_deal_resultset,
                p_trade_details_mm				 => lv_trade_details_mm,
                p_trade_details_fx				 => lv_trade_details_fx,
                p_trade_details_fi				 => lv_trade_details_fi
        );

EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            p_success_flag := 'N';
            p_error_message := 'S08~Error others while consuming MLV customer additional information. ' || SQLERRM;
            pkg_error_mgmt.prc_log_error_message
        (p_program_name => 'PKG_QLM_INCOMING_STATIC_MSG.PRC_MLV_CUSTOMER_ADDL_INFO',
             p_error_code => SQLERRM,
             p_error_message => SUBSTR(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE(),1,4000),
             p_created_by => p_user_id,
             p_param_value => 'P_BRANCH_CODE:'||p_branch_code||'~'||'P_CUSTOMER_CODE:'||p_customer_code);
END prc_mlv_customer_addl_info;
    PROCEDURE prc_mlv_customer_msg_addr
    (
        p_user_id                        IN  qlm_customer_msg_addr_q.maker_id%TYPE,
        p_auto_auth_flag                 IN  PLS_INTEGER,
        p_action                         IN  qlm_customer_msg_addr_q.action%TYPE,
        p_alpha_branch_code              IN  qlm_branch.alpha_branch_code%TYPE,
        p_modules                        IN  qlm_customer_msg_addr_q.modules%TYPE,
        p_customer_code                  IN  qlm_customer_msg_addr_q.customer_code%TYPE,
        p_media                          IN  qlm_customer_msg_addr_q.media%TYPE,
        p_location                       IN  qlm_customer_msg_addr_q.location%TYPE,
        p_gcn_mapping_bic                IN  qlm_customer_msg_addr_q.gcn_mapping_bic%TYPE,
        p_supp_new_conf_flag             IN  qlm_customer_msg_addr_q.supp_new_conf_flag%TYPE,
        p_supp_amend_conf_flag           IN  qlm_customer_msg_addr_q.supp_amend_conf_flag%TYPE,
        p_supp_tracer_conf_flag          IN  qlm_customer_msg_addr_q.supp_tracer_conf_flag%TYPE,
        p_tag_83D                        IN  qlm_customer_msg_addr_q.tag_83D%TYPE,
        p_tag_87D                        IN  qlm_customer_msg_addr_q.tag_87D%TYPE,
        p_tag_83DCLS                     IN  qlm_customer_msg_addr_q.tag_83DCLS%TYPE,
        p_gcn_msg_identifier             IN  qlm_customer_msg_addr_q.gcn_msg_identifier%TYPE,
        p_copied_from_pri_branch_flag    IN  qlm_customer_msg_addr_q.copied_from_pri_branch_flag%TYPE DEFAULT 0,
        p_copy_to_sub_Branch_flag        IN  qlm_customer_msg_addr_q.copy_to_sub_Branch_flag%TYPE DEFAULT 0,
        p_fi_straight_through            IN  qlm_customer_msg_addr_q.fi_straight_through%TYPE DEFAULT 0,
        p_supp_new_eod_conf_flag         IN  qlm_customer_msg_addr_q.supp_new_eod_conf_flag%TYPE,
        p_version                        IN  qlm_customer_msg_addr_q.version%TYPE,
        p_active_flag                    IN  qlm_customer_msg_addr_q.active_flag%TYPE,
        p_tab_cust_msg_addr_pii          IN  tab_cust_msg_addr_pii,
        p_tab_cust_msg_addr_types        IN  tab_cust_msg_addr_types,
        p_tab_cust_emailaddress_pii      IN  tab_cust_emailaddress_pii,
        p_tab_cust_msg_fax               IN  tab_cust_msg_fax,
        p_tab_cust_docusign_pii          IN  tab_cust_docusign_pii,
        p_language                       IN  qlm_customer_msg_addr_q.language%TYPE,
        p_supp_new_cms_conf_flag         IN  qlm_customer_msg_addr_q.supp_new_cms_conf_flag%TYPE,
        p_supp_amend_cms_conf_flag       IN  qlm_customer_msg_addr_q.supp_amend_cms_conf_flag%TYPE,
        p_mandatory_docu_signers         IN  qlm_customer_msg_addr_q.mandatory_docu_signers%TYPE,
        p_affirm_advice_flag             IN  qlm_customer_msg_addr_q.affirm_advice_flag%TYPE,
        p_msg_type                       IN  qlm_customer_msg_addr_q.msg_type%TYPE,
        p_success_flag                   OUT VARCHAR2,
        p_error_message                  OUT VARCHAR2
    )
    IS
        lv_customer_maintenance       PLS_INTEGER := 0;
        lv_branch_code                qlm_branch.branch_code%TYPE;
        lv_action                     qlm_customer_msg_addr_q.action%TYPE;
        lv_version                    qlm_customer_msg_addr_q.version%TYPE := 0;
    BEGIN
        SELECT NVL(MAX(branch_code), 0)
        INTO lv_branch_code
        FROM qlm_branch
        WHERE alpha_branch_code = p_alpha_branch_code
        AND active_flag = 1;

        IF lv_branch_code = 0 THEN
            p_success_flag := 'N';
            p_error_message := 'S03~ Branch is not active ' || p_alpha_branch_code;
            RETURN;
        END IF;

        SELECT COUNT(1)
        INTO lv_customer_maintenance
        FROM qlm_customer
        WHERE branch_code = lv_branch_code
          AND customer_code = p_customer_code
          AND active_flag = 1;

        IF lv_customer_maintenance = 0 THEN
            p_success_flag := 'N';
            p_error_message := 'S02~' || lv_branch_code || '/' || p_customer_code ||
                               ' Customer is not maintained for the branch';
            RETURN;
        END IF;

        BEGIN
            SELECT  version
            INTO    lv_version
            FROM    qlm_customer_msg_addr
            WHERE   branch_code   = lv_branch_code
            AND     modules       = p_modules
            AND     customer_code = p_customer_code
            AND     media         = p_media
            AND     location      = p_location;

            lv_action := 'E';
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                lv_action := 'C';
                lv_version := 0;
            WHEN TOO_MANY_ROWS THEN
                p_success_flag := 'N';
                p_error_message := 'S02~Multiple Customer Message Address records exist for ' ||
                                   lv_branch_code || '/' || p_modules || '/' || p_customer_code || '/' ||
                                   p_media || '/' || p_location;
                RETURN;
        END;

        PKG_CUST_MSG_ADDR_MGMT.prc_edit_cust_msg_addr
        (
            p_user_id                        => 'MLVDATA',
            p_auto_auth_flag                 => 1,
            p_action                         => lv_action,
            p_branch_code                    => lv_branch_code,
            p_modules                        => p_modules,
            p_customer_code                  => p_customer_code,
            p_media                          => p_media,
            p_location                       => p_location,
            p_gcn_mapping_bic                => p_gcn_mapping_bic,
            p_supp_new_conf_flag             => p_supp_new_conf_flag,
            p_supp_amend_conf_flag           => p_supp_amend_conf_flag,
            p_supp_tracer_conf_flag          => p_supp_tracer_conf_flag,
            p_tag_83D                        => p_tag_83D,
            p_tag_87D                        => p_tag_87D,
            p_tag_83DCLS                     => p_tag_83DCLS,
            p_gcn_msg_identifier             => p_gcn_msg_identifier,
            p_copied_from_pri_branch_flag    => p_copied_from_pri_branch_flag,
            p_copy_to_sub_Branch_flag        => p_copy_to_sub_Branch_flag,
            p_fi_straight_through            => p_fi_straight_through,
            p_supp_new_eod_conf_flag         => p_supp_new_eod_conf_flag,
            p_version                        => lv_version,
            p_active_flag                    => p_active_flag,
            p_tab_cust_msg_addr_pii          => p_tab_cust_msg_addr_pii,
            p_tab_cust_msg_addr_types        => p_tab_cust_msg_addr_types,
            p_tab_cust_emailaddress_pii      => p_tab_cust_emailaddress_pii,
            p_tab_cust_msg_fax               => p_tab_cust_msg_fax,
            p_tab_cust_docusign_pii          => p_tab_cust_docusign_pii,
            p_language                       => p_language,
            p_supp_new_cms_conf_flag         => p_supp_new_cms_conf_flag,
            p_supp_amend_cms_conf_flag       => p_supp_amend_cms_conf_flag,
            p_mandatory_docu_signers         => p_mandatory_docu_signers,
            p_affirm_advice_flag             => p_affirm_advice_flag,
            p_msg_type                       => p_msg_type,
            p_success_flag                   => p_success_flag,
            p_error_message                  => p_error_message
        );
    EXCEPTION
        WHEN OTHERS THEN
            p_success_flag := 'N';
            p_error_message := 'S08~Error others while consuming MLV customer message address. ' || SQLERRM;
            pkg_error_mgmt.prc_log_error_message
            (p_program_name => 'PKG_QLM_INCOMING_STATIC_MSG.PRC_MLV_CUSTOMER_MSG_ADDR',
             p_error_code => SQLERRM,
             p_error_message => SUBSTR(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE(),1,4000),
             p_created_by => p_user_id,
             p_param_value => 'P_ALPHA_BRANCH_CODE:'||p_alpha_branch_code||'~'||'P_CUSTOMER_CODE:'||p_customer_code);
    END prc_mlv_customer_msg_addr;

    FUNCTION fnc_get_cust_account
    (
        p_acc_number         IN  qlm_customer_accounts_q.acc_number%TYPE,
        p_branch_code        IN  qlm_branch_currency.branch_code%TYPE,
        p_custacc_max_length IN  qlm_ext_branch.customer_number_max_length%TYPE,
        p_custacc_prefix     IN  qlm_ext_branch.customer_number_prefix%TYPE,
        p_custacc_prefix_val IN  qlm_ext_branch.customer_number_prefix_value%TYPE
    )
    RETURN VARCHAR2
    /* ****************************************************
    Function Name 	: 	fnc_get_cust_account
    Created By     	: 	Karthikeyan Govindaraj
    Description    	: 	This function appends the value to the customer account.
    ----------------------------------------------------------------------------------
    Modified By	    		Date 				Modification
    ----------------------------------------------------------------------------------
    Karthikeyan G		05/Nov/2023		C166472-16649 - Customer account maintenance in QFXLM - 0 padding
    ***************************************************** */
    IS
       lv_cust_account              qlm_customer_accounts.acc_number%type;
       lv_cust_account_split        qlm_customer_accounts.acc_number%type;
    BEGIN

        IF  p_custacc_prefix = 'F' AND p_custacc_prefix_val IS NOT NULL AND p_custacc_max_length IS NOT NULL THEN
            lv_cust_account_split := SUBSTR(p_acc_number,4,LENGTH(p_acc_number));
            lv_cust_account := SUBSTR(p_acc_number,0,3) || LPAD(
                (CASE
                    WHEN p_custacc_max_length < LENGTH(lv_cust_account_split) THEN TRIM(LEADING 0 FROM lv_cust_account_split)
                    ELSE lv_cust_account_split
                END),
                p_custacc_max_length,
                p_custacc_prefix_val
            );
        ELSE
            lv_cust_account 	:= 	p_acc_number;
        END IF;

        RETURN lv_cust_account;
    EXCEPTION
        WHEN OTHERS THEN
            pkg_error_mgmt.prc_log_error_message
            (
                p_program_name 	=> 'PKG_QLM_INCOMING_STATIC_MSG.fnc_get_cust_account',
                p_error_code 	=> SQLERRM,
                p_error_message => SUBSTR(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE(),1,4000),
                p_created_by 	=> 'SYSTEM',
                p_param_value	=> 'P_ACC_NUMBER :'||p_acc_number||'~'||'P_BRANCH_CODE :'||p_branch_code||'~'||'p_custacc_max_length :'||p_custacc_max_length||'~'||'p_custacc_prefix :'||p_custacc_prefix||'~'||'p_custacc_prefix_val :'||p_custacc_prefix_val
            );
    END fnc_get_cust_account;

    FUNCTION get_maker_id
    (
        p_ext_system    IN  VARCHAR2
    )
    RETURN VARCHAR2
    /* ****************************************************
        Function Name 	: 	get_maker_id
        Created By     	: 	Sandagorda Patricia
        Description    	: 	This function returns Maker/checker id depends on the ext system.
        ----------------------------------------------------------------------------------
        Modified By	    		Date 				Modification
        ----------------------------------------------------------------------------------
        Sandagorda P		02/Jun/2026		C166472-37161 - Change maker/checker IDs from SYSTEM to ISGDATA for ISG Cloud Customer Account Records
        ***************************************************** */
    IS
    BEGIN
        RETURN CASE
            WHEN p_ext_system = 'ISG_CUST_ACC' THEN 'ISGDATA'
            ELSE 'SYSTEM'
        END;
    END get_maker_id;

END PKG_QLM_INCOMING_STATIC_MSG;
/
SHOW ERR

CREATE OR REPLACE PUBLIC SYNONYM PKG_QLM_INCOMING_STATIC_MSG FOR QLM_OWNER.PKG_QLM_INCOMING_STATIC_MSG
/
GRANT EXECUTE ON QLM_OWNER.PKG_QLM_INCOMING_STATIC_MSG TO QLM_READWRITE
/