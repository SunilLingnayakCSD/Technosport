@isTest
public class OrderTargetBatchTest {
    
    static Order od1;
    static Order od2;
    static List<Order> odList = new List<Order>();
    
    @testSetup
    public static void setupMethod(){
        
        Account acc = new Account(
            name = 'Acc1',
            BillingPostalCode = '581178',
            BillingState = 'Karnataka',
            BillingStreet = '3rd cross',
            BillingCity = 'Mysore'
        );
        insert acc;
        
        od1 = new Order(
            name = 'Od1',
            AccountId = acc.Id,
            EffectiveDate = System.today(),
            isASMorder__c = true,
            RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Order' AND DeveloperName = 'Sales_Order'].Id,
            status = 'Draft'
        );
        odList.add(od1);
        
        od2 = new Order(
            name = 'Od2',
            AccountId = acc.Id,
            EffectiveDate = System.today(),
            isASMorder__c = true,
            RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Order' AND DeveloperName = 'Sales_Order'].Id,
            status = 'Draft',
            Order_Type__c = 'TD Order'
        );
        odList.add(od2);
        
        insert odList;
        
        od1.put('Order_Amount__c', 110);
        update od1;
    }
    
    @isTest
    public static void orderBatchTestMethod(){
        od1 = [SELECT Id, Name FROM Order WHERE Name = 'Od1'];
        od2 = [SELECT Id, Name FROM Order WHERE Name ='Od2'];
        List<Order> oderList = new List<Order>{od1, od2};
        System.debug('od--> '+ oderList);
        Test.startTest();
        OrderTargetBatch.processOrders(oderList);
        OrderTargetBatch.processUniqueOrdersMonthly(oderList);
        Test.stopTest();
    }
}