public class CartController {
    @AuraEnabled()
    public static Map<String,Object> insertCarts(Map<String, Object> cartData,String recordId) {
        if (cartData!= null) {
            Map<String,Object> result = new Map<String,Object>();
            List<Account> accounts = ProductController.getAccountsForLoggedInUser(recordId);
            System.debug('Accounts' + accounts);

            if (accounts.isEmpty()) {
                throw new AuraHandledException('No account found for the logged-in user');
            }
            Cart__c cart = new Cart__c();
            
            String productId = (String) cartData.get('id');
            String cartName = (String) cartData.get('name');
            Decimal price = Decimal.valueOf((String) cartData.get('price'));
            String imageUrl = (String) cartData.get('imageUrl');
            Decimal bundleQuantity=(Decimal)cartData.get('quantity');
            Decimal total=(Decimal)cartData.get('total');
            Decimal boxes=Decimal.valueOf((String)cartData.get('boxes'));
            String producttype=(String)cartData.get('type');
            
            
            Product2 productTemplate = [SELECT Id, Name FROM Product2 WHERE Id = :productId LIMIT 1];
            List<Cart_Item__c> items=new List<Cart_Item__c>();
            if (productTemplate != null) {
        
                cart.Name = cartName;
                cart.Unit_Price__c = price;
                cart.Image_URL__c = imageUrl;
                cart.Product__c = productTemplate.Id;
                
                cart.Account__c = accounts[0].Id;
                cart.Bundle_Quantity__c=bundleQuantity!=null ?bundleQuantity:0;
                cart.Total__c=total!=null?total:0;
                cart.Boxes__c=boxes!=null?boxes:0;
                cart.Product_type__c=producttype;
                
                try {
                    insert cart;
                    result.put('cartId',cart.Id);
                    result.put('id',cart.Product__c);
                    result.put('name',cart.Name);
                    result.put('price',cart.Unit_Price__c);
                    result.put('imageUrl',cart.Image_URL__c);
                    result.put('boxes',String.valueOf(cart.Boxes__c));
                    result.put('quantity',cart.Bundle_Quantity__c);
                    result.put('type',cart.Product_type__c);
                    result.put('total',cart.Total__c);
                   
                    System.debug('Cart inserted successfully.');
                } catch (DmlException e) {
                    System.debug('Error inserting cart: ' + e.getMessage());
                }
                Map<Object, Object> sizeMap = (Map<Object, Object>) cartData.get('sizes');
                if(!sizeMap.isEmpty()){
                    for (Object sizeKeyObj : sizeMap.keySet()) {
                        String sizeKey = String.valueOf(sizeKeyObj);
                        Map<Object, Object> sizeValueObj = (Map<Object, Object>) sizeMap.get(sizeKeyObj);
                        if(!sizeValueObj.isEmpty()){
                            for (Object entryKey : sizeValueObj.keySet()) {
                                String key = String.valueOf(entryKey);
                                Map<Object, Object> sizeValueObjinside = (Map<Object, Object>) sizeValueObj.get(entryKey);
                                //for(Object entry:sizeValueObjinside.keySet()){
                                    Decimal sizeValue = (Decimal) sizeValueObjinside.get('quantity');
                                    String colorvar=(String)sizeValueObjinside.get('color');
                                    System.debug('sizeKey: ' + key + ', sizeValue: ' + sizeValue+'color  :'+colorvar);
                                    
                                    if (sizeValue > 0) {
                                        
                                        Cart_Item__c cartItems=new Cart_Item__c();
                                        cartItems.Cart__c = cart.Id;
                                        cartItems.Name = key;
                                        cartItems.Size__c=sizeKey;
                                        cartItems.Product_varient__c=key;
                                        cartItems.Quantity__c = sizeValue;
                                        
                                        cartItems.Color__c = colorvar;
                                        items.add(cartItems);
                                        
                                            
                                    }
                                    
                                }
                            }
                            
                        }
                    }
                    if(!items.isEmpty()){
                        try {
                            insert items;
                            result.put('sizes',items);
                            System.debug('Cart Items inserted successfully.');
                        }catch(DmlException e) {
                            System.debug('Error inserting cart items: ' + e.getMessage());
                        }
                    }
                }
                 return result;
                
            } 
           return null; 
        }
        @AuraEnabled(cacheable=true)
        public static List<Cart__c>  getAllCartItems(String recordId){
            try {
                List<Account> accounts = ProductController.getAccountsForLoggedInUser(recordId);
                System.debug('Accounts' + accounts);
                
                if (accounts.isEmpty()) {
                    throw new AuraHandledException('No account found for the logged-in user');
                }
                List<Cart__c> cartdetails=[SELECT Id,Name,Unit_Price__c,Image_URL__c,Product__c,Account__c,Bundle_Quantity__c,Total__c,Boxes__c,Product_type__c,(SELECT Id,Name,Color__c,Quantity__c,Size__c,Product_varient__c From Cart_Items__r Where Id != null) From Cart__c Where Account__c =:accounts[0].Id];

                return cartdetails;

            } catch (Exception e) {
                throw new AuraHandledException(e.getMessage());
            }
        }
        @AuraEnabled
        public static void deleteFromCart(String cartId,String recordId){
            try {
                List<Account> accounts = ProductController.getAccountsForLoggedInUser(recordId);
                System.debug('Accounts' + accounts);
                
                if (accounts.isEmpty()) {
                    throw new AuraHandledException('No account found for the logged-in user');
                }
                Cart__c c = [SELECT Id,Account__c FROM Cart__c WHERE Id = :cartId AND Account__c=:accounts[0].Id];
                System.debug('cartItems to delete'+c);
                    if(c!=null){
                        delete c;
                    }
            } catch (Exception e) {
                throw new AuraHandledException(e.getMessage());
            }
        }
    }