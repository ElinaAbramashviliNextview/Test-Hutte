public with sharing class Cst {
	/* ORDER SAP STATUS */
	public static final String CURR_CZK	= 'CZK';
	public static final String CURR_EUR	= 'EUR';
	public static final String CURR_USD	= 'USD';

    /* METHOD RESULT STATUS */
    public static final String STATUS_SUCCESS  = 'success';
    public static final String STATUS_ERROR    = 'error';
    public static final String STATUS_WARNING  = 'warn';
    public static final String STATUS_INFO     = 'info';

    /* SYNC STATUS */
	public static final String SYNC_STATUS_SUCCESS = 'SUCCESS';
	public static final String SYNC_STATUS_WARNING = 'WARNING';
	public static final String SYNC_STATUS_ERROR   = 'ERROR';
	public static final String SYNC_STATUS_SYNCING = 'SYNCING';
	public static final String SYNC_STATUS_FORCE   = 'FORCE';
	public static final String SYNC_STATUS_HOLD    = 'HOLD';

	/* REQUEST FOR TECHNICIAN STATUS */
	public static final String RFT_STATUS_REQUESTED		= 'Requested';
	public static final String RFT_STATUS_INPROGRESS    = 'In Progress';
	public static final String RFT_STATUS_DONE			= 'Done';

	/* QUOTE STATUS */
	public static final String QUOTE_STATUS_NEW			= 'New';
	public static final String QUOTE_STATUS_TOPROCESS	= 'To Process';
	public static final String QUOTE_STATUS_PROCESSED	= 'Processed';
	public static final String QUOTE_STATUS_PRINTED		= 'Printed';
	public static final String QUOTE_STATUS_QUOTED		= 'Quoted';

	/* OPPORTUNITY STAGE */
	public static final String OPPORTUNITY_STAGE_QUALIFICATION	= 'Qualification';
	public static final String OPPORTUNITY_STAGE_ASSOFNEEDS		= 'Assessment of Needs';
	public static final String OPPORTUNITY_STAGE_TECHSUPP		= 'Technical support';
	public static final String OPPORTUNITY_STAGE_QUOTED			= 'Quoted';
	public static final String OPPORTUNITY_STAGE_POSFOLLOWUP	= 'Positive Follow-up';
	public static final String OPPORTUNITY_STAGE_NEGOTIATION	= 'Negotiation';
	public static final String OPPORTUNITY_STAGE_FINALIZING 	= 'Finalizing';
	public static final String OPPORTUNITY_STAGE_CLOSEDWON		= 'Closed Won';
	public static final String OPPORTUNITY_STAGE_CLOSEDLOST		= 'Closed Lost';
	public static final String OPPORTUNITY_STAGE_HANDOVER		= 'Handover';

	/* ORDER SAP STATUS */
	public static final String ORDER_SAP_STATUS_I	= 'I'; // naimportováno
	public static final String ORDER_SAP_STATUS_F	= 'F'; // předáno

	/* QUANTITY UNITS OF MEASURE */
	public static final String QUOM_KS	= 'ks';
	
	/* QUANTITY UNITS OF MEASURE */
	public static final String PROD_SPEC_VYROBEK = 'M-VYROBEK';

	/* PRODUCT SPECIFICATION */
	public static final String PROD_SPEC_CALOUNENI	= '10';
	public static final String PROD_SPEC_VYROBA		= '11';

	/*TEMPORARY RECORD*/
    public static final String RFT_TMP_RECORD_NAME = 'SystemRFT';

	/*CRON EXPRESSION*/
	public static final String CRON_EXPRESSION = '0 0 1 ? * *';
	
	/* GOOGLE DRIVE */
	public static final String[] OPP_SUBFOLDER_NAMES_LIST = new String[]{
		'01 Archiv',
		'02 Podklady',
		'03 Nabidky Subdodavatel',
		'04 Objednavka Smlouva Specifikace',
		'05 Predavaci protokol',
		'06 Foto realizace',
		'07 Schvalena dokumentace'
	};

	/* PRODUCT TRANSPORT */
	public static final String TRANSPORT_ID = '01t3Y00000FaajoQAB';

	/* PRODUCT TYPE */
	public static final String PROD_TYPE_PRODUCT = 'V-VYROBEK';

	/* PRODUCT BATCH CLASSES NAMES */
	public static final String[] PROD_BATCH_NAMES_LIST = new String[]{
		'ProductBulkUpdateBatch',
		'ProductBulkGenerateBatch'
	};

	/* ASYNC JOB SATUSES */
	public static final String[] ASYNC_JOB_FINISHED_STATUSES_LIST = new String[]{
		'Aborted',
		'Completed',
		'Failed'
	};

	/* QLI VISIBLE IN PDF DATE */
	// Date of deploy IsShowInQuotePDF__c
	// IsShowInQuotePDF__c default value was set to true but default value on old records was false
	public static final Datetime VISIBLE_IN_PDF_DATE = Datetime.newInstance(2022, 3, 23, 23, 59, 0);
}