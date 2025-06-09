public class InsertreatilerOrder {
 @AuraEnabled
    public static boolean CreateOrder(List<Map<String, Object>> productsList, String recordId,String visitId,String distributorId) {
       // Boolean isAdmin = [SELECT Profile.Name FROM User WHERE Id = :recordId LIMIT 1].Profile.Name == 'Sales Representative';
        Decimal bundleQuantity;
        List<OrderItem> orderItems = new List<OrderItem>(); 
        try {
            
            List<Account> accounts;
            String accountId;
            String Accountname;
            Id retailerAccountId;
          
               
              List<Visit> visit=[Select Id, AccountId,Account.Name,Account.Distributor__c From Visit Where Id=:visitId];
                if(!visit.isEmpty()){
                   retailerAccountId=visit[0].AccountId;
                    Accountname=visit[0].Account.Name;
                	distributorId=visit[0].Account.Distributor__c !=null ?visit[0].Account.Distributor__c:null;
                }
             if(distributorId ==null){
                     throw new CustomException('No Distributor selected for the Order');
                }
                  List<Account> account=[Select Id, Name From Account Where Id=:distributorId];
                if(!account.isEmpty()){
                   accountId=account[0].Id;
                    Accountname=account[0].Name;
                }
            
            Pricebook2 standardPricebook = [
        SELECT Id
        FROM Pricebook2
        WHERE IsStandard = TRUE
        LIMIT 1
      ];
    String selectedPricebookId = standardPricebook.Id;

            

            Set<String> cartIds = new Set<String>();
            Map<String, Order> ordersToInsert = new Map<String, Order>();
            
            if (productsList != null && !productsList.isEmpty()) {
                Map<String, String> detailsofProducts = new Map<String, String>();
                List<PricebookEntry> pricebookEntries = [SELECT Id, Product2Id, UnitPrice, Pricebook2Id FROM PricebookEntry WHERE Pricebook2Id = :selectedPricebookId];
                for (PricebookEntry p : pricebookEntries) {
                    if (p.Product2Id != null) {
                        detailsofProducts.put(p.Product2Id, p.Id);
                    }
                }
				Order newOrder = new Order(
                        AccountId = retailerAccountId !=null?retailerAccountId:null,
                        Status = 'Draft',
                        Name = Accountname,
                        Pricebook2Id = selectedPricebookId,
                        EffectiveDate = System.today(),          
                        Retailer_Account__c=accountId,
                    	isASMorder__c=true,
                        Visit__c =visitId
                    );
                    insert newOrder;
             
                for (Map<String, Object> product : productsList) {
                    String cartId = (String) product.get('cartId');
                    cartIds.add(cartId);
                    String productId = (Id) product.get('id');
                    String typeofProduct = (String) product.get('type') != null ? (String) product.get('type') : null;
                    Decimal quantity = (Decimal) product.get('quantity');
                    bundleQuantity = quantity;

                    
                    
                    List<Object> sizeMap = (List<Object>) product.get('sizes');
                    if (!sizeMap.isEmpty()) {
                        for (Object size : sizeMap) {
                            Map<Object, Object> sizeValueObj = (Map<Object, Object>) size;
                            String productVariantId = (String) sizeValueObj.get('Product_varient__c');
                            String pricebookEntryForSize = detailsofProducts.get(productVariantId);
                            String vsize = (String) sizeValueObj.get('Size__c') != null ? (String) sizeValueObj.get('Size__c') : '';
                            String vcolor = (String) sizeValueObj.get('Color__c') != null ? (String) sizeValueObj.get('Color__c') : '';
                            Decimal vquantity = (Decimal) sizeValueObj.get('Quantity__c') != null ? (Decimal) sizeValueObj.get('Quantity__c') : 0;

                            if (pricebookEntryForSize != null) {
                                OrderItem orderItem = new OrderItem(
                                    OrderId = newOrder.Id, 
                                    PricebookEntryId = pricebookEntryForSize,
                                    Quantity = vquantity,
                                    Product2Id = productVariantId,
                                    UnitPrice = typeofProduct == 'Catalogue'?(Decimal) product.get('price')*(decimal)product.get('noofpieces'):(Decimal) product.get('price'),
                                    Description = vsize + ': ' + vquantity + ' : ' + vcolor,
                                    Colors__c = vcolor,
                                    Product_Type__c = typeofProduct,
                                    Bundle_Quantity__c = (typeofProduct == 'Catalogue' ? bundleQuantity : 0)
                                );

                                orderItems.add(orderItem);
                            }
                        }
                    }

                    if (typeofProduct == 'Catalogue') {
                        newOrder.Bundle_Quantity__c = bundleQuantity;
                    } else {
                        newOrder.Bundle_Quantity__c = 0; 
                    }

                    ordersToInsert.put(newOrder.Id, newOrder);
                }

                if (!orderItems.isEmpty()) {
                    insert orderItems;
                    System.debug('Inserted OrderItems: ' + orderItems.size());
                }
                List<Cart__c> cartsToDelete; 
           
                   cartsToDelete = [SELECT Id, Account__c FROM Cart__c WHERE Id IN :cartIds AND Account__c = :retailerAccountId];
                
                if (!cartsToDelete.isEmpty()) {
                    delete cartsToDelete;
                    System.debug('Deleted Carts: ' + cartsToDelete.size());
                }

                return false;
            } else {
                System.debug('No products received in the productsList.');
                return null;
            }
        } catch (Exception ex) {
            System.debug('Error occurred: ' + ex.getMessage());
            throw new AuraHandledException('Error creating order: ' + ex.getMessage());
        }
    }
    public class CustomException extends Exception {}
}