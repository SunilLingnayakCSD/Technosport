public class OrderTargetBatch {
    
    public static void processOrders(List<Order> orders) {
        if (orders.isEmpty()) return;
        
        Set<Id> orderIds = new Set<Id>();
        for (Order ord : orders) {
            orderIds.add(ord.Id);
        }
        
        List<Order> fullOrders = [
            SELECT Id, Order_Amount__c, CreatedById, CreatedDate, AccountId, Account.Name,
            RecordType.DeveloperName, isASMorder__c, Order_Type__c
            FROM Order
            WHERE Id IN :orderIds AND RecordType.DeveloperName = 'Sales_Order'
        ];
        
        List<Order> retailerOrders = new List<Order>();
        List<Order> asmOrders = new List<Order>();
        List<Order> technoOrders = new List<Order>();
        List<Order> nonTechnoOrders = new List<Order>();
        
        for (Order ord : fullOrders) {
            if (ord.AccountId != null) {
                retailerOrders.add(ord);
            }
            
            if (ord.isASMorder__c == true) {
                asmOrders.add(ord);
                if (ord.Order_Type__c == 'TD Order') {
                    technoOrders.add(ord);
                } else {
                    nonTechnoOrders.add(ord);
                }
            }
        }
        List<ASM_AOP_Target__c> existingTargets = new List<ASM_AOP_Target__c>();
        
        if (!retailerOrders.isEmpty()) {
            processRetailerTargets(retailerOrders);
        }
        if (!asmOrders.isEmpty()) {
            existingTargets = getASMRecordwithFields(asmOrders, 'TotalOrder');
            updateASMTargets(asmOrders,existingTargets, 'Total_Order_Target__c', 'Total_Order_YTD_Achieved__c', 'Total_Order');
        }
        if (!technoOrders.isEmpty()) {
            existingTargets = getASMRecordwithFields(technoOrders, 'Techno');
            updateASMTargets(technoOrders,existingTargets, 'Technodirect_Order_Target__c', 'Technodirect_YTD_Achieved__c', 'Technosdirect');
        }
        if (!nonTechnoOrders.isEmpty()) {
            existingTargets = getASMRecordwithFields(nonTechnoOrders, 'NonTechno');
            updateASMTargets(nonTechnoOrders,existingTargets, 'Nontechno_Direct_Order_Target__c', 'Nontechno_Direct_YTD_Achieved__c', 'Nontechno_Direct');
        }
    }
    
    Public static void processRetailerTargets(List<Order> orders) {
        Set<String> years = new Set<String>();
        Set<Id> accountIds = new Set<Id>();
        
        for (Order ord : orders) {
            years.add(String.valueOf(ord.CreatedDate.year()));
            accountIds.add(ord.AccountId);
        }
        
        List<Retailer_AOP_Target__c> existingTargets = [
            SELECT Id, Account__c, Year__c,
            January_Achieved_Target__c, February_Achieved_Target__c, March_Achieved_Target__c,
            April_Achieved_Target__c, May_Achieved_Target__c, June_Achieved_Target__c,
            July_Achieved_Target__c, August_Achieved_Target__c, September_Achieved_Target__c,
            October_Achieved_Target__c, November_Achieved_Target__c, December_Achieved_Target__c,
            Q1_Achieved_Target__c, Q2_Achieved_Target__c, Q3_Achieved_Target__c, Q4_Achieved_Target__c,
            Year_Achieved_Target__c,Order_Created_Date__c
            FROM Retailer_AOP_Target__c
            WHERE Year__c IN :years AND Account__c IN :accountIds
        ];
        
        Map<String, Retailer_AOP_Target__c> existingMap = new Map<String, Retailer_AOP_Target__c>();
        for (Retailer_AOP_Target__c t : existingTargets) {
            existingMap.put(t.Account__c + '_' + t.Year__c, t);
        }
        
        Map<Id, Retailer_AOP_Target__c> updateMap = new Map<Id, Retailer_AOP_Target__c>();
        List<Retailer_AOP_Target__c> inserts = new List<Retailer_AOP_Target__c>();
        
        Map<Id, String> accountIdToRecordType = new Map<Id, String>();
        for (Account acc : [
            SELECT Id, RecordType.DeveloperName
            FROM Account
            WHERE Id IN :accountIds
        ]) {
            accountIdToRecordType.put(acc.Id, acc.RecordType.DeveloperName);
        }
        
        for (Order ord : orders) {
            String year = String.valueOf(ord.CreatedDate.year());
            String month = ord.CreatedDate.format('MMMM');
            String quarter = getQuarterField(ord.CreatedDate.month());
            String key = ord.AccountId + '_' + year;
            Decimal amt = ord.Order_Amount__c == null ? 0 : ord.Order_Amount__c;
            
            Retailer_AOP_Target__c target = existingMap.get(key);
            
            if (target == null) {
                target = new Retailer_AOP_Target__c(
                    Account__c = ord.AccountId
                    // Name = 'Retailer AOP Target ' + year + ' - ' + ord.Account.Name
                );
                existingMap.put(key, target);
                inserts.add(target);
            }
            
            target.put(month + '_Achieved_Target__c', safeAdd(target.get(month + '_Achieved_Target__c'), amt));
            target.put(quarter, safeAdd(target.get(quarter), amt));
            target.put('Year_Achieved_Target__c', safeAdd(target.get('Year_Achieved_Target__c'), amt));
            
            if (accountIdToRecordType.get(ord.AccountId) == 'Customer') {
                Date newDate = ord.CreatedDate.date();
                Date existingDate = (Date) target.get('Order_Created_Date__c');
                
                if (existingDate == null || existingDate <= newDate) {
                    target.put('Order_Created_Date__c', newDate);
                }
            }
            
            
            if (target.Id != null) updateMap.put(target.Id, target);
        }
        
        if (!updateMap.isEmpty()){
            update updateMap.values();
            System.debug('updateMap.values()--> ' + updateMap.values());
        } 
        if (!inserts.isEmpty()) {
            insert inserts;
            System.debug('insertsMap.values()--> ' + inserts);
        }
    }
    
    private static void updateASMTargets(List<Order> orders, List<ASM_AOP_Target__c> existingTargets, String monthlySuffix, String yearField, String typePrefix) {
        
        Map<String, ASM_AOP_Target__c> existingMap = new Map<String, ASM_AOP_Target__c>();
        for (ASM_AOP_Target__c t : existingTargets) {
            existingMap.put(t.Sales_Rep__c + '_' + t.Year__c, t);
        }
        
        Map<Id, ASM_AOP_Target__c> updateMap = new Map<Id, ASM_AOP_Target__c>();
        List<ASM_AOP_Target__c> inserts = new List<ASM_AOP_Target__c>();
        
        for (Order ord : orders) {
            String year = String.valueOf(ord.CreatedDate.year());
            String month = ord.CreatedDate.format('MMMM');
            String quarter = getASMQuarterField(ord.CreatedDate.month(), typePrefix);
            String key = ord.CreatedById + '_' + year;
            Decimal amt = ord.Order_Amount__c == null ? 0 : ord.Order_Amount__c;
            
            ASM_AOP_Target__c target = existingMap.get(key);
            
            if (target == null) {
                target = new ASM_AOP_Target__c(Sales_Rep__c = ord.CreatedById);
                existingMap.put(key, target);
                inserts.add(target);
            }
            
            target.put(month + '_' + monthlySuffix, safeAdd(target.get(month + '_' + monthlySuffix), amt));
            target.put(quarter, safeAdd(target.get(quarter), amt));
            target.put(yearField, safeAdd(target.get(yearField), amt));
            
            if (target.Id != null) updateMap.put(target.Id, target);
        }
        
        if (!updateMap.isEmpty()) {
            update updateMap.values();
            System.debug('MonthlySuffix--> ' + monthlySuffix);
            System.debug('updateMap--> ' + updateMap.values());
        }
        if (!inserts.isEmpty()) {
            insert inserts;
            System.debug('inserts--> ' + inserts);
            System.debug('MonthlySuffixs--> ' + monthlySuffix);
        }
    }
    
    private static Decimal safeAdd(Object current, Decimal add) {
        return (current == null ? 0 : (Decimal)current) + add;
    }
    
    private static String getQuarterField(Integer month) {
        if (month <= 3) return 'Q1_Achieved_Target__c';
        if (month <= 6) return 'Q2_Achieved_Target__c';
        if (month <= 9) return 'Q3_Achieved_Target__c';
        return 'Q4_Achieved_Target__c';
    }
    
    private static String getASMQuarterField(Integer month, String prefix) {
        if (month <= 3) return 'Q1_' + prefix + '_QTD_Target__c';
        if (month <= 6) return 'Q2_' + prefix + '_QTD_Target__c';
        if (month <= 9) return 'Q3_' + prefix + '_QTD_Target__c';
        return 'Q4_' + prefix + '_QTD_Target__c';
    }
    
    private static List<ASM_AOP_Target__c> getASMRecordwithFields(List<Order> orders, String type){
        Set<String> years = new Set<String>();
        Set<Id> reps = new Set<Id>();
        
        for (Order ord : orders) {
            years.add(String.valueOf(ord.CreatedDate.year()));
            reps.add(ord.CreatedById);
        }
        
        List<ASM_AOP_Target__c> existingTargets = new List<ASM_AOP_Target__c>();
        
        if(type == 'TotalOrder')
        {
            existingTargets = [
                SELECT Id,Sales_Rep__c,Year__c,
                January_Total_Order_Target__c, February_Total_Order_Target__c, March_Total_Order_Target__c, 
                April_Total_Order_Target__c, May_Total_Order_Target__c, June_Total_Order_Target__c, 
                July_Total_Order_Target__c, August_Total_Order_Target__c, September_Total_Order_Target__c, 
                October_Total_Order_Target__c, November_Total_Order_Target__c, December_Total_Order_Target__c,
                Q1_Total_Order_QTD_Target__c, Q2_Total_Order_QTD_Target__c, Q3_Total_Order_QTD_Target__c, Q4_Total_Order_QTD_Target__c,
                Total_Order_YTD_Achieved__c
                FROM ASM_AOP_Target__c
                WHERE Year__c IN :years AND Sales_Rep__c IN :reps
            ];
        }else if (type == 'Techno'){
            existingTargets = [SELECT Id,Sales_Rep__c,Year__c,
                               January_Technodirect_Order_Target__c, February_Technodirect_Order_Target__c, March_Technodirect_Order_Target__c, 
                               April_Technodirect_Order_Target__c, May_Technodirect_Order_Target__c, June_Technodirect_Order_Target__c, 
                               July_Technodirect_Order_Target__c, August_Technodirect_Order_Target__c, September_Technodirect_Order_Target__c, 
                               October_Technodirect_Order_Target__c, November_Technodirect_Order_Target__c, December_Technodirect_Order_Target__c,
                               Q1_Technosdirect_QTD_Target__c, Q2_Technosdirect_QTD_Target__c, Q3_Technosdirect_QTD_Target__c, Q4_Technosdirect_QTD_Target__c,
                               Technodirect_YTD_Achieved__c
                               FROM ASM_AOP_Target__c
                               WHERE Year__c IN :years AND Sales_Rep__c IN :reps
                              ];
        }else{
            existingTargets = [SELECT Id,Sales_Rep__c,Year__c,
                               January_Nontechno_Direct_Order_Target__c, February_Nontechno_Direct_Order_Target__c, March_Nontechno_Direct_Order_Target__c, 
                               April_Nontechno_Direct_Order_Target__c, May_Nontechno_Direct_Order_Target__c, June_Nontechno_Direct_Order_Target__c, 
                               July_Nontechno_Direct_Order_Target__c, August_Nontechno_Direct_Order_Target__c, September_Nontechno_Direct_Order_Target__c, 
                               October_Nontechno_Direct_Order_Target__c, November_Nontechno_Direct_Order_Target__c, December_Nontechno_Direct_Order_Target__c,
                               Q1_Nontechno_Direct_QTD_Target__c, Q2_Nontechno_Direct_QTD_Target__c, Q3_Nontechno_Direct_QTD_Target__c, Q4_Nontechno_Direct_QTD_Target__c,
                               Nontechno_Direct_YTD_Achieved__c
                               FROM ASM_AOP_Target__c
                               WHERE Year__c IN :years AND Sales_Rep__c IN :reps];
        }
        
        return existingTargets;
    }
    
    public static void processUniqueOrdersMonthly(List<Order> orders){
        if (orders.isEmpty()) return;
        
        Set<Id> orderIds = new Set<Id>();
        for (Order ord : orders) {
            orderIds.add(ord.Id);
        }
        
        List<Order> fullOrders = [
            SELECT Id, Order_Amount__c, CreatedById, CreatedDate, AccountId, Account.Name,
            RecordType.DeveloperName, isASMorder__c, Order_Type__c
            FROM Order
            WHERE Id IN :orderIds AND RecordType.DeveloperName = 'Sales_Order'
        ];
        
        List<Order> asmOrders = new List<Order>();
        List<Order> technoOrders = new List<Order>();
        List<Order> nonTechnoOrders = new List<Order>();
        
        for (Order ord : fullOrders) {
            if (ord.isASMorder__c == true) {
                asmOrders.add(ord);
                if (ord.Order_Type__c == 'TD Order') {
                    technoOrders.add(ord);
                } else {
                    nonTechnoOrders.add(ord);
                }
            }
        }
        List<ASM_AOP_Target__c> existingTargets = new List<ASM_AOP_Target__c>();
        
        if (!asmOrders.isEmpty()) {
            existingTargets = getUniqueAOPRecordwithFields(asmOrders, 'TotalOrder');
            processTechnodirectOrderCount(asmOrders, '_Unique_Total_Order_MTD__c', existingTargets, 'TotalOrder');
        }
        if (!technoOrders.isEmpty()) {
            existingTargets = getUniqueAOPRecordwithFields(technoOrders, 'Techno');
            processTechnodirectOrderCount(technoOrders, '_Unique_Technodirect_Order_MTD__c', existingTargets, 'Techno');
        }
        if (!nonTechnoOrders.isEmpty()) {
            existingTargets = getUniqueAOPRecordwithFields(nonTechnoOrders, 'Nontechno');
            processTechnodirectOrderCount(nonTechnoOrders, '_Unique_NTD_Order_MTD__c',existingTargets, 'Nontechno');
        }
    }
    
    public static void processTechnodirectOrderCount(List<Order> orders, String monthSuffix, List<ASM_AOP_Target__c> existingTargets, String type) {
        
        System.debug('orders--> '+ orders);
        DateTime currentDate = Date.today();
        String currentMonth = currentDate.format('MMMM');
        Integer currentMonthNum = currentDate.month();
        Integer currentYearNum = currentDate.year();
        String currentYear = String.valueOf(currentYearNum); 
        
        // Filter Technodirect orders of current month and year
        List<Order> technoOrders = new List<Order>();
        Set<Id> repIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();
        
        for (Order ord : orders) {
            Integer orderMonth = ord.CreatedDate.month();
            Integer orderYear = ord.CreatedDate.year();
            System.debug('orderMonth '+ orderMonth);
            System.debug('currentMonthNum '+ currentMonthNum);
            System.debug('orderYear '+ orderYear);
            System.debug('currentYearNum '+ currentYearNum);
            System.debug('ord.RecordType.DeveloperName '+ ord.RecordType.DeveloperName);
            System.debug('Sales_Order ');
            if (orderMonth == currentMonthNum && orderYear == currentYearNum) {
                technoOrders.add(ord);
                System.debug('technoOrders--> '+ technoOrders);
                repIds.add(ord.CreatedById);
                System.debug('repIds--> '+ repIds);
                accountIds.add(ord.AccountId);
                System.debug('accountIds--> '+ accountIds);
            }
        }
        
        if (technoOrders.isEmpty()) return;
        
        Map<String, ASM_AOP_Target__c> targetMap = new Map<String, ASM_AOP_Target__c>();
        for (ASM_AOP_Target__c t : existingTargets) {
            targetMap.put(t.Sales_Rep__c + '_' + t.Year__c, t);
        }
        
        String orderType = orders[0].Order_Type__c;
        
        // Query existing orders in this month for each rep-account
        List<Order> historicalOrders = new List<Order>();
        
        if(type == 'TotalOrder'){
            historicalOrders = [
                SELECT CreatedById, AccountId
                FROM Order
                WHERE CreatedById IN :repIds
                AND AccountId IN :accountIds
                AND Id NOT IN :technoOrders
                AND isASMorder__c = TRUE
                AND CALENDAR_MONTH(CreatedDate) = :currentMonthNum
                AND CALENDAR_YEAR(CreatedDate) = :currentYearNum
                AND RecordType.DeveloperName = 'Sales_Order'
            ];
        }else {
            historicalOrders = [
                SELECT CreatedById, AccountId
                FROM Order
                WHERE CreatedById IN :repIds
                AND AccountId IN :accountIds
                AND Id NOT IN :technoOrders
                AND isASMorder__c = TRUE
                AND CALENDAR_MONTH(CreatedDate) = :currentMonthNum
                AND CALENDAR_YEAR(CreatedDate) = :currentYearNum
                AND RecordType.DeveloperName = 'Sales_Order' 
                AND Order_Type__c = :orderType
            ];
        }
        
        // Build map of existing rep-account combos in current month
        Set<String> existingCombos = new Set<String>();
        for (Order ord : historicalOrders) {
            existingCombos.add(ord.CreatedById + '_' + ord.AccountId);
        }
        System.debug('existingCombos--> '+ existingCombos);
        
        Set<String> newCombos = new Set<String>();
        List<ASM_AOP_Target__c> toUpdate = new List<ASM_AOP_Target__c>();
        List<ASM_AOP_Target__c> toInsert = new List<ASM_AOP_Target__c>();
        
        for (Order ord : technoOrders) {
            System.debug('ord --> '+ ord);
            String comboKey = ord.CreatedById + '_' + ord.AccountId;
            System.debug('comboKey --> '+ comboKey);
            String repKey = ord.CreatedById + '_' + currentYear;
            
            // If this is the first time this combo appears in this run and wasn't in historical data
            if (!existingCombos.contains(comboKey) && !newCombos.contains(comboKey)) {
                ASM_AOP_Target__c target = targetMap.get(repKey);
                if (target == null) {
                    target = new ASM_AOP_Target__c(Sales_Rep__c = ord.CreatedById);
                    targetMap.put(repKey, target);
                    toInsert.add(target);
                }
                
                String monthField = currentMonth + monthSuffix;
                System.debug('monthField--> '+ monthField);
                Decimal currentVal = (Decimal)target.get(monthField);
                target.put(monthField, (currentVal == null ? 0 : currentVal) + 1);
                
                if (target.Id != null && !toUpdate.contains(target)) {
                    toUpdate.add(target);
                }
                
                newCombos.add(comboKey);
                System.debug('newCombos--> '+ newCombos);
            }
        }
        
        if (!toInsert.isEmpty()) {
            insert toInsert;
            System.debug('toInsert--> '+ toInsert);
        }
        if (!toUpdate.isEmpty()) {
            update toUpdate;
            System.debug('toUpdate--> '+ toUpdate);
        }
    }
    
    private static List<ASM_AOP_Target__c> getUniqueAOPRecordwithFields(List<Order> orders, String type){
        
        List<ASM_AOP_Target__c> existingTargets = new List<ASM_AOP_Target__c>();
        
        Integer currentYearNum = Date.today().year();
        String currentYear = String.valueOf(currentYearNum);
        Integer currentMonthNum = Date.today().month();
        
        Set<Id> repIds = new Set<Id>();
        for (Order ord : orders) {
            Integer orderMonth = ord.CreatedDate.month();
            Integer orderYear = ord.CreatedDate.year();
            if (orderMonth == currentMonthNum && orderYear == currentYearNum) {
                repIds.add(ord.CreatedById);
                System.debug('repIds--> '+ repIds);
            }
        }
        
        if(type == 'TotalOrder')
        {
            existingTargets = [
                SELECT Id, Sales_Rep__c, Year__c,
                January_Unique_Total_Order_MTD__c,
                February_Unique_Total_Order_MTD__c,
                March_Unique_Total_Order_MTD__c,
                April_Unique_Total_Order_MTD__c,
                May_Unique_Total_Order_MTD__c,
                June_Unique_Total_Order_MTD__c,
                July_Unique_Total_Order_MTD__c,
                August_Unique_Total_Order_MTD__c,
                September_Unique_Total_Order_MTD__c,
                October_Unique_Total_Order_MTD__c,
                November_Unique_Total_Order_MTD__c,
                December_Unique_Total_Order_MTD__c
                FROM ASM_AOP_Target__c
                WHERE Year__c = :currentYear AND Sales_Rep__c IN :repIds
            ];
        }else if (type == 'Techno'){
            existingTargets = [SELECT Id, Sales_Rep__c, Year__c,
                               January_Unique_Technodirect_Order_MTD__c,
                               February_Unique_Technodirect_Order_MTD__c,
                               March_Unique_Technodirect_Order_MTD__c,
                               April_Unique_Technodirect_Order_MTD__c,
                               May_Unique_Technodirect_Order_MTD__c,
                               June_Unique_Technodirect_Order_MTD__c,
                               July_Unique_Technodirect_Order_MTD__c,
                               August_Unique_Technodirect_Order_MTD__c,
                               September_Unique_Technodirect_Order_MTD__c,
                               October_Unique_Technodirect_Order_MTD__c,
                               November_Unique_Technodirect_Order_MTD__c,
                               December_Unique_Technodirect_Order_MTD__c
                               FROM ASM_AOP_Target__c
                               WHERE Year__c = :currentYear 
                               AND Sales_Rep__c IN :repIds
                              ];
        }else{
            existingTargets = [SELECT Id, Sales_Rep__c, Year__c,
                               January_Unique_NTD_Order_MTD__c,
                               February_Unique_NTD_Order_MTD__c,
                               March_Unique_NTD_Order_MTD__c,
                               April_Unique_NTD_Order_MTD__c,
                               May_Unique_NTD_Order_MTD__c,
                               June_Unique_NTD_Order_MTD__c,
                               July_Unique_NTD_Order_MTD__c,
                               August_Unique_NTD_Order_MTD__c,
                               September_Unique_NTD_Order_MTD__c,
                               October_Unique_NTD_Order_MTD__c,
                               November_Unique_NTD_Order_MTD__c,
                               December_Unique_NTD_Order_MTD__c
                               FROM ASM_AOP_Target__c
                               WHERE Year__c = :currentYear 
                               AND Sales_Rep__c IN :repIds
                              ];
        }
        
        return existingTargets;
    }
}