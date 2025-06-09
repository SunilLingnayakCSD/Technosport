public class CartController {
    
    @AuraEnabled()
    public static Map<String,Object> insertCarts(Map<String, Object> cartData, String recordId,String visitId) {
        try {
            System.debug('cartData--->'+ JSON.serializePretty(cartData));
            System.debug('recordId--->'+ recordId);
            Boolean isAdmin = [SELECT Profile.Name FROM User WHERE Id = :recordId LIMIT 1].Profile.Name == 'Sales Representative';
            
            if (cartData == null) {
                throw new AuraHandledException('Cart data cannot be null');
            }

            List<Account> accounts;
            String accountId;
            String Accountname;
            if(!isAdmin){
            accounts = ProductController.getAccountsForLoggedInUser(recordId);
            System.debug('Accounts' + accounts);
			accountId=accounts[0].Id;
            Accountname=accounts[0].Name;
            if (accounts.isEmpty()) {
                throw new AuraHandledException('No account found for the logged-in user');
            	}
            }
            else{
                
              List<Visit> visit=[Select Id, AccountId,Account.Name From Visit Where Id=:visitId];
                if(!visit.isEmpty()){
                   accountId=visit[0].AccountId;
                    Accountname=visit[0].Account.Name;
                }
            }
            
            String productId = getStringValue(cartData.get('id'));
            String cartName = getStringValue(cartData.get('name'));
            Decimal price = getDecimalValue(cartData.get('price'));
            String imageUrl = getStringValue(cartData.get('imageUrl'));
            Decimal bundleQuantity = getDecimalValue(cartData.get('quantity'));
            Decimal total = getDecimalValue(cartData.get('total'));
            Decimal boxes = getDecimalValue(cartData.get('boxes'));
            String productType = getStringValue(cartData.get('type'));
            Decimal retailerprice=getDecimalvalue(cartData.get('retailerPrice'));
            Decimal noofpieces=getDecimalvalue(cartData.get('noofpieces'));
            Boolean isfuture=boolean.valueOf(cartData.get('isFutureProduct'));
            Boolean isFutureQuoShouuldteCreate=boolean.valueOf(cartData.get('isFutureQuoShouuldteCreate'));
          
            Product2 productTemplate = [SELECT Id, Name FROM Product2 WHERE Id = :productId LIMIT 1];
            if (productTemplate == null) {
                throw new AuraHandledException('Product not found');
            }
       
            Cart__c cart = new Cart__c(
                Name = cartName,
                Unit_Price__c = price,
                Image_URL__c = imageUrl,
                Product__c = productTemplate.Id,
                Account__c = accountId,
                Bundle_Quantity__c = bundleQuantity != null ? bundleQuantity : 0,
                Total__c = total != null ? total : 0,
                Boxes__c = boxes != null ? boxes : 0,
                Product_type__c = productType,
                Total_Retailer_Price__c=retailerprice != null ?retailerprice:0,
                No_of_Boxes_Pieces_In_Bundle__c=noofpieces,
                isFutureProduct__c=isfuture,
                isFutureQuoShouuldteCreate__c=isFutureQuoShouuldteCreate
            );
            
            insert cart;
            System.debug('Cart inserted successfully: ' + cart.Id);
            
            // Prepare result map
            Map<String,Object> result = new Map<String,Object>{
                'cartId' => cart.Id,
                'id' => cart.Product__c,
                'name' => cart.Name,
                'price' => cart.Unit_Price__c,
                'imageUrl' => cart.Image_URL__c,
                'boxes' => cart.Boxes__c,
                'quantity' => cart.Bundle_Quantity__c,
                'type' => cart.Product_type__c,
                'total' => cart.Total__c,
                    'retailerPrice'=>cart.Total_Retailer_Price__c,
                    'noofpieces'=>cart.No_of_Boxes_Pieces_In_Bundle__c,
                    'isFutureProduct'=>cart.isFutureProduct__c,
                    'isFutureQuoShouuldteCreate'=>cart.isFutureQuoShouuldteCreate__c
            };
            
       
            List<Cart_Item__c> cartItems = processSizeVariants(cartData, cart.Id);
            if (!cartItems.isEmpty()) {
                insert cartItems;
                result.put('sizes', cartItems);
                System.debug('Inserted ' + cartItems.size() + ' cart items');
            }
            
            return result;
            
        } catch (Exception e) {
            System.debug('Error in insertCarts: ' + e.getMessage() + '\n' + e.getStackTraceString());
            throw new AuraHandledException('Error processing cart: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Cart__c> getAllCartItems(String recordId,String visitId) {
        try {
            Boolean isAdmin = [SELECT Profile.Name FROM User WHERE Id = :recordId LIMIT 1].Profile.Name == 'Sales Representative';
            List<Account> accounts;
            String accountId;
            String Accountname;
            if(!isAdmin){
            accounts = ProductController.getAccountsForLoggedInUser(recordId);
            System.debug('Accounts' + accounts);
			accountId=accounts[0].Id;
            Accountname=accounts[0].Name;
            if (accounts.isEmpty()) {
                throw new AuraHandledException('No account found for the logged-in user');
            	}
            }
            else{
                
              List<Visit> visit=[Select Id, AccountId,Account.Name From Visit Where Id=:visitId];
                if(!visit.isEmpty()){
                   accountId=visit[0].AccountId;
                    Accountname=visit[0].Account.Name;
                }
            }
          
            
            return [SELECT Id, Name, Unit_Price__c, Image_URL__c, Product__c, Account__c,isFutureQuoShouuldteCreate__c,isFutureProduct__c, 
                    Bundle_Quantity__c, Total__c, Boxes__c, Product_type__c,Total_Retailer_Price__c,No_of_Boxes_Pieces_In_Bundle__c,
                    (SELECT Id, Name, Color__c, Quantity__c, Size__c, Product_varient__c,isUpcomingVarient__c 
                     FROM Cart_Items__r 
                     WHERE Id != null) 
                    FROM Cart__c 
                    WHERE Account__c = :accountId];
                    
        } catch (Exception e) {
            System.debug('Error in getAllCartItems: ' + e.getMessage());
            throw new AuraHandledException('Error retrieving cart items: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static void deleteFromCart(String cartId, String recordId,String visitId) {
        try {
            Boolean isAdmin = [SELECT Profile.Name FROM User WHERE Id = :recordId LIMIT 1].Profile.Name == 'Sales Representative';
            List<Account> accounts;
            String accountId;
            String Accountname;
            if(!isAdmin){
            accounts = ProductController.getAccountsForLoggedInUser(recordId);
            System.debug('Accounts' + accounts);
			accountId=accounts[0].Id;
            Accountname=accounts[0].Name;
            if (accounts.isEmpty()) {
                throw new AuraHandledException('No account found for the logged-in user');
            	}
            }
            else{
                
              List<Visit> visit=[Select Id, AccountId,Account.Name From Visit Where Id=:visitId];
                if(!visit.isEmpty()){
                   accountId=visit[0].AccountId;
                    Accountname=visit[0].Account.Name;
                }
            }
            
            Cart__c cartToDelete = [SELECT Id FROM Cart__c 
                                  WHERE Id = :cartId 
                                  AND Account__c = :accountId
                                  LIMIT 1];
            
            if (cartToDelete != null) {
                delete cartToDelete;
                System.debug('Deleted cart: ' + cartId);
            }
            
        } catch (Exception e) {
            System.debug('Error in deleteFromCart: ' + e.getMessage());
            throw new AuraHandledException('Error deleting cart: ' + e.getMessage());
        }
    }
    
    // Helper method to process size variants
    private static List<Cart_Item__c> processSizeVariants(Map<String, Object> cartData, Id cartId) {
        List<Cart_Item__c> items = new List<Cart_Item__c>();
        
        try {
            Map<Object, Object> sizeMap = (Map<Object, Object>) cartData.get('sizes');
            if (sizeMap != null && !sizeMap.isEmpty()) {
                for (Object sizeKeyObj : sizeMap.keySet()) {
                    String sizeKey = String.valueOf(sizeKeyObj);
                    Map<Object, Object> sizeValueObj = (Map<Object, Object>) sizeMap.get(sizeKeyObj);
                    
                    if (sizeValueObj != null) {
                        for (Object entryKey : sizeValueObj.keySet()) {
                            String variantId = String.valueOf(entryKey);
                            Map<Object, Object> variantData = (Map<Object, Object>) sizeValueObj.get(entryKey);
                            
                            Decimal quantity = getDecimalValue(variantData.get('quantity'));
                            String color = getStringValue(variantData.get('color'));
                            boolean isupcomming=boolean.valueOf(variantData.get('isUpcomingVariant'));
                            
                            if (quantity > 0) {
                                items.add(new Cart_Item__c(
                                    Cart__c = cartId,
                                    Name = variantId,
                                    Size__c = sizeKey,
                                    Product_varient__c = variantId,
                                    Quantity__c = quantity,
                                    Color__c = color,
                                    isUpcomingVarient__c=isupcomming
                                ));
                            }
                        }
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error processing size variants: ' + e.getMessage());
        }
        
        return items;
    }
    
    // Helper method to safely convert to Decimal
    private static Decimal getDecimalValue(Object value) {
        if (value == null) return 0;
        if (value instanceof Decimal) return (Decimal)value;
        if (value instanceof Integer) return Decimal.valueOf((Integer)value);
        if (value instanceof String) {
            try {
                return Decimal.valueOf(((String)value).trim());
            } catch (Exception e) {
                return 0;
            }
        }
        return 0;
    }
    
    // Helper method to safely convert to String
    private static String getStringValue(Object value) {
        if (value == null) return '';
        return String.valueOf(value);
    }
}