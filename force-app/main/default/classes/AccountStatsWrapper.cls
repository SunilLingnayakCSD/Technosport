public class AccountStatsWrapper {
     @AuraEnabled public Account account;
      @AuraEnabled  public Integer totalCases;
     @AuraEnabled public Integer casesNotOnHold;
     @AuraEnabled public Integer closedCases;
     @AuraEnabled public Integer totalLeads;
    @AuraEnabled  public Integer convertedLeads;
    @AuraEnabled  public Integer unqualifiedLeads;
     @AuraEnabled  public Decimal totalSalesCurrentMonth;
     @AuraEnabled  public Decimal totalSalesLastMonth;

    public AccountStatsWrapper(Account account) {
        this.account = account;
        this.totalCases = 0;
        this.casesNotOnHold = 0;
        this.closedCases = 0;
        this.totalLeads = 0;
        this.convertedLeads = 0;
        this.unqualifiedLeads = 0;
        this.totalSalesCurrentMonth=0;
        this.totalSalesLastMonth=0;
    }
}