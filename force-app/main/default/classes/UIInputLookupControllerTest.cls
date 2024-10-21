@isTest 
private class UIInputLookupControllerTest {

    @isTest
    private static void apexSearchTest() {
            UIInputLookupController.apexSearch('User', '' , null, null, '', false, '');
            UIInputLookupController.apexSearch('User', '' , null, null, '', false, '');
            UIInputLookupController.apexSearch('User', 'Test' , null, null, '', true, '');
            UIInputLookupController.apexSearch('User', '' , null, null, '', true, '');
    }
}