public without sharing class Mdl  {
/*===========================================================================================*/
/* GOOGLE DRIVE - GOOGLE DRIVE - GOOGLE DRIVE - GOOGLE DRIVE - GOOGLE DRIVE - GOOGLE DRIVE - */
/*===========================================================================================*/
	public virtual class BaseResponse{
		public boolean isSuccess {get;set;}
		public string msg {get;set;}

		public BaseResponse(){
			this.isSuccess = false;
		}
	}

	public class DriveTokenRefreshResponse extends BaseResponse{
		public string authTkn {get;set;}
		public Datetime validTo {get;set;}
	}

	public class DriveOAuthResponse{
		public string access_token	{get;set;}
		public integer expires_in	{get;set;}
		public string refresh_token	{get;set;}
		public string scope			{get;set;}
		public string token_type	{get;set;}
	}

	public class DriveCreateFolderResponse{
		public string kind {get;set;}
		public string id {get;set;}
		public string name {get;set;}
		public string mimeType {get;set;}
	}

	public class CreateFolderResult extends BaseResponse{
		public string folderID {get;set;}
	}

	public class CreateFolderStructureResult extends BaseResponse{
		public string parentFolderId{get;set;}
		public DriveFolderInfo structure{get;set;}
	}

	public class DriveFolderInfo{
		public string folderName{get;set;}
		public string folderId{get;set;}
		public DriveFolderInfo[] subfolders{get;set;}

		public DriveFolderInfo(){
			this.subfolders = new DriveFolderInfo[]{};
		}
	}

/*===========================================================================================*/
/* GOOGLE CALENDAR - GOOGLE CALENDAR - GOOGLE CALENDAR - GOOGLE CALENDAR - GOOGLE CALENDAR - */
/*===========================================================================================*/

	public class CreateEventResult extends BaseResponse{
		public String id{get;set;}
	}

	public class CalendarEvents{
		public Item[] items {get;set;}
	}

	public class Item{
		public String id{get;set;}
		public DtWrapper x_start{get;set;}
		public DtWrapper x_end{get;set;}
	}

	public class DtWrapper{
		public Date x_date {get;set;}
		public Datetime x_dateTime{get;set;}
	} 

/*===================================================================================================*/
/* SYNC MODELS - SYNC MODELS - SYNC MODELS - SYNC MODELS - SYNC MODELS - SYNC MODELS - SYNC MODELS - */
/*===================================================================================================*/
	
	// SAP RESPONSE
	// -----------------------------------------------------------
	public class SAPResponse{
		public String Id	{get;set;}
		public String SAPId {get;set;}
	}

	// PRODUCT & BOM
	// -----------------------------------------------------------
	public class SfProduct{
		public String Description 			{get;set;}
		public String Family 				{get;set;}
		public String Id 					{get;set;}
		public Boolean IsActive				{get;set;}
		public String Name 					{get;set;}
		public String ProductCode 			{get;set;}
		public String QuantityUnitOfMeasure {get;set;}
		public String Type	 				{get;set;}
		public Double UnitCost	 			{get;set;}
		public Double UnitPriceCZK	 		{get;set;}
		public Double UnitPriceUSD	 		{get;set;}
		public Double UnitPriceEUR	 		{get;set;}
		public String SAPId	 				{get;set;}
		public String Specification			{get;set;} // Composed from 64 Y/N (default N) values joined to one string with ', ' separator
		public Mdl.SfProductSubItems BOMs {get;set;}
		public SfProduct(){
			this.BOMs = new Mdl.SfProductSubItems();
		}
	}

	public class SfProductSubItems{
		public Boolean		Done	{get;set;}
		public Mdl.SfBom[]	Records	{get;set;}
		public SfProductSubItems(){
			this.Records = new Mdl.SfBom[]{};
		}
	}
	
	public class SfBom{
		public String BundleId	 			{get;set;}
		public String BundleSAPId	 		{get;set;}
		public String BundleItemId	 		{get;set;}
		public String BundleItemSAPId		{get;set;}
		public String Id 					{get;set;}
		public Double Quantity	 			{get;set;}
		public String QuantityUnitOfMeasure	{get;set;}
		public Integer RowNumber	 		{get;set;}
		public String Type	 				{get;set;}
		public String Position 				{get;set;}
	}
	
	// ORDER & ORDER LINE ITEMS
	// -----------------------------------------------------------
	public class SfOrder{
		public String AccountId 			{get;set;}
		public String AccountSAPId	 		{get;set;}
		public String BillingAddressTxt 	{get;set;}
		public String CurrencyIsoCode 		{get;set;}
		public Date	  DueDate	 			{get;set;}
		public Date	  DeliveryDate	 		{get;set;}
		public String Description	 		{get;set;}
		public String Id 					{get;set;}
		public String Name 					{get;set;}
		public String OpportunityNo			{get;set;}
		public String OwnerId		 		{get;set;}
		public String OwnerSAPId	 		{get;set;}
		public String PrimaryContactId	 	{get;set;}
		public String RefNo				 	{get;set;}
		public String SAPOrderStatus	 	{get;set;}
		public String ShippingAddressTxt	{get;set;}
		public String SyncStatus	 		{get;set;}
		public Map<String,Mdl.SfOrderLineItem[]> OrderLineItems {get;set;}
		public SfOrder(){
			this.OrderLineItems = new Map<String,Mdl.SfOrderLineItem[]>();
		}
	}

	public class SfOrderLineItem{
		public String Description	{get;set;}
		public Decimal Discount		{get;set;}
		public String Id			{get;set;}
		public Boolean IsDefault	{get;set;}
		public Integer LineNum		{get;set;}
		public Double ListPrice		{get;set;}
		public String Name			{get;set;}
		public String OrderId		{get;set;}
		public String ProductSAPId	{get;set;}
		public String ProductId		{get;set;}
		public Double Quantity		{get;set;}
		public Double Subtotal		{get;set;}
		public Double TotalPrice	{get;set;}
		public Double UnitPrice		{get;set;}
		public String Type			{get;set;}
		public Map<String,SfOrderLineSubItem[]> OrderLineSubItems {get;set;}
		public SfOrderLineItem(){
			this.OrderLineSubItems = new Map<String,SfOrderLineSubItem[]>();
		}
	}

	public class SfOrderLineSubItem{
		public String Description 		{get;set;}
		public Id Id 					{get;set;}
		public String Name 				{get;set;}
		public String Product2Id 		{get;set;}
		public String ProductSAPId		{get;set;}
		public String ProductName 		{get;set;}
		public Decimal Quantity 		{get;set;}
		public String QuoteLineItemId	{get;set;}
		public String Position			{get;set;}
	}

/*===========================================================================================*/
/* CREATE OPP COMPONENT - CREATE OPP COMPONENT - CREATE OPP COMPONENT - CREATE OPP COMPONENT */
/*===========================================================================================*/
	public class QA_InitResponseMdl{
		@AuraEnabled public Mdl.PickVal[] stagePickVals		{get;set;}
		@AuraEnabled public Mdl.PickVal[] currencyCodes		{get;set;}
		@AuraEnabled public Mdl.PickVal[] countryPickVals	{get;set;}
		@AuraEnabled public String accountCurrency			{get;set;}
		@AuraEnabled public Boolean isSuccess				{get;set;}
		@AuraEnabled public String msg						{get;set;}
		public QA_InitResponseMdl(){
			this.isSuccess = false;
		}
	}

	public class QA_GetDuplicatesResult{
		@AuraEnabled public Opportunity[] duplicateOpps		{get;set;}
		@AuraEnabled public Boolean isSuccess				{get;set;}
		@AuraEnabled public Boolean isOppCreated			{get;set;}
		@AuraEnabled public Id newOppId						{get;set;}
		@AuraEnabled public String msg						{get;set;}
		public QA_GetDuplicatesResult(){
			this.isSuccess = false;
		}
	}
	
	public class QA_CreateOppResult{
		@AuraEnabled public Boolean isSuccess				{get;set;}
		@AuraEnabled public String msg						{get;set;}
		@AuraEnabled public Id newOppId						{get;set;}
		public QA_CreateOppResult(){
			this.isSuccess = false;
		}
	}

/*===========================================================================================*/
/* PICKLIST - PICKLIST - PICKLIST - PICKLIST - PICKLIST - PICKLIST - PICKLIST - PICKLIST - P */
/*===========================================================================================*/	

	public class PickVal {
    	@AuraEnabled public String value {get;set;}
    	@AuraEnabled public String label {get;set;}
    	public PickVal(String value, String label) {
    	    this.value = value;
    	    this.label = label;
    	}
    }

/*===================================================================================================*/
/* RELATED PICKLISTS - RELATED PICKLISTS - RELATED PICKLISTS - RELATED PICKLISTS - RELATED PICKLISTS */
/*===================================================================================================*/
	public class PicklistEntryWrapper{
        public String active        {get; set;}
        public String defaultValue  {get; set;}
        public String label         {get; set;}
        public String value         {get; set;}
        public String validFor      {get; set;}
    }

    public class DependentPicklist{
        public String               value         {get;set;}
        public String               label         {get;set;}
        public DependentPicklist[]  relatedValues {get;set;}

        public DependentPicklist(){
            relatedValues = new DependentPicklist[]{};
        }
    }

// ---------------------------------------------------------------------------------------------------------------------
// QUOTE MODELS - QUOTE MODELS - QUOTE MODELS - QUOTE MODELS - QUOTE MODELS - QUOTE MODELS - QUOTE MODELS - QUOTE MODELS
// ---------------------------------------------------------------------------------------------------------------------   

	public class QuoteLineItemMdl{
        public Id Id							{get;set;}
        public Id Product2Id					{get;set;}
        public String ProductBusName			{get;set;}
        public String ProductName				{get;set;}
        public String ProductType				{get;set;}
        public String ProductFamily				{get;set;}
        public String ProductSpecification		{get;set;}
		public String ProductDescriptionCZ		{get;set;}
		public String ProductDescriptionEN		{get;set;}
        public String Description				{get;set;}
		public String Quantity					{get;set;}
		public String ListPrice					{get;set;}
		public String UnitPrice					{get;set;}
		public String TotalPrice				{get;set;}
		public String RowDiscount				{get;set;}
		public String RowTotalPrice				{get;set;}
		public String DiscountUnitPrice			{get;set;}
		public String RelatedOptional			{get;set;}
		public QLIDescription__c[] qliDescs		{get;set;}
		public QuoteLineSubItem__c[] qlsis		{get;set;}
		public Boolean isDelimiter				{get;set;}
		public Boolean showDelimiter			{get;set;}
		public Boolean showProduct				{get;set;}
		public String subtotal					{get;set;}
		
		public QuoteLineItemMdl(){
			qliDescs = new QLIDescription__c[]{};
			qlsis = new QuoteLineSubItem__c[]{};
			isDelimiter = false;
			showDelimiter = false;
		}
	}

	public class SpecificationMdl{
		public QuoteLineItem qli			{get;set;}
		public QuoteLineSubItem__c[] qlsis	{get;set;}
		public QuoteLineItem[] optQlis		{get;set;}
		public String productCount			{get;set;}
		public SpecificationMdl(){
			qlsis = new QuoteLineSubItem__c[]{};
			optQlis = new QuoteLineItem[]{};
		}
	}

// ---------------------------------------------------------------------------------------------------------------------
// RFT MODEL - RFT MODEL - RFT MODEL - RFT MODEL - RFT MODEL - RFT MODEL - RFT MODEL - RFT MODEL - RFT MODEL - RFT MODEL
// ---------------------------------------------------------------------------------------------------------------------   

	public class RFTMdl{
		public Product2 prod							{get; set;}
		public BOM__c[] boms							{get; set;}
		public ProductDescription__c[] prodDescs		{get; set;}
		public Mdl.ProductAttachmentsModel[] pAttchMdl	{get; set;}
		public RFTMdl(){
			boms = new BOM__c[]{};
			prodDescs = new ProductDescription__c[]{};
			pAttchMdl = new Mdl.ProductAttachmentsModel[]{};
		}
	}

	public class RFTMdlList{
		public String id {get;set;}
		public String name {get;set;}
	}

	public class RFTInitMdl{
		public Mdl.PickVal[] typePickVals		{get;set;}
		public Mdl.PickVal[] specPickVals		{get;set;}
		public Mdl.PickVal[] qomPickVals		{get;set;}
		public Mdl.PickVal[] currncyPickVals	{get;set;}
		public Mdl.PickVal[] prodFamilies		{get;set;}
		public String tmpRecordId				{get;set;}
		public String guid						{get;set;}

		public RFTInitMdl(){
			typePickVals = new Mdl.PickVal[]{};
			specPickVals = new Mdl.PickVal[]{};
			qomPickVals = new Mdl.PickVal[]{};
			currncyPickVals = new Mdl.PickVal[]{};
			prodFamilies = new Mdl.PickVal[]{};
		}
	}

	 // Product Attachments model
    // ----------------------------------------------------------
    public class ProductAttachmentsModel{
        public String   id          {get; set;}
        public String   shortname   {get; set;}
        public String   fullname    {get; set;}
        public String   suffix      {get; set;}
        public Boolean  isAttached  {get; set;}
        public String   sendName    {get; set;}
        public String   sortOrder   {get; set;}
        public String   attachLink  {get; set;}
        public String   name        {get; set;}
    }

	// ---------------------------------------------------------------------------------------------------------------------
	// QM MODEL - QM MODEL - QM MODEL - QM MODEL - QM MODEL - QM MODEL - QM MODEL - QM MODEL - QM MODEL - QM MODEL - QM MODEL
	// ---------------------------------------------------------------------------------------------------------------------   

	public class QuoteManagerMdl {
		@AuraEnabled public Boolean isQuotedPrinted			{get;set;}
		@AuraEnabled public Quote qt						{get;set;}
		@AuraEnabled public QuoteLineMdl[] qlis				{get;set;}
		@AuraEnabled public PricebookEntry[] products		{get;set;}	
		@AuraEnabled public Mdl.PickVal[] specPicklist		{get;set;}
		@AuraEnabled public QuoteLineItem	qliTransport	{get;set;}
		@AuraEnabled public Decimal accountDiscount			{get;set;}
		@AuraEnabled public Boolean quoteIsLocked			{get;set;}
		@AuraEnabled public Boolean needAppprove			{get;set;}
		@AuraEnabled public ProjectSalesFee__c[] psfs		{get;set;}
		public QuoteManagerMdl(){
			qlis = new QuoteLineMdl[]{};
			specPicklist = new Mdl.PickVal[]{};
			psfs = new ProjectSalesFee__c[]{};
		}
	}

	public class QuoteLineMdl {
		@AuraEnabled public String qliParentId 					{get;set;}
		@AuraEnabled public QuoteLineItem	qliParent			{get;set;}
		@AuraEnabled public QuoteLineSubItem__c[]	qliChilds	{get;set;}
		@AuraEnabled public QLIDescription__c[]	qliDescriptions	{get;set;}
		// @AuraEnabled public QuoteLineOptionMdl[] qliOptionals  	{get;set;}
		public QuoteLineMdl(){
			qliChilds = new QuoteLineSubItem__c[]{};
			qliDescriptions = new QLIDescription__c[]{};
			// qliOptionals = new QuoteLineOptionMdl[]{};
		}
	}

	// public class QuoteLineOptionMdl {
	// 	@AuraEnabled public QuoteLineItem	qliParent			{get;set;}
	// 	@AuraEnabled public QuoteLineSubItem__c[]	qliChilds	{get;set;}
	// 	@AuraEnabled public QLIDescription__c[]	qliDescriptions	{get;set;}
	// 	public QuoteLineOptionMdl(){
	// 		qliChilds = new QuoteLineSubItem__c[]{};
	// 		qliDescriptions = new QLIDescription__c[]{};
	// 	}
	// }

	public class ProductMdl{
		@AuraEnabled public PricebookEntry				pbeProduct	{get;set;}
		@AuraEnabled public	ProductDescription__c[]		prodDescs	{get;set;}
		@AuraEnabled public BOM__c[]					materials	{get;set;}
		public ProductMdl(){
			prodDescs = new ProductDescription__c[]{};
			materials = new BOM__c[]{};
		}
	}

	public class SaveMdl{
        @AuraEnabled public String 		message 		{ get; set; }
        @AuraEnabled public Boolean		isSuccess		{ get; set; }
        public SaveMdl(){
        	this.isSuccess = false;
        }
    }

	// ---------------------------------------------------------------------------------------------------------------------
	// PRODUCT BULK UPDATE MODEL - PRODUCT BULK UPDATE MODEL - PRODUCT BULK UPDATE MODEL - PRODUCT BULK UPDATE MODEL -PRODUCT
	// ---------------------------------------------------------------------------------------------------------------------   

	public class PBUMdl {
		public Mdl.PickVal[] typePickVals		{get;set;}
		public Mdl.PickVal[] specPickVals		{get;set;}
		public Mdl.PickVal[] prodFamilies		{get;set;}
		public String tmpRecordId				{get;set;}
		public String guid						{get;set;}
		public Boolean isImportEnabled			{get;set;}

		public PBUMdl(){
			typePickVals = new Mdl.PickVal[]{};
			specPickVals = new Mdl.PickVal[]{};
			prodFamilies = new Mdl.PickVal[]{};
			isImportEnabled = false;
		}
	}

	public class PBUSearchMdl{
		public String query 		{get;set;}
		public String shortQuery 	{get;set;}
		public Integer recordCount 	{get;set;}
	}
}