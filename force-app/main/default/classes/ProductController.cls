public class ProductController {  
  @AuraEnabled(Cacheable=true)
  public static List<Product2> getProducts(
    String filterValue,
    String categoryValue,
    Integer limitSize,
    Integer offset,
    Boolean isfuture,
    String catval
  ) {
    Id customRecTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName()
      .get('Product')
      .getRecordTypeId();
      Pricebook2 standardPricebook = [
        SELECT Id
        FROM Pricebook2
        WHERE IsStandard = TRUE
        LIMIT 1
      ];
    String selectedPricebookId = standardPricebook.Id;
    List<Product2> products;

    String query =
      'SELECT Id, Name, Image_url__c,isActive, Video_Url__c, Product_Type__c, cgcloud__Category__c, Boxes__c, Product_Category__c,Number_of_pieces_in_Box__c, RecordTypeId,URL__c,Discount__c,isFutureProduct__c,Next_Available_Date__c, ' +
      '(SELECT Id, Product2Id, UnitPrice, Pricebook2Id FROM PricebookEntries WHERE Pricebook2Id = :selectedPricebookId),(Select Id,Color__c,Variant_ExternalId__c,Size__c,Is_Upcoming_Variant__c,(Select Id,Free_Quantity__c From Inventories__r limit 1) From Products1__r Where isActive=true ORDER BY Size__c ASC)' +
      'FROM Product2 WHERE   RecordTypeId = :customRecTypeId AND isActive=true  AND Product_Template__c=null ';

    if (categoryValue != null) {
      query += ' AND Product_Category__c = :categoryValue';
    }

    if (filterValue != 'ALL' && filterValue != null) {
      query += ' AND cgcloud__Category__c = :filterValue';
    }
    if(catval != null){
      query += ' AND Product_Type__c = :catval';
    }if (isfuture != null) {
      query += ' AND isFutureProduct__c = :isfuture';
    }
   

    query += ' LIMIT :limitSize OFFSET :offset';

    products = Database.query(query);
   System.debug(products);
    return products;
  }

 @AuraEnabled(cacheable=true)
  public static List<Account> getAccountsForLoggedInUser(Id recordId) {
    System.debug('Logged-in User Id: ' + recordId);

    List<User> userList = [SELECT Id, Email FROM User WHERE Id = :recordId];
      
    if (userList.isEmpty()) {
      System.debug('No User found for the provided Id.');
      return new List<Account>();
    }

    User userEmail = userList[0];
    System.debug('userEmail-------->' + userEmail);
    /*User userEmail=[SELECT Id,Email From User Where Id=:recordId];
     System.debug('userEmail-------->'+userEmail);*/

    List<Contact> contacts = [
      SELECT AccountId, Email
      FROM Contact
      WHERE Email = :userEmail.Email
    ];
    System.debug('Contacts: ' + contacts);

    Set<Id> accountIds = new Set<Id>();
    for (Contact contact : contacts) {
      if (contact.AccountId != null) {
        accountIds.add(contact.AccountId);
      }
    }
    System.debug('Associated Account IDs: ' + accountIds);

    List<Account> accounts = [
      SELECT
        Id,
        Name,
        Phone,
        ShippingCity,
        ShippingStreet,
        ShippingCountry,
        ShippingState,
        ShippingPostalCode,
        Customer_Category__c,
        BillingStreet,
        BillingCity,
        BillingState,
        BillingPostalCode,
        BillingCountry,
        cgcloud__Account_Email__c,
        Birthday__c,
        Credit__c,
        Debit__c,
        residual_amount__c,Overdue_Threshold_Limit__c,Total_Invoice_Amount__c,Threshold_days__c,
        (SELECT Id, Name, FirstName, LastName, Email, Phone FROM Contacts),
        (SELECT Id, Status FROM cases WHERE Status != 'Hold')
      FROM Account
      WHERE Id IN :accountIds
    ];
    System.debug('Accounts: ' + accounts);

    return accounts;
  } 
  
  @AuraEnabled(cacheable=true)
  public static List<AccountStatsWrapper> userCounts(Id recordId) {
    System.debug('Logged-in User Id: ' + recordId);

    List<User> userList = [SELECT Id, Email FROM User WHERE Id = :recordId];
    if (userList.isEmpty()) {
      System.debug('No User found for the provided Id.');
      return new List<AccountStatsWrapper>();
    }

    User userEmail = userList[0];
    System.debug('User email: ' + userEmail.Email);

    List<Contact> contacts = [
      SELECT AccountId, Email
      FROM Contact
      WHERE Email = :userEmail.Email
    ];
    System.debug('Contacts: ' + contacts);

    Set<Id> accountIds = new Set<Id>();
    for (Contact contact : contacts) {
      if (contact.AccountId != null) {
        accountIds.add(contact.AccountId);
      }
    }
    System.debug('Associated Account IDs: ' + accountIds);

    List<Case> cases = [
      SELECT AccountId, Status
      FROM Case
      WHERE AccountId IN :accountIds
    ];
    System.debug('Cases: ' + cases);

    List<Lead__c> leads = [
      SELECT Assigned_Distributor__c, Lead_Status__c
      FROM Lead__c
      WHERE Assigned_Distributor__c IN :accountIds
    ];
    System.debug('Leads: ' + leads);

    Map<Id, Integer> totalCases = new Map<Id, Integer>();
    Map<Id, Integer> totalCasesNotOnHold = new Map<Id, Integer>();
    Map<Id, Integer> closedCases = new Map<Id, Integer>();

    String name = 'Salesforce User';
    Integer count = 10;
    Boolean isActive = true;

    for (Case c : cases) {
      Id accountId = c.AccountId;
      if (!totalCases.containsKey(accountId)) {
        totalCases.put(accountId, 0);
        totalCasesNotOnHold.put(accountId, 0);
        closedCases.put(accountId, 0);
      }
      totalCases.put(accountId, totalCases.get(accountId) + 1);
      if (c.Status != 'On Hold') {
        totalCasesNotOnHold.put(
          accountId,
          totalCasesNotOnHold.get(accountId) + 1
        );
      }
      if (c.Status == 'Resolved') {
        closedCases.put(accountId, closedCases.get(accountId) + 1);
      }
    }

    Map<Id, Integer> totalLeads = new Map<Id, Integer>();
    Map<Id, Integer> convertedLeads = new Map<Id, Integer>();
    Map<Id, Integer> unqualifiedLeads = new Map<Id, Integer>();

    for (Lead__c l : leads) {
      Id accountId = l.Assigned_Distributor__c;
      if (!totalLeads.containsKey(accountId)) {
        totalLeads.put(accountId, 0);
        convertedLeads.put(accountId, 0);
        unqualifiedLeads.put(accountId, 0);
      }
      totalLeads.put(accountId, totalLeads.get(accountId) + 1);
      if (l.Lead_Status__c == 'Converted') {
        convertedLeads.put(accountId, convertedLeads.get(accountId) + 1);
      }
      if (l.Lead_Status__c == 'Unqualified') {
        unqualifiedLeads.put(accountId, unqualifiedLeads.get(accountId) + 1);
      }
    }

    Date firstDayCurrentMonth = Date.today().toStartOfMonth();
    Date firstDayLastMonth = Date.today().addMonths(-1).toStartOfMonth();
    Date lastDayLastMonth = firstDayCurrentMonth.addDays(-1);

    List<Order> orders = [
      SELECT AccountId, TotalAmount, EffectiveDate
      FROM Order
      WHERE
        AccountId IN :accountIds
        AND EffectiveDate >= :firstDayLastMonth
        AND EffectiveDate <= :Date.today()
    ];

    Decimal totalSalesCurrentMonth = 0;
    Decimal totalSalesLastMonth = 0;

    for (Order o : orders) {
      if (o.EffectiveDate >= firstDayCurrentMonth) {
        totalSalesCurrentMonth += o.TotalAmount;
      } else if (
        o.EffectiveDate >= firstDayLastMonth &&
        o.EffectiveDate <= lastDayLastMonth
      ) {
        totalSalesLastMonth += o.TotalAmount;
      }
    }

    List<Account> accounts = [
      SELECT
        Id,
        Name,
        Phone,
        ShippingCity,
        ShippingStreet,
        ShippingCountry,
        ShippingState,
        ShippingPostalCode,
        Customer_Category__c,
        BillingStreet,
        BillingCity,
        BillingState,
        BillingPostalCode,
        BillingCountry,
        cgcloud__Account_Email__c,
        Birthday__c,
        Credit__c,
        Debit__c,
        residual_amount__c,
        (SELECT Id, Name, FirstName, LastName, Email, Phone FROM Contacts),
        (SELECT Id, Status FROM Cases WHERE Status != 'Hold')
      FROM Account
      WHERE Id IN :accountIds
    ];
    System.debug('Accounts: ' + accounts);

    List<AccountStatsWrapper> accountStatsWrappers = new List<AccountStatsWrapper>();

    for (Account account : accounts) {
      AccountStatsWrapper wrapper = new AccountStatsWrapper(account);

      wrapper.totalCases = totalCases.get(account.Id) != null
        ? totalCases.get(account.Id)
        : 0;
      wrapper.casesNotOnHold = totalCasesNotOnHold.get(account.Id) != null
        ? totalCasesNotOnHold.get(account.Id)
        : 0;
      wrapper.closedCases = closedCases.get(account.Id) != null
        ? closedCases.get(account.Id)
        : 0;

      wrapper.totalLeads = totalLeads.get(account.Id) != null
        ? totalLeads.get(account.Id)
        : 0;
      wrapper.convertedLeads = convertedLeads.get(account.Id) != null
        ? convertedLeads.get(account.Id)
        : 0;
      wrapper.unqualifiedLeads = unqualifiedLeads.get(account.Id) != null
        ? unqualifiedLeads.get(account.Id)
        : 0;

      wrapper.totalSalesCurrentMonth = totalSalesCurrentMonth;
      wrapper.totalSalesLastMonth = totalSalesLastMonth;

      accountStatsWrappers.add(wrapper);
    }
    System.debug(JSON.serializePretty(accountStatsWrappers));
    return accountStatsWrappers;
  }
    @AuraEnabled(cacheable=true)
    public static List<Assigned_Distributor__c> getAssignedDistributor(String recordId){
        List<Assigned_Distributor__c> assignedDistributor=[SELECT Id,Name,Distributor_Account__c,Distributor_Account__r.Name,User__c  From Assigned_Distributor__c Where User__c =:recordId];
        System.debug(assignedDistributor);
       return assignedDistributor;
    } 
    
   /* @AuraEnabled(cacheable=true)
public static String getUserProductType(Id recordId) {
    User user = [SELECT Id, Select_Product_Type__c FROM User WHERE Id = :recordId LIMIT 1];
    return user.Select_Product_Type__c;
}  */
    public class UserAccountWrapper {
    @AuraEnabled public Boolean isBlank;
    @AuraEnabled public Boolean isCatalogue;
    @AuraEnabled public List<Account> accounts;

    public UserAccountWrapper(Boolean isBlank, Boolean isCatalogue, List<Account> accounts) {
        this.isBlank = isBlank;
        this.isCatalogue = isCatalogue;
        this.accounts = accounts;
    }
}
}