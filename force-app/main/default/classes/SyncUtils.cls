public without sharing class SyncUtils {
  public class SyncUtilException extends Exception {
  }

  public static final Integer RESPONSE_CODE_ERROR = 400;
  public static void logServiceActivity(
    String svcName,
    String status,
    Decimal respCode,
    String msg
  ) {
    logServiceActivity(svcName, status, respCode, msg, null, null);
  }

  public static void logServiceActivity(
    String svcName,
    String status,
    Decimal respCode,
    String msg,
    String stackTrace
  ) {
    logServiceActivity(svcName, status, respCode, msg, stackTrace, null);
  }

  public static void logServiceActivity(
    String svcName,
    String status,
    Decimal respCode,
    String msg,
    String stackTrace,
    String req
  ) {
    logServiceActivity(svcName, status, respCode, msg, stackTrace, req, null);
  }

  public static void logServiceActivity(
    String svcName,
    String status,
    Decimal respCode,
    String msg,
    String stackTrace,
    String req,
    String resp
  ) {
    SyncServiceSettings__c stt = SyncServiceSettings__c.getValues(svcName);
    ServiceLog__c sl = new ServiceLog__c();
    sl.Message__c = Hlp.getStringWithLength(msg, 1000);
    sl.ResponseCode__c = respCode;
    sl.Response__c = Hlp.getStringWithLength(resp, 120000);
    sl.ServiceName__c = svcName;
    sl.ServiceStatus__c = status;
    sl.StackTrace__c = Hlp.getStringWithLength(stackTrace, 120000);
    if (stt != null && stt.IsLogRequest__c) {
      sl.Request__c = Hlp.getStringWithLength(req, 120000);
    }
    insert sl;
    // Remove logs older than 30 days
    ServiceLog__c[] slsToDel = [
      SELECT Id
      FROM ServiceLog__c
      WHERE
        ServiceName__c = :svcName
        AND CreatedDate < :Datetime.now().addDays(-30)
    ];
    delete slsToDel;
  }

  public static Id getIdValueFromJSONValue(String idStr) {
    return idStr = (String.isEmpty(idStr)) ? null : (Id) idStr; // Id cannot be empty string, must be null or valid SF Id
  }

  private static Map<String, Id> userMapBySAPId = new Map<String, Id>();
  private static void fillUsersMap() {
    User[] usrList = [SELECT Id, SAPId__c FROM User WHERE IsActive = TRUE];
    for (User u : usrList) {
      userMapBySAPId.put(u.SAPId__c, u.Id);
    }
  }
  public static Id setSFUserId(String nOwnerSAPId, String oOwnerSAPId) {
    if (userMapBySAPId.isEmpty()) {
      fillUsersMap();
    }
    System.debug(nOwnerSAPId + ' ' + oOwnerSAPId);
    String usrId = (nOwnerSAPId != null &&
      nOwnerSAPId != oOwnerSAPId)
      ? userMapBySAPId.get(nOwnerSAPId)
      : userMapBySAPId.get(oOwnerSAPId); // Compare old and new Owner
    System.debug(usrId);
    usrId = (usrId != null) ? usrId : '0051t000003AtoJAAS'; // If ID not available - set default (SU)
    System.debug(usrId);
    return usrId;
  }

  public static String getValidJsonForCustomModel(String jstr) {
    if (String.isEmpty(jstr)) {
      jstr = '';
    } // prevent null exception
    return jstr.remove('__c').remove('__r');
  }

  /*===================================================================================================*/
  /* FIELD MAPPING - FIELD MAPPING - FIELD MAPPING - FIELD MAPPING - FIELD MAPPING - FIELD MAPPING - F */
  /*===================================================================================================*/

  // PRODUCT & BOM
  // -----------------------------------------------------------
  public static Product2 mapProductFields(Mdl.SfProduct sfp) {
    Product2 p = new Product2();
    p.Description = sfp.Description;
    p.Id = null; // Always set to null due to correct upsertion - SAP ID is master pairing key
    p.IsActive = !sfp.IsActive; // Inverted value - in SAP it's "FrozenFor"
    p.Name = (String.isNotEmpty(sfp.Name))
      ? sfp.Name
      : 'MISSING PRODUCT NAME (ID: ' + sfp.SAPId + ')'; // Prevent stacking queue from SAP if Name is not set
    p.ProductCode = sfp.ProductCode;
    p.SAPId__c = sfp.SAPId;
    p.Type__c = sfp.Type;

    // Set only if defined in request
    if (!String.isBlank(sfp.Family)) {
      p.Family = sfp.Family;
    }

    if (String.isNotEmpty(sfp.Specification)) {
      p.Specification__c = itemAttributesToProductSpecification(
        sfp.Specification
      );
    }

    if (sfp.UnitCost != null && sfp.Type != Cst.PROD_TYPE_PRODUCT) {
      p.UnitCost__c = sfp.UnitCost;
    }
    if (String.isNotEmpty(sfp.QuantityUnitOfMeasure)) {
      p.QuantityUnitOfMeasure = sfp.QuantityUnitOfMeasure;
    }
    return p;
  }

  public static String productSpecificationToItemAttributes(String specStr) {
    Integer ARR_LENGTH = 64; // string value in the result must always have 64 "boolean" values
    Set<String> specVals = new Set<String>(
      (String.isNotEmpty(specStr)) ? specStr.split(';') : new List<String>{}
    );
    String[] vals = new List<String>{};

    for (Integer i = 0; i < ARR_LENGTH; i++) {
      String pickVal = String.valueOf(i + 1);
      if (specVals.contains(pickVal)) {
        vals.add('Y');
      } else {
        vals.add('N');
      }
    }
    return String.join(vals, ', ');
  }

  public static String itemAttributesToProductSpecification(String attStr) {
    String[] specArr = (String.isNotEmpty(attStr))
      ? attStr.split(',')
      : new List<String>{};
    Integer[] vals = new List<Integer>{};

    for (Integer i = 0; i < specArr.size(); i++) {
      if (specArr[i].trim() == 'Y') {
        vals.add(i + 1);
      }
    }
    return String.join(vals, ';');
  }

  public static Boolean isPDFVisible(String productSpecification) {
    String[] invalidSpec = new List<String>{
      '4',
      '5',
      '10',
      '11',
      '16',
      '17',
      '18'
    };
    return (!invalidSpec.contains(productSpecification));
  }

  public static BOM__c mapBomFields(Mdl.SfBom sfb) {
    BOM__c b = new BOM__c();
    b.BundleId__c = sfb.BundleId;
    b.BundleSAPId__c = sfb.BundleSAPId;
    b.BundleItemId__c = sfb.BundleItemId;
    b.BundleItemSAPId__c = sfb.BundleItemSAPId;
    b.Id = sfb.Id;
    b.Quantity__c = sfb.Quantity;
    b.QuantityUnitOfMeasure__c = sfb.QuantityUnitOfMeasure;
    b.RowNumber__c = sfb.RowNumber;
    b.Position__c = sfb.Position;
    // Default value will not be set, yet
    //b.IsVisible__c				= true;
    //b.IsEditable__c				= true;
    return b;
  }

  // ORDER & ORDER LINE ITEMS
  // -----------------------------------------------------------
  public static Order__c mapOrderFields(Mdl.SfOrder sfo) {
    Order__c o = new Order__c();
    o.AccountId__c = sfo.AccountId;
    o.BillingAddressTxt__c = sfo.BillingAddressTxt;
    o.CurrencyIsoCode = sfo.CurrencyIsoCode;
    o.DueDate__c = sfo.DueDate;
    o.DeliveryDate__c = sfo.DeliveryDate;
    o.Description__c = sfo.Description;
    o.Id = sfo.Id;
    o.Name = sfo.Name;
    o.OwnerSAPId__c = sfo.OwnerSAPId;
    o.PrimaryContactId__c = (String.isEmpty(sfo.PrimaryContactId))
      ? null
      : sfo.PrimaryContactId;
    o.SAPOrderStatus__c = sfo.SAPOrderStatus;
    o.ShippingAddressTxt__c = sfo.ShippingAddressTxt;
    o.SyncStatus__c = sfo.SyncStatus;
    return o;
  }

  public static OrderLineItem__c mapOLIFields(Mdl.SfOrderLineItem sfOli) {
    OrderLineItem__c oli = new OrderLineItem__c();
    oli.Description__c = sfOli.Description;
    oli.Discount__c = sfOli.Discount;
    oli.Id = (String.isEmpty(sfOli.Id)) ? null : sfOli.Id;
    oli.LineNum__c = sfOli.LineNum;
    oli.ListPrice__c = sfOli.ListPrice;
    oli.Name = sfOli.Name;
    oli.OrderId__c = (String.isEmpty(sfOli.OrderId)) ? null : sfOli.OrderId;
    oli.ProductId__c = sfOli.ProductId;
    oli.Quantity__c = sfOli.Quantity;
    oli.Subtotal__c = sfOli.Subtotal;
    oli.TotalPrice__c = sfOli.TotalPrice;
    oli.UnitPrice__c = sfOli.UnitPrice;
    return oli;
  }

  /**
   * @description TODO:
   * FOR NOW COMMENTED OUT - NOT USED
   * -------------------------------------------------------------------------
   * public static void validateAccess(String svcName){
   * SyncServiceSettings__c stt = SyncServiceSettings__c.getValues(svcName);
   * //Check if OAuth2 enabled and token near expiration or not set
   * if(stt.ExpirationTime__c == null || stt.ExpirationTime__c.addMinutes(2) < Datetime.now()){
   *
   * // Create HTTP Request - get access token
   * Http http = new Http();
   * HttpRequest req = new HttpRequest();
   * String accToken;
   * Integer expires = 0;
   * String tokenType;
   *
   * String body = 'some body';
   *
   * req.setEndpoint('SAP ACCOUNT ENDPOINT');
   * req.setMethod('POST');
   * req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
   * req.setHeader('Host', 'IP ADDRESS');
   * req.setBody(body);
   * req.setTimeout(120000);
   *
   * System.debug('HTTP request ' + req);
   * HttpResponse httpRes;
   *
   * if(!Test.isRunningTest()){
   * // Send request
   * httpRes = http.send(req);
   * }
   * System.debug('HTTP Response: Access Token ' + httpRes);
   * System.debug('HTTP Response: Access Token Body ' + httpRes.getBody());
   *
   *
   * if(httpRes.getStatusCode() == 200){
   * // Parse HTTP Response
   * JSONParser parser = JSON.createParser(httpRes.getBody());
   * while(parser.nextToken() != null){
   * if(parser.getCurrentToken() == JSONToken.FIELD_NAME){
   * String fieldName = parser.getText();
   * parser.nextToken();
   * if(fieldName == 'access_token'){
   * accToken = parser.getText();
   * System.debug('Access Token ' + accToken);
   * }else if(fieldName == 'expires_in'){
   * expires = parser.getIntegerValue();
   * }else if(fieldName == 'token_type'){
   * tokenType = parser.getText();
   * }
   * }
   * }
   *
   * // Set new value to custom settings
   * Datetime currentDT = Datetime.now();
   * stt.ExpirationTime__c = currentDT.addSeconds(expires);
   * stt.Token__c = accToken;
   * update stt;
   * }else{
   * throw new SyncUtilException('Access Token was not ');
   * }
   * }
   * }
   *
   * @param svcName
   * @param dataStr
   *
   * @return
   */

  public static HttpResponse sendData(String svcName, String dataStr) {
    SyncServiceSettings__c stt = SyncServiceSettings__c.getValues(svcName);

    Http http = new Http();
    HttpRequest req = new HttpRequest();

    req.setEndpoint('callout:' + stt?.Endpoint__c);
    req.setMethod('POST');
    req.setBody(dataStr);
    req.setTimeOut(120000);

    HttpResponse httpRes;
    try {
      httpRes = http.send(req);
    } catch (Exception e) {
      httpRes = new HttpResponse();
      httpRes.setStatusCode(RESPONSE_CODE_ERROR);
      httpRes.setStatus(e.getMessage());
      httpRes.setBody(e.getStackTraceString());
    }

    return httpRes;
  }
}
