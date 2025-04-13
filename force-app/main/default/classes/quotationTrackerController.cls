public with sharing class quotationTrackerController {

    @AuraEnabled(cacheable=true)
    public static List<QuoteWrapper> fetchAllQuotes(String startDate, String endDate, String productFilter) {

        // Check if the current user is an admin
        Boolean isAdmin = [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1].Profile.Name == 'System Administrator';

        System.debug('isAdmin: ' +  isAdmin);
        String userAccountId = null;

        // If the user is not an admin, get the AccountId associated with the logged-in user
        if (!isAdmin) {
            userAccountId = [SELECT AccountId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1].AccountId;
            System.debug('portaluserAccountID: ' +  userAccountId);
        }

        // Convert the received start and end date strings into Date objects
        Date startDateConverted = Date.valueOf(startDate);
        Date endDateConverted = Date.valueOf(endDate);

        // Log the received dates
        System.debug('Start Date: ' + startDateConverted);
        System.debug('End Date: ' + endDateConverted);

        // Adjust endDate to include the full day (23:59:59.999) of the end date
        DateTime startDateTime = DateTime.newInstance(startDateConverted, Time.newInstance(0, 0, 0, 0));
        DateTime endDateTime = DateTime.newInstance(endDateConverted, Time.newInstance(23, 59, 59, 999));

        System.debug('startDateTime: ' + startDateTime);
        System.debug('endDateTime: ' + endDateTime);

        // Initialize the list of QuoteWrapper to store results
        List<QuoteWrapper> quotesList = new List<QuoteWrapper>();

        // Build the base query
        String query = 'SELECT Id, Name, Status, CreatedDate, QuoteAccountId, ' +
                '(SELECT Id, Product2.Name, Product_Type__c, Quantity FROM QuoteLineItems) ' +
                'FROM Quote WHERE CreatedDate >= :startDateTime AND CreatedDate <= :endDateTime ' +
                'AND Status IN (\'Draft\', \'SalesOrder\', \'Invoice\')';

        // If the user is not an admin and has an associated AccountId
        if (!isAdmin && userAccountId != null) {
            query += ' AND QuoteAccountId = :userAccountId';
        } else {
            query += ' AND QuoteAccountId != null';
        }

        // Modify query based on the selected product filter
        if (productFilter == 'Blank') {
            // Include only Quotes where QuoteLineItems have Product_Type__c = 'Blank'
            query += ' AND Id IN (SELECT QuoteId FROM QuoteLineItem WHERE Product_Type__c = \'Blank\' AND Product_Type__c != null)';
            System.debug('Blank Filter: ' + query);
        }  if (productFilter == 'Catalogue') {
            // Include only Quotes where QuoteLineItems have Product_Type__c = 'Catalogue'
            query += ' AND Id IN (SELECT QuoteId FROM QuoteLineItem WHERE Product_Type__c = \'Catalogue\' AND Product_Type__c != null)';
            System.debug('Catalogue Filter: ' + query);
        }if (productFilter == 'AllProducts') {
            // Include only Quotes where QuoteLineItems have Product_Type__c = 'Catalogue'
            query += ' AND Id IN (SELECT QuoteId FROM QuoteLineItem WHERE Product_Type__c = \'Catalogue\' OR Product_Type__c = \'Blank\' )';
            System.debug('Catalogue Filter: ' + query);
        }

        query += ' ORDER BY CreatedDate DESC';

        // Log the final query for debugging
        System.debug('Final Query: ' + query);

        // Execute the query
        List<Quote> quotes = Database.query(query);

        // Log the fetched quotes
        System.debug('Fetched Quotes: ' + quotes);

        // Loop through the fetched quotes and populate the wrapper list
        for (Quote q : quotes) {
            QuoteWrapper qw = new QuoteWrapper();
            qw.quoteId = q.Id;
            qw.quoteName = q.Name;
            qw.status = q.Status;
            qw.createdDate = q.CreatedDate;
            qw.quoteLineItems = new List<QuoteLineItemWrapper>();

            // Loop through QuoteLineItems and populate the items
            for (QuoteLineItem lineItem : q.QuoteLineItems) {
                // Only include the productType if the filter is applied
                // if ((productFilter == 'All Products' ||(productFilter == 'Blank' && lineItem.Product_Type__c == 'Blank') || 
                //     (productFilter == 'Catalogue' && lineItem.Product_Type__c == 'Catalogue'))) {
                    qw.quoteLineItems.add(new QuoteLineItemWrapper(
                        lineItem.Product2.Name, 
                        (Integer)lineItem.Quantity,
                        lineItem.Product_Type__c
                    ));
                // }
            }

            // Add the populated QuoteWrapper to the list
            quotesList.add(qw);
        }

        // Return the list of QuoteWrapper objects
        System.debug('final quotelist returning'+quotesList);
        return quotesList;
    }

    // Wrapper class for the Quote object
    public class QuoteWrapper {
        @AuraEnabled public String quoteId;
        @AuraEnabled public String quoteName;
        @AuraEnabled public String status;
        @AuraEnabled public Datetime createdDate;
        @AuraEnabled public List<QuoteLineItemWrapper> quoteLineItems;
    }

    // Wrapper class for the QuoteLineItem object
    public class QuoteLineItemWrapper {
        @AuraEnabled public String itemName;
        @AuraEnabled public Integer quantity;
        @AuraEnabled public String productType;

        public QuoteLineItemWrapper(String name, Integer qty, String productType) {
            this.itemName = name;
            this.quantity = qty;
            this.productType = productType;
        }
    }
}