public class InsertOrderMain {
	 @AuraEnabled
    public static boolean callSuitableMethod(List<Map<String, Object>> productsList, String recordId,String visitId,String distributorId){
        Boolean isAdmin = [SELECT Profile.Name FROM User WHERE Id = :recordId LIMIT 1].Profile.Name == 'Sales Representative';
        if(!isAdmin){
            return InsertOrder.CreateOrder(productsList,recordId);
        }
        else{
            return InsertreatilerOrder.CreateOrder(productsList,recordId,visitId,distributorId);
        }
      // return false;
    }
}