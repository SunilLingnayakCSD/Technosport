public class InsertOrder {
    @AuraEnabled
    public static String CreateOrder(List<Map<String, Object>> productsList, String recordId) {
        Decimal bundleQuantity;
        List<OrderItem> orderItems = new List<OrderItem>(); 
        try {
            System.debug('received Product list' + productsList);
            Id userId = UserInfo.getUserId();
            System.debug('userId' + userId + 'recordId' + recordId);
            List<Account> accounts = ProductController.getAccountsForLoggedInUser(recordId);
            System.debug('Accounts' + accounts);

            if (accounts.isEmpty()) {
                throw new AuraHandledException('No account found for the logged-in user');
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

             
                for (Map<String, Object> product : productsList) {
                    String cartId = (String) product.get('cartId');
                    cartIds.add(cartId);
                    String productId = (Id) product.get('id');
                    String typeofProduct = (String) product.get('type') != null ? (String) product.get('type') : null;
                    Decimal quantity = (Decimal) product.get('quantity');
                    bundleQuantity = quantity;

                    Order newOrder = new Order(
                        AccountId = accounts[0].Id,
                        Status = 'Draft',
                        Name = typeofProduct + '  - ' + accounts[0].Name,
                        Pricebook2Id = selectedPricebookId,
                        EffectiveDate = System.today()
                    );
                    insert newOrder;
                    
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
                                    UnitPrice = (Decimal) product.get('price'),
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

             
                for (Order order : ordersToInsert.values()) {
                    order.Status = 'Activated';
                    update order;
                }

              
                List<Cart__c> cartsToDelete = [SELECT Id, Account__c FROM Cart__c WHERE Id IN :cartIds AND Account__c = :accounts[0].Id];
                if (!cartsToDelete.isEmpty()) {
                    delete cartsToDelete;
                    System.debug('Deleted Carts: ' + cartsToDelete.size());
                }

                return 'Orders created successfully!';
            } else {
                System.debug('No products received in the productsList.');
                return null;
            }
        } catch (Exception ex) {
            System.debug('Error occurred: ' + ex.getMessage());
            throw new AuraHandledException('Error creating order: ' + ex.getMessage());
        }
    }
}